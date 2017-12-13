port module Hospitilizations.Main exposing (Msg, subscriptions, init, update, view)

import Hospitilizations.Functions exposing (getHospitilizations, getLoadedState, deleteHospitilization, filterFields, filteredRecords)
import Hospitilizations.Types exposing (Model)
import Html exposing (Html, text, div, button)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Table exposing (defaultCustomizations)
import Common.Grid exposing (checkColumn, standardTableAttrs, standardThead, rowDropDownDiv)
import Common.Types exposing (MenuMessage, FilterState, AddEditDataSource, HospitilizationsRow)
import Common.Functions as Functions exposing (defaultString, defaultDate)
import Common.Ports exposing (sendMenuMessage)
import Common.Route as Route
import Common.Mouse as Mouse
import Http


port deleteHospitilizationConfirmed : (Int -> msg) -> Sub msg


subscriptions : List HospitilizationsRow -> Sub Msg
subscriptions rows =
    Sub.batch
        [ deleteHospitilizationConfirmed DeleteHospitilizationConfirmed
        , if Functions.anyDropDownOpon rows then
            Mouse.clicks Blur
          else
            Sub.none
        ]


init : Int -> Cmd Msg
init patientId =
    getHospitilizations patientId Load


type Msg
    = Load (Result Http.Error (List HospitilizationsRow))
    | Blur Mouse.Position
    | SetTableState Table.State
    | SetFilter FilterState
    | DropDownToggle Int
    | DeleteHospitilizationConfirmed Int
    | DeleteCompleted (Result Http.Error String)
    | HospitilizationsAdd
    | HospitilizationsEdit Int
    | SendMenuMessage Int String


update : Msg -> Model -> Int -> ( Model, Cmd Msg )
update msg model _ =
    case msg of
        Load (Ok t) ->
            getLoadedState model t ! [ Functions.setLoadingStatus False ]

        Load (Err t) ->
            model ! [ Functions.displayErrorMessage (toString t) ]

        SetTableState newState ->
            { model | tableState = newState } ! []

        DropDownToggle recordId ->
            { model | hospitilizations = Functions.flipDropDownOpen model.hospitilizations recordId } ! []

        SendMenuMessage recordId messageType ->
            model ! [ sendMenuMessage (MenuMessage messageType recordId Nothing Nothing) ]

        DeleteHospitilizationConfirmed rowId ->
            let
                updatedRecords =
                    model.hospitilizations |> List.filter (\t -> t.id /= rowId)
            in
                { model | hospitilizations = updatedRecords } ! [ deleteHospitilization rowId DeleteCompleted ]

        DeleteCompleted (Ok responseMsg) ->
            case Functions.getResponseError responseMsg of
                Just t ->
                    model ! [ Functions.displayErrorMessage t ]

                Nothing ->
                    model ! [ Functions.displaySuccessMessage "Record deleted successfully!" ]

        DeleteCompleted (Err t) ->
            model ! [ Functions.displayErrorMessage (toString t) ]

        SetFilter filterState ->
            { model | filterFields = filterFields model.filterFields filterState } ! []

        HospitilizationsAdd ->
            model ! [ Route.modifyUrl Route.HospitilizationsAdd ]

        HospitilizationsEdit rowId ->
            model ! [ Route.modifyUrl (Route.HospitilizationsEdit rowId) ]

        Blur position ->
            { model
                | hospitilizations = Functions.closeDropdowns model.hospitilizations position.target
            }
                ! []


view : Model -> Maybe AddEditDataSource -> Html Msg
view model addEditDataSource =
    div []
        [ case addEditDataSource of
            Just _ ->
                button [ type_ "button", class "btn btn-sm btn-default margin-bottom-5", onClick HospitilizationsAdd ] [ text "New Record" ]

            Nothing ->
                button [ type_ "button", class "btn btn-sm btn-default margin-bottom-5 disabled" ] [ text "New Record" ]
        , div [ class "e-grid e-js e-waitingpopup" ]
            [ Table.view (config SetFilter) model.tableState (filteredRecords model) ]
        ]


getColumns : List (Table.Column HospitilizationsRow Msg)
getColumns =
    [ Table.stringColumn "ID" (\t -> toString t.id)
    , Table.stringColumn "Facility Name" (\t -> defaultString t.facilityName)
    , Table.stringColumn "Date Of Admission" (\t -> defaultDate t.dateOfAdmission)
    , Table.stringColumn "Admit Problem" (\t -> defaultString t.admitProblem)
    , Table.stringColumn "Date Of Discharge" (\t -> defaultDate t.dateOfDischarge)
    , Table.stringColumn "Discharge Problem" (\t -> defaultString t.dischargeProblem)
    , Table.stringColumn "Svc Type" (\t -> defaultString t.serviceType)
    , checkColumn "Is From TCM" (\t -> t.fromTcm)
    , customColumn
    , rowDropDownColumn
    ]


customColumn : Table.Column HospitilizationsRow Msg
customColumn =
    Table.veryCustomColumn
        { name = "Has File"
        , viewData = viewCustomColumn
        , sorter = Table.unsortable
        }


viewCustomColumn : HospitilizationsRow -> Table.HtmlDetails Msg
viewCustomColumn { recordId } =
    Table.HtmlDetails []
        [ case recordId of
            Just t ->
                div [ class "RecordTableHref", onClick (SendMenuMessage t "ViewFile") ] [ text "File" ]

            Nothing ->
                div [] []
        ]


rowDropDownColumn : Table.Column HospitilizationsRow Msg
rowDropDownColumn =
    Table.veryCustomColumn
        { name = ""
        , viewData = \t -> rowDropDownDiv t.dropDownOpen (onClick (DropDownToggle t.id)) (dropDownItems t.id)
        , sorter = Table.unsortable
        }


dropDownItems : Int -> List ( String, String, Html.Attribute Msg )
dropDownItems rowId =
    [ ( "e-edit", "Edit", onClick (HospitilizationsEdit rowId) )
    , ( "e-contextdelete", "Delete", onClick (SendMenuMessage rowId "HospitilizationDelete") )
    ]


config : (FilterState -> Msg) -> Table.Config HospitilizationsRow Msg
config event =
    Table.customConfig
        { toId = \t -> toString t.id
        , toMsg = SetTableState
        , columns = getColumns
        , customizations =
            { defaultCustomizations | tableAttrs = standardTableAttrs "RecordTable", thead = standardThead event }
        }
