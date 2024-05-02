module Landing exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes as HtmlA
import Html.Events exposing (onClick)
import Http
import Json.Decode as D
import Json.Encode exposing (Value)
import Models.Landing exposing (ToModel, toModel)


type Msg
    = GotEpics (Result Http.Error (List String))


type alias Model =
    { state : AppState
    , epics : Maybe (List String)
    , username : Maybe String
    }


type AppState
    = Ready
    | LoadingEpics
    | Error String


init : Value -> ( Model, Cmd Msg )
init f =
    case D.decodeValue toModel f of
        Ok m ->
            ( { state = LoadingEpics, epics = Nothing, username = m }
            , case m of
                Just _ ->
                    Http.get
                        { url = "epics-api/epics/"
                        , expect =
                            Http.expectJson
                                GotEpics
                                (D.list (D.field "title" D.string))
                        }

                _ ->
                    Cmd.none
            )

        Err _ ->
            ( { state = Error "Server error"
              , epics = Nothing
              , username = Nothing
              }
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
            ( { model | epics = Just epics, state = Ready }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ HtmlA.id "main" ] <|
        case (model.state, model.epics) of
            (LoadingEpics, _) ->
                [ userView model.username
                , text "load data, please wait"
                ]
            (Ready, Just epics) ->
                [ userView model.username
                , epicsView epics
                ]

            _ ->
                [ text "something went wrong" ]


epicsView : List String -> Html Msg
epicsView epics =
    div
        [ HtmlA.id "epics-list"
        , HtmlA.class "page-element"
        ]
    <|
        List.map (\url -> div [ HtmlA.class "epic-item" ] [ text url ]) epics


userView : Maybe String -> Html Msg
userView model =
    case model of
        Just username ->
            div
                [ HtmlA.id "welcome"
                , HtmlA.class "page-element"
                ]
                [ text <| "Hello " ++ username ++ "!"
                ]

        Nothing ->
            div []
                [ text "not connected"
                ]
