port module Main exposing (..)

import Ant.Icon
import Ant.Icons as Icon
import Browser
import Element as Ui
import Element.Background as Background
import Element.Border as Border
import Element.Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Http
import Json.Decode
import Json.Decode.Extra
import Json.Encode
import Task
import Time
import Time.Extra as Time
import TimeStuff



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = viewDocument
        }



-- MODEL


dummyCalls : List Call
dummyCalls =
    [ { id = FromBackend 1
      , who = "Woe 24/02 19:24"
      , comments = "TEST bellen naar labo enal, kwenie"
      , when = Time.millisToPosix 1614191035000
      }
    , { id = FromBackend 2
      , who = "23/02 03:23"
      , comments = "Wa een tang"
      , when = Time.millisToPosix 1614093833000
      }
    , { id = FromBackend 3
      , who = "22/02 03:23"
      , comments = "Wdddd een tang"
      , when = Time.millisToPosix 1614007433000
      }
    , { id = FromBackend 4
      , who = "21/02"
      , comments = "Ik ben epic"
      , when = Time.millisToPosix 1613921033000
      }
    , { id = FromBackend 5
      , who = "Dinsdag 23/02 22:33?"
      , comments = "Soep"
      , when = Time.millisToPosix 1614116005166
      }
    ]


dummySubTasks : List SubTask
dummySubTasks =
    [ { callId = FromBackend 1, text = "Bel labo", done = False }
    , { callId = FromBackend 1, text = "Check die stock", done = False }
    , { callId = FromBackend 2, text = "Bel Cissy", done = False }
    , { callId = FromBackend 2, text = "Dingske mailen met vraag", done = False }
    ]


type alias Model =
    FormStuff
        { inputSearch : String
        , formVisible : Bool

        -- Calls & subtasks (data)
        , calls : List Call
        , archivedCalls : List Call
        , searchResults : List Call
        , subTasks : List SubTask

        -- Time stuff
        , timeZone : Time.Zone
        , today : Time.Posix

        -- Will need this to do http requests
        , backendUrl : String
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { -- Form stuff
        inputWho = ""
      , inputComments = ""
      , inputSubTask = ""
      , preSaveSubTasks = []

      -- Not in the type alias of Form
      , formVisible = False

      -- Other inputs
      , inputSearch = ""

      -- Calls & subtasks (data)
      , calls = dummyCalls
      , subTasks = []
      , archivedCalls = []
      , searchResults = []

      -- Time stuff
      , timeZone = Time.utc
      , today = Time.millisToPosix 0

      -- Will need this to do http requests
      , backendUrl = "http://localhost:3000"
      }
    , Cmd.batch
        [ Task.perform GetTimeZone Time.here
        , Task.perform SetToday Time.now
        , getCallsAndSubTasks "http://localhost:3000"
        ]
    )


type alias FormStuff r =
    { r
        | inputWho : String
        , inputComments : String
        , inputSubTask : String
        , preSaveSubTasks : List SubTask
    }


type alias Call =
    { id : CallId
    , who : String
    , comments : String
    , when : Time.Posix
    }


type alias SubTask =
    { callId : CallId
    , text : String
    , done : Bool
    }


type CallId
    = Creating
    | FromBackend Int



-- PORTS


port sendMessage : String -> Cmd msg


port receiveMessage : (Int -> msg) -> Sub msg



-- UPDATE


