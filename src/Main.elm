module Main exposing (..)

import Model exposing (..)
import Html exposing (Html, text, div)
import Records.Main as Records
import RecordAddNew.Main as RecordAddNew
import Hospitilizations.Main as Hospitilizations
import HospitilizationsAddEdit.Main as HospitilizationsAddEdit
import Common.Functions exposing (..)
import Common.Types exposing (..)
import Functions exposing (..)
import Ports exposing (..)
import Navigation


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Sub.map RecordsMsg Records.subscriptions
        , Sub.map RecordAddNewMsg RecordAddNew.subscriptions
        , presetPageComplete PresetPageComplete
        , setPageComplete SetPageComplete
        ]


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        model =
            emptyModel location flags
    in
        if flags.pageFlag == "billing" then
            { model | page = Billing } ! []
        else if flags.pageFlag == "records" then
            { model | page = Records }
                ! [ Cmd.map RecordsMsg (Records.init flags)
                  , getDropDowns flags.patientId AddEditDataSourceLoaded
                  ]
        else if flags.pageFlag == "hospitilizations" then
            { model | page = Hospitilizations }
                ! [ Cmd.map HospitilizationsMsg (Hospitilizations.init flags)
                  , getDropDowns flags.patientId AddEditDataSourceLoaded
                  ]
        else
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


view : Model -> Html Msg
view model =
    case model.page of
        None ->
            div [] []

        Billing ->
            div [] []

        Records ->
            Html.map RecordsMsg (Records.view model.recordsState model.addEditDataSource)

        RecordAddNew ->
            Html.map RecordAddNewMsg (RecordAddNew.view model.recordAddNewState)

        Hospitilizations ->
            Html.map HospitilizationsMsg (Hospitilizations.view model.hospitalizationsState model.addEditDataSource)

        HospitilizationsAddEdit ->
            Html.map HospitilizationsAddEditMsg (HospitilizationsAddEdit.view model.hospitilizationsAddEditState)

        Error str ->
            div [] [ text str ]


update : Msg -> Model -> ( Model, Cmd Model.Msg )
update msg model =
    case msg of
        BillingMsg billingMsg ->
            model ! []

        RecordsMsg recordsMsg ->
            let
                ( ( newModel, pageCmd ), nextPage ) =
                    Records.update recordsMsg model.recordsState
            in
                case nextPage of
                    Just newPage ->
                        { model | page = None, recordsState = newModel } ! [ presetPage (pageToString newPage) ]

                    Nothing ->
                        { model | recordsState = newModel } ! [ Cmd.map RecordsMsg pageCmd ]

        RecordAddNewMsg recordAddNewMsg ->
            let
                ( ( newModel, pageCmd ), nextPage ) =
                    RecordAddNew.update recordAddNewMsg model.recordAddNewState
            in
                case nextPage of
                    Just newPage ->
                        { model | page = None, recordAddNewState = newModel } ! [ presetPage (pageToString newPage) ]

                    Nothing ->
                        { model | recordAddNewState = newModel } ! [ Cmd.map RecordAddNewMsg pageCmd ]

        HospitilizationsMsg hospitilizationsMsg ->
            let
                ( ( newModel, pageCmd ), nextPage ) =
                    Hospitilizations.update hospitilizationsMsg model.hospitalizationsState
            in
                case nextPage of
                    Just newPage ->
                        { model | page = None, hospitalizationsState = newModel } ! [ presetPage (pageToString newPage) ]

                    Nothing ->
                        { model | hospitalizationsState = newModel } ! [ Cmd.map HospitilizationsMsg pageCmd ]

        HospitilizationsAddEditMsg hospitilizationsAddEditMsg ->
            let
                ( ( newModel, pageCmd ), nextPage ) =
                    HospitilizationsAddEdit.update hospitilizationsAddEditMsg model.hospitilizationsAddEditState
            in
                case nextPage of
                    Just newPage ->
                        { model | page = None, hospitilizationsAddEditState = newModel } ! [ presetPage (pageToString newPage) ]

                    Nothing ->
                        { model | hospitilizationsAddEditState = newModel } ! [ Cmd.map HospitilizationsAddEditMsg pageCmd ]

        AddEditDataSourceLoaded (Ok t) ->
            let
                newState =
                    model.recordAddNewState

                tt =
                    { newState | facilityId = t.facilityId }
            in
                { model | addEditDataSource = Just t, recordAddNewState = tt } ! []

        AddEditDataSourceLoaded (Err httpError) ->
            { model | page = Error (toString httpError) } ! []

        PresetPageComplete pageStr ->
            case getPage pageStr of
                Records ->
                    { model | page = Records } ! []

                RecordAddNew ->
                    case model.addEditDataSource of
                        Just addEditDataSource ->
                            { model | page = RecordAddNew } ! [ setPage (getAddEditMsg addEditDataSource model.recordAddNewState.recordTypeId False False) ]

                        Nothing ->
                            { model | page = Error "Can't display this page without a datasource" } ! []

                HospitilizationsAddEdit ->
                    case model.addEditDataSource of
                        Just addEditDataSource ->
                            { model | page = HospitilizationsAddEdit } ! [ setPage (getAddEditMsg addEditDataSource model.recordAddNewState.recordTypeId False False) ]

                        Nothing ->
                            { model | page = Error "Can't display this page without a datasource" } ! []

                _ ->
                    model
                        ! []

        SetPageComplete _ ->
            model ! [ setLoadingStatus False ]

        UrlChange location ->
            case location.hash of
                "#/people/_hospitalizations/new" ->
                    { model | page = HospitilizationsAddEdit, currentUrl = location } ! []

                _ ->
                    { model | currentUrl = location } ! []
