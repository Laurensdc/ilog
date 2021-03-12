module CallTypes exposing (..)

import Time


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
