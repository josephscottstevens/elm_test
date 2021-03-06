port module Main exposing (main)

import Allergies
import Billing
import ClinicalSummary
import Common.Dialog as Dialog
import Common.Functions as Functions
import Common.Types as Common exposing (AddEditDataSource)
import Demographics
import Hospitilizations
import Html exposing (Html, div)
import Http exposing (Error)
import Immunizations
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import LastKnownVitals
import Navigation
import PastMedicalHistory
import Records
import Task exposing (Task)
import Window


port loadAddEditDataSource : (AddEditDataSource -> msg) -> Sub msg


port documentScroll : (Float -> msg) -> Sub msg


port updateScrollY : Bool -> Cmd msg


type alias Model =
    { patientId : Int
    , rootDialog : Dialog.RootDialog
    , page : Page
    , addEditDataSource : Maybe AddEditDataSource
    }


type Page
    = Demographics Demographics.Model
    | Billing Billing.Model
    | ClinicalSummary ClinicalSummary.Model
    | Records Records.Model
    | Hospitilizations Hospitilizations.Model
    | PastMedicalHistory PastMedicalHistory.Model
    | Allergies Allergies.Model
    | Immunizations Immunizations.Model
    | LastKnownVitals LastKnownVitals.Model
      -- Other
    | NoPage


