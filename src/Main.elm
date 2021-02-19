module Main exposing (..)

import Browser
import Element as Ui
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
    Ui.layout []
        (Ui.column
            []
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
