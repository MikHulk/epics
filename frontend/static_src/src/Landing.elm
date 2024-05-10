module Landing exposing (..)

import Browser
import Browser.Navigation as Nav
import Common exposing (logoutForm)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events as HtmlE
import Http
import Json.Decode as JsonD
import Json.Decode.Pipeline as JsonP
import Json.Encode exposing (Value)
import Models.Landing exposing (Epics_, ToModel, UserInfo_, toModel)


init : Value -> ( AppState, Cmd Msg )
init f =
    case JsonD.decodeValue toModel f of
        Ok m ->
            ( Ready <|
                Model m.userInfo m.csrfToken m.logoutUrl <|
                    Epics m.epics Nothing Nothing
            , Cmd.none
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



-- MSG


type Msg
    = UserWantsHisEpics
    | UserWantsAllEpics
    | UserSearchForText String
    | UserSelectEpic String



-- MODEL


type alias UserInfo =
    UserInfo_


type alias Epic =
    Epics_


type alias Model =
    { userInfo : UserInfo
    , csrfToken : String
    , logoutUrl : String
    , epics : Epics
    }


type alias Epics =
    { epics : List Epic
    , userOnly : Maybe String
    , textSearch : Maybe String
    }


type AppState
    = Ready Model
    | Error String



-- SUBSCRIPTIONS


subscriptions : AppState -> Sub Msg
subscriptions _ =
    Sub.none



-- UPDATE


update : Msg -> AppState -> ( AppState, Cmd Msg )
update msg state =
    case msg of
        UserWantsHisEpics ->
            case state of
                Ready model ->
                    let
                        epics =
                            model.epics
                    in
                    ( Ready
                        { model
                            | epics =
                                { epics
                                    | userOnly = Just model.userInfo.name
                                }
                        }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )

        UserWantsAllEpics ->
            case state of
                Ready model ->
                    let
                        epics =
                            model.epics
                    in
                    ( Ready { model | epics = { epics | userOnly = Nothing } }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )

        UserSearchForText text ->
            case state of
                Ready model ->
                    let
                        epics =
                            model.epics
                    in
                    ( Ready
                        { model
                            | epics =
                                { epics
                                    | textSearch =
                                        if text == "" then
                                            Nothing

                                        else
                                            Just <| String.toLower text
                                }
                        }
                    , Cmd.none
                    )

                _ ->
                    ( state, Cmd.none )

        UserSelectEpic url ->
            ( state, Nav.load url )



-- VIEW


view : AppState -> Html Msg
view state =
    Html.main_ [] <|
        case state of
            Ready model ->
                [ userView model
                , epicsView model.epics
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
        [ HtmlA.class "list-item"
        , HtmlA.class "clickable"
        , HtmlE.onClick <| UserSelectEpic epic.url
        ]
        [ Html.h1 [] [ Html.text epic.title ]
        , Html.p [] [ Html.text epic.pubDate ]
        , Html.p [] [ Html.text epic.ownerFullname ]
        , Html.p
            [ HtmlA.class "item-description" ]
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
                            epic.owner == username && textFilter text epic
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
                        , HtmlA.class "blue"
                        ]
                        [ Html.text "All epics" ]

                _ ->
                    Html.button
                        [ HtmlE.onClick UserWantsHisEpics
                        , HtmlA.class "green"
                        ]
                        [ Html.text "My epics" ]
    in
    Html.div
        [ HtmlA.class "scrollable-container", HtmlA.class "container" ]
        [ Html.div
            [ HtmlA.class "container-toolbar" ]
            [ filterSwitch
            , Html.input
                [ HtmlE.onInput UserSearchForText
                ]
                []
            ]
        , Html.div
            [ HtmlA.class "scrollable-list"
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
        [ HtmlA.class "container"
        , HtmlA.class "head-container"
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
            [ HtmlA.class "toolbar" ]
            [ logoutForm model.csrfToken model.logoutUrl ]
        ]
