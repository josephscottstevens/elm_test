module HtmlHelper exposing (..)

import Html exposing (Html, text, div, input, program, button, select, option)
import Html.Attributes exposing (style, class, placeholder, id, type_, value)
import Html.Events exposing (onClick, onInput)
import Model exposing (..)
import Array


getEmployer : Array.Array Employer -> Int -> Maybe Employer
getEmployer employers idx =
    employers
        |> Array.get idx


updateEmployerState : Array.Array Employer -> Int -> String -> Array.Array Employer
updateEmployerState employers idx newState =
    case getEmployer employers idx of
        Just emp ->
            employers
                |> Array.set idx { emp | state = newState }

        Nothing ->
            employers


updateEmployerCity : Array.Array Employer -> Int -> String -> Array.Array Employer
updateEmployerCity employers idx newCity =
    case getEmployer employers idx of
        Just emp ->
            employers
                |> Array.set idx { emp | city = newCity }

        Nothing ->
            employers


updateEmployerStartDate : Array.Array Employer -> Int -> String -> Array.Array Employer
updateEmployerStartDate employers idx newStartDate =
    case getEmployer employers idx of
        Just emp ->
            employers
                |> Array.set idx { emp | startDate = newStartDate }

        Nothing ->
            employers


controlStyle : Html.Attribute msg
controlStyle =
    style [ ( "margin", "5px" ) ]


gridStyle : Html.Attribute msg
gridStyle =
    style
        [ ( "display", "grid" )
        , ( "grid-template-columns", "1fr" )
        , ( "grid-template-rows", "repeat(-1, auto)" )
        , ( "padding", "40px" )
        , ( "text-align", "center" )
        ]


rowStyle : Html.Attribute msg
rowStyle =
    style
        [ ( "display", "grid" )
        , ( "grid-template-columns", "80px 1fr 1fr 1fr 1fr 1fr 1fr 1fr" )
        , ( "grid-template-rows", "auto auto" )
        , ( "grid-row-gap", "1px" )
        , ( "box-sizing", "border-box" )
        , ( "box-shadow", "0 0 1px grey" )
        ]


cellStyle : List (Html.Attribute msg)
cellStyle =
    [ style
        [ ( "padding", "10px" )
        ]
    ]


headerStyle : List (Html.Attribute msg)
headerStyle =
    List.append cellStyle
        [ style
            [ ( "font-weight", "600" )
            , ( "background-color", "#f1f1f1" )
            , ( "cursor", "pointer" )
            ]
        ]


employmentHeaders : Html msg
employmentHeaders =
    div [ rowStyle ]
        [ div headerStyle [ text " " ]
        , div headerStyle [ text "Id" ]
        , div headerStyle [ text "Priority" ]
        , div headerStyle [ text "Title" ]
        , div headerStyle [ text "Name" ]
        , div headerStyle [ text "InitiatedOn" ]
        , div headerStyle [ text "Due At" ]
        , div headerStyle [ text "State" ]
        ]


employmentRows : Array.Array Employer -> List (Html Msg)
employmentRows emp =
    emp
        |> Array.indexedMap
            (\idx t ->
                div [ rowStyle ]
                    [ button [ class "btn btn-default", controlStyle, onClick (EditStart idx) ] [ text "edit" ]
                    , div cellStyle [ text t.occupation ]
                    , div cellStyle [ text t.employer ]
                    , div cellStyle [ text t.startDate ]
                    , div cellStyle [ text t.endDate ]
                    , div cellStyle [ text t.contactPerson ]
                    , div cellStyle [ text t.status ]
                    , div cellStyle [ text t.state ]
                    ]
            )
        |> Array.toList
