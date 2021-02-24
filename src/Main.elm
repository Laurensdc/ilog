module Main exposing (..)

import Browser
import Color
import Element as Ui
import Element.Background as Background
import Element.Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Material.Icons.Action
import Material.Icons.Content
import Material.Icons.Navigation
import Material.Icons.Toggle
import Task
import Time
import Time.Extra as Time
import Widget
import Widget.Customize
import Widget.Icon as Icon
import Widget.Material
import Widget.Material.Color



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


type alias Model =
    { inputWho : String
    , inputComments : String
    , inputSubTask : String
    , inputSearch : String
    , formVisible : Bool
    , calls : List Call
    , archivedCalls : List Call
    , searchResults : List Call
    , subTasks : List SubTask
    , preSaveSubTasks : List SubTask
    , timeZone : Time.Zone
    , today : Time.Posix
    }


dummyCalls : List Call
dummyCalls =
    [ { id = FromBackend 1
      , who = "Woe 24/02 19:24"
      , comments = "Nog bellen naar labo enal, kwenie"
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


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputWho = ""
      , inputComments = ""
      , inputSubTask = ""
      , inputSearch = ""
      , formVisible = False
      , calls = dummyCalls
      , subTasks = dummySubTasks
      , archivedCalls = []
      , preSaveSubTasks = []
      , searchResults = []
      , timeZone = Time.utc
      , today = Time.millisToPosix 0
      }
    , Cmd.batch [ Task.perform GetTimeZone Time.here, Task.perform SetToday Time.now ]
    )


type alias Call =
    { id : CallId
    , who : String
    , comments : String
    , when : Time.Posix
    }


type alias SubTask =
    { callId : CallId, text : String, done : Bool }


type CallId
    = Creating
    | FromBackend Int



-- UPDATE


type Msg
    = InputWhoChanged String
    | InputCommentsChanged String
    | InputSubTaskChanged String
    | InputSearchChanged String
    | AddPreSaveSubTask
    | AddCall
    | AddCallWithTime Time.Posix
    | DeletePreSaveSubTask SubTask
    | ToggleSubTask SubTask
    | ArchiveCall Call
    | OpenForm
    | CloseForm
    | GetTimeZone Time.Zone
    | SetToday Time.Posix


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
            ( { model | formVisible = True }, Cmd.none )

        CloseForm ->
            ( { model | formVisible = False }, Cmd.none )


