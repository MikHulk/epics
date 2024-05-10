module Epic exposing (..)

import Browser
import Browser.Navigation as Nav
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode exposing (decodeValue)
import Json.Encode exposing (Value)
import Models.Epic exposing (Stories_, ToModel, toModel)


type Msg
    = UserReturnsHome


type alias Epic =
    ToModel


type alias Story =
    Stories_


type Model
    = Ready Epic
    | Error


init : Value -> ( Model, Cmd Msg )
init f =
    case decodeValue toModel f of
        Ok m ->
            ( Ready m, Cmd.none )

        Err _ ->
            ( Error, Cmd.none )


main : Program Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserReturnsHome ->
            ( model, Nav.load "/" )


view : Model -> Html.Html Msg
view model =
    case model of
        Ready epic ->
            Html.main_
                []
                [ Html.div
                    [ HtmlA.class "head-container"
                    , HtmlA.class "toolbar"
                    , HtmlA.class "container"
                    ]
                    [ Html.button
                        [ HtmlA.class "button"
                        , HtmlA.class "green"
                        , HtmlE.onClick UserReturnsHome
                        ]
                        [ Html.text "Home" ]
                    ]
                , Html.div
                    [ HtmlA.class "container"
                    , HtmlA.class "list-item"
                    ]
                    [ Html.h1 [] [ Html.text epic.title ]
                    , Html.p []
                        [ Html.text epic.ownerFullname
                        , Html.text ", "
                        , Html.text epic.pubDate
                        ]
                    , Html.div [] <|
                        List.map (\l -> Html.p [ HtmlA.class "description" ] [ Html.text l ]) <|
                            String.split "\n" epic.description
                    ]
                , storiesView epic.stories
                ]

        _ ->
            Html.text "Something went wrong"


storiesView : List Story -> Html.Html Msg
storiesView stories =
    Html.div
        [ HtmlA.class "container"
        , HtmlA.class "scrollable-list"
        ]
    <|
        List.map
            (\story ->
                Html.div
                    [ HtmlA.class "list-item" ]
                    [ Html.h1 [] [ Html.text story.title ]
                    , Html.p [] [ Html.text story.status ]
                    , Html.p [] [ Html.text story.description ]
                    ]
            )
            stories
