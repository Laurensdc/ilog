module Main exposing (..)

import Browser
import Element as Ui
import Element.Font as Font
import Html exposing (Html, text)
import Material.Icons.Communication
import Widget
import Widget.Icon
import Widget.Material



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
    { currentTime : Int }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentTime = 1 }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Ui.layout
        [ Font.family
            [ Font.external { url = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap", name = "Roboto" }
            ]
        , Font.color <| color Text
        ]
        (Ui.column
            [ Ui.width (Ui.fill |> Ui.maximum 1200), Ui.centerX ]
            [ Ui.text "hi"
            , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                { text = "Submit"
                , icon = Material.Icons.Communication.phone |> Widget.Icon.materialIcons
                , onPress = Just NoOp
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
            Ui.rgb255 0xEE 0xEE 0xEE

        TextInverted ->
            Ui.rgb255 0x33 0x33 0x33

        Bg ->
            Ui.rgb255 0x22 0x28 0x31
