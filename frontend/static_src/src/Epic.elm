module Epic exposing (..)

import Browser
import Browser.Navigation as Nav
import Common exposing (logoutForm)
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode exposing (decodeValue)
import Json.Encode exposing (Value)
import Models.Epic exposing (Epic_, Epic_Stories__, ToModel, toModel)


type Msg
    = UserReturnsHome
    | UserAddStatusFilter Status
    | UserRemoveStatusFilter Status
    | UserRemoveAllFilters


type alias Epic =
    { title : String
    , pubDate : String
    , description : String
    , ownerFullname : String
    }


type alias Story =
    Epic_Stories__


type Status
    = Created
    | OnGoing
    | Cancelled
    | Suspended
    | Finished


type alias StoryModel =
    { stories : List Story
    , statusFilter : List Status
    }


type alias Model =
    { session : SessionInfo
    , epic : Epic
    , stories : StoryModel
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
    case decodeValue toModel f of
        Ok m ->
            let
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
                        { stories = m.epic.stories
                        , statusFilter = [ Cancelled, Finished, Suspended ]
                        }
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
                    model.stories.stories
            in
            ( Ready
                { model
                    | stories = { stories = stories, statusFilter = newFilters }
                }
            , Cmd.none
            )

        ( Ready model, UserRemoveStatusFilter status ) ->
            let
                newFilters =
                    List.filter (\s -> s /= status) model.stories.statusFilter

                stories =
                    model.stories.stories
            in
            ( Ready
                { model
                    | stories = { stories = stories, statusFilter = newFilters }
                }
            , Cmd.none
            )

        ( Ready model, UserAddStatusFilter status ) ->
            let
                newFilters =
                    status :: model.stories.statusFilter

                stories =
                    model.stories.stories
            in
            ( Ready
                { model
                    | stories = { stories = stories, statusFilter = newFilters }
                }
            , Cmd.none
            )

        _ ->
            ( state, Cmd.none )


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
                , Html.div
                    [ HtmlA.class "container"
                    , HtmlA.class "list-item"
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
            Html.text "Something went wrong"


storiesView : StoryModel -> Html.Html Msg
storiesView model =
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
                (if List.member Created model.statusFilter then
                    [ HtmlA.class "bg-green"
                    , HtmlE.onClick <| UserRemoveStatusFilter Created
                    ]

                 else
                    [ HtmlA.class "green"
                    , HtmlE.onClick <| UserAddStatusFilter Created
                    ]
                )
                [ Html.text "created" ]
            , Html.button
                (if List.member OnGoing model.statusFilter then
                    [ HtmlA.class "bg-green"
                    , HtmlE.onClick <| UserRemoveStatusFilter OnGoing
                    ]

                 else
                    [ HtmlA.class "green"
                    , HtmlE.onClick <| UserAddStatusFilter OnGoing
                    ]
                )
                [ Html.text "on going" ]
            , Html.button
                (if List.member Cancelled model.statusFilter then
                    [ HtmlA.class "bg-green"
                    , HtmlE.onClick <| UserRemoveStatusFilter Cancelled
                    ]

                 else
                    [ HtmlA.class "green"
                    , HtmlE.onClick <| UserAddStatusFilter Cancelled
                    ]
                )
                [ Html.text "cancelled" ]
            , Html.button
                (if List.member Suspended model.statusFilter then
                    [ HtmlA.class "bg-green"
                    , HtmlE.onClick <| UserRemoveStatusFilter Suspended
                    ]

                 else
                    [ HtmlA.class "green"
                    , HtmlE.onClick <| UserAddStatusFilter Suspended
                    ]
                )
                [ Html.text "suspended" ]
            , Html.button
                (if List.member Finished model.statusFilter then
                    [ HtmlA.class "bg-green"
                    , HtmlE.onClick <| UserRemoveStatusFilter Finished
                    ]

                 else
                    [ HtmlA.class "green"
                    , HtmlE.onClick <| UserAddStatusFilter Finished
                    ]
                )
                [ Html.text "finished" ]
            ]
        , Html.div
            [ HtmlA.class "scrollable-list"
            ]
          <|
            List.map
                (\story ->
                    Html.div
                        [ HtmlA.class "list-item" ]
                        [ Html.h1 [] [ Html.text story.title ]
                        , Html.p [] [ Html.text story.status ]
                        , Html.p
                            [ HtmlA.class "item-description" ]
                            [ Html.text story.description ]
                        ]
                )
                model.stories
        ]
