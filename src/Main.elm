module Main exposing (..)

import Browser
import Element as Ui
import Element.Background as Background
import Element.Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Events
import Json.Decode
import Material.Icons.Action
import Material.Icons.Content
import Widget
import Widget.Icon
import Widget.Material
import Widget.Material.Color



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { inputClient : String
    , inputFirm : String
    , inputComments : String
    , inputSubTask : String
    , tasks : List Task
    , tempSubTasks : List SubTask
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputClient = ""
      , inputFirm = ""
      , inputComments = ""
      , inputSubTask = ""
      , tasks = []
      , tempSubTasks = []
      }
    , Cmd.none
    )


type alias Task =
    { client : String
    , firm : String
    , comments : String
    , subTasks : List SubTask
    }


type alias SubTask =
    { text : String, done : Bool }



-- UPDATE


type Msg
    = InputClientChanged String
    | InputFirmChanged String
    | InputCommentsChanged String
    | InputTaskChanged String
    | AddTempSubTask
    | AddTask
    | DeleteTempSubTask SubTask


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputClientChanged text ->
            ( { model | inputClient = text }, Cmd.none )

        InputFirmChanged text ->
            ( { model | inputFirm = text }, Cmd.none )

        InputCommentsChanged text ->
            ( { model | inputComments = text }, Cmd.none )

        InputTaskChanged text ->
            ( { model | inputSubTask = text }, Cmd.none )

        AddTempSubTask ->
            ( { model
                | tempSubTasks = model.tempSubTasks ++ [ { text = model.inputSubTask, done = False } ]
                , inputSubTask = ""
              }
            , Cmd.none
            )

        AddTask ->
            ( { model
                | tasks = model.tasks ++ [ { client = model.inputClient, firm = model.inputFirm, comments = model.inputComments, subTasks = model.tempSubTasks } ]
                , tempSubTasks = []
                , inputClient = ""
                , inputFirm = ""
                , inputComments = ""
              }
            , Cmd.none
            )

        DeleteTempSubTask subtask ->
            ( { model
                | tempSubTasks = List.filter (\s -> s /= subtask) model.tempSubTasks
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html.Html Msg
view model =
    Ui.layout
        [ Font.family
            [ Font.external { url = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap", name = "Roboto" }
            ]
        , Font.color <| color Text
        , Background.color <| color Bg
        , Ui.paddingXY 0 32
        ]
        (Ui.column
            [ Ui.width (Ui.fill |> Ui.maximum 1200), Ui.centerX, Ui.spacing 32 ]
            [ --  Client
              Ui.row
                []
                [ Input.text
                    [ Font.color <| color TextInverted
                    , Ui.width (Ui.shrink |> Ui.minimum 200)
                    , Input.focusedOnLoad
                    ]
                    { onChange = InputClientChanged
                    , text = model.inputClient
                    , placeholder = Nothing
                    , label = Input.labelLeft [] <| Ui.text "Klant"
                    }

                --  Firm
                , Input.text
                    [ Font.color <| color TextInverted
                    , Ui.width (Ui.shrink |> Ui.minimum 200)
                    ]
                    { onChange = InputFirmChanged
                    , text = model.inputFirm
                    , placeholder = Nothing
                    , label = Input.labelLeft [] <| Ui.text "van firma"
                    }
                ]

            --  Comments
            , Input.multiline
                [ Font.color <| color TextInverted
                , Ui.width (Ui.shrink |> Ui.minimum 600)
                , Ui.height <| Ui.px 120
                ]
                { onChange = InputCommentsChanged
                , text = model.inputComments
                , placeholder = Nothing
                , label = Input.labelHidden "Comments"
                , spellcheck = True
                }
            , Ui.text "Subtaken"
            , Ui.row []
                [ Input.text
                    [ Font.color <| color TextInverted
                    , Ui.width (Ui.shrink |> Ui.minimum 200)
                    , onEnter AddTempSubTask
                    , Ui.htmlAttribute
                        (Html.Events.onBlur AddTempSubTask)
                    ]
                    { onChange = InputTaskChanged
                    , text = model.inputSubTask
                    , placeholder = Nothing
                    , label = Input.labelHidden "Add subtask"
                    }

                -- , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                --     { text = "Subtaak toevoegen"
                --     , icon = Material.Icons.Content.add |> Widget.Icon.materialIcons
                --     , onPress = Just AddTempSubTask
                --     }
                ]
            , Ui.column [] <| viewSubTasks model
            , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                { text = "Taak toevoegen"
                , icon = Material.Icons.Content.add |> Widget.Icon.materialIcons
                , onPress = Just AddTask
                }
            ]
        )


viewSubTasks : Model -> List (Ui.Element Msg)
viewSubTasks model =
    List.map viewSubTask model.tempSubTasks


viewSubTask : SubTask -> Ui.Element Msg
viewSubTask subTask =
    Ui.row []
        [ Ui.el [ Ui.paddingEach { top = 0, right = 16, bottom = 0, left = 0 } ] (Ui.text subTask.text)
        , Widget.iconButton (Widget.Material.containedButton Widget.Material.darkPalette)
            { icon = Material.Icons.Action.delete |> Widget.Icon.materialIcons
            , text = "Delete task"
            , onPress = Just (DeleteTempSubTask subTask)
            }
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type AppColor
    = Text
    | TextInverted
    | Bg


onEnter : msg -> Ui.Attribute msg
onEnter msg =
    Ui.htmlAttribute
        (Html.Events.on "keyup"
            (Json.Decode.field "key" Json.Decode.string
                |> Json.Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Json.Decode.succeed msg

                        else
                            Json.Decode.fail "Not the enter key"
                    )
            )
        )


color : AppColor -> Ui.Color
color col =
    case col of
        Text ->
            Ui.rgb255 0xFF 0xFF 0xFF

        TextInverted ->
            Ui.rgb255 0x33 0x33 0x33

        Bg ->
            Widget.Material.Color.fromColor Widget.Material.Color.dark