type Msg
    = -- Input stuff
      InputWhoChanged String
    | InputCommentsChanged String
    | InputSubTaskChanged String
    | InputSearchChanged String
      -- Call & subTask stuff
    | AddPreSaveSubTask
    | AddCall
    | AddCallWithTime Time.Posix
    | DeletePreSaveSubTask SubTask
    | ToggleSubTask SubTask
    | ArchiveCall Call
      -- Form stuff
    | OpenForm
    | CloseForm
      -- Time stuff
    | GetTimeZone Time.Zone
    | SetToday Time.Posix
      -- API stuff
    | GotCallsAndSubTasks (Result Http.Error (List SubTask))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputWhoChanged text ->
            ( { model | inputWho = text }, Cmd.none )

        InputCommentsChanged text ->
            ( { model | inputComments = text }, Cmd.none )

        InputSubTaskChanged text ->
            ( { model | inputSubTask = text }, Cmd.none )

        InputSearchChanged text ->
            ( { model | inputSearch = text }, Cmd.none )

        AddPreSaveSubTask ->
            if model.inputSubTask == "" then
                ( model, Cmd.none )

            else
                ( { model
                    | preSaveSubTasks = model.preSaveSubTasks ++ [ { callId = Creating, text = model.inputSubTask, done = False } ]
                    , inputSubTask = ""
                  }
                , Cmd.none
                )

        AddCall ->
            ( model, Task.perform AddCallWithTime Time.now )

        AddCallWithTime time ->
            let
                newCallId =
                    createNewCallId model
            in
            ( { model
                | calls =
                    model.calls
                        ++ [ { -- TODO -> actually from backend
                               id = newCallId
                             , who = model.inputWho
                             , comments = model.inputComments
                             , when = time
                             }
                           ]
                , subTasks = model.subTasks ++ List.map (\subTask -> { subTask | callId = newCallId }) model.preSaveSubTasks
                , preSaveSubTasks = []
                , inputWho = ""
                , inputComments = ""
                , formVisible = False
              }
            , Cmd.none
            )

        DeletePreSaveSubTask subtask ->
            ( { model
                | preSaveSubTasks = List.filter (\s -> s /= subtask) model.preSaveSubTasks
              }
            , Cmd.none
            )

        GetTimeZone newZone ->
            ( { model | timeZone = newZone }, Cmd.none )

        SetToday time ->
            ( { model | today = time }, Cmd.none )

        ToggleSubTask subTask ->
            ( { model
                | subTasks =
                    List.map
                        (\sub ->
                            if sub == subTask then
                                toggleSubTask sub

                            else
                                sub
                        )
                        model.subTasks
              }
            , Cmd.none
            )

        ArchiveCall call ->
            ( { model
                | calls =
                    if List.member call model.calls then
                        List.filter (\fCall -> fCall /= call) model.calls

                    else
                        call :: model.calls
                , archivedCalls =
                    if List.member call model.archivedCalls then
                        List.filter (\fCall -> fCall /= call) model.archivedCalls

                    else
                        call :: model.archivedCalls
              }
            , Cmd.none
            )

        OpenForm ->
            ( { model | formVisible = True }, sendMessage "Test" )

        CloseForm ->
            ( { model | formVisible = False }, Cmd.none )

        GotCallsAndSubTasks httpResult ->
            case httpResult of
                Ok subTasks ->
                    ( { model | subTasks = subTasks }, Cmd.none )

                -- TODO : Handle errors in UI
                Err err ->
                    Debug.log (anyErrorToString err) ( model, Cmd.none )


{-| Checks calls for highest value of id.

Returns a new highest id.
Should become redundant when using actual API.

-}
createNewCallId : Model -> CallId
createNewCallId model =
    let
        max =
            List.maximum
                (List.map
                    (\call ->
                        case call.id of
                            Creating ->
                                -1

                            FromBackend callid ->
                                callid
                    )
                    model.calls
                )
    in
    case max of
        Nothing ->
            Creating

        Just x ->
            FromBackend (x + 1)


{-| Todo: Call API
-}
toggleSubTask : SubTask -> SubTask
toggleSubTask subTask =
    { subTask
        | done = not subTask.done
    }



-- VIEW


viewDocument : Model -> Browser.Document Msg
viewDocument model =
    { title = "ILog", body = [ view model ] }


fontGlobals : List (Ui.Attribute Msg)
fontGlobals =
    [ Font.family
        [ Font.external { url = "https://fonts.googleapis.com/css2?family=Open+Sans:ital,wght@0,300;0,400;0,700;1,300;1,400&family=Ubuntu:ital,wght@0,400;0,700;1,400;1,500&display=swap", name = "Open Sans" }
        , Font.typeface "Helvetica"
        , Font.sansSerif
        ]
    , Font.size 18
    , Font.light
    , Font.color <| color Text
    ]


