module Main exposing (..)

import Browser
import Element as Ui
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html, text)
import Material.Icons.Communication
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
    { input : String }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { input = "" }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | InputChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        InputChanged text ->
            ( { model | input = text }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Ui.layout
        [ Font.family
            [ Font.external { url = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap", name = "Roboto" }
            ]
        , Font.color <| color Text
        , Background.color <| color Bg
        ]
        (Ui.column
            [ Ui.width (Ui.fill |> Ui.maximum 1200), Ui.centerX ]
            [ Ui.text "hi"
            , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                { text = "Submit"
                , icon = Material.Icons.Communication.phone |> Widget.Icon.materialIcons
                , onPress = Just NoOp
                }
            , Widget.textInput (Widget.Material.textInput Widget.Material.darkPalette)
                { chips = []
                , text = model.input
                , placeholder = Nothing
                , label = "Hoi"
                , onChange = InputChanged
                }
            ]
        )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type AppColor
    = Text
    | TextInverted
    | Bg


color : AppColor -> Ui.Color
color col =
    case col of
        Text ->
            Ui.rgb255 0xFF 0xFF 0xFF

        TextInverted ->
            Ui.rgb255 0x33 0x33 0x33

        Bg ->
            Widget.Material.Color.fromColor Widget.Material.Color.dark