{-| Checks calls for highest value of id.

Returns a new highest id.

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


toggleSubTask : SubTask -> SubTask
toggleSubTask subTask =
    { subTask
        | done = not subTask.done
    }



-- VIEW


viewDocument : Model -> Browser.Document Msg
viewDocument model =
    { title = "ILog", body = [ view model ] }


view : Model -> Html.Html Msg
view model =
    let
        overlayFormIfVisible =
            if model.formVisible == True then
                Ui.inFront
                    (Ui.el
                        [ Background.color <| Ui.rgba 0 0 0 0.7
                        , Ui.width Ui.fill
                        , Ui.height Ui.fill
                        , Font.center

                        -- Close icon "x"
                        , Ui.behindContent
                            (Ui.el [ Ui.centerX, Ui.centerY, Ui.paddingEach { top = 0, right = 0, left = 700, bottom = 500 } ]
                                (Ui.el [ Element.Events.onClick CloseForm ] (Icon.materialIcons Material.Icons.Navigation.close { size = 40, color = Color.white }))
                            )

                        -- Also clicking anywhere on the screen (but not on the form) should close the form
                        , Ui.behindContent (Ui.el [ Ui.width Ui.fill, Ui.height Ui.fill, Element.Events.onClick CloseForm ] Ui.none)
                        ]
                        (Ui.column [ Ui.centerX, Ui.centerY, Font.alignLeft, Ui.spacing 16 ] (viewForm model))
                    )

            else
                -- Nothing
                Ui.htmlAttribute (Html.Attributes.class "")
    in
    Ui.layout
        [ Font.family
            [ Font.external { url = "https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap", name = "Roboto" }
            ]
        , Font.size 18
        , Font.color <| color Text
        , Background.color <| color Bg
        , Ui.paddingXY 0 32

        -- Form
        , overlayFormIfVisible
        ]
        (Ui.column
            [ Ui.width (Ui.fill |> Ui.maximum 1200)
            , Ui.centerX
            , Ui.spacing 16
            ]
            [ -- Show Form Button
              Ui.row [ Ui.width Ui.fill ]
                [ Ui.el [ Ui.alignLeft ]
                    (Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
                        { text = "Gesprek toevoegen"
                        , icon = Material.Icons.Content.add |> Icon.materialIcons
                        , onPress = Just OpenForm
                        }
                    )

                --  Search
                , Ui.el [ Ui.alignRight ] (Icon.materialIcons Material.Icons.Action.search { size = 40, color = Color.lightGray })
                , Input.text
                    [ Font.color <| color TextInverted
                    , Ui.width (Ui.px 320)
                    , Ui.alignRight
                    ]
                    { onChange = InputSearchChanged
                    , text = model.inputSearch
                    , placeholder = Just (Input.placeholder [] (Ui.text "Zoeken: Klant, datum, commentaar, ..."))
                    , label = Input.labelHidden "Zoeken"
                    }
                ]
            , -- Calls
              if model.inputSearch == "" then
                viewUnarchivedCalls model

              else
                Ui.none
            , if model.inputSearch == "" then
                viewArchivedCalls model

              else
                Ui.none
            , if model.inputSearch /= "" then
                viewSearchCalls model

              else
                Ui.none
            ]
        )


viewForm : Model -> List (Ui.Element Msg)
viewForm model =
    -- Title
    [ Ui.el [ Font.size 24 ]
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
    , Widget.button (Widget.Material.containedButton Widget.Material.darkPalette)
        { text = "Gesprek opslaan"
        , icon = Material.Icons.Content.add |> Icon.materialIcons
        , onPress = Just AddCall
        }
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
                        || String.contains search (dateToHumanStr model.timeZone call.when |> String.toLower)
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
            , Ui.column [] <| viewCalls foundCalls model.subTasks { archived = False, timeZone = model.timeZone, today = model.today }
            , Ui.column [] <| viewCalls foundArchivedCalls model.subTasks { archived = True, timeZone = model.timeZone, today = model.today }
            ]

    else
        Ui.none


viewUnarchivedCalls : Model -> Ui.Element Msg
viewUnarchivedCalls model =
    let
        topPadding =
            Ui.paddingEach { top = 16, left = 0, right = 0, bottom = 0 }

        callsToday =
            viewCalls (filterCallsFromDay model.calls model.timeZone model.today)
                model.subTasks
                { archived = False, timeZone = model.timeZone, today = model.today }

        callsThisWeek =
            viewCalls (filterCallsFromThisWeekButNotToday model.calls model.timeZone model.today)
                model.subTasks
                { archived = False, timeZone = model.timeZone, today = model.today }

        callsBeforeThisWeek =
            viewCalls (filterCallsBeforeThisWeek model.calls model.timeZone model.today)
                model.subTasks
                { archived = False, timeZone = model.timeZone, today = model.today }
    in
    if List.length model.calls > 0 then
        Ui.column []
            [ Ui.el
                [ topPadding
                , Font.size 24
                , Font.bold
                ]
                (Ui.text "Gesprekken / todo's")

            -- Today
            , if List.length callsToday > 0 then
                Ui.el [ Font.italic, topPadding ] (Ui.text "Vandaag")

              else
                Ui.none
            , Ui.column [] <| callsToday

            -- Week
            , if List.length callsThisWeek > 0 then
                Ui.el [ Font.italic, topPadding ] (Ui.text "Eerder deze week")

              else
                Ui.none
            , Ui.column [] <| callsThisWeek

            -- Before that
            , if List.length callsBeforeThisWeek > 0 then
                Ui.el [ Font.italic, topPadding ] (Ui.text "Heel erg lang geleden...")

              else
                Ui.none
            , Ui.column [] <| callsBeforeThisWeek
            ]

    else
        Ui.none


viewArchivedCalls : Model -> Ui.Element Msg
viewArchivedCalls model =
    -- Archive
    if List.length model.archivedCalls > 0 then
        Ui.column []
            [ Ui.el
                [ Ui.paddingEach { top = 16, left = 0, right = 0, bottom = 0 }
                , Font.size 24
                , Font.bold
                ]
                (Ui.text
                    "Archief"
                )
            , Ui.column [] <| viewCalls model.archivedCalls model.subTasks { archived = True, timeZone = model.timeZone, today = model.today }
            ]

    else
        Ui.none


viewCalls : List Call -> List SubTask -> { archived : Bool, timeZone : Time.Zone, today : Time.Posix } -> List (Ui.Element Msg)
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
    in
    List.map
        (\call ->
            Ui.row
                [ Ui.paddingXY 0 16
                , if options.archived == True then
                    Font.strike

                  else
                    Font.regular
                ]
                [ -- The little ball to click
                  Ui.row []
                    [ Ui.el [ Ui.width (Ui.px 32), Ui.alignTop, Element.Events.onClick (ArchiveCall call) ]
                        (if options.archived == True then
                            Icon.materialIcons Material.Icons.Toggle.check_box { size = 24, color = Color.lightGreen }

                         else
                            Icon.materialIcons Material.Icons.Toggle.radio_button_unchecked { size = 24, color = Color.lightGray }
                        )

                    -- Date / time
                    , Ui.column [ Ui.alignTop, Ui.width (Ui.px 300) ]
                        [ Ui.column []
                            [ Ui.el [ Font.italic ] (Ui.text (dateToHumanStr options.timeZone call.when))
                            , Ui.el [ Font.bold ] (Ui.text call.who)
                            ]
                        ]

                    -- Comments & SubTasks
                    , Ui.column [ Ui.alignTop ]
                        ([ Ui.el [ Ui.paddingEach { top = 0, left = 0, right = 0, bottom = 0 } ] (Ui.text call.comments)
                         , if
                            List.length
                                (List.filter
                                    (\s ->
                                        if s.callId == call.id then
                                            True

                                        else
                                            False
                                    )
                                    subtasks
                                )
                                > 0
                           then
                            Ui.el [ Ui.paddingEach { top = 16, left = 0, right = 0, bottom = 0 } ] (Ui.text "Taken")

                           else
                            Ui.none
                         ]
                            ++ viewSubTasks call subtasks
                        )
                    ]
                ]
        )
        sortedCalls


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
                [ Ui.el [ Ui.paddingEach { top = 0, left = 0, right = 4, bottom = 0 } ]
                    (if subTask.done then
                        Icon.materialIcons Material.Icons.Toggle.check_box { size = 24, color = Color.lightGreen }

                     else
                        Icon.materialIcons Material.Icons.Toggle.check_box_outline_blank { size = 24, color = Color.lightGray }
                    )
                , if subTask.done then
                    Ui.el [ Font.strike ] (Ui.text subTask.text)

                  else
                    Ui.text subTask.text
                ]
        )
        filteredSubTasks


