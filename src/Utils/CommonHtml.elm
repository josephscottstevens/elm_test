module Utils.CommonHtml exposing (..)

import Html exposing (Html, text, div, program, button, input, span, th, li, ul, a, label)
import Html.Attributes exposing (style, class, type_, id, value, tabindex, for, name)
import Html.Events exposing (onInput)
import Char exposing (isLower, isUpper)
import Utils.Dropdowns exposing (..)


isAlpha : Char -> Bool
isAlpha char =
    isLower char || isUpper char


forId : String -> Html.Attribute msg
forId str =
    for (String.filter isAlpha str)


idAttr : String -> Html.Attribute msg
idAttr str =
    id (String.filter isAlpha str)


nameAttr : String -> Html.Attribute msg
nameAttr str =
    name (String.filter isAlpha str)


fullWidth : String
fullWidth =
    "col-sm-10 col-md-7 col-lg-6"


labelWidth : String
labelWidth =
    "col-sm-2 col-md-2 col-lg-2"


controlWidth : String
controlWidth =
    "col-sm-8 col-md-5 col-lg-4"


inputCommonFormat : Bool -> String -> List (Html msg) -> Html msg
inputCommonFormat isRequired displayText t =
    let
        isRequiredStr =
            if isRequired then
                " required"
            else
                ""
    in
        div [ class "form-group" ]
            [ label [ class (labelWidth ++ "control-label" ++ isRequiredStr), forId displayText ] [ text displayText ]
            , div [ class controlWidth ]
                t
            ]


inputCommonWithType : (List (Html.Attribute msg) -> List a -> Html msg) -> String -> String -> (String -> msg) -> Bool -> String -> Html msg
inputCommonWithType control displayText inputValue event isRequired controlType =
    if controlType == "file" then
        inputCommonFormat isRequired displayText [ control [ type_ controlType, class "e-textbox", id "Files", name "Files" ] [] ]
    else if controlType == "textarea" then
        inputCommonFormat isRequired displayText [ control [ type_ controlType, class "e-textbox", id "Files", name "Files" ] [] ]
    else if controlType == "text" then
        inputCommonFormat isRequired displayText [ control [ type_ controlType, class "e-textbox", idAttr displayText, nameAttr displayText, onInput event ] [] ]
    else
        inputCommonFormat isRequired displayText [ (ejDropDownListSource (String.filter isAlpha displayText) []) ]


inputCommonAsDropDown : (List (Html.Attribute msg) -> List a -> Html msg) -> String -> String -> (String -> msg) -> Bool -> Html msg
inputCommonAsDropDown control displayText inputValue event isRequired =
    inputCommonWithType control displayText inputValue event isRequired <| "dropdown"


inputCommon : (List (Html.Attribute msg) -> List a -> Html msg) -> String -> String -> (String -> msg) -> Bool -> Html msg
inputCommon control displayText inputValue event isRequired =
    inputCommonWithType control displayText inputValue event isRequired <| "text"