view : Model -> Html.Html Msg
view model =
    let
        overlayFormIfVisible =
            if model.formVisible == True then
                viewFullScreenOverlay model

            else
                noAttr
    in
    Ui.layoutWith
        { options =
            [ -- Global Focus styles
              Ui.focusStyle
                { borderColor = Nothing -- Just (color Boom)
                , backgroundColor = Nothing
                , shadow = Just { color = color Accented, offset = ( 0, 0 ), blur = 10, size = 3 }
                }
            ]
        }
        (fontGlobals
            ++ [ Background.color <| color Bg
               , Ui.padding 32

               -- Form
               , overlayFormIfVisible
               ]
        )
        (Ui.column
            [ Ui.width (Ui.fill |> Ui.maximum 1100)
            , Ui.centerX
            , Ui.spacing 16
            ]
            [ Ui.row [ Ui.width Ui.fill, Ui.spacingXY 32 0 ]
                [ Ui.el [ Font.size 48, Font.bold ] (Ui.text "ILog")
                , viewSearchbar model.inputSearch
                , Ui.el []
                    (button "Gesprek toevoegen" OpenForm)
                ]
            , -- Calls
              if model.inputSearch == "" then
                viewUnarchivedCalls model

              else
                Ui.none
            , if model.inputSearch == "" then
                Ui.el [ Ui.width Ui.fill, Ui.paddingEach { top = 128, left = 0, right = 0, bottom = 0 } ] (viewArchivedCalls model)

              else
                Ui.none
            , if model.inputSearch /= "" then
                viewSearchCalls model

              else
                Ui.none
            ]
        )


viewSearchbar : String -> Ui.Element Msg
viewSearchbar text =
    Input.text
        [ Font.color <| color TextInverted
        , Ui.paddingXY 16 8
        , Ui.width (Ui.px 320)
        , Ui.alignRight
        , Border.rounded 4
        ]
        { onChange = InputSearchChanged
        , text = text
        , placeholder = Just (Input.placeholder [] (Ui.text "Zoek in gesprekken"))
        , label = Input.labelHidden "Zoeken"
        }


viewFullScreenOverlay : FormStuff r -> Ui.Attribute Msg
viewFullScreenOverlay model =
    Ui.inFront
        (Ui.el
            [ Background.color <| Ui.rgba 1 1 1 0.7
            , Ui.width Ui.fill
            , Ui.height Ui.fill
            , Font.center

            -- Also clicking anywhere on the screen (but not on the form) should close the form
            , Ui.behindContent (Ui.el [ Ui.width Ui.fill, Ui.height Ui.fill, Element.Events.onClick CloseForm ] Ui.none)
            ]
            (Ui.column
                [ Ui.centerX
                , Ui.centerY
                , Font.alignLeft
                , Ui.spacing 16
                , Background.color <| color Bg
                , Ui.paddingXY 56 48
                , Border.rounded 32
                ]
                (viewForm model)
            )
        )


viewForm : FormStuff r -> List (Ui.Element Msg)
viewForm model =
    -- Title
    [ -- Close icon "x"
      Ui.row [ Ui.width Ui.fill ]
        [ Ui.el [ Font.size 24 ]
            (Ui.text "Voeg een gesprek toe")
        , Ui.el [ Ui.alignTop, Ui.alignRight ]
            (Ui.el [ Element.Events.onClick CloseForm ] (Icon.closeCircleOutlined [ Ant.Icon.width 32 ]))
        ]
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

    -- Pre Save SubTasks
    , Ui.row [ Ui.width (Ui.shrink |> Ui.minimum 200) ]
        [ Input.text
            [ Font.color <| color TextInverted
            , onEnter AddPreSaveSubTask
            , Ui.htmlAttribute
                (Html.Events.onBlur AddPreSaveSubTask)
            ]
            { onChange = InputSubTaskChanged
            , text = model.inputSubTask
            , placeholder = Nothing
            , label = Input.labelAbove [] <| Ui.text "Taak toevoegen"
            }
        ]
    , Ui.column [] <| viewPreSaveSubTasks model
    , button "Gesprek opslaan" AddCall
    ]


