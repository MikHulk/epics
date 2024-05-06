module Landing exposing (..)

import Browser
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Http
import Json.Decode as JsonD
import Json.Decode.Pipeline as JsonP
import Json.Encode exposing (Value)
import Models.Landing exposing (ToModel, UserInfo_, toModel)


init : Value -> ( AppState, Cmd Msg )
init f =
    case JsonD.decodeValue toModel f of
        Ok m ->
            ( LoadingEpics <| Model m.userInfo m.csrfToken m.logoutUrl m.epics.url
            , getEpics m.epics.url
            )

        Err _ ->
            ( Error "Server error "
            , Cmd.none
            )


main : Program Value AppState Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


getEpics url =
    Http.get
        { url = url
        , expect =
            Http.expectJson
                GotEpics
                (JsonD.list toEpic)
        }



-- MSG


type Msg
    = GotEpics (Result Http.Error (List Epic))
    | UserWantsHisEpics
    | UserWantsAllEpics
    | UserSearchForText String



-- MODEL


type alias UserInfo =
    UserInfo_


type alias Epic =
    { title : String
    , pubDate : String
    , description : String
    , ownerFullname : String
    , owner : String
    }


type alias Model =
    { userInfo : UserInfo
    , csrfToken : String
    , logoutUrl : String
    , epicUrl : String
    }


type alias Epics =
    { epics : List Epic
    , userOnly : Maybe String
    , textSearch : Maybe String
    }


type AppState
    = LoadingEpics Model
    | Ready Model Epics
    | Error String



-- SUBSCRIPTIONS


subscriptions : AppState -> Sub Msg
subscriptions _ =
    Sub.none



-- UPDATE


update : Msg -> AppState -> ( AppState, Cmd Msg )
update msg state =
    case msg of
        GotEpics (Ok epics) ->
            case state of
                LoadingEpics model ->
                    ( Ready model
                        { epics = epics
                        , userOnly = Nothing
                        , textSearch = Nothing
                        }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )

        GotEpics (Err error) ->
            ( Error <|
                "Error fetching epics: "
                    ++ Debug.toString error
            , Cmd.none
            )

        UserWantsHisEpics ->
            case state of
                Ready model epics ->
                    ( Ready model
                        { epics
                            | userOnly = Just model.userInfo.name
                        }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )

        UserWantsAllEpics ->
            case state of
                Ready model epics ->
                    ( Ready model { epics | userOnly = Nothing }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )

        UserSearchForText text ->
            case state of
                Ready model epics ->
                    ( Ready model
                        { epics
                            | textSearch =
                                if text == "" then
                                    Nothing

                                else
                                    Just <| String.toLower text
                        }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )



-- DECODERS


toEpic : JsonD.Decoder Epic
toEpic =
    JsonD.succeed Epic
        |> JsonP.required "title" JsonD.string
        |> JsonP.required "pub_date" JsonD.string
        |> JsonP.required "description" JsonD.string
        |> JsonP.required "owner"
            (JsonD.field "fullname" JsonD.string)
        |> JsonP.required "owner"
            (JsonD.field "user" (JsonD.field "username" JsonD.string))



-- VIEW


view : AppState -> Html Msg
view state =
    Html.main_ [ HtmlA.class "page-element" ] <|
        case state of
            LoadingEpics model ->
                [ userView model
                , Html.text "load data, please wait"
                ]

            Ready model epics ->
                [ userView model
                , epicsView epics
                ]

            Error s ->
                [ Html.div
                    [ HtmlA.class "error-msg"
                    ]
                    [ Html.text s ]
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
            [ HtmlA.class "epic-description" ]
            [ Html.text epic.description ]
        ]


epicsView : Epics -> Html Msg
epicsView model =
    let
        textFilter text epic =
            (String.contains text <| String.toLower epic.description)
                || (String.contains text <| String.toLower epic.title)

        epics =
            case ( model.userOnly, model.textSearch ) of
                ( Just username, Just text ) ->
                    List.filter
                        (\epic ->
                            epic.owner == username && (textFilter text epic)
                        )
                        model.epics

                ( Just username, Nothing ) ->
                    List.filter
                        (\epic -> epic.owner == username)
                        model.epics

                ( Nothing, Just text ) ->
                    List.filter (textFilter text) model.epics

                _ ->
                    model.epics

        filterSwitch =
            case model.userOnly of
                Just _ ->
                    Html.button
                        [ HtmlE.onClick UserWantsAllEpics
                        , HtmlA.class "button"
                        , HtmlA.class "blue"
                        ]
                        [ Html.text "All epics" ]

                _ ->
                    Html.button
                        [ HtmlE.onClick UserWantsHisEpics
                        , HtmlA.class "button"
                        , HtmlA.class "green"
                        ]
                        [ Html.text "My epics" ]
    in
    Html.div
        [ HtmlA.id "epic-container", HtmlA.class "container" ]
        [ Html.div
              [ HtmlA.class "container-toolbar" ]
              [ filterSwitch
              , Html.input
                    [ HtmlE.onInput UserSearchForText
                    , HtmlA.style "margin-top" "6px"
                    ]
                    []
              ]
        , Html.div
            [ HtmlA.id "epic-list"
            ]
          <|
            List.map epicItem epics
        ]


userView : Model -> Html Msg
userView model =
    let
        user =
            model.userInfo
    in
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
        , Html.div
            [ HtmlA.id "toolbar" ]
            [ Html.form
                [ HtmlA.action model.logoutUrl
                , HtmlA.method "post"
                ]
                [ Html.input
                    [ HtmlA.type_ "hidden"
                    , HtmlA.name "csrfmiddlewaretoken"
                    , HtmlA.value model.csrfToken
                    ]
                    []
                , Html.button
                    [ HtmlA.type_ "submit"
                    , HtmlA.class "red"
                    ]
                    [ Html.text "Log out" ]
                ]
            ]
        ]
