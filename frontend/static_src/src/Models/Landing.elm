module Models.Landing exposing (..)

{-| Do not manually edit this file, it was auto-generated by djelm
<https://github.com/Confidenceman02/django-elm>
-}

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, optional, hardcoded)


type alias ToModel =
    Maybe String


toModel : Decode.Decoder ToModel
toModel =
    (Decode.nullable Decode.string)