viewSearchCalls : Model -> Ui.Element Msg
viewSearchCalls model =
    let
        search =
            String.toLower model.inputSearch

        filterer : Call -> Bool
        filterer =
            \call ->
                if
                    String.contains search (call.who |> String.toLower)
                        || String.contains search (TimeStuff.toDutchWeekday model.timeZone call.when |> String.toLower)
                        || String.contains search (TimeStuff.toHumanDate model.timeZone call.when |> String.toLower)
                        || String.contains search (TimeStuff.toHumanTime model.timeZone call.when |> String.toLower)
                        || String.contains search (call.comments |> String.toLower)
                then
                    True

                else
                    False

        foundCalls =
            List.filter filterer model.calls

        foundArchivedCalls =
            List.filter filterer model.archivedCalls
    in
    if List.length foundCalls > 0 || List.length foundArchivedCalls > 0 then
        Ui.column []
            [ Ui.el
                [ Ui.paddingEach { top = 16, left = 0, right = 0, bottom = 0 }
                , Font.size 24
                , Font.bold
                ]
                (Ui.text "Zoekresultaten")
            , viewCalls foundCalls model.subTasks { archived = False, timeZone = model.timeZone, today = model.today }
            , viewCalls foundArchivedCalls model.subTasks { archived = True, timeZone = model.timeZone, today = model.today }
            ]

    else
        Ui.none


viewUnarchivedCalls : Model -> Ui.Element Msg
viewUnarchivedCalls model =
    let
        topPadding =
            Ui.paddingEach { top = 32, left = 0, right = 0, bottom = 0 }

        titleStyles =
            [ Ui.paddingEach { top = 32, left = 0, right = 0, bottom = 0 }
            , Font.size 22
            , Font.regular
            ]

        callsToday =
            filterCallsFromDay model.calls model.timeZone model.today

        viewCallsToday =
            viewCalls callsToday
                model.subTasks
                { archived = False, timeZone = model.timeZone, today = model.today }

        callsThisWeek =
            filterCallsFromThisWeekButNotToday model.calls model.timeZone model.today

        viewCallsThisWeek =
            viewCalls callsThisWeek
                model.subTasks
                { archived = False, timeZone = model.timeZone, today = model.today }

        callsBeforeThisWeek =
            filterCallsBeforeThisWeek model.calls model.timeZone model.today

        viewCallsBeforeThisWeek =
            viewCalls callsBeforeThisWeek
                model.subTasks
                { archived = False, timeZone = model.timeZone, today = model.today }
    in
    if List.length model.calls > 0 then
        Ui.column [ Ui.width Ui.fill ]
            [ -- Today
              if List.length callsToday > 0 then
                Ui.el titleStyles (Ui.text "Vandaag")

              else
                Ui.none
            , viewCallsToday

            -- Week
            , if List.length callsThisWeek > 0 then
                Ui.el titleStyles (Ui.text "Eerder deze week")

              else
                Ui.none
            , viewCallsThisWeek

            -- Before that
            , if List.length callsBeforeThisWeek > 0 then
                Ui.el titleStyles (Ui.text "Gesprekken uit een ver verleden")

              else
                Ui.none
            , viewCallsBeforeThisWeek
            ]

    else
        Ui.none


viewArchivedCalls : Model -> Ui.Element Msg
viewArchivedCalls model =
    -- Archive
    if List.length model.archivedCalls > 0 then
        viewCalls model.archivedCalls model.subTasks { archived = True, timeZone = model.timeZone, today = model.today }

    else
        Ui.none


