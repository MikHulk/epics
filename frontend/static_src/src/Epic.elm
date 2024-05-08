module Epic exposing (..)

import Browser
import Html
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Json.Decode exposing (decodeValue)
import Json.Encode exposing (Value)
import Models.Epic exposing (ToModel, toModel)


type Msg
    = Nop


type alias Epic =
    ToModel


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
    case model of
        _ ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    case model of
        Ready epic ->
            Html.div
                [ HtmlA.class "container"
                , HtmlA.class "epic-item"
                ]
                [ Html.h1 [] [ Html.text epic.title ]
                , Html.p []
                    [ Html.text epic.ownerFullname
                    , Html.text ", "
                    , Html.text epic.pubDate
                    ]
                , Html.div [] <|
                    List.map (\l -> Html.p [] [ Html.text l ]) <|
                        String.split "\n" epic.description
                ]

        _ ->
            Html.text ""
