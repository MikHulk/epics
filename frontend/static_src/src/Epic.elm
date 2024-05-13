module Epic exposing (..)

import Browser
import Browser.Navigation as Nav
import Common exposing (logoutForm)
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Http
import Json.Decode as JsonD
import Json.Encode exposing (Value)
import Models.Epic exposing (Epic_, Epic_Stories__, ToModel, toModel)


type Msg
    = UserReturnsHome
    | UserAddStatusFilter Status
    | UserRemoveStatusFilter Status
    | UserRemoveAllFilters
    | UserUpdateTextSearch String
    | UserTakeStory Story
    | StoryTaken (Result Http.Error Epic_Stories__)


type alias Epic =
    { title : String
    , pubDate : String
    , description : String
    , ownerFullname : String
    }


type alias Story =
    { id : Int
    , pubDate : String
    , title : String
    , description : String
    , status : Status
    }


type Status
    = Created
    | OnGoing
    | Cancelled
    | Suspended
    | Finished
    | Unknown


type alias StoryModel =
    { stories : List Story
    , statusFilter : List Status
    , textSearch : Maybe String
    }


type alias Model =
    { session : SessionInfo
    , epic : Epic
    , stories : StoryModel
    , error : Maybe String
    }


type alias SessionInfo =
    { csrfToken : String
    , logoutUrl : String
    }


type State
    = Ready Model
    | Error


init : Value -> ( State, Cmd Msg )
init f =
    case JsonD.decodeValue toModel f of
        Ok m ->
            let
                toStory story =
                    { id = story.id
                    , title = story.title
                    , pubDate = story.pubDate
                    , description = story.description
                    , status = statusFromString story.status
                    }

                model =
                    { session =
                        { csrfToken = m.csrfToken
                        , logoutUrl = m.logoutUrl
                        }
                    , epic =
                        { title = m.epic.title
                        , pubDate = m.epic.pubDate
                        , description = m.epic.description
                        , ownerFullname = m.epic.ownerFullname
                        }
                    , stories =
                        { stories = List.map toStory m.epic.stories
                        , statusFilter = [ Cancelled, Finished, Suspended ]
                        , textSearch = Nothing
                        }
                    , error = Nothing
                    }
            in
            ( Ready model, Cmd.none )

        Err _ ->
            ( Error, Cmd.none )


main : Program Value State Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : State -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> State -> ( State, Cmd Msg )
update msg state =
    case ( state, msg ) of
        ( Ready _, UserReturnsHome ) ->
            ( state, Nav.load "/" )

        ( Ready model, UserRemoveAllFilters ) ->
            let
                newFilters =
                    []

                stories =
                    model.stories
            in
            ( Ready
                { model
                    | stories = { stories | statusFilter = newFilters }
                }
            , Cmd.none
            )

        ( Ready model, UserRemoveStatusFilter status ) ->
            let
                newFilters =
                    List.filter (\s -> s /= status) model.stories.statusFilter

                stories =
                    model.stories
            in
            ( Ready
                { model
                    | stories = { stories | statusFilter = newFilters }
                }
            , Cmd.none
            )

        ( Ready model, UserAddStatusFilter status ) ->
            let
                newFilters =
                    status :: model.stories.statusFilter

                stories =
                    model.stories
            in
            ( Ready
                { model
                    | stories = { stories | statusFilter = newFilters }
                }
            , Cmd.none
            )

        ( Ready model, UserUpdateTextSearch text ) ->
            let
                term =
                    if text /= "" then
                        Just <| String.toLower text

                    else
                        Nothing

                stories =
                    model.stories

                newStories =
                    { stories | textSearch = term }
            in
            ( Ready
                { model | stories = newStories }
            , Cmd.none
            )

        ( Ready model, UserTakeStory story ) ->
            ( state, takeStory model.session.csrfToken story.id )

        ( Ready model, StoryTaken (Ok story) ) ->
            let
                newStatus =
                    statusFromString story.status

                stories =
                    model.stories

                newStories =
                    List.map
                        (\s ->
                            if s.id == story.id then
                                { id = story.id
                                , pubDate = story.pubDate
                                , title = story.title
                                , description = story.description
                                , status = newStatus
                                }

                            else
                                s
                        )
                        stories.stories
            in
            ( Ready { model | stories = { stories | stories = newStories } }, Cmd.none )

        ( Ready model, StoryTaken (Err e) ) ->
            let
                errorMsg =
                    case e of
                        Http.BadUrl s ->
                            "Bad URL: " ++ s

                        Http.Timeout ->
                            "Time out"

                        Http.NetworkError ->
                            "Network error"

                        Http.BadStatus code ->
                            "Bad Status: " ++ String.fromInt code

                        Http.BadBody s ->
                            "Bad body: " ++ s
            in
            ( Ready { model | error = Just errorMsg }, Cmd.none )

        ( Error, _ ) ->
            ( state, Cmd.none )


statusFromString : String -> Status
statusFromString s =
    case s of
        "created" ->
            Created

        "suspended" ->
            Suspended

        "canceled" ->
            Cancelled

        "in progress" ->
            OnGoing

        "finished" ->
            Finished

        _ ->
            Unknown


statusToString : Status -> String
statusToString s =
    case s of
        Created ->
            "created"

        Suspended ->
            "suspended"

        Cancelled ->
            "canceled"

        OnGoing ->
            "in progress"

        Finished ->
            "finished"

        Unknown ->
            "unknwown"


