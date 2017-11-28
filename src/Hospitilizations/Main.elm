port module Hospitilizations.Main exposing (..)

import Hospitilizations.Functions exposing (..)
import Hospitilizations.Types exposing (..)
import Html exposing (Html, text, div, button)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Table exposing (..)
import Common.Grid exposing (..)
import Common.Types exposing (..)
import Common.Functions exposing (..)


port toggleConsent : Bool -> Cmd msg


port editTask : Int -> Cmd msg


port dropDownToggle : (Int -> msg) -> Sub msg


port deleteConfirmed : (Int -> msg) -> Sub msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ deleteConfirmed DeleteConfirmed
        ]


init : Flags -> Cmd Msg
init flags =
    getHospitilizations flags.patientId flags.recordTypeId Load


update : Msg -> Model -> ( ( Model, Cmd Msg ), Maybe AddEditDataSource )
update msg model =
    case msg of
        Load (Ok t) ->
            ( getLoadedState model t ! [ setLoadingStatus False ], Nothing )

        Load (Err httpError) ->
            ( { model | state = Error (toString httpError) } ! [ setLoadingStatus False ], Nothing )

        SetTableState newState ->
            ( { model | tableState = newState } ! [], Nothing )

        DeleteConfirmed rowId ->
            let
                updatedRecords =
                    model.hospitilizations |> List.filter (\t -> t.id /= rowId)
            in
                ( { model | hospitilizations = updatedRecords } ! [ deleteRequest rowId ], Nothing )

        DeleteCompleted (Ok responseMsg) ->
            case getResponseError responseMsg of
                Just t ->
                    ( model ! [ displayErrorMessage t ], Nothing )

                Nothing ->
                    ( model ! [ displaySuccessMessage "Record deleted successfully!" ], Nothing )

        DeleteCompleted (Err httpError) ->
            ( { model | state = Error (toString httpError) } ! [], Nothing )

        EditTask taskId ->
            ( model ! [ editTask taskId ], Nothing )

        SetFilter filterState ->
            ( { model | filterFields = filterFields model.filterFields filterState } ! [], Nothing )

        AddNewStart addEditDataSource ->
            ( model ! [], Just addEditDataSource )


view : Model -> Maybe AddEditDataSource -> Html Msg
view model addEditDataSource =
    case model.state of
        Grid ->
            div []
                [ case addEditDataSource of
                    Just t ->
                        button [ type_ "button", class "btn btn-sm btn-default margin-bottom-5", onClick (AddNewStart t) ] [ text "New Record" ]

                    Nothing ->
                        button [ type_ "button", class "btn btn-sm btn-default margin-bottom-5 disabled" ] [ text "New Record" ]
                , div [ class "e-grid e-js e-waitingpopup" ]
                    [ Table.view (config SetFilter) model.tableState (filteredRecords model) ]
                ]

        Limbo ->
            div [] []

        Error errMessage ->
            div [] [ text errMessage ]


getColumns : List (Column HospitilizationsRow Msg)
getColumns =
    [ stringColumn "ID" (\t -> toString t.id)
    , stringColumn "Facility Name" (\t -> defaultString t.facilityName)
    , stringColumn "Date Of Admission" (\t -> defaultDateTime t.dateOfAdmission)
    , stringColumn "Admit Problem" (\t -> defaultString t.admitProblem)
    , stringColumn "Date Of Discharge" (\t -> defaultDateTime t.dateOfDischarge)
    , stringColumn "Discharge Problem" (\t -> defaultString t.dischargeProblem)
    , stringColumn "Svc Type" (\t -> toString t.serviceType)
    , stringColumn "Is From TCM" (\t -> toString t.fromTcm)
    , stringColumn "Has Record" (\t -> toString t.hasRecord)
    ]


config : (FilterState -> Msg) -> Config HospitilizationsRow Msg
config event =
    customConfig
        { toId = \t -> toString t.id
        , toMsg = SetTableState
        , columns = getColumns
        , customizations =
            { defaultCustomizations | tableAttrs = standardTableAttrs "RecordTable", thead = standardThead event }
        }
