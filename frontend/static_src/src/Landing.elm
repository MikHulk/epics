module Landing exposing (..)

import Browser
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events exposing (onClick)
import Http
import Json.Decode as D
import Json.Encode exposing (Value)
import Models.Landing exposing (ToModel, toModel)


type Msg
    = GotEpics (Result Http.Error (List String))


type alias UserInfo =
    ToModel


type alias Model =
    { state : AppState
    , epics : Maybe (List String)
    , user : Maybe UserInfo
    }


type AppState
    = Ready
    | LoadingEpics
    | Error String


init : Value -> ( Model, Cmd Msg )
init f =
    case D.decodeValue toModel f of
        Ok m ->
            ( { state = LoadingEpics
              , epics = Nothing
              , user = Just m
              }
            , Http.get
                { url = "epics-api/epics/"
                , expect =
                    Http.expectJson
                        GotEpics
                        (D.list (D.field "title" D.string))
                }
            )

        Err _ ->
            ( { state = Error "Server error"
              , epics = Nothing
              , user = Nothing
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
    Html.div [ HtmlA.id "main" ] <|
        case ( model.state, model.epics ) of
            ( LoadingEpics, _ ) ->
                [ userView model.user
                , Html.text "load data, please wait"
                ]

            ( Ready, Just epics ) ->
                [ userView model.user
                , epicsView epics
                ]

            _ ->
                [ Html.text "something went wrong" ]


epicsView : List String -> Html Msg
epicsView epics =
    Html.div
        [ HtmlA.id "epics-list"
        , HtmlA.class "page-element"
        ]
    <|
        List.map
            (\url -> Html.div [ HtmlA.class "epic-item" ] [ Html.text url ])
            epics


userView : Maybe UserInfo -> Html Msg
userView userOpt =
    case userOpt of
        Just user ->
            Html.div
                [ HtmlA.id "welcome"
                , HtmlA.class "page-element"
                ]
                [ Html.h1 [] [ Html.text <| "Hello " ++ user.fullname ++ "!" ]
                , Html.p []
                    [ Html.text <|
                        case user.email of
                            Just address ->
                                address

                            _ ->
                                "no email address"
                    ]
                , Html.p []
                    [ Html.text <|
                        (++) "Is staff: " <|
                            if user.isStaff then
                                "yes"

                            else
                                "no"
                    ]
                , Html.form
                    [ HtmlA.action user.logoutUrl
                    , HtmlA.method "post"
                    ]
                    [ Html.input
                          [ HtmlA.type_ "hidden"
                          , HtmlA.name "csrfmiddlewaretoken"
                          , HtmlA.value user.csrfToken
                          ]
                          []
                    , Html.button [ HtmlA.type_ "submit" ] [ Html.text "Log out" ]
                    ]
                ]

        _ ->
            Html.text "not connected"