{-| Subtasks before they are submitted
-}
viewPreSaveSubTasks : Model -> List (Ui.Element Msg)
viewPreSaveSubTasks model =
    List.map
        (\subTask ->
            Ui.row []
                [ Ui.el [ Ui.paddingEach { top = 0, right = 16, bottom = 0, left = 0 } ] (Ui.text subTask.text)
                , Ui.el [ Element.Events.onClick (DeletePreSaveSubTask subTask) ] (Icon.materialIcons Material.Icons.Action.delete { size = 24, color = Color.lightRed })
                ]
        )
        model.preSaveSubTasks


toTwoDigits : Int -> String
toTwoDigits i =
    if i < 10 then
        "0" ++ String.fromInt i

    else
        String.fromInt i



-- TIME STUFF


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


rollbackDays : Int -> Time.Posix -> Time.Posix
rollbackDays days time =
    let
        aDay =
            24 * 60 * 60 * 1000
    in
    (Time.posixToMillis time - days * aDay)
        |> Time.millisToPosix


lastMondayBeforeDate : Time.Zone -> Time.Posix -> Time.Posix
lastMondayBeforeDate zone time =
    let
        intWeekday =
            Time.toWeekday zone time
                |> weekDayToInt
    in
    rollbackDays intWeekday time


oneWeekInMs : Int
oneWeekInMs =
    1000 * 60 * 60 * 24 * 7


oneDayInMs : Int
oneDayInMs =
    1000 * 60 * 60 * 24


dateToHumanStr : Time.Zone -> Time.Posix -> String
dateToHumanStr zone posix =
    toDutchWeekday (Time.toWeekday zone posix)
        ++ " "
        ++ toTwoDigits (Time.toDay zone posix)
        ++ "/"
        ++ toDutchMonthNumber (Time.toMonth zone posix)
        ++ "\n"
        ++ (Time.toHour zone posix |> String.fromInt)
        ++ ":"
        ++ (Time.toMinute zone posix |> toTwoDigits)


weekDayToInt : Time.Weekday -> Int
weekDayToInt day =
    case day of
        Time.Mon ->
            0

        Time.Tue ->
            1

        Time.Wed ->
            2

        Time.Thu ->
            3

        Time.Fri ->
            4

        Time.Sat ->
            5

        Time.Sun ->
            6


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
