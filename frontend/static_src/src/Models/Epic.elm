module Models.Epic exposing (..)

{-| Do not manually edit this file, it was auto-generated by djelm
<https://github.com/Confidenceman02/django-elm>
-}

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, optional, hardcoded)


type alias ToModel =
    { epic : Epic_
    , logoutUrl : String
    , csrfToken : String
    }

type alias Epic_ =
    { title : String
    , pubDate : String
    , description : String
    , ownerFullname : String
    , stories : List Epic_Stories__
    }

type alias Epic_Stories__ =
    { id : Int
    , pubDate : String
    , title : String
    , description : String
    , status : String
    }


toModel : Decode.Decoder ToModel
toModel =
    Decode.succeed ToModel
        |> required "epic" epic_Decoder
        |> required "logoutUrl" Decode.string
        |> required "csrfToken" Decode.string

epic_Decoder : Decode.Decoder Epic_
epic_Decoder =
    Decode.succeed Epic_
        |> required "title" Decode.string
        |> required "pubDate" Decode.string
        |> required "description" Decode.string
        |> required "ownerFullname" Decode.string
        |> required "stories" (Decode.list epic_stories__Decoder)

epic_stories__Decoder : Decode.Decoder Epic_Stories__
epic_stories__Decoder =
    Decode.succeed Epic_Stories__
        |> required "id" Decode.int
        |> required "pubDate" Decode.string
        |> required "title" Decode.string
        |> required "description" Decode.string
        |> required "status" Decode.string
