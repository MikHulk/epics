module Story exposing (..)

import Browser
import Browser.Navigation as Nav
import Common
    exposing
        ( StoryAction(..)
        , cancelButton
        , logoutForm
        , resumeButton
        , suspendButton
        , takeButton
        , validateButton
        )
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Http
import Json.Decode as JsonD
import Json.Encode as JsonE
import Models.Story exposing (Story_, ToModel, toModel)


type alias StoryChange =
    { id : Int
    , pubDate : String
    , title : String
    , description : String
    , status : String
    , assignedTo : Maybe String
    , assignedToFullname : Maybe String
    }


type Msg
    = UserReturnsHome
    | UserReturnsToEpic
    | UserActonStory StoryAction
    | StoryChanged (Result Http.Error StoryChange)


type alias Model =
    { story : Story_
    , logoutUrl : String
    , csrfToken : String
    , username : String
    , error : Maybe String
    }


type State
    = Ready Model
    | Error


init : JsonE.Value -> ( State, Cmd Msg )
init f =
    case JsonD.decodeValue toModel f of
        Ok m ->
            ( Ready
                { story = m.story
                , logoutUrl = m.logoutUrl
                , csrfToken = m.csrfToken
                , username = m.username
                , error = Nothing
                }
            , Cmd.none
            )

        Err _ ->
            ( Error, Cmd.none )


main : Program JsonE.Value State Msg
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


actionStoryCmd : Model -> StoryAction -> Cmd Msg
actionStoryCmd model action =
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
    cmd model.csrfToken model.story.id


update : Msg -> State -> ( State, Cmd Msg )
update msg state =
    case state of
        Ready model ->
            case msg of
                UserReturnsHome ->
                    ( state, Nav.load "/" )

                UserReturnsToEpic ->
                    ( state, Nav.load model.story.epic.url )

                UserActonStory action ->
                    ( state, actionStoryCmd model action )

                StoryChanged (Ok change) ->
                    let
                        story =
                            model.story

                        newStory =
                            { story
                                | id = change.id
                                , pubDate = change.pubDate
                                , title = change.title
                                , description = change.description
                                , status = change.status
                                , assignedTo = change.assignedTo
                                , assignedToFullname = change.assignedToFullname
                                , epic = story.epic
                            }
                    in
                    ( Ready { model | story = newStory }
                    , Cmd.none
                    )

                StoryChanged (Err e) ->
                    let
                        m =
                            (++) "Error on story action, " <|
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
                    ( Ready { model | error = Just m }, Cmd.none )

        _ ->
            ( state, Cmd.none )


view : State -> Html.Html Msg
view state =
    Html.main_ [] <|
        case state of
            Ready model ->
                let
                    isOwner =
                        model.story.epic.owner == model.username

                    story =
                        model.story

                    controlButtons =
                        case story.status of
                            "created" ->
                                if isOwner then
                                    [ takeButton UserActonStory
                                    , suspendButton UserActonStory
                                    , cancelButton UserActonStory
                                    , validateButton UserActonStory
                                    ]

                                else
                                    case story.assignedTo of
                                        Just s ->
                                            if s == model.username then
                                                []

                                            else
                                                [ takeButton UserActonStory ]

                                        Nothing ->
                                            [ takeButton UserActonStory ]

                            "in progress" ->
                                if isOwner then
                                    [ takeButton UserActonStory
                                    , suspendButton UserActonStory
                                    , cancelButton UserActonStory
                                    , validateButton UserActonStory
                                    ]

                                else
                                    case story.assignedTo of
                                        Just s ->
                                            if s == model.username then
                                                []

                                            else
                                                [ takeButton UserActonStory ]

                                        Nothing ->
                                            [ takeButton UserActonStory ]

                            "suspended" ->
                                if isOwner then
                                    [ resumeButton UserActonStory
                                    , cancelButton UserActonStory
                                    , validateButton UserActonStory
                                    ]

                                else
                                    []

                            _ ->
                                []
                in
                [ Html.div
                    [ HtmlA.class "head-container"
                    , HtmlA.class "toolbar"
                    , HtmlA.class "container"
                    ]
                    ([ Html.button
                        [ HtmlA.class "green"
                        , HtmlE.onClick UserReturnsHome
                        ]
                        [ Html.text "Home" ]
                     , Html.button
                        [ HtmlA.class "blue"
                        , HtmlE.onClick UserReturnsToEpic
                        ]
                        [ Html.text "To Epic" ]
                     , logoutForm model.csrfToken model.logoutUrl
                     ]
                        ++ controlButtons
                    )
                , Html.div
                    [ HtmlA.class "head-container"
                    , HtmlA.class "container"
                    ]
                    [ Html.p []
                        [ Html.text <|
                            model.story.pubDate
                                ++ ", "
                                ++ model.story.status
                        ]
                    , case model.story.assignedToFullname of
                        Just name ->
                            Html.p [] [ Html.text <| "Assigned to: " ++ name ]

                        Nothing ->
                            Html.text ""
                    , Html.div [] <|
                        List.map
                            (\l -> Html.p [ HtmlA.class "description" ] [ Html.text l ])
                        <|
                            String.split "\n" model.story.description
                    ]
                ]

            _ ->
                [ Html.div
                    [ HtmlA.class "error-msg" ]
                    [ Html.text "SPA error" ]
                ]



-- HTTP


storyActionRequest : String -> String -> Int -> Cmd Msg
storyActionRequest csrfToken action storyId =
    Http.request
        { method = "PUT"
        , headers = [ Http.header "X-CSRFToken" csrfToken ]
        , url = "/epics-api/stories/" ++ String.fromInt storyId ++ "/" ++ action ++ "/"
        , body = Http.emptyBody
        , expect = Http.expectJson StoryChanged storyDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


takeStory : String -> Int -> Cmd Msg
takeStory csrfToken storyId =
    storyActionRequest csrfToken "take" storyId


suspendStory : String -> Int -> Cmd Msg
suspendStory csrfToken storyId =
    storyActionRequest csrfToken "suspend" storyId


resumeStory : String -> Int -> Cmd Msg
resumeStory csrfToken storyId =
    storyActionRequest csrfToken "resume" storyId


cancelStory : String -> Int -> Cmd Msg
cancelStory csrfToken storyId =
    storyActionRequest csrfToken "cancel" storyId


validateStory : String -> Int -> Cmd Msg
validateStory csrfToken storyId =
    storyActionRequest csrfToken "validate" storyId


storyDecoder : JsonD.Decoder StoryChange
storyDecoder =
    JsonD.map7 StoryChange
        (JsonD.field "id" JsonD.int)
        (JsonD.field "pub_date" JsonD.string)
        (JsonD.field "title" JsonD.string)
        (JsonD.field "description" JsonD.string)
        (JsonD.field "status" JsonD.string)
        (JsonD.field "assigned_to"
            (JsonD.nullable (JsonD.field "user" (JsonD.field "username" JsonD.string)))
        )
        (JsonD.field "assigned_to"
            (JsonD.nullable (JsonD.field "fullname" JsonD.string))
        )