{-| Core viewCalls function that's being used by viewSearchCalls, viewArchivedCalls, viewArchivedCalls..
-}
viewCalls : List Call -> List SubTask -> { archived : Bool, timeZone : Time.Zone, today : Time.Posix } -> Ui.Element Msg
viewCalls calls subtasks options =
    let
        sortedCalls =
            List.sortWith
                (\a b ->
                    if Time.posixToMillis a.when > Time.posixToMillis b.when then
                        LT

                    else
                        GT
                )
                calls

        archivedStyles =
            if options.archived == True then
                [ Font.color <| darken <| darken <| darken <| color Text
                ]

            else
                []
    in
    Ui.column
        [ Ui.width Ui.fill
        , Ui.spacingXY 0 16
        ]
        (List.map
            (\call ->
                Ui.row
                    (archivedStyles
                        ++ [ Ui.width Ui.fill
                           , Ui.paddingXY 0 32
                           , Border.widthEach { top = 0, left = 0, right = 0, bottom = 1 }
                           , Border.color <| lighten <| lighten <| color Bg
                           ]
                    )
                    [ -- Icon
                      Ui.el
                        [ Ui.width (Ui.px 48)
                        , Ui.alignTop
                        , Element.Events.onClick (ArchiveCall call)
                        , Ui.pointer
                        ]
                        (if options.archived == True then
                            Icon.checkSquareFilled [ iconsize ]

                         else
                            Icon.borderOutlined [ iconsize ]
                        )

                    -- Date / time
                    , Ui.column [ Ui.alignTop ]
                        [ Ui.column []
                            [ Ui.el [ Font.bold, Font.size 22, Ui.paddingEach { left = 0, right = 0, top = 0, bottom = 8 } ]
                                (Ui.text call.who)
                            , Ui.row [ Font.italic ]
                                [ Ui.el [ Ui.width <| Ui.px 140 ] (Ui.text (TimeStuff.toDutchWeekday options.timeZone call.when))
                                , Ui.el [ Ui.width <| Ui.px 80 ] (Ui.text (TimeStuff.toHumanDate options.timeZone call.when))
                                , Ui.el [] (Ui.text (TimeStuff.toHumanTime options.timeZone call.when))
                                ]
                            , Ui.paragraph [ Ui.paddingEach { top = 32, left = 0, right = 0, bottom = 0 } ] [ Ui.text call.comments ]
                            ]
                        ]

                    -- Comments & SubTasks
                    , Ui.column
                        [ Ui.alignTop
                        , Ui.spacingXY 0 8
                        , Ui.alignRight
                        , Ui.width <| Ui.px 400
                        , Font.alignLeft
                        , Ui.paddingEach { top = 28, left = 0, right = 0, bottom = 0 }
                        ]
                        (viewSubTasks call subtasks)
                    ]
            )
            sortedCalls
        )


viewSubTasks : Call -> List SubTask -> List (Ui.Element Msg)
viewSubTasks call subtasks =
    let
        filteredSubTasks =
            List.filter
                (\subTask ->
                    if subTask.callId == call.id then
                        True

                    else
                        False
                )
                subtasks
    in
    List.map
        (\subTask ->
            Ui.row
                [ Element.Events.onClick (ToggleSubTask subTask)
                , Ui.pointer
                ]
                [ Ui.el [ Ui.paddingEach { top = 0, left = 0, right = 8, bottom = 0 } ]
                    (if subTask.done then
                        Icon.checkSquareFilled [ iconsize ]

                     else
                        Icon.borderOutlined [ iconsize ]
                    )
                , if subTask.done then
                    Ui.paragraph [ Font.strike ] [ Ui.text subTask.text ]

                  else
                    Ui.paragraph [] [ Ui.text subTask.text ]
                ]
        )
        filteredSubTasks


{-| Subtasks before they are submitted
-}
viewPreSaveSubTasks : FormStuff r -> List (Ui.Element Msg)
viewPreSaveSubTasks model =
    List.map
        (\subTask ->
            Ui.row []
                [ Ui.el [ Ui.paddingEach { top = 0, right = 16, bottom = 0, left = 0 } ] (Ui.text subTask.text)
                , Ui.el [ Element.Events.onClick (DeletePreSaveSubTask subTask), Ui.pointer ] (Icon.deleteFilled [ iconsize ])
                ]
        )
        model.preSaveSubTasks


