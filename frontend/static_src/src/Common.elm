module Common exposing
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


type StoryAction
    = Take
    | Suspend
    | Resume
    | Cancel
    | Validate


logoutForm : String -> String -> Html.Html msg
logoutForm csrfToken logoutUrl =
    Html.form
        [ HtmlA.action logoutUrl
        , HtmlA.method "post"
        ]
        [ Html.input
            [ HtmlA.type_ "hidden"
            , HtmlA.name "csrfmiddlewaretoken"
            , HtmlA.value csrfToken
            ]
            []
        , Html.button
            [ HtmlA.type_ "submit"
            , HtmlA.class "red"
            ]
            [ Html.text "Log out" ]
        ]


ctrlButton : msg -> List (Html.Html msg) -> Html.Html msg
ctrlButton msg content =
    Html.div
        [ HtmlA.class "blue"
        , HtmlA.style "font-size" "1.2em"
        , HtmlA.style "height" "1em"
        , HtmlA.style "margin-top" "-0.1em"
        , HtmlA.style "cursor" "pointer"
        , HtmlE.onClick msg
        ]
        content


takeButton : (StoryAction -> msg) -> Html.Html msg
takeButton fmsg =
    ctrlButton (fmsg Take) [ Html.text "⛏" ]


suspendButton : (StoryAction -> msg) -> Html.Html msg
suspendButton fmsg =
    ctrlButton (fmsg Suspend) [ Html.text "✋" ]


resumeButton : (StoryAction -> msg) -> Html.Html msg
resumeButton fmsg =
    ctrlButton (fmsg Resume) [ Html.text "✨" ]


cancelButton : (StoryAction -> msg) -> Html.Html msg
cancelButton fmsg =
    ctrlButton (fmsg Cancel) [ Html.text "❌" ]


validateButton : (StoryAction -> msg) -> Html.Html msg
validateButton fmsg =
    ctrlButton (fmsg Validate) [ Html.text "✅" ]



-- HTTP


type alias StoryChange =
    { id : Int
    , pubDate : String
    , title : String
    , description : String
    , status : String
    , assignedTo : Maybe String
    , assignedToFullname : Maybe String
    }


type ApiError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int
    | DomainError String
    | BadBody String


expectJson :
    (Result ApiError StoryChange -> msg)
    -> JsonD.Decoder StoryChange
    -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (BadUrl url)

                Http.Timeout_ ->
                    Err Timeout

                Http.NetworkError_ ->
                    Err NetworkError

                Http.BadStatus_ metadata body ->
                    if metadata.statusCode == 420 then
                        let
                            result =
                                JsonD.decodeString
                                    (JsonD.field "detail" JsonD.string)
                                    body
                        in
                        case result of
                            Ok detail ->
                                Err (DomainError detail)

                            _ ->
                                Err (BadStatus metadata.statusCode)

                    else
                        Err (BadStatus metadata.statusCode)

                Http.GoodStatus_ metadata body ->
                    case JsonD.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (BadBody (JsonD.errorToString err))


storyActionRequest :
    (Result ApiError StoryChange -> msg)
    -> String
    -> String
    -> Int
    -> Cmd msg
storyActionRequest msg csrfToken action storyId =
    Http.request
        { method = "PUT"
        , headers = [ Http.header "X-CSRFToken" csrfToken ]
        , url = "/epics-api/stories/" ++ String.fromInt storyId ++ "/" ++ action ++ "/"
        , body = Http.emptyBody
        , expect = expectJson msg storyDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


refreshStory :
    (Result ApiError StoryChange -> msg)
    -> Int
    -> Cmd msg
refreshStory msg storyId =
    Http.get
        { url = "/epics-api/stories/" ++ String.fromInt storyId ++ "/"
        , expect = expectJson msg storyDecoder
        }


takeStory :
    (Result ApiError StoryChange -> msg)
    -> String
    -> Int
    -> Cmd msg
takeStory msg csrfToken storyId =
    storyActionRequest msg csrfToken "take" storyId


suspendStory :
    (Result ApiError StoryChange -> msg)
    -> String
    -> Int
    -> Cmd msg
suspendStory msg csrfToken storyId =
    storyActionRequest msg csrfToken "suspend" storyId


resumeStory :
    (Result ApiError StoryChange -> msg)
    -> String
    -> Int
    -> Cmd msg
resumeStory msg csrfToken storyId =
    storyActionRequest msg csrfToken "resume" storyId


cancelStory :
    (Result ApiError StoryChange -> msg)
    -> String
    -> Int
    -> Cmd msg
cancelStory msg csrfToken storyId =
    storyActionRequest msg csrfToken "cancel" storyId


validateStory :
    (Result ApiError StoryChange -> msg)
    -> String
    -> Int
    -> Cmd msg
validateStory msg csrfToken storyId =
    storyActionRequest msg csrfToken "validate" storyId


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
