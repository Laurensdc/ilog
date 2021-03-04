module TimeStuff exposing (..)

import Time
import Time.Extra as Time


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


{-| e.g.: 24/03
-}
toHumanDate : Time.Zone -> Time.Posix -> String
toHumanDate zone posix =
    toTwoDigits (Time.toDay zone posix)
        ++ "/"
        ++ toDutchMonthNumber (Time.toMonth zone posix)


{-| e.g.: 17:12
-}
toHumanTime : Time.Zone -> Time.Posix -> String
toHumanTime zone posix =
    (Time.toHour zone posix |> String.fromInt)
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


toDutchWeekday : Time.Zone -> Time.Posix -> String
toDutchWeekday zone posix =
    let
        day =
            Time.toWeekday zone posix
    in
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


toTwoDigits : Int -> String
toTwoDigits i =
    if i < 10 then
        "0" ++ String.fromInt i

    else
        String.fromInt i