type alias Flags =
    { page : String
    , patientId : Int
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( model, cmds ) =
            pageInit flags.page
                { patientId = flags.patientId
                , rootDialog = { windowSize = Window.Size 0 0, top = 0, left = 0, windowScrollY = 0.0 }
                , page = NoPage
                , addEditDataSource = Nothing
                }
    in
        model
            ! [ Functions.setLoadingStatus False
              , cmds
              , Task.perform Resize Window.size
              ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ pageSubscriptions model.page
        , Functions.updatePatientId UpdatePatientId
        , Window.resizes Resize
        , documentScroll DocumentScroll
        ]


pageSubscriptions : Page -> Sub Msg
pageSubscriptions page =
    case page of
        Demographics _ ->
            Sub.map DemographicsMsg Demographics.subscriptions

        ClinicalSummary _ ->
            Sub.map ClinicalSummaryMsg ClinicalSummary.subscriptions

        PastMedicalHistory _ ->
            Sub.map PastMedicalHistoryMsg PastMedicalHistory.subscriptions

        Hospitilizations _ ->
            Sub.map HospitilizationsMsg Hospitilizations.subscriptions

        Allergies _ ->
            Sub.map AllergiesMsg Allergies.subscriptions

        Immunizations _ ->
            Sub.map ImmunizationsMsg Immunizations.subscriptions

        LastKnownVitals _ ->
            Sub.map LastKnownVitalsMsg LastKnownVitals.subscriptions

        Records _ ->
            Sub.map RecordsMsg Records.subscriptions

        Billing _ ->
            Sub.map BillingMsg Billing.subscriptions

        -- Other
        NoPage ->
            Sub.none


view : Model -> Html Msg
view model =
    case model.page of
        Records subModel ->
            Html.map RecordsMsg (Records.view subModel model.addEditDataSource)

        Demographics subModel ->
            Html.map DemographicsMsg (Demographics.view model.rootDialog subModel)

        Billing subModel ->
            Html.map BillingMsg (Billing.view subModel model.patientId model.addEditDataSource model.rootDialog)

        ClinicalSummary subModel ->
            Html.map ClinicalSummaryMsg (ClinicalSummary.view subModel model.rootDialog model.patientId)

        PastMedicalHistory subModel ->
            Html.map PastMedicalHistoryMsg (PastMedicalHistory.view subModel model.addEditDataSource)

        Hospitilizations subModel ->
            Html.map HospitilizationsMsg (Hospitilizations.view subModel model.addEditDataSource)

        Allergies subModel ->
            Html.map AllergiesMsg (Allergies.view subModel model.addEditDataSource)

        Immunizations subModel ->
            Html.map ImmunizationsMsg (Immunizations.view subModel model.addEditDataSource)

        LastKnownVitals subModel ->
            Html.map LastKnownVitalsMsg (LastKnownVitals.view subModel model.addEditDataSource)

        -- Other
        NoPage ->
            div [] []


type Msg
    = Resize Window.Size
    | DocumentScroll Float
    | UpdatePatientId Int
    | BillingMsg Billing.Msg
    | ClinicalSummaryMsg ClinicalSummary.Msg
    | PastMedicalHistoryMsg PastMedicalHistory.Msg
    | HospitilizationsMsg Hospitilizations.Msg
    | AllergiesMsg Allergies.Msg
    | ImmunizationsMsg Immunizations.Msg
    | LastKnownVitalsMsg LastKnownVitals.Msg
    | RecordsMsg Records.Msg
    | DemographicsMsg Demographics.Msg
    | AddEditDataSourceLoaded (Result Http.Error AddEditDataSource)


pageInit : String -> Model -> ( Model, Cmd Msg )
pageInit pageStr model =
    let
        getDropdownsCmd =
            case model.addEditDataSource of
                Just _ ->
                    Cmd.none

                Nothing ->
                    getDropDowns model.patientId

        cmds t =
            [ getDropdownsCmd
            , Functions.setLoadingStatus False
            ]
                ++ t

        setModel page =
            { model | page = page }

        setRecordsModel recordType =
            setModel (Records (Records.emptyModel recordType))
                ! cmds [ Cmd.map RecordsMsg (Records.init recordType model.patientId) ]
    in
        case pageStr of
            -- Patients\Profile
            "demographics" ->
                setModel (Demographics (Demographics.emptyModel model.patientId))
                    ! cmds [ Cmd.map DemographicsMsg (Demographics.init model.patientId) ]

            -- --People\Records
            "primarycarerecords" ->
                setRecordsModel Common.PrimaryCare

            "specialtyrecords" ->
                setRecordsModel Common.Specialty

            "labrecords" ->
                setRecordsModel Common.Labs

            "radiologyrecords" ->
                setRecordsModel Common.Radiology

            "hospitalizationrecords" ->
                setRecordsModel Common.Hospitalizations

            "legalrecords" ->
                setRecordsModel Common.Legal

            "miscrecords" ->
                setRecordsModel Common.Misc

            "enrollmentrecords" ->
                setRecordsModel Common.Enrollment

            "previoushistoryrecords" ->
                setRecordsModel Common.PreviousHistories

            "callrecordingrecords" ->
                setRecordsModel Common.CallRecordings

            "continuityofcaredocument" ->
                setRecordsModel Common.ContinuityOfCareDocument

            --Other
            "billing" ->
                setModel (Billing Billing.emptyModel)
                    ! cmds [ Cmd.map BillingMsg (Billing.init model.patientId) ]

            --People/ClinicalSummary
            "clinicalsummary" ->
                setModel (ClinicalSummary ClinicalSummary.emptyModel)
                    ! cmds [ Cmd.map ClinicalSummaryMsg (ClinicalSummary.init model.patientId) ]

            "pastmedicalhistory" ->
                setModel (PastMedicalHistory PastMedicalHistory.emptyModel)
                    ! cmds [ Cmd.map PastMedicalHistoryMsg (PastMedicalHistory.init model.patientId) ]

            "hospitalizations" ->
                setModel (Hospitilizations Hospitilizations.emptyModel)
                    ! cmds [ Cmd.map HospitilizationsMsg (Hospitilizations.init model.patientId) ]

            "immunizations" ->
                setModel (Immunizations Immunizations.emptyModel)
                    ! cmds [ Cmd.map ImmunizationsMsg (Immunizations.init model.patientId) ]

            "allergies" ->
                setModel (Allergies Allergies.emptyModel)
                    ! cmds [ Cmd.map AllergiesMsg (Allergies.init model.patientId) ]

            "vitals" ->
                setModel (LastKnownVitals LastKnownVitals.emptyModel)
                    ! cmds [ Cmd.map LastKnownVitalsMsg (LastKnownVitals.init model.patientId) ]

            _ ->
                setModel NoPage ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage model.page msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel model.patientId
            in
                { model | page = toModel newModel } ! [ Cmd.map toMsg newCmd ]
    in
        case ( msg, page ) of
            ( Resize windowSize, _ ) ->
                let
                    rootDialog =
                        model.rootDialog
                in
                    { model | rootDialog = { rootDialog | windowSize = windowSize } }
                        ! [ updateScrollY True
                          ]

            ( DocumentScroll windowScrollY, _ ) ->
                let
                    rootDialog =
                        model.rootDialog
                in
                    { model | rootDialog = { rootDialog | windowScrollY = windowScrollY } } ! []

            ( UpdatePatientId newPatientId, _ ) ->
                { model | patientId = newPatientId }
                    ! [ if newPatientId == model.patientId then
                            Cmd.none
                        else
                            Navigation.newUrl ("./?patientId=" ++ toString newPatientId)
                      ]

            ( AddEditDataSourceLoaded response, _ ) ->
                case response of
                    Ok t ->
                        { model | addEditDataSource = Just t } ! []

                    Err t ->
                        { model | page = NoPage }
                            ! [ Functions.displayErrorMessage (toString t) ]

            ( DemographicsMsg subMsg, Demographics subModel ) ->
                toPage Demographics DemographicsMsg Demographics.update subMsg subModel

            ( PastMedicalHistoryMsg subMsg, PastMedicalHistory subModel ) ->
                toPage PastMedicalHistory PastMedicalHistoryMsg PastMedicalHistory.update subMsg subModel

            ( BillingMsg subMsg, Billing subModel ) ->
                toPage Billing BillingMsg Billing.update subMsg subModel

            ( HospitilizationsMsg subMsg, Hospitilizations subModel ) ->
                toPage Hospitilizations HospitilizationsMsg Hospitilizations.update subMsg subModel

            ( ClinicalSummaryMsg subMsg, ClinicalSummary subModel ) ->
                toPage ClinicalSummary ClinicalSummaryMsg ClinicalSummary.update subMsg subModel

            ( RecordsMsg subMsg, Records subModel ) ->
                toPage Records RecordsMsg Records.update subMsg subModel

            ( AllergiesMsg subMsg, Allergies subModel ) ->
                toPage Allergies AllergiesMsg Allergies.update subMsg subModel

            ( ImmunizationsMsg subMsg, Immunizations subModel ) ->
                toPage Immunizations ImmunizationsMsg Immunizations.update subMsg subModel

            ( LastKnownVitalsMsg subMsg, LastKnownVitals subModel ) ->
                toPage LastKnownVitals LastKnownVitalsMsg LastKnownVitals.update subMsg subModel

            _ ->
                --{ model | page = Error <| "Missing Page\\Message " ++ toString page ++ " !!!__-__!!! " ++ toString msg } ! []
                -- above line is useful for debugging, but when releasing, needs to be this
                -- because, what if you save, move away from the page, then receive confirmation previous thing saved, we don't care at this point
                model ! []


getDropDowns : Int -> Cmd Msg
getDropDowns patientId =
    decode AddEditDataSource
        |> required "facilityId" (Decode.maybe Decode.int)
        |> required "facilityDropdown" (Decode.list Functions.decodeDropdownItem)
        |> required "providersDropdown" (Decode.list Functions.decodeDropdownItem)
        |> required "recordTypeDropdown" (Decode.list Functions.decodeDropdownItem)
        |> required "userDropDown" (Decode.list Functions.decodeDropdownItem)
        |> required "taskDropDown" (Decode.list Functions.decodeDropdownItem)
        |> required "hospitilizationServiceTypeDropdown" (Decode.list Functions.decodeDropdownItem)
        |> required "hospitalizationDischargePhysicianDropdown" (Decode.list Functions.decodeDropdownItem)
        |> required "hospitilizations" (Decode.list Functions.decodeDropdownItem)
        |> Http.get ("/People/PatientRecordsDropdowns?patientId=" ++ toString patientId)
        |> Http.send AddEditDataSourceLoaded


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
