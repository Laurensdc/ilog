module Main exposing (..)

import Browser
import Color
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
import Svg
import Task
import Time
import Widget
import Widget.Icon as Icon
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
    { inputWho : String
    , inputComments : String
    , inputSubTask : String
    , tasks : List Task
    , tempSubTasks : List SubTask
    , time : Time.Posix
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputWho = ""
      , inputComments = ""
      , inputSubTask = ""
      , tasks = []
      , tempSubTasks = []
      , time = Time.millisToPosix 0
      }
    , Cmd.none
    )


type alias Task =
    { who : String
    , comments : String
    , when : Time.Posix
    , subTasks : List SubTask
    }


type alias SubTask =
    { text : String, done : Bool }



-- UPDATE


type Msg
    = InputWhoChanged String
    | InputCommentsChanged String
    | InputSubTaskChanged String
    | AddTempSubTask
    | AddCall
    | DeleteTempSubTask SubTask
    | GetTimeNow Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputWhoChanged text ->
            ( { model | inputWho = text }, Cmd.none )

        InputCommentsChanged text ->
            ( { model | inputComments = text }, Cmd.none )

        InputSubTaskChanged text ->
            ( { model | inputSubTask = text }, Cmd.none )

        AddTempSubTask ->
            if model.inputSubTask == "" then
                ( model, Cmd.none )

            else
                ( { model
                    | tempSubTasks = model.tempSubTasks ++ [ { text = model.inputSubTask, done = False } ]
                    , inputSubTask = ""
                  }
                , Cmd.none
                )

        AddCall ->
            ( { model
                | tasks =
                    model.tasks
                        ++ [ { who = model.inputWho
                             , comments = model.inputComments
                             , subTasks = model.tempSubTasks
                             , when = model.time
                             }
                           ]
                , tempSubTasks = []
                , inputWho = ""
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

        GetTimeNow time ->
            ( { model
                | time = time
              }
            , Cmd.none
            )


getTimeNow : Cmd Msg
getTimeNow =
    Task.perform GetTimeNow Time.now



-- VIEW


view : Model -> Html.Html Msg
view model =
    Ui.layout
        [ Font.family
            [ Font.external { url = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap", name = "Roboto" }
            ]
        , Font.size 18
        , Font.color <| color Text
        , Background.color <| color Bg
        , Ui.paddingXY 0 32
        ]
        (Ui.column
            [ Ui.width (Ui.fill |> Ui.maximum 1200)
            , Ui.centerX
            , Ui.spacing 16
            ]
            [ -- Title
              Ui.el [ Font.size 24 ]
                (Ui.text "Voeg een gesprek toe")
            , --  Client
              Input.text
                [ Font.color <| color TextInverted
                , Ui.width (Ui.shrink |> Ui.minimum 200)
                , Input.focusedOnLoad
                ]
                { onChange = InputWhoChanged
                , text = model.inputWho
                , placeholder = Just (Input.placeholder [] (Ui.text "Jef van de Carrefour"))
                , label = Input.labelAbove [] <| Ui.text "Wie?"
                }

            --  Comments
            , Input.multiline
                [ Font.color <| color TextInverted
                , Ui.width (Ui.shrink |> Ui.minimum 600)
                , Ui.height <| Ui.px 120
                ]
                { onChange = InputCommentsChanged
                , text = model.inputComments
                , placeholder = Nothing
                , label = Input.labelAbove [] <| Ui.text "Opmerkingen"
                , spellcheck = True
                }
            , Ui.row [ Ui.width (Ui.shrink |> Ui.minimum 200) ]
                [ Input.text
                    [ Font.color <| color TextInverted
                    , onEnter AddTempSubTask
                    , Ui.htmlAttribute
                        (Html.Events.onBlur AddTempSubTask)
                    ]
                    { onChange = InputSubTaskChanged
                    , text = model.inputSubTask
                    , placeholder = Nothing
                    , label = Input.labelAbove [] <| Ui.text "Taak toevoegen"
                    }

                -- , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                --     { text = "Subtaak toevoegen"
                --     , icon = Material.Icons.Content.add |> Widget.Icon.materialIcons
                --     , onPress = Just AddTempSubTask
                --     }
                ]
            , Ui.column [] <| viewSubTasks model
            , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                { text = "Gesprek opslaan"
                , icon = Material.Icons.Content.add |> Icon.materialIcons
                , onPress = Just AddCall
                }
            , Ui.column [] <| viewTasks model
            ]
        )


viewTasks : Model -> List (Ui.Element Msg)
viewTasks model =
    List.map viewTask model.tasks


viewTask : Task -> Ui.Element Msg
viewTask task =
    let
        subtasks =
            List.map (\subtask -> Ui.text subtask.text) task.subTasks
    in
    Ui.row []
        (List.append
            [ Ui.text (task.who ++ " " ++ task.comments) ]
            subtasks
        )


viewSubTasks : Model -> List (Ui.Element Msg)
viewSubTasks model =
    List.map viewSubTask model.tempSubTasks


viewSubTask : SubTask -> Ui.Element Msg
viewSubTask subTask =
    Ui.row []
        [ Ui.el [ Ui.paddingEach { top = 0, right = 16, bottom = 0, left = 0 } ] (Ui.text subTask.text)

        -- , Widget.iconButton (Widget.Material.containedButton Widget.Material.darkPalette)
        --     { icon = Icon.materialIcons Material.Icons.Action.delete
        --     , text = "Delete task"
        --     , onPress = Just (DeleteTempSubTask subTask)
        --     }
        , Ui.el [ Element.Events.onClick (DeleteTempSubTask subTask) ] (Icon.materialIcons Material.Icons.Action.delete { size = 24, color = Color.lightRed })
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