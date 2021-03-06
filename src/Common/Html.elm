module Common.Html
    exposing
        ( InputControlType
            ( AreaInput
            , CheckInput
            , ControlElement
            , DateInput
            , DropInput
            , DropInputWithButton
            , Dropdown
            , FileInput
            , HtmlElement
            , KnockInput
            , NumrInput
            , TextInput
            )
        , controlWidth
        , defaultConfig
        , dividerLabel
        , fullWidth
        , getValidationErrors
        , labelWidth
        , makeControls
        )

import Common.Dropdown as Dropdown
import Common.Functions exposing (isAlpha)
import Common.Types as Common
import Html exposing (Html, button, div, input, label, text, textarea)
import Html.Attributes exposing (checked, class, defaultValue, for, id, name, style, type_)
import Html.Events exposing (onCheck, onInput)


type InputControlType msg
    = TextInput String Common.RequiredType (Maybe String) (String -> msg)
    | NumrInput String Common.RequiredType Int (String -> msg)
    | CheckInput String Common.RequiredType Bool (Bool -> msg)
    | AreaInput String Common.RequiredType (Maybe String) (String -> msg)
    | KnockInput String Common.RequiredType String
    | DropInput String Common.RequiredType (Maybe Int) String
    | DropInputWithButton String Common.RequiredType (Maybe Int) String String
    | DateInput String Common.RequiredType String String
    | FileInput String Common.RequiredType String
    | ControlElement String (Html msg)
    | HtmlElement (Html msg)
    | Dropdown String Common.RequiredType Dropdown.DropState (( Dropdown.DropState, Maybe Int, Cmd msg ) -> msg)


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


checkStyle : Html.Attribute msg
checkStyle =
    style [ ( "height", "20px" ), ( "width", "20px" ), ( "margin-top", "2px" ) ]


type alias Config msg =
    { controlAttributes : List (Html.Attribute msg)
    }


defaultConfig : Config msg
defaultConfig =
    { controlAttributes = [ class controlWidth ]
    }


makeControls : Config msg -> List (InputControlType msg) -> Html msg
makeControls config controls =
    let
        common controlType =
            case controlType of
                TextInput labelText requiredType displayValue event ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ input
                                [ type_ "textbox"
                                , class "e-textbox"
                                , nameAttr labelText
                                , idAttr labelText
                                , onInput event
                                , defaultValue (Maybe.withDefault "" displayValue)
                                ]
                                []
                            ]
                        ]

                NumrInput labelText requiredType displayValue event ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ input
                                [ type_ "number"
                                , class "e-textbox"
                                , nameAttr labelText
                                , idAttr labelText
                                , onInput event
                                , defaultValue <| toString displayValue
                                ]
                                []
                            ]
                        ]

                CheckInput labelText requiredType displayValue event ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ input
                                [ type_ "checkbox"
                                , checkStyle
                                , nameAttr labelText
                                , idAttr labelText
                                , onCheck event
                                , checked displayValue
                                ]
                                []
                            ]
                        ]

                AreaInput labelText requiredType displayValue event ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ textarea
                                [ idAttr labelText
                                , class "e-textbox"
                                , onInput event
                                , defaultValue (Maybe.withDefault "" displayValue)
                                ]
                                []
                            ]
                        ]

                DropInput labelText requiredType _ syncfusionId ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ input
                                [ type_ "text"
                                , id syncfusionId
                                ]
                                []
                            ]
                        ]

                KnockInput _ _ syncfusionId ->
                    div [ id syncfusionId ] []

                DropInputWithButton labelText requiredType _ syncfusionId buttonText ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div [ class controlWidth ] [ input [ type_ "text", id syncfusionId ] [] ]
                        , div [ class labelWidth ] [ button [ class "btn btn-sm btn-default" ] [ text buttonText ] ]
                        ]

                DateInput labelText requiredType displayValue syncfusionId ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ input [ type_ "text", id syncfusionId, defaultValue displayValue ] [] ]
                        ]

                FileInput labelText requiredType displayValue ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes [ input [ type_ "text", class "e-textbox", defaultValue displayValue ] [] ]
                        , div [ class labelWidth ]
                            [ input [ type_ "file", name "UploadFile", id "UploadFile", style [ ( "display", "none" ) ] ] []
                            , label [ for "UploadFile", class "sf-file-upload" ] [ text "Browse Files" ]
                            ]
                        ]

                ControlElement labelText controlElement ->
                    div [ class "form-group" ]
                        [ commonLabel labelText Common.Optional
                        , div config.controlAttributes
                            [ controlElement ]
                        ]

                Dropdown labelText requiredType _ event ->
                    div [ class "form-group" ]
                        [ commonLabel labelText requiredType
                        , div config.controlAttributes
                            [ text " TODO, re add dropdown" ]

                        -- [ Html.map event <| Dropdown.view displayValue ]
                        ]

                HtmlElement t ->
                    t
    in
    div [] (controls |> List.map common)


