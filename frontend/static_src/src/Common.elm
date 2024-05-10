module Common exposing (logoutForm)

import Html
import Html.Attributes as HtmlA


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
