module HospitilizationsAddEdit.Main exposing (..)

import HospitilizationsAddEdit.Functions exposing (..)
import HospitilizationsAddEdit.Types exposing (..)
import Html exposing (Html, text, div, button)
import Html.Attributes exposing (class, id, value, type_)
import Html.Events exposing (onClick)
import Common.Html exposing (..)
import Common.Types exposing (..)
import Common.Functions exposing (..)
import Ports exposing (..)


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ updateFacility UpdateFacility
        , updateHospitilization UpdateHospitilization
        , updateFacility2 UpdateFacility2
        , updateDateOfAdmission UpdateDateOfAdmission
        , updateDateOfDischarge UpdateDateOfDischarge
        , updateHospitalServiceType UpdateHospitalServiceType
        , updateDischargePhysician UpdateDischargePhysician
        ]


view : Model -> Html Msg
view model =
    let
        errors =
            getValidationErrors (formInputs model)

        validationErrorsDiv =
            if model.showValidationErrors == True && List.length errors > 0 then
                div [ class "error margin-bottom-10" ] (List.map (\t -> div [] [ text t ]) errors)
            else
                div [] []

        saveBtnClass =
            class "btn btn-sm btn-success margin-left-5 pull-right"
    in
        div [ class "form-horizontal" ]
            [ validationErrorsDiv
            , makeControls (formInputs model)
            , div [ class "form-group" ]
                [ div [ class fullWidth ]
                    [ button [ type_ "button", id "Save", value "AddNewRecord", onClick Save, saveBtnClass ] [ text "Save" ]
                    , button [ type_ "button", onClick Cancel, class "btn btn-sm btn-default pull-right" ] [ text "Cancel" ]
                    ]
                ]
            ]


update : Msg -> Model -> ( ( Model, Cmd Msg ), Maybe Page )
update msg model =
    let
        updateAddNew t =
            ( t ! [ setUnsavedChanges True ], Nothing )
    in
        case msg of
            Save ->
                if List.length (getValidationErrors (formInputs model)) > 0 then
                    ( { model | showValidationErrors = True } ! [], Nothing )
                else
                    ( model ! [ saveForm model, setUnsavedChanges False ], Nothing )

            SaveCompleted (Ok responseMsg) ->
                case getResponseError responseMsg of
                    Just t ->
                        ( model ! [ displayErrorMessage t ], Nothing )

                    Nothing ->
                        ( model ! [ displaySuccessMessage "Save completed successfully!" ], Just Records )

            SaveCompleted (Err t) ->
                ( model ! [ setLoadingStatus False ], error t )

            Cancel ->
                ( model ! [ setUnsavedChanges False ], Just Records )

            UpdateFacility dropDownItem ->
                updateAddNew { model | facilityId = dropDownItem.id, facilityText = dropDownItem.name }

            AddNewFacility ->
                ( model ! [ addNewFacility Nothing ], Nothing )

            AddNewPhysician ->
                ( model ! [ addNewPhysician Nothing ], Nothing )

            UpdateHospitilization dropDownItem ->
                updateAddNew { model | hospitalizationId = dropDownItem.id, hospitalizationText = dropDownItem.name }

            UpdatePatientReported bool ->
                updateAddNew { model | patientReported = bool }

            UpdateFacility2 dropDownItem ->
                updateAddNew { model | facilityId2 = dropDownItem.id, facilityText2 = dropDownItem.name }

            UpdateDateOfAdmission str ->
                updateAddNew { model | dateOfAdmission = str }

            UpdateDateOfDischarge str ->
                updateAddNew { model | dateOfDischarge = str }

            UpdateHospitalServiceType dropDownItem ->
                updateAddNew { model | hospitalServiceTypeId = dropDownItem.id, hospitalServiceTypeText = dropDownItem.name }

            UpdateChiefComplaint str ->
                updateAddNew { model | chiefComplaint = str }

            UpdateDischargeRecommendations str ->
                updateAddNew { model | dischargeRecommendations = str }

            UpdateDischargePhysician dropDownItem ->
                updateAddNew { model | dischargePhysicianId = dropDownItem.id, dischargePhysicianText = dropDownItem.name }


formInputs : Model -> List ( String, RequiredType, InputControlType Msg )
formInputs newRecord =
    [ ( "Patient Reported", Optional, CheckInput newRecord.patientReported UpdatePatientReported )
    , ( "Facility", Required, DropInputWithButton newRecord.facilityId "FacilityId" AddNewFacility "Add New Facility" )
    , ( "Date of Admission", Required, DateInput (defaultString newRecord.dateOfAdmission) "DateOfAdmissionId" UpdateDateOfAdmission )
    , ( "Date of Discharge", Required, DateInput (defaultString newRecord.dateOfDischarge) "DateOfDischargeId" UpdateDateOfDischarge )
    , ( "Hospital Service Type", Required, DropInput newRecord.hospitalServiceTypeId "HospitalServiceTypeId" )
    , ( "Chief Complaint", Required, AreaInput newRecord.chiefComplaint UpdateChiefComplaint )
    , ( "Admit Diagnosis", Required, KnockInput "HospitalizationAdmitProblemSelection" )
    , ( "Discharge Diagnosis", Required, KnockInput "HospitalizationDischargeProblemSelection" )
    , ( "Discharge Recommendations", Required, TextInput newRecord.dischargeRecommendations UpdateDischargeRecommendations )
    , ( "Discharge Physician", Required, DropInputWithButton newRecord.dischargePhysicianId "DischargePhysicianId" AddNewPhysician "New Provider" )
    , ( "Secondary Facility Name", Required, DropInputWithButton newRecord.facilityId2 "FacilityId2" AddNewFacility "Add New Facility" )
    , ( "Secondary Date of Admission", Required, DateInput (defaultString newRecord.dateOfAdmission) "DateOfAdmissionId2" UpdateDateOfAdmission )
    , ( "Secondary Date of Discharge", Required, DateInput (defaultString newRecord.dateOfDischarge) "DateOfDischargeId2" UpdateDateOfDischarge )
    ]