commonLabel : String -> Common.RequiredType -> Html msg
commonLabel labelText requiredType =
    let
        lastChar =
            String.right 1 labelText

        formattedLabelText =
            if lastChar == ":" then
                labelText
            else if labelText == "" then
                ""
            else
                labelText ++ ":"
    in
    label [ class (labelWidth ++ " " ++ isRequiredStr requiredType), forId labelText ] [ text formattedLabelText ]


getValidationErrors : List (InputControlType msg) -> List String
getValidationErrors controls =
    controls
        |> List.map commonValidation
        |> List.filterMap identity


is : Common.RequiredType -> Maybe a -> Maybe a
is requiredType t =
    case requiredType of
        Common.Required ->
            t

        Common.Optional ->
            Nothing


commonValidation : InputControlType msg -> Maybe String
commonValidation controlType =
    case controlType of
        TextInput labelText requiredType displayValue _ ->
            is requiredType <| requiredStr labelText (Maybe.withDefault "" displayValue)

        AreaInput labelText requiredType displayValue _ ->
            is requiredType <| requiredStr labelText (Maybe.withDefault "" displayValue)

        DropInput labelText requiredType displayValue _ ->
            is requiredType <|
                case displayValue of
                    Just _ ->
                        Nothing

                    Nothing ->
                        Just (labelText ++ " is required")

        DateInput labelText requiredType displayValue _ ->
            is requiredType <| requiredStr labelText displayValue

        FileInput labelText requiredType displayValue ->
            is requiredType <| requiredStr labelText displayValue

        NumrInput labelText requiredType displayValue _ ->
            is requiredType (requiredStr labelText (toString displayValue))

        CheckInput _ _ _ _ ->
            Nothing

        KnockInput labelText requiredType displayValue ->
            is requiredType <| requiredStr labelText displayValue

        DropInputWithButton labelText requiredType displayValue _ _ ->
            is requiredType <|
                case displayValue of
                    Just _ ->
                        Nothing

                    Nothing ->
                        Just (labelText ++ " is required")

        ControlElement _ _ ->
            Nothing

        Dropdown labelText requiredType displayValue _ ->
            --todo
            Nothing

        HtmlElement _ ->
            Nothing



-- is requiredType <| requiredStr labelText displayValue.selectedItem.name


requiredStr : String -> String -> Maybe String
requiredStr labelText str =
    if str == "" then
        Just (labelText ++ " is required")
    else
        Nothing


isRequiredStr : Common.RequiredType -> String
isRequiredStr requiredType =
    case requiredType of
        Common.Required ->
            " required"

        Common.Optional ->
            ""


dividerLabel : String -> InputControlType msg
dividerLabel labelText =
    HtmlElement <|
        div
            [ style
                [ ( "border-bottom-style", "solid" )
                , ( "border-bottom-width", "1px" )
                , ( "border-bottom-color", "rgb(209, 209, 209)" )
                , ( "font-size", "14px" )
                , ( "color", "#808080" )
                , ( "padding", "3px" )
                , ( "font-weight", "400 !important" )
                , ( "width", "90%" )
                , ( "margin-top", "10px" )
                , ( "margin-bottom", "20px" )
                ]
            ]
            [ text labelText
            ]
