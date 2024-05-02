module Landing exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Html.Attributes as HtmlA
import Http
import Json.Decode as D
import Json.Encode exposing (Value)
import Models.Landing exposing (ToModel, toModel)


type Msg
    = GotEpics (Result Http.Error (List String))


type alias Model =
    { state : AppState
    , loadingEpicListState : LoadingEpicListState
    }


type LoadingEpicListState
    = Failure
    | Loading
    | Success (List String)


type AppState
    = Ready ToModel
    | Error


init : Value -> ( Model, Cmd Msg )
init f =
    case D.decodeValue toModel f of
        Ok m ->
            ( { state = Ready m, loadingEpicListState = Loading }
            , Http.get
                { url = "epics-api/epics/"
                , expect = Http.expectJson GotEpics (D.list (D.field "title" D.string))
                }
            )

        Err _ ->
            ( { state = Error, loadingEpicListState = Failure }
            , Cmd.none
            )


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
        GotEpics (Ok epics) ->
            ( { model | loadingEpicListState = Success epics }
            , Cmd.none
            )
        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ HtmlA.id "main" ]
        [ stateView model.state
        , epicsView model.loadingEpicListState
        ]

epicsView : LoadingEpicListState -> Html Msg
epicsView model =
    case model of
        Success (epics) ->
            div [ HtmlA.id "epics-list"
                , HtmlA.class "page-element"
                ]
                <| List.map (\url -> div [ HtmlA.class "epic-item"] [ text url ]) epics
        _ -> text ""


stateView : AppState -> Html Msg
stateView model =
    case model of
        Ready (Just username) ->
            div [ HtmlA.id "welcome"
                , HtmlA.class "page-element"
                ]
                [ text <| "Hello " ++ username ++ "!"
                ]

        Ready Nothing ->
            div []
                [ text "not connected"
                ]

        _ ->
            text "something went wrong"