button : String -> Msg -> Ui.Element Msg
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


smoothTransition : Ui.Attribute msg
smoothTransition =
    Ui.htmlAttribute (Html.Attributes.style "transition" "0.15s ease-in-out")



-- HTTP


getCallsAndSubTasks : String -> Cmd Msg
getCallsAndSubTasks backendUrl =
    Http.get { url = backendUrl ++ "/calls", expect = Http.expectJson GotCallsAndSubTasks subTasksDecoder }



-- callsAndSubTasksDecoder : Json.Decode.Decoder ( List Call, List SubTask )
-- callsAndSubTasksDecoder =
--     -- How to combine these?? They are two separate Lists in model ..
--     Json.Decode.map2 () callsDecoder subTasksDecoder


callsDecoder : Json.Decode.Decoder (List Call)
callsDecoder =
    Json.Decode.field "calls"
        (Json.Decode.list
            (Json.Decode.map4 Call
                (Json.Decode.field "id" Json.Decode.int
                    |> Json.Decode.andThen (\i -> Json.Decode.succeed (FromBackend i))
                )
                (Json.Decode.field "who" Json.Decode.string)
                (Json.Decode.field "comments" Json.Decode.string)
                (Json.Decode.field "created_at" Json.Decode.Extra.datetime)
             -- How to split this into archived calls???
            )
        )


subTasksDecoder : Json.Decode.Decoder (List SubTask)
subTasksDecoder =
    Json.Decode.field "subTasks"
        (Json.Decode.list
            (Json.Decode.map3 SubTask
                (Json.Decode.field "call_id" Json.Decode.int
                    |> Json.Decode.andThen
                        (\id ->
                            Json.Decode.succeed (FromBackend id)
                        )
                )
                (Json.Decode.field "text" Json.Decode.string)
                (Json.Decode.field "done" Json.Decode.bool)
            )
        )


anyErrorToString : Http.Error -> String
anyErrorToString err =
    case err of
        Http.BadUrl str ->
            "Bad URL: " ++ str

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus i ->
            "Bad status " ++ String.fromInt i

        Http.BadBody str ->
            "Bad body: " ++ str



-- FILTERING CALLS


filterCallsFromDay : List Call -> Time.Zone -> Time.Posix -> List Call
filterCallsFromDay calls zone day =
    List.filter
        (\call -> Time.posixToMillis (Time.startOfDay zone day) == Time.posixToMillis (Time.startOfDay zone call.when))
        calls


filterCallsFromThisWeekButNotToday : List Call -> Time.Zone -> Time.Posix -> List Call
filterCallsFromThisWeekButNotToday calls zone today =
    let
        startOfWeekInt =
            Time.posixToMillis <| Time.startOfDay zone <| Time.startOfWeek zone Time.Mon today

        startOfTodayInt =
            Time.posixToMillis <| Time.startOfDay zone today
    in
    List.filter
        (\call ->
            let
                startOfCallDayInt =
                    Time.posixToMillis <| Time.startOfDay zone call.when
            in
            (startOfCallDayInt >= startOfWeekInt) && (startOfCallDayInt < startOfTodayInt)
        )
        calls


filterCallsBeforeThisWeek : List Call -> Time.Zone -> Time.Posix -> List Call
filterCallsBeforeThisWeek calls zone today =
    let
        startOfWeekInt =
            Time.posixToMillis <| Time.startOfDay zone <| Time.startOfWeek zone Time.Mon today
    in
    List.filter
        (\call ->
            let
                startOfCallDayInt =
                    Time.posixToMillis <| Time.startOfDay zone call.when
            in
            startOfWeekInt > startOfCallDayInt
        )
        calls



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


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



-- COLORS


type AppColor
    = Text
    | TextInverted
    | Bg
    | Boom
    | Accented


color : AppColor -> Ui.Color
color col =
    -- #1b1f3a, #a64942, #ff7844
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