view : State -> Html.Html Msg
view state =
    case state of
        Ready model ->
            Html.main_
                []
                [ Html.div
                    [ HtmlA.class "head-container"
                    , HtmlA.class "toolbar"
                    , HtmlA.class "container"
                    ]
                    [ Html.button
                        [ HtmlA.class "green"
                        , HtmlE.onClick UserReturnsHome
                        ]
                        [ Html.text "Home" ]
                    , logoutForm model.session.csrfToken model.session.logoutUrl
                    ]
                , case model.error of
                    Nothing ->
                        Html.text ""

                    Just reason ->
                        Html.div [ HtmlA.class "error-msg" ] [ Html.text reason ]
                , Html.div
                    [ HtmlA.class "container"
                    , HtmlA.class "list-item"
                    , HtmlA.id "epic-detail"
                    ]
                    [ Html.h1 [] [ Html.text model.epic.title ]
                    , Html.p []
                        [ Html.text model.epic.ownerFullname
                        , Html.text ", "
                        , Html.text model.epic.pubDate
                        ]
                    , Html.div [] <|
                        List.map
                            (\l -> Html.p [ HtmlA.class "description" ] [ Html.text l ])
                        <|
                            String.split "\n" model.epic.description
                    ]
                , storiesView model.stories
                ]

        _ ->
            Html.div
                [ HtmlA.class "error-msg" ]
                [ Html.text "Server error" ]


filterStories : StoryModel -> List Story
filterStories model =
    let
        storiesForStatus =
            List.filter
                (\story ->
                    not <|
                        List.member
                            story.status
                            model.statusFilter
                )
                model.stories

        storiesForText =
            case model.textSearch of
                Nothing ->
                    storiesForStatus

                Just text ->
                    List.filter
                        (\story ->
                            (String.contains text <| String.toLower story.description)
                                || (String.contains text <| String.toLower story.title)
                        )
                        storiesForStatus
    in
    storiesForText


storiesView : StoryModel -> Html.Html Msg
storiesView model =
    let
        onOffFor status =
            if List.member status model.statusFilter then
                [ HtmlA.class "green"
                , HtmlE.onClick <| UserRemoveStatusFilter status
                ]

            else
                [ HtmlA.class "bg-green"
                , HtmlE.onClick <| UserAddStatusFilter status
                ]
    in
    Html.div
        [ HtmlA.class "container"
        , HtmlA.class "scrollable-container"
        ]
        [ Html.div
            [ HtmlA.class "container-toolbar" ]
            [ Html.button
                [ HtmlA.class "blue"
                , HtmlE.onClick UserRemoveAllFilters
                ]
                [ Html.text "All" ]
            , Html.button
                (onOffFor Created)
                [ Html.text "created" ]
            , Html.button
                (onOffFor OnGoing)
                [ Html.text "on going" ]
            , Html.button
                (onOffFor Cancelled)
                [ Html.text "cancelled" ]
            , Html.button
                (onOffFor Suspended)
                [ Html.text "suspended" ]
            , Html.button
                (onOffFor Finished)
                [ Html.text "finished" ]
            , Html.input
                [ HtmlE.onInput UserUpdateTextSearch
                , HtmlA.value <|
                    case model.textSearch of
                        Nothing ->
                            ""

                        Just text ->
                            text
                ]
                []
            ]
        , Html.div
            [ HtmlA.class "scrollable-list"
            ]
          <|
            List.map
                storyItem
            <|
                filterStories model
        ]


storyItem : Story -> Html.Html Msg
storyItem story =
    let
        takeButton =
            Html.div
                [ HtmlA.class "blue"
                , HtmlA.style "font-size" "1.2em"
                , HtmlA.style "margin-top" "-0.1em"
                , HtmlA.style "cursor" "pointer"
                , HtmlE.onClick <| UserTakeStory story
                ]
                [ Html.text "⛏" ]

        controlButtons =
            case story.status of
                Created ->
                    [ takeButton ]

                OnGoing ->
                    [ takeButton ]

                _ ->
                    []
    in
    Html.div
        [ HtmlA.class "list-item" ]
        [ Html.h1 [] [ Html.text story.title ]
        , Html.div
            [ HtmlA.class "story-control" ]
          <|
            (Html.text <| "Status: " ++ statusToString story.status)
                :: controlButtons
        , Html.p
            [ HtmlA.class "item-description" ]
            [ Html.text story.description ]
        ]



-- HTTP


takeStory : String -> Int -> Cmd Msg
takeStory csrfToken storyId =
    Http.request
        { method = "PUT"
        , headers = [ Http.header "X-CSRFToken" csrfToken ]
        , url = "/epics-api/stories/" ++ String.fromInt storyId ++ "/take/"
        , body = Http.emptyBody
        , expect = Http.expectJson StoryTaken storyDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


storyDecoder : JsonD.Decoder Epic_Stories__
storyDecoder =
    JsonD.map5 Epic_Stories__
        (JsonD.field "id" JsonD.int)
        (JsonD.field "pub_date" JsonD.string)
        (JsonD.field "title" JsonD.string)
        (JsonD.field "description" JsonD.string)
        (JsonD.field "status" JsonD.string)
