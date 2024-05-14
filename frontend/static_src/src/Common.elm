module Common exposing
    ( StoryAction(..)
    , cancelButton
    , ctrlButton
    , logoutForm
    , resumeButton
    , suspendButton
    , takeButton
    , validateButton
    )

import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE


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
