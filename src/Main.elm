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
    , calls : List Call
    , tempSubTasks : List SubTask
    , timeZone : Time.Zone
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputWho = ""
      , inputComments = ""
      , inputSubTask = ""
      , calls =
            [ { who = "Jan van Carrefour"
              , comments = "Nog bellen naar labo enal, kwenie"
              , when = Time.millisToPosix 1613981969763
              , subTasks = [ { text = "Bel labo", done = False }, { text = "Check die stock", done = False } ]
              }
            , { who = "Eva / Beyond Meat"
              , comments = "Wa een tang"
              , when = Time.millisToPosix 1613981973556
              , subTasks = [ { text = "Bel Cissy", done = False }, { text = "Dingske mailen met vraag", done = False } ]
              }
            ]
      , tempSubTasks = []
      , timeZone = Time.utc
      }
    , Task.perform GetTimeZone Time.here
    )


type alias Call =
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
    | AddCallWithTime Time.Posix
    | DeleteTempSubTask SubTask
    | GetTimeZone Time.Zone


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
            ( model, Task.perform AddCallWithTime Time.now )

        AddCallWithTime time ->
            ( { model
                | calls =
                    model.calls
                        ++ [ { who = model.inputWho
                             , comments = model.inputComments
                             , subTasks = model.tempSubTasks
                             , when = time
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

        GetTimeZone newZone ->
            ( { model | timeZone = newZone }, Cmd.none )



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
            , Ui.column [] <| viewCalls model
            ]
        )


viewCalls : Model -> List (Ui.Element Msg)
viewCalls model =
    List.map viewCall model.calls


viewCall : Call -> Ui.Element Msg
viewCall call =
    let
        subtasks =
            List.map (\subtask -> Ui.text subtask.text) call.subTasks
    in
    Ui.column [ Ui.paddingXY 0 16 ]
        ([ Ui.column []
            [ Ui.el [ Font.bold ] (Ui.text call.who)
            , Ui.el [ Font.italic ] (Ui.text (dateToHumanStr Time.utc call.when))
            , Ui.text call.comments
            , Ui.text "Taken"
            ]
         ]
            ++ subtasks
        )


dateToHumanStr : Time.Zone -> Time.Posix -> String
dateToHumanStr zone posix =
    toDutchWeekday (Time.toWeekday zone posix) ++ " " ++ toTwoDigits (Time.toDay zone posix) ++ "/" ++ toDutchMonthNumber (Time.toMonth zone posix)


toTwoDigits : Int -> String
toTwoDigits i =
    if i < 10 then
        "0" ++ String.fromInt i

    else
        String.fromInt i


toDutchMonthStr : Time.Month -> String
toDutchMonthStr month =
    case month of
        Time.Jan ->
            "januari"

        Time.Feb ->
            "februari"

        Time.Mar ->
            "maart"

        Time.Apr ->
            "april"

        Time.May ->
            "mei"

        Time.Jun ->
            "juni"

        Time.Jul ->
            "juli"

        Time.Aug ->
            "augustus"

        Time.Sep ->
            "september"

        Time.Oct ->
            "oktober"

        Time.Nov ->
            "november"

        Time.Dec ->
            "december"


toDutchMonthNumber : Time.Month -> String
toDutchMonthNumber month =
    case month of
        Time.Jan ->
            "01"

        Time.Feb ->
            "02"

        Time.Mar ->
            "03"

        Time.Apr ->
            "04"

        Time.May ->
            "05"

        Time.Jun ->
            "06"

        Time.Jul ->
            "07"

        Time.Aug ->
            "08"

        Time.Sep ->
            "09"

        Time.Oct ->
            "10"

        Time.Nov ->
            "11"

        Time.Dec ->
            "12"


toDutchWeekday : Time.Weekday -> String
toDutchWeekday day =
    case day of
        Time.Mon ->
            "Maandag"

        Time.Tue ->
            "Dinsdag"

        Time.Wed ->
            "Woensdag"

        Time.Thu ->
            "Donderdag"

        Time.Fri ->
            "Vrijdag"

        Time.Sat ->
            "Zaterdag"

        Time.Sun ->
            "Zondag"


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
