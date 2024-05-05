module Landing exposing (..)

import Browser
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events exposing (onClick)
import Http
import Json.Decode as JsonD
import Json.Decode.Pipeline as JsonP
import Json.Encode exposing (Value)
import Models.Landing exposing (ToModel, toModel)


init : Value -> ( Model, Cmd Msg )
init f =
    case JsonD.decodeValue toModel f of
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
                        (JsonD.list toEpic)
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



-- MSG


type Msg
    = GotEpics (Result Http.Error (List Epic))



-- MODEL


type alias UserInfo =
    ToModel


type alias Epic =
    { title : String
    , pubDate : String
    , description : String
    , ownerFullname : String
    }


type alias Model =
    { state : AppState
    , epics : Maybe (List Epic)
    , user : Maybe UserInfo
    }


type AppState
    = Ready
    | LoadingEpics
    | Error String



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotEpics (Ok epics) ->
            ( { model | epics = Just epics, state = Ready }
            , Cmd.none
            )

        GotEpics (Err error) ->
            ( { model
                | epics = Nothing
                , state = Error <| "Error fetching epics: " ++ Debug.toString error
              }
            , Cmd.none
            )



-- DECODERS


toEpic : JsonD.Decoder Epic
toEpic =
    JsonD.succeed Epic
        |> JsonP.required "title" JsonD.string
        |> JsonP.required "pub_date" JsonD.string
        |> JsonP.required "description" JsonD.string
        |> JsonP.required "owner"
            (JsonD.field "fullname" JsonD.string)



-- VIEW


view : Model -> Html Msg
view model =
    Html.main_ [ HtmlA.class "page-element" ] <|
        case ( model.state, model.epics ) of
            ( LoadingEpics, _ ) ->
                [ userView model.user
                , Html.text "load data, please wait"
                ]

            ( Ready, Just epics ) ->
                [ userView model.user
                , epicsView epics
                ]

            ( Error s, _ ) ->
                [ Html.div
                    [ HtmlA.class "error-msg"
                    ]
                    [ Html.text s ]
                ]

            _ ->
                [ Html.div
                    [ HtmlA.class "error-msg"
                    ]
                    [ Html.text "Well... Something really bad happened.😱" ]
                ]


epicItem : Epic -> Html Msg
epicItem epic =
    Html.div
        [ HtmlA.class "epic-item"
        , HtmlA.class "clickable"
        ]
        [ Html.h1 [] [ Html.text epic.title ]
        , Html.p [] [ Html.text epic.pubDate ]
        , Html.p [] [ Html.text epic.ownerFullname ]
        , Html.p
              [ HtmlA.class "epic-description"]
              [ Html.text epic.description ]
        ]


epicsView : List Epic -> Html Msg
epicsView epics =
    Html.div
        [ HtmlA.id "epic-list"
        , HtmlA.class "container"
        ]
    <|
        List.map epicItem epics


userView : Maybe UserInfo -> Html Msg
userView userOpt =
    case userOpt of
        Just user ->
            Html.div
                [ HtmlA.id "welcome"
                , HtmlA.class "container"
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
                    , Html.button
                        [ HtmlA.type_ "submit"
                        , HtmlA.class "logout-button"
                        ]
                        [ Html.text "Log out" ]
                    ]
                ]

        _ ->
            Html.text "not connected"
