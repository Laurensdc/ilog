module UiStuff exposing (..)

import Ant.Icon
import CallTypes exposing (..)
import Element as Ui
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Time
import Time.Extra as Time



-- STYLES & FORM COMPONENTS


button : String -> msg -> Ui.Element msg
button label onPressMsg =
    Input.button
        [ Background.color <| color Boom
        , Border.rounded 6
        , Ui.paddingXY 32 8
        , Font.color <| color Text
        , Ui.mouseOver [ color Boom |> darken |> Background.color ]
        , smoothTransition
        ]
        { label = Ui.text label, onPress = Just onPressMsg }


h2Styles : List (Ui.Attribute msg)
h2Styles =
    [ Ui.paddingEach { top = 32, left = 0, right = 0, bottom = 0 }
    , fontBig
    , Font.regular
    ]


textInputStyles : List (Ui.Attribute msg)
textInputStyles =
    [ Font.color <| color TextInverted
    , Ui.paddingXY 16 8
    , Border.rounded 4
    ]


smoothTransition : Ui.Attribute msg
smoothTransition =
    Ui.htmlAttribute (Html.Attributes.style "transition" "0.15s ease-in-out")



-- HELPERS


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


noAttr : Ui.Attribute msg
noAttr =
    Ui.htmlAttribute (Html.Attributes.class "")


iconsize : Ant.Icon.Attribute msg
iconsize =
    Ant.Icon.width 24


fontNormal =
    Font.size 16


fontBig =
    Font.size 20


fontHuge =
    Font.size 24



-- COLORS


type AppColor
    = Text
    | TextInverted
    | Bg
    | Boom
    | Accented


color : AppColor -> Ui.Color
color col =
    case col of
        Text ->
            Ui.rgb255 0xFF 0xFF 0xFF

        TextInverted ->
            Ui.rgb255 0x22 0x22 0x22

        Bg ->
            Ui.rgb255 0x20 0x20 0x3A

        Boom ->
            Ui.rgb255 0xB0 0x2A 0xB0

        Accented ->
            Ui.rgb255 0x60 0x20 0x80


setAlpha : Float -> Ui.Color -> Ui.Color
setAlpha alpha col =
    let
        rgb =
            Ui.toRgb col
    in
    Ui.fromRgb
        { red = rgb.red
        , blue = rgb.blue
        , green = rgb.green
        , alpha = alpha
        }


darken : Ui.Color -> Ui.Color
darken col =
    let
        rgb =
            Ui.toRgb col

        factor =
            0.85
    in
    Ui.fromRgb
        { red = rgb.red * factor
        , blue = rgb.blue * factor
        , green = rgb.green * factor
        , alpha = rgb.alpha
        }


lighten : Ui.Color -> Ui.Color
lighten col =
    let
        rgb =
            Ui.toRgb col

        factor =
            1.15
    in
    Ui.fromRgb
        { red = rgb.red * factor
        , blue = rgb.blue * factor
        , green = rgb.green * factor
        , alpha = rgb.alpha * factor
        }
