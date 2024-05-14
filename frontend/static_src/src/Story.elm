module Story exposing (..)

import Browser
import Browser.Navigation as Nav
import Common exposing (logoutForm)
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode as JsonD
import Json.Encode as JsonE
import Models.Story exposing (ToModel, toModel)


type Msg
    = UserReturnsHome
    | UserReturnsToEpic


type State
    = Ready ToModel
    | Error


init : JsonE.Value -> ( State, Cmd Msg )
init f =
    case JsonD.decodeValue toModel f of
        Ok m ->
            ( Ready m, Cmd.none )

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


update : Msg -> State -> ( State, Cmd Msg )
update msg state =
    case state of
        Ready model ->
            case msg of
                UserReturnsHome ->
                    ( state, Nav.load "/" )

                UserReturnsToEpic ->
                    ( state, Nav.load model.story.epic.url )

        _ ->
            ( state, Cmd.none )


view : State -> Html.Html Msg
view state =
    Html.main_ [] <|
        case state of
            Ready model ->
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
                    , Html.button
                        [ HtmlA.class "blue"
                        , HtmlE.onClick UserReturnsToEpic
                        ]
                        [ Html.text "To Epic" ]
                    , logoutForm model.csrfToken model.logoutUrl
                    ]
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
