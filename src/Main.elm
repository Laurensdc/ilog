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


type alias Model =
    FormStuff
        { -- Other Form stuff
          inputSearch : String

        -- Calls & subtasks (data)
        , calls : List Call
        , archivedCalls : List Call
        , subTasks : List SubTask

        -- Time stuff
        , timeZone : Time.Zone
        , today : Time.Posix

        -- Will need this to do http requests
        , backendUrl : String
        , loading : Bool
        }


type FormStatus
    = Editing Call
    | AddingCall
    | Closed


init : () -> ( Model, Cmd Msg )
init _ =
    ( { -- Form stuff
        inputWho = ""
      , inputComments = ""
      , inputSubTask = ""
      , preSaveSubTasks = []
      , formStatus = Closed

      -- Other inputs
      , inputSearch = ""

      -- Calls & subtasks (data)
      , calls = []
      , subTasks = []
      , archivedCalls = []

      -- Time stuff
      , timeZone = Time.utc
      , today = Time.millisToPosix 0

      -- Will need this to do http requests
      , backendUrl = "http://localhost:3000"
      , loading = True
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
        , formStatus : FormStatus
    }


type alias Call =
    { id : AppId
    , who : String
    , comments : String
    , when : Time.Posix
    , isArchived : Bool
    }


type alias SubTask =
    { id : AppId
    , callId : AppId
    , text : String
    , done : Bool
    }


type AppId
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
    | DeletePreSaveSubTask SubTask
    | ArchiveCall Call
      -- Form stuff
    | OpenFormToAddCall
    | CloseForm
    | OpenFormToEditCall Call
    | CloseEditForm
      -- Time stuff
    | GetTimeZone Time.Zone
    | SetToday Time.Posix
      -- API stuff
    | AddCall
    | AddCallWithTime Time.Posix
    | ToggleSubTask SubTask
    | GotCallsAndSubTasks (Result Http.Error { calls : List Call, subTasks : List SubTask })
    | AddedCall (Result Http.Error { call : Call, subTasks : List SubTask })
    | ToggledSubTask (Result Http.Error SubTask)
    | ArchivedCall (Result Http.Error Call)
    | UpdateCall { call : Call, subTasks : List SubTask }
    | UpdatedCall (Result Http.Error { call : Call, subTasks : List SubTask })


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
                    | preSaveSubTasks = model.preSaveSubTasks ++ [ { id = Creating, callId = Creating, text = model.inputSubTask, done = False } ]
                    , inputSubTask = ""
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

        OpenFormToAddCall ->
            ( { model | formStatus = AddingCall }, sendMessage "Test" )

        CloseForm ->
            ( { model | formStatus = Closed }, Cmd.none )

        OpenFormToEditCall call ->
            ( { model
                | formStatus = Editing call
                , inputWho = call.who
                , inputComments = call.comments
                , inputSubTask = ""
                , preSaveSubTasks = List.filter (\st -> st.callId == call.id) model.subTasks
              }
            , Cmd.none
            )

        CloseEditForm ->
            ( { model
                | formStatus = Closed
                , inputWho = ""
                , inputComments = ""
                , inputSubTask = ""
                , preSaveSubTasks = []
              }
            , Cmd.none
            )

        -- HTTP msgs
        GotCallsAndSubTasks httpResult ->
            case httpResult of
                Ok result ->
                    ( { model
                        | calls = List.filter (\c -> c.isArchived == False) result.calls
                        , archivedCalls = List.filter (\c -> c.isArchived == True) result.calls
                        , subTasks = result.subTasks
                        , loading = False
                      }
                    , Cmd.none
                    )

                -- TODO : Handle errors in UI
                Err err ->
                    -- Debug.log (anyErrorToString err) ( { model | loading = False }, Cmd.none )
                    ( model, Cmd.none )

        AddCall ->
            ( model, Task.perform AddCallWithTime Time.now )

        AddCallWithTime time ->
            ( { model | loading = True }
            , addCall model.backendUrl
                { id = Creating
                , who = model.inputWho
                , comments = model.inputComments
                , when = time
                , isArchived = False
                }
                (List.map (\subTask -> { subTask | callId = Creating }) model.preSaveSubTasks)
            )

        AddedCall httpResult ->
            case httpResult of
                Ok result ->
                    ( { model
                        | calls = model.calls ++ [ result.call ]
                        , subTasks = model.subTasks ++ result.subTasks
                        , preSaveSubTasks = []
                        , inputWho = ""
                        , inputComments = ""
                        , formStatus = Closed
                        , loading = False
                      }
                    , Cmd.none
                    )

                -- TODO : Handle errors in UI
                Err err ->
                    ( model, Cmd.none )

        ToggleSubTask subTask ->
            ( model
            , toggleSubTask model.backendUrl subTask
            )

        ToggledSubTask httpResult ->
            case httpResult of
                Ok subTask ->
                    ( { model
                        | subTasks =
                            List.map
                                (\st ->
                                    if st.id == subTask.id then
                                        subTask

                                    else
                                        st
                                )
                                model.subTasks
                      }
                    , Cmd.none
                    )

                -- TODO : Handle errors in UI
                Err err ->
                    ( model, Cmd.none )

        ArchiveCall call ->
            ( model
            , archiveCall model.backendUrl call
            )

        ArchivedCall httpResult ->
            case httpResult of
                Ok call ->
                    let
                        updatedArchivedCalls =
                            if call.isArchived then
                                model.archivedCalls ++ [ call ]

                            else
                                List.filter (\c -> c.id /= call.id) model.archivedCalls

                        updatedCalls =
                            if call.isArchived then
                                List.filter (\c -> c.id /= call.id) model.calls

                            else
                                model.calls ++ [ call ]
                    in
                    ( { model
                        | calls = updatedCalls
                        , archivedCalls = updatedArchivedCalls
                      }
                    , Cmd.none
                    )

                -- TODO : Handle errors in UI
                Err err ->
                    ( model, Cmd.none )

        UpdateCall record ->
            ( { model | loading = True }
            , updateCall model.backendUrl record.call record.subTasks
            )

        UpdatedCall httpResult ->
            case httpResult of
                Ok result ->
                    ( { model
                        | loading = False
                        , formStatus = Closed
                        , calls =
                            List.map
                                (\c ->
                                    if result.call.id == c.id then
                                        result.call

                                    else
                                        c
                                )
                                model.calls
                        , subTasks = model.subTasks --TODO
                      }
                    , Cmd.none
                    )

                -- TODO : Handle errors in UI
                Err err ->
                    ( model, Cmd.none )


{-| Checks calls for highest value of id.

Returns a new highest id.
Should become redundant when using actual API.

-}
createNewCallId : Model -> AppId
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



-- VIEW


viewDocument : Model -> Browser.Document Msg
viewDocument model =
    { title = "ILog", body = [ view model ] }


fontGlobals : List (Ui.Attribute Msg)
fontGlobals =
    [ Font.family
        [ Font.external { url = "https://fonts.googleapis.com/css2?family=Open+Sans:ital,wght@0,300;0,400;0,600;0,700;1,300;1,400&family=Ubuntu:ital,wght@0,400;0,700;1,400;1,500&display=swap", name = "Open Sans" }
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
            case model.formStatus of
                Editing call ->
                    viewFullScreenFormOverlay model

                AddingCall ->
                    viewFullScreenFormOverlay model

                Closed ->
                    noAttr

        spinnerIfVisible =
            if model.loading == True then
                viewSpinner

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

               -- Loading spinner
               , spinnerIfVisible
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
                    (button "Gesprek toevoegen" OpenFormToAddCall)
                ]
            , -- Calls
              if model.inputSearch == "" then
                viewUnarchivedCalls model

              else
                Ui.none
            , if model.inputSearch == "" then
                Ui.column [ Ui.width Ui.fill, Ui.paddingEach { top = 128, left = 0, right = 0, bottom = 0 } ]
                    [ if List.length model.archivedCalls > 0 then
                        Ui.el h2Styles (Ui.text "Done!")

                      else
                        Ui.none
                    , viewArchivedCalls model
                    ]

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
        (textInputStyles
            ++ [ Ui.width (Ui.px 320)
               , Ui.alignRight
               ]
        )
        { onChange = InputSearchChanged
        , text = text
        , placeholder = Just (Input.placeholder [] (Ui.text "Zoek in gesprekken"))
        , label = Input.labelHidden "Zoeken"
        }


viewFullScreenOverlay : List (Ui.Element Msg) -> Ui.Attribute Msg
viewFullScreenOverlay stuffInside =
    Ui.inFront
        (Ui.el
            [ Background.color <| Ui.rgba 0.2 0.2 0.2 0.8
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
                , Ui.paddingEach { left = 32, right = 32, top = 48, bottom = 56 }
                , Border.rounded 16
                ]
                stuffInside
            )
        )


viewSpinner : Ui.Attribute Msg
viewSpinner =
    viewFullScreenOverlay [ Ui.text "Loading..." ]


viewFullScreenFormOverlay : FormStuff r -> Ui.Attribute Msg
viewFullScreenFormOverlay model =
    viewFullScreenOverlay (viewForm model)


viewForm : FormStuff r -> List (Ui.Element Msg)
viewForm model =
    -- Title
    [ -- Close icon "x"
      Ui.row [ Ui.width Ui.fill ]
        [ Ui.el [ Font.size 24 ]
            (Ui.text "Voeg een gesprek toe")
        , Ui.el [ Ui.alignTop, Ui.alignRight ]
            (Ui.el
                [ case model.formStatus of
                    AddingCall ->
                        Element.Events.onClick CloseForm

                    Editing call ->
                        Element.Events.onClick CloseEditForm

                    Closed ->
                        noAttr
                ]
                (Icon.closeCircleOutlined [ Ant.Icon.width 32 ])
            )
        ]
    , --  Client
      Input.text
        (textInputStyles
            ++ [ Ui.width (Ui.px 320)
               ]
        )
        { onChange = InputWhoChanged
        , text = model.inputWho
        , placeholder = Just (Input.placeholder [] (Ui.text "Jef van de Carrefour"))
        , label = Input.labelAbove [] <| Ui.text "Wie?"
        }

    --  Comments
    , Input.multiline
        (textInputStyles
            ++ [ Ui.width (Ui.shrink |> Ui.minimum 600)
               , Ui.height <| Ui.px 120
               ]
        )
        { onChange = InputCommentsChanged
        , text = model.inputComments
        , placeholder = Nothing
        , label = Input.labelAbove [] <| Ui.text "Notities"
        , spellcheck = True
        }

    -- Pre Save SubTasks
    , Ui.row [ Ui.width (Ui.shrink |> Ui.minimum 200) ]
        [ Input.text
            (textInputStyles
                ++ [ onEnter AddPreSaveSubTask
                   , Ui.htmlAttribute
                        (Html.Events.onBlur AddPreSaveSubTask)
                   , Ui.width (Ui.px 480)
                   ]
            )
            { onChange = InputSubTaskChanged
            , text = model.inputSubTask
            , placeholder = Just (Input.placeholder [] (Ui.text "Taak toevoegen"))
            , label = Input.labelAbove [] <| Ui.text "Taken"
            }
        ]
    , Ui.column [] <| viewPreSaveSubTasks model
    , button "Gesprek opslaan"
        (case model.formStatus of
            AddingCall ->
                AddCall

            Editing call ->
                UpdateCall { call = { call | who = model.inputWho, comments = model.inputComments }, subTasks = model.preSaveSubTasks }

            Closed ->
                CloseForm
        )
    ]


viewSearchCalls : Model -> Ui.Element Msg
viewSearchCalls model =
    let
        search =
            String.toLower model.inputSearch

        dateFound call =
            String.contains search (TimeStuff.toDutchWeekday model.timeZone call.when |> String.toLower)
                || String.contains search (TimeStuff.toHumanDate model.timeZone call.when |> String.toLower)
                || String.contains search (TimeStuff.toHumanTime model.timeZone call.when |> String.toLower)

        whoFound call =
            String.contains search (call.who |> String.toLower)

        commentFound call =
            String.contains search (call.comments |> String.toLower)

        filterer : Call -> Bool
        filterer =
            -- Todo: Search in calls' subTasks too?
            \call -> whoFound call || commentFound call || dateFound call

        foundCalls =
            List.filter filterer model.calls

        foundArchivedCalls =
            List.filter filterer model.archivedCalls
    in
    if List.length foundCalls > 0 || List.length foundArchivedCalls > 0 then
        Ui.column [ Ui.width Ui.fill ]
            [ Ui.el
                h2Styles
                (Ui.text "Zoekresultaten")
            , viewCalls foundCalls model.subTasks { archived = False, timeZone = model.timeZone, today = model.today }
            , viewCalls foundArchivedCalls model.subTasks { archived = True, timeZone = model.timeZone, today = model.today }
            ]

    else
        Ui.none


viewUnarchivedCalls : Model -> Ui.Element Msg
viewUnarchivedCalls model =
    let
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
                Ui.el h2Styles (Ui.text "Vandaag")

              else
                Ui.none
            , viewCallsToday

            -- Week
            , if List.length callsThisWeek > 0 then
                Ui.el h2Styles (Ui.text "Eerder deze week")

              else
                Ui.none
            , viewCallsThisWeek

            -- Before that
            , if List.length callsBeforeThisWeek > 0 then
                Ui.el h2Styles (Ui.text "Gesprekken uit een ver verleden")

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
                      Ui.column
                        [ Ui.width (Ui.px 48)
                        , Ui.alignTop
                        , Ui.spacingXY 0 16
                        ]
                        [ -- Check icon
                          Ui.el
                            [ Element.Events.onClick (ArchiveCall call)
                            , Ui.pointer
                            ]
                            (if options.archived == True then
                                Icon.checkSquareFilled [ iconsize ]

                             else
                                Icon.borderOutlined [ iconsize ]
                            )
                        , Ui.el
                            [ Element.Events.onClick (OpenFormToEditCall call)
                            , Ui.pointer
                            ]
                            (Icon.editOutlined
                                [ iconsize ]
                            )
                        ]

                    -- Date / time
                    , Ui.column [ Ui.alignTop ]
                        [ Ui.column []
                            [ Ui.el [ Font.semiBold, Font.size 22, Ui.paddingEach { left = 0, right = 0, top = 0, bottom = 8 } ]
                                (Ui.text call.who)
                            , Ui.row [ Font.italic ]
                                [ Ui.el [ Ui.width <| Ui.px 100 ] (Ui.text (TimeStuff.toDutchWeekday options.timeZone call.when))
                                , Ui.el [] (Ui.text (TimeStuff.toHumanDate options.timeZone call.when ++ " - " ++ TimeStuff.toHumanTime options.timeZone call.when))
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


h2Styles : List (Ui.Attribute msg)
h2Styles =
    [ Ui.paddingEach { top = 32, left = 0, right = 0, bottom = 0 }
    , Font.size 22
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



-- HTTP


updateCall : String -> Call -> List SubTask -> Cmd Msg
updateCall backendUrl call subTasks =
    let
        id =
            case call.id of
                Creating ->
                    0

                -- Todo: This isn't right
                FromBackend i ->
                    i
    in
    Http.post
        { url = backendUrl ++ "/calls/" ++ String.fromInt id ++ "/edit"
        , body = Http.jsonBody (updateCallEncoder call subTasks)
        , expect = Http.expectJson UpdatedCall editedCallDecoder
        }


updateCallEncoder : Call -> List SubTask -> Json.Encode.Value
updateCallEncoder call subTasks =
    Json.Encode.object
        [ ( "call"
          , Json.Encode.object
                [ ( "who", Json.Encode.string call.who )
                , ( "comments", Json.Encode.string call.comments )
                ]
          )
        , ( "subTasks"
          , Json.Encode.list
                (\st ->
                    let
                        -- TODO : Meeeeeeeeeeh
                        callId =
                            case st.callId of
                                Creating ->
                                    0

                                FromBackend i ->
                                    i

                        subTaskId =
                            case st.id of
                                Creating ->
                                    0

                                FromBackend i ->
                                    i
                    in
                    Json.Encode.object
                        [ ( "callId", Json.Encode.int callId )
                        , ( "done", Json.Encode.bool st.done )
                        , ( "id", Json.Encode.int subTaskId )
                        , ( "text", Json.Encode.string st.text )
                        ]
                )
                subTasks
          )
        ]


{-| Same as addedCallDecoder, but definited separately because it is not necessarily the same
-}
editedCallDecoder : Json.Decode.Decoder { call : Call, subTasks : List SubTask }
editedCallDecoder =
    Json.Decode.map2 (\call subTasks -> { call = call, subTasks = subTasks })
        (Json.Decode.field "call" callDecoder)
        subTasksDecoder



-- Toggle SubTask "done"


toggleSubTask : String -> SubTask -> Cmd Msg
toggleSubTask backendUrl subTask =
    let
        id =
            case subTask.id of
                Creating ->
                    0

                -- Todo: This isn't right
                FromBackend i ->
                    i
    in
    Http.get
        { url = backendUrl ++ "/subtasks/" ++ String.fromInt id ++ "/done"
        , expect = Http.expectJson ToggledSubTask toggledSubTaskDecoder
        }


toggledSubTaskDecoder : Json.Decode.Decoder SubTask
toggledSubTaskDecoder =
    Json.Decode.field "updatedSubTask" subTaskDecoder



-- Archive call


archiveCall : String -> Call -> Cmd Msg
archiveCall backendUrl call =
    let
        id =
            case call.id of
                Creating ->
                    0

                -- Todo: This isn't right
                FromBackend i ->
                    i
    in
    Http.get
        { url = backendUrl ++ "/calls/" ++ String.fromInt id ++ "/archive"
        , expect = Http.expectJson ArchivedCall archivedCallDecoder
        }


archivedCallDecoder : Json.Decode.Decoder Call
archivedCallDecoder =
    Json.Decode.field "updatedCall" callDecoder



-- Add call


addCall : String -> Call -> List SubTask -> Cmd Msg
addCall backendUrl call subTasks =
    Http.request
        { method = "PUT"
        , headers = []
        , url = backendUrl ++ "/calls/add"
        , body = Http.jsonBody (addCallEncoder call subTasks)
        , expect = Http.expectJson AddedCall addedCallDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


addCallEncoder : Call -> List SubTask -> Json.Encode.Value
addCallEncoder call subTasks =
    Json.Encode.object
        [ ( "call"
          , Json.Encode.object
                [ ( "who", Json.Encode.string call.who )
                , ( "comments", Json.Encode.string call.comments )
                , ( "when", Json.Encode.int (Time.posixToMillis call.when) )
                , ( "isArchived", Json.Encode.bool call.isArchived )
                , ( "subTasks"
                  , Json.Encode.list
                        (\st ->
                            Json.Encode.object
                                [ ( "text", Json.Encode.string st.text )
                                , ( "done", Json.Encode.bool False )
                                ]
                        )
                        subTasks
                  )
                ]
          )
        ]


addedCallDecoder : Json.Decode.Decoder { call : Call, subTasks : List SubTask }
addedCallDecoder =
    Json.Decode.map2 (\call subTasks -> { call = call, subTasks = subTasks })
        (Json.Decode.field "call" callDecoder)
        subTasksDecoder



-- GET calls & subTasks


getCallsAndSubTasks : String -> Cmd Msg
getCallsAndSubTasks backendUrl =
    Http.get { url = backendUrl ++ "/calls", expect = Http.expectJson GotCallsAndSubTasks callsAndSubTasksDecoder }


callsAndSubTasksDecoder : Json.Decode.Decoder { calls : List Call, subTasks : List SubTask }
callsAndSubTasksDecoder =
    Json.Decode.map2 (\calls subTasks -> { calls = calls, subTasks = subTasks }) callsDecoder subTasksDecoder



-- Call & subtask decoder / basic blocks


subTaskDecoder : Json.Decode.Decoder SubTask
subTaskDecoder =
    Json.Decode.map4 SubTask
        (Json.Decode.field "id" Json.Decode.int
            |> Json.Decode.andThen
                (\id ->
                    Json.Decode.succeed (FromBackend id)
                )
        )
        (Json.Decode.field "callId" Json.Decode.int
            |> Json.Decode.andThen
                (\id ->
                    Json.Decode.succeed (FromBackend id)
                )
        )
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "done" Json.Decode.bool)


callDecoder : Json.Decode.Decoder Call
callDecoder =
    (Json.Decode.map5 Call
        (Json.Decode.field "id" Json.Decode.int
            |> Json.Decode.andThen (\i -> Json.Decode.succeed (FromBackend i))
        )
        (Json.Decode.field "who" Json.Decode.string)
        (Json.Decode.field "comments" Json.Decode.string)
        (Json.Decode.field "createdAt" Json.Decode.Extra.datetime)
        (Json.Decode.field "isArchived" Json.Decode.bool)
     -- How to split this into archived calls???
    )


callsDecoder : Json.Decode.Decoder (List Call)
callsDecoder =
    Json.Decode.field "calls"
        (Json.Decode.list callDecoder)


subTasksDecoder : Json.Decode.Decoder (List SubTask)
subTasksDecoder =
    Json.Decode.field "subTasks"
        (Json.Decode.list subTaskDecoder)



-- Other http helpers


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
