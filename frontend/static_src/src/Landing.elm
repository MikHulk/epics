module Landing exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Json.Decode exposing (decodeValue)
import Json.Encode exposing (Value)
import Models.Landing exposing (ToModel, toModel)


type Msg
    = Nop


type Model
    = Ready ToModel
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
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model of
        Ready ( Just username ) ->
            div []
                [ text <| "Hello " ++ username ++ "!"
                ]
        Ready Nothing ->
            div []
                [ text "not connected"
                ]

        _ ->
            text "not ready"
