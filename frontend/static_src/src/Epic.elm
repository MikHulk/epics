module Epic exposing (..)

import Browser
import Browser.Navigation as Nav
import Common
    exposing
        ( ApiError(..)
        , StoryAction(..)
        , StoryChange
        , cancelButton
        , cancelStory
        , ctrlButton
        , logoutForm
        , refreshStory
        , resumeButton
        , resumeStory
        , suspendButton
        , suspendStory
        , takeButton
        , takeStory
        , validateButton
        , validateStory
        )
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Http
import Json.Decode as JsonD
import Json.Encode exposing (Value)
import Models.Epic exposing (Epic_, Epic_Stories__, ToModel, toModel)


type Msg
    = UserReturnsHome
    | UserCleanError
    | UserAddStatusFilter Status
    | UserRemoveStatusFilter Status
    | UserRemoveAllFilters
    | UserUpdateTextSearch String
    | UserActonStory Story StoryAction
    | UserSelectStory Story
    | StoryChanged (Maybe Int) (Result ApiError StoryChange)


type alias Epic =
    { title : String
    , pubDate : String
    , description : String
    , ownerFullname : String
    , owner : String
    }


type alias Story =
    { id : Int
    , pubDate : String
    , title : String
    , description : String
    , status : Status
    , assignedTo : Maybe String
    , assignedToFullname : Maybe String
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
    , username : String
    }


type State
    = Ready Model
    | Error


storyUrl =
    "/story/"


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
                    , assignedTo = story.assignedTo
                    , assignedToFullname = story.assignedToFullname
                    }

                model =
                    { session =
                        { csrfToken = m.csrfToken
                        , logoutUrl = m.logoutUrl
                        , username = m.username
                        }
                    , epic =
                        { title = m.epic.title
                        , pubDate = m.epic.pubDate
                        , description = m.epic.description
                        , ownerFullname = m.epic.ownerFullname
                        , owner = m.epic.owner
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


actionStoryCmd : Model -> Story -> StoryAction -> Cmd Msg
actionStoryCmd model story action =
    let
        cmd =
            case action of
                Take ->
                    takeStory

                Suspend ->
                    suspendStory

                Resume ->
                    resumeStory

                Cancel ->
                    cancelStory

                Validate ->
                    validateStory
    in
    cmd (StoryChanged <| Just story.id) model.session.csrfToken story.id


update : Msg -> State -> ( State, Cmd Msg )
update msg state =
    case ( state, msg ) of
        ( Ready _, UserReturnsHome ) ->
            ( state, Nav.load "/" )

        ( Ready model, UserCleanError ) ->
            ( Ready { model | error = Nothing }, Cmd.none )

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

        ( Ready model, UserActonStory story action ) ->
            ( state, actionStoryCmd model story action )

        ( Ready model, StoryChanged _ (Ok story) ) ->
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
                                , assignedTo = story.assignedTo
                                , assignedToFullname = story.assignedToFullname
                                }

                            else
                                s
                        )
                        stories.stories
            in
            ( Ready { model | stories = { stories | stories = newStories } }, Cmd.none )

        ( Ready model, StoryChanged optStoryId (Err e) ) ->
            let
                ( m, cmd ) =
                    case e of
                        BadUrl s ->
                            ( "Bad URL: " ++ s, Cmd.none )

                        Timeout ->
                            ( "Time out", Cmd.none )

                        NetworkError ->
                            ( "Network error", Cmd.none )

                        BadStatus code ->
                            ( "Bad Status: " ++ String.fromInt code, Cmd.none )

                        DomainError reason ->
                            case optStoryId of
                                Just storyId ->
                                    ( reason
                                    , refreshStory (StoryChanged Nothing) storyId
                                    )

                                Nothing ->
                                    ( reason, Cmd.none )

                        BadBody s ->
                            ( "Bad body: " ++ s, Cmd.none )
            in
            ( Ready
                { model
                    | error =
                        Just <|
                            "Error on story action, "
                                ++ m
                }
            , cmd
            )

        ( _, UserSelectStory story ) ->
            ( state, Nav.load <| (++) storyUrl <| String.fromInt story.id )

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
                        errorMsg model reason
                , Html.div
                    [ HtmlA.class "container"
                    , HtmlA.class "list-item"
                    , HtmlA.id "epic-detail"
                    ]
                    [ Html.p []
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
                , storiesView
                    model.session.username
                    (model.session.username == model.epic.owner)
                    model.stories
                ]

        Error ->
            Html.div
                [ HtmlA.class "error-msg" ]
                [ Html.text "SPA error" ]


errorMsg : Model -> String -> Html.Html Msg
errorMsg model reason =
    Html.div
        [ HtmlA.class "error-msg" ]
        [ Html.div [] [ Html.text reason ]
        , Html.div
            [ HtmlA.style "background-color" "#a61e1e"
            , HtmlA.style "color" "black"
            , HtmlA.style "height" "1em"
            , HtmlA.style "padding" "0px 4px 4px"
            , HtmlA.style "font-size" "1em"
            , HtmlA.style "cursor" "pointer"
            , HtmlE.onClick UserCleanError
            ]
            [ Html.text "✘" ]
        ]


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


storiesView : String -> Bool -> StoryModel -> Html.Html Msg
storiesView username isOwner model =
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
                (storyItem username isOwner)
            <|
                filterStories model
        ]


storyItem : String -> Bool -> Story -> Html.Html Msg
storyItem username isOwner story =
    let
        viewButton =
            ctrlButton
                (UserSelectStory story)
                [ Html.text "🔍" ]

        controlButtons =
            case story.status of
                Created ->
                    if isOwner then
                        [ takeButton (UserActonStory story)
                        , suspendButton (UserActonStory story)
                        , cancelButton (UserActonStory story)
                        , validateButton (UserActonStory story)
                        ]

                    else
                        case story.assignedTo of
                            Just s ->
                                if s == username then
                                    []

                                else
                                    [ takeButton (UserActonStory story) ]

                            Nothing ->
                                [ takeButton (UserActonStory story) ]

                OnGoing ->
                    if isOwner then
                        [ takeButton (UserActonStory story)
                        , suspendButton (UserActonStory story)
                        , cancelButton (UserActonStory story)
                        , validateButton (UserActonStory story)
                        ]

                    else
                        case story.assignedTo of
                            Just s ->
                                if s == username then
                                    []

                                else
                                    [ takeButton (UserActonStory story) ]

                            Nothing ->
                                [ takeButton (UserActonStory story) ]

                Suspended ->
                    if isOwner then
                        [ resumeButton (UserActonStory story)
                        , cancelButton (UserActonStory story)
                        , validateButton (UserActonStory story)
                        ]

                    else
                        []

                _ ->
                    []
    in
    Html.div
        [ HtmlA.class "list-item" ]
        [ Html.h1 [] [ Html.text story.title ]
        , Html.div
            [ HtmlA.class "story-control" ]
          <|
            Html.div
                [ HtmlA.style "width" "10em" ]
                [ Html.text <| "Status: " ++ statusToString story.status ]
                :: (viewButton :: controlButtons)
        , case story.assignedToFullname of
            Just s ->
                Html.p [] [ Html.text <| "assigned to: " ++ s ]

            _ ->
                Html.text ""
        , Html.p
            [ HtmlA.class "item-description" ]
            [ Html.text story.description ]
        ]
