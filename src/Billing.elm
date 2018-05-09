module Billing exposing (Msg, Model, emptyModel, subscriptions, init, update, view)

import Html exposing (Html, div, text, input, button, label)
import Html.Attributes exposing (class, title, style, checked, type_, attribute)
import Html.Events exposing (onClick)
import Common.ServerTable as Table exposing (ColumnStyle(Width, CustomStyle), Operator(..), IdAttrType(IdAttr))
import Common.Functions as Functions
import Common.Types exposing (RequiredType(Optional, Required), AddEditDataSource, monthDropdown, yearDropdown)
import Common.Dialog as Dialog
import Common.Dropdown as Dropdown
import Common.Html exposing (InputControlType(CheckInput, ControlElement, HtmlElement), defaultConfig, fullWidth, makeControls)
import Date exposing (Date)
import Http
import Task
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


init : Int -> Cmd Msg
init patientId =
    Cmd.batch
        [ load patientId <| Table.init 20 (Just "BillingDate") columns
        , Table.initFilter columns
        ]


subscriptions : Sub Msg
subscriptions =
    Table.updateFilters UpdateFilters


type alias Model =
    { rows : List Row
    , gridOperations : Table.State
    , confirmData : Maybe (Dialog.Dialog Row Msg)
    , invoiceReportsDialog : Maybe (Dialog.Dialog InvoiceReportsDialog Msg)
    , currentMonth : Maybe Int
    , currentYear : Maybe Int
    }


type alias InvoiceReportsDialog =
    { currentMonth : Maybe Int
    , currentYear : Maybe Int
    , facilityId : Maybe Int
    , saveToClientPortal : Bool
    , facilityDropState : Dropdown.DropState
    , monthDropState : Dropdown.DropState
    , yearDropState : Dropdown.DropState
    }


emptyModel : Model
emptyModel =
    { rows = []
    , gridOperations = Table.init 20 (Just "BillingDate") columns
    , confirmData = Nothing
    , invoiceReportsDialog = Nothing
    , currentMonth = Nothing
    , currentYear = Nothing
    }


emptyInvoiceReportDialog : Maybe Int -> Maybe Int -> InvoiceReportsDialog
emptyInvoiceReportDialog currentMonth currentYear =
    { currentMonth = currentMonth
    , currentYear = currentYear
    , facilityId = Nothing
    , saveToClientPortal = False
    , facilityDropState = Dropdown.init "facilityDropdown" True
    , monthDropState = Dropdown.init "monthDropdown" False
    , yearDropState = Dropdown.init "yearDropdown" False
    }


type alias Row =
    { id : Int
    , facility : Maybe String
    , facilityId : Int
    , mainProvider : Maybe String
    , patientName : Maybe String
    , patientId : Int
    , dob : Maybe String
    , patientFacilityIdNo : Maybe String
    , assignedTo : Maybe String
    , openTasks : Int
    , totalTimeSpent : Maybe Int
    , ccmRegistrationDate : Maybe String
    , billingDate : Maybe String
    , isClosed : Bool
    , batchCloseOnInvoiceCompletion : Bool
    , isReviewed : Bool
    , dxPresent : Bool
    , carePlanPresent : Bool
    , medsPresent : Bool
    , allergiesPresent : Bool
    , vitalsPresent : Bool
    , recordingPresent : Bool
    , chartComplete : Bool
    , is24HoursSinceBilled : Bool
    , billingCode : Maybe String
    }


view : Model -> Int -> Maybe AddEditDataSource -> Dialog.RootDialog -> Html Msg
view model patientId maybeAddEditDataSource rootDialog =
    div []
        [ Table.view model.gridOperations (gridConfig maybeAddEditDataSource) model.rows Nothing
        , Dialog.viewDialog model.confirmData rootDialog
        , Dialog.viewDialog model.invoiceReportsDialog rootDialog
        ]


columns : List (Table.Column Row Msg)
columns =
    let
        checkHelper t =
            div [ class "e-checkcell" ]
                [ div [ class "e-checkcelldiv", style [ ( "text-align", "center" ) ] ]
                    [ input (type_ "checkbox" :: t) []
                    ]
                ]

        batchClose row =
            checkHelper
                [ checked row.batchCloseOnInvoiceCompletion
                , onClick (ToggleBatchClose row)
                ]

        toggleReviewed row =
            checkHelper
                [ checked row.isReviewed
                , if row.isReviewed then
                    attribute "onclick" "event.preventDefault();"
                  else
                    attribute "onClick" ""
                , if row.isReviewed then
                    onClick (ShowToggleReviewedDialog row)
                  else
                    onClick (ConfirmedToggleReviewedDialog row)
                ]

        dxCpRcAlRxVsOperator =
            CustomSingleOperator "Equals" [ "DxPresent", "CarePlanPresent", "RecordingPresent", "AllergiesPresent", "MedsPresent", "VitalsPresent" ]

        isNew t =
            if t.is24HoursSinceBilled then
                text "NEW"
            else
                text ""

        billingDate t =
            t.billingDate
                |> Functions.formatDateTime "MMMM YYYY"
                |> Maybe.withDefault ""
                |> text

        timeSpent t =
            t.totalTimeSpent
                |> Maybe.map Functions.ticksToSeconds
                |> Maybe.map Functions.secondsToHHMMSS

        openTasks t =
            Just (toString t.openTasks ++ " Tasks")

        filterStyle =
            CustomStyle
                [ ( "width", "100px" )
                , ( "padding-left", "10px" )
                ]
    in
        [ Table.htmlColumn "<= 24 Hrs" isNew (Width 4) Table.FilterIsNewControl (Equals "Is24HoursSinceBilled") (IdAttr "lessThan24HoursColumn")
        , Table.htmlColumn "Reviewed" toggleReviewed (Width 4) Table.CheckBoxControl (Equals "IsReviewed") (IdAttr "reviewedColumn")
        , Table.htmlColumn "Batch Close" batchClose (Width 4) Table.CheckBoxControl (Equals "BatchCloseOnInvoiceCompletion") (IdAttr "batchCloseColumn")
        , Table.stringColumn "Facility" .facility (Width 9) "Facility"
        , Table.htmlColumn "Billing Date" billingDate (Width 5) Table.Last60MonthsControl (Between "BillingDate" "BillingDate") (IdAttr "billingDateColumn")
        , Table.stringColumn "Main Provider" .mainProvider (Width 5) "MainProvider"
        , Table.stringColumn "Patient Name" .patientName (Width 5) "PatientName"
        , Table.dateColumn "DOB" .dob (Width 5) "DoB"
        , Table.stringColumn "Patient's Facility Id" .patientFacilityIdNo (Width 5) "PatientFacilityIdNo"
        , Table.stringColumn "AssignedTo" .assignedTo (Width 5) "AssignedTo"
        , Table.stringColumn "Time Spent" timeSpent (Width 4) "TotalTimeSpent"
        , Table.hrefColumn "Open Tasks" (\t -> ( openTasks t, toString t.openTasks ++ " Tasks" )) (Width 3) "OpenTasks"
        , Table.dateColumn "CCM Enrollment" .ccmRegistrationDate (Width 5) "CcmRegistrationDate"
        , Table.stringColumn "Billing Codes" .billingCode (Width 3) "BillingCode"
        , Table.htmlColumn "Dx CP RC Al Rx VS" dxCpRcAlRxVs filterStyle Table.SixCirclesControl dxCpRcAlRxVsOperator (IdAttr "presentFlagsColumn")
        ]


dxCpRcAlRxVs : Row -> Html msg
dxCpRcAlRxVs row =
    let
        getStyle t =
            if t then
                style [ ( "background-color", "currentColor" ) ]
            else
                style [ ( "background-color", "white" ), ( "border", "1.4px solid" ) ]

        fullCircle ( t, titleText ) =
            div [ title titleText, class "circle", getStyle t ] []
    in
        [ ( row.dxPresent, "Chronic Diagnoses present?" )
        , ( row.carePlanPresent, "Care Plan present?" )
        , ( row.recordingPresent, "Recorded call present?" )
        , ( row.allergiesPresent, "Allergies present?" )
        , ( row.medsPresent, "Medication present?" )
        , ( row.vitalsPresent, "Vitals Signs present?" )
        ]
            |> List.map fullCircle
            |> div [ class "circleMargin" ]


type Msg
    = Load (Result Http.Error LoadResult)
    | GetDate Date
    | SetGridOperations Table.State
    | UpdateFilters (List Table.Filter)
    | GenerateSummaryReport Row
    | ToggleBatchClose Row
    | ToggleBatchCloseDone (Result Http.Error String)
      -- Toggle Reviewed
    | ShowToggleReviewedDialog Row
    | ConfirmedToggleReviewedDialog Row
    | RequestToggleReviewedCompleted (Result Http.Error String)
    | CloseDialogToggleReviewed Row
      -- Save Summary Report
    | ShowSaveSummaryReportDialog Row
    | ConfirmedSaveSummaryReportDialog Row
    | RequestSaveSummaryReportCompleted (Result Http.Error String)
      -- Close Billing Session
    | ShowCloseBillingSessionDialog Row
    | ConfirmedCloseBillingSessionDialog Row
    | RequestCloseBillingSessionCompleted (Result Http.Error String)
      -- Edit CCM Billing
    | ShowEditCCMBillingDialog Row
    | ConfirmedEditCCMBillingDialog Row
    | RequestEditCCMBillingCompleted (Result Http.Error String)
      -- Invoice Reports
    | ShowInvoiceReportsDialog AddEditDataSource
    | ConfirmedInvoiceReportsDialog AddEditDataSource InvoiceReportsDialog
    | UpdateFacility InvoiceReportsDialog ( Dropdown.DropState, Maybe Int, Cmd Msg )
    | UpdateMonth InvoiceReportsDialog ( Dropdown.DropState, Maybe Int, Cmd Msg )
    | UpdateYear InvoiceReportsDialog ( Dropdown.DropState, Maybe Int, Cmd Msg )
    | UpdateSaveToClientPortal InvoiceReportsDialog Bool
    | CloseInvoiceReportsDialog
    | InvoiceReportsDialogCompleted ( Int, Int, Int, Bool ) (Result Http.Error String)
    | InvoiceReportsDialogExcelCompleted (Result Http.Error String)
      -- Common Close Dialog
    | CloseDialog


update : Msg -> Model -> Int -> ( Model, Cmd Msg )
update msg model patientId =
    let
        openInvoiceReportDialog t =
            { model | invoiceReportsDialog = Dialog.update model.invoiceReportsDialog t }
    in
        case msg of
            Load (Ok t) ->
                { model | rows = t.result, gridOperations = Table.updateFromServer t.serverData model.gridOperations }
                    ! [ Task.perform GetDate Date.now ]

            Load (Err t) ->
                model ! [ Functions.displayErrorMessage (toString t) ]

            GetDate dt ->
                { model
                    | currentMonth = Just (dt |> Functions.getMonthIndex)
                    , currentYear = Just (Date.year dt)
                }
                    ! []

            SetGridOperations gridOperations ->
                { model | gridOperations = gridOperations }
                    ! [ load patientId gridOperations ]

            UpdateFilters filters ->
                let
                    gridOperations =
                        Table.updateFilter filters model.gridOperations
                in
                    { model | gridOperations = gridOperations }
                        ! [ load patientId gridOperations ]

            GenerateSummaryReport row ->
                Debug.crash "todo"

            ToggleBatchClose row ->
                model
                    ! [ "/Phase2Billing/ToggleBatchInvoice"
                            |> Functions.postRequest
                                (Encode.object [ ( "billingId", Encode.int row.id ) ])
                            |> Http.send ToggleBatchCloseDone
                      ]

            ToggleBatchCloseDone t ->
                Functions.getRequestCompleted model t

            -- Toggle Reviewed
            ShowToggleReviewedDialog row ->
                { model
                    | confirmData =
                        Just
                            { data = row
                            , headerText = "Confirm"
                            , onConfirm = ConfirmedToggleReviewedDialog
                            , onCancel = CloseDialog
                            , dialogContent = \_ -> text "Are you sure you wish to change the reviewed status?"
                            , dialogOptions = Dialog.defaultDialogOptions
                            }
                }
                    ! []

            ConfirmedToggleReviewedDialog row ->
                { model | confirmData = Nothing, rows = Functions.updateRows model.rows { row | isReviewed = False } }
                    ! [ "/Phase2Billing/ToggleBillingRecordReviewed"
                            |> Functions.postRequest
                                (Encode.object [ ( "billingId", Encode.int row.id ) ])
                            |> Http.send RequestToggleReviewedCompleted
                      ]

            RequestToggleReviewedCompleted t ->
                Functions.getRequestCompleted model t

            -- Save Summary Report
            ShowSaveSummaryReportDialog row ->
                { model
                    | confirmData =
                        Just
                            { data = row
                            , headerText = "Save to Client Portal"
                            , onConfirm = ConfirmedSaveSummaryReportDialog
                            , onCancel = CloseDialog
                            , dialogContent = \_ -> text "Are you sure that you want to save this report in Clinical Portal?"
                            , dialogOptions = Dialog.defaultDialogOptions
                            }
                }
                    ! []

            ConfirmedSaveSummaryReportDialog row ->
                let
                    month =
                        row.billingDate
                            |> Maybe.andThen Functions.dateFromString
                            |> Maybe.map Functions.getMonthIndex
                            |> Maybe.map toString
                            |> Maybe.withDefault ""

                    year =
                        row.billingDate
                            |> Maybe.andThen Functions.dateFromString
                            |> Maybe.map Date.year
                            |> Maybe.map toString
                            |> Maybe.withDefault ""
                in
                    { model | confirmData = Nothing }
                        ! [ Functions.getStringRequestWithParams
                                "/Phase2Billing/SaveCCMMonthlyReportInClientPortal"
                                [ ( "hcoID", toString row.facilityId )
                                , ( "year", year )
                                , ( "month", month )
                                , ( "filePath", "clinical\\CCMMonthlySummaryReport.pdf" )
                                , ( "patientId", toString patientId )
                                ]
                                |> Http.send RequestSaveSummaryReportCompleted
                          ]

            RequestSaveSummaryReportCompleted t ->
                Functions.getRequestCompleted model t

            -- Close Billing Session
            CloseDialogToggleReviewed row ->
                { model | confirmData = Nothing, rows = Functions.updateRows model.rows { row | isReviewed = True } } ! []

            ShowCloseBillingSessionDialog row ->
                { model
                    | confirmData =
                        Just
                            { data = row
                            , headerText = "Close Bill"
                            , onConfirm = ConfirmedCloseBillingSessionDialog
                            , onCancel = CloseDialog
                            , dialogContent = \_ -> text "Are you sure that you want to close this bill?"
                            , dialogOptions = Dialog.defaultDialogOptions
                            }
                }
                    ! []

            ConfirmedCloseBillingSessionDialog row ->
                { model | confirmData = Nothing }
                    ! [ Functions.getStringRequestWithParams
                            "/Phase2Billing/CloseBillingSession"
                            [ ( "billingId", toString row.id ) ]
                            |> Http.send RequestCloseBillingSessionCompleted
                      ]

            RequestCloseBillingSessionCompleted requestResponse ->
                case requestResponse of
                    Ok _ ->
                        model ! [ load patientId model.gridOperations ]

                    Err t ->
                        model ! [ Functions.displayErrorMessage (toString t) ]

            -- Edit CCM Billing
            ShowEditCCMBillingDialog row ->
                { model
                    | confirmData =
                        Just
                            { data = row
                            , headerText = "Edit CCM Billing"
                            , onConfirm = ConfirmedCloseBillingSessionDialog
                            , onCancel = CloseDialog
                            , dialogContent = \_ -> text "todo"
                            , dialogOptions = Dialog.defaultDialogOptions
                            }
                }
                    ! []

            ConfirmedEditCCMBillingDialog row ->
                Debug.crash "todo"

            RequestEditCCMBillingCompleted t ->
                Functions.getRequestCompleted model t

            -- Invoice Reports
            ShowInvoiceReportsDialog addEditDataSource ->
                { model
                    | invoiceReportsDialog =
                        Just
                            { data = emptyInvoiceReportDialog model.currentMonth model.currentYear
                            , headerText = "Invoice XLS"
                            , onConfirm = ConfirmedInvoiceReportsDialog addEditDataSource
                            , onCancel = CloseInvoiceReportsDialog
                            , dialogContent = viewInvoiceReportsDialog addEditDataSource
                            , dialogOptions = Dialog.simpleDialogOptions 800 500
                            }
                }
                    ! []

            UpdateFacility invoiceReportsDialog ( newDropState, newId, newMsg ) ->
                openInvoiceReportDialog { invoiceReportsDialog | facilityDropState = newDropState, facilityId = newId }
                    ! [ newMsg ]

            UpdateMonth invoiceReportsDialog ( newDropState, newId, newMsg ) ->
                openInvoiceReportDialog { invoiceReportsDialog | monthDropState = newDropState, currentMonth = newId }
                    ! [ newMsg ]

            UpdateYear invoiceReportsDialog ( newDropState, newId, newMsg ) ->
                openInvoiceReportDialog { invoiceReportsDialog | yearDropState = newDropState, currentYear = newId }
                    ! [ newMsg ]

            UpdateSaveToClientPortal invoiceReportsDialog t ->
                openInvoiceReportDialog { invoiceReportsDialog | saveToClientPortal = t } ! []

            CloseInvoiceReportsDialog ->
                { model | invoiceReportsDialog = Nothing } ! []

            ConfirmedInvoiceReportsDialog addEditDataSource invoiceReportsDialog ->
                case ( invoiceReportsDialog.currentMonth, invoiceReportsDialog.currentMonth, invoiceReportsDialog.facilityId ) of
                    ( Just month, Just year, Just facilityId ) ->
                        { model | invoiceReportsDialog = Nothing }
                            ! [ Functions.getStringRequestWithParams
                                    "/CCM/ValidateCcmRateForInvoice"
                                    [ ( "facilityId", toString facilityId )
                                    , ( "month", toString month )
                                    , ( "year", toString year )
                                    , ( "saveToClientPortal", String.toLower <| toString invoiceReportsDialog.saveToClientPortal )
                                    , ( "includeOpenBillingRecords", "false" )
                                    ]
                                    |> Http.send (InvoiceReportsDialogCompleted ( facilityId, year, month, invoiceReportsDialog.saveToClientPortal ))
                              ]

                    _ ->
                        { model | invoiceReportsDialog = Nothing } ! []

            InvoiceReportsDialogCompleted ( facilityId, year, month, saveToClientPortal ) requestResponse ->
                case requestResponse of
                    Ok _ ->
                        model
                            ! [ Functions.postStringRequestWithObject
                                    "/CCM/GetInvoiceReportXls"
                                    [ ( "facilityId", Encode.int facilityId )
                                    , ( "year", Encode.int year )
                                    , ( "month", Encode.int month )
                                    , ( "saveToClientPortal", Encode.bool saveToClientPortal )
                                    , ( "includeOpenBillingRecords", Encode.bool False )
                                    ]
                                    |> Http.send InvoiceReportsDialogExcelCompleted
                              ]

                    Err t ->
                        model ! [ Functions.displayErrorMessage (toString t) ]

            InvoiceReportsDialogExcelCompleted requestResponse ->
                case requestResponse of
                    Ok response ->
                        case
                            response
                                |> Decode.decodeString (Decode.at [ "AdditionalData", "fileName" ] Decode.string)
                                |> Result.toMaybe
                        of
                            Just fileName ->
                                model
                                    ! [ Functions.displaySuccessMessage "Invoice report created successfully."
                                      , Functions.openFile ("/CCM/DownloadMonthlyInvoice?fileName=" ++ fileName)
                                      ]

                            Nothing ->
                                model ! [ Functions.displayErrorMessage ("Cannot download file right now, please try again later") ]

                    Err t ->
                        model ! [ Functions.displayErrorMessage (toString t) ]

            -- Common Close Dialog
            CloseDialog ->
                { model | confirmData = Nothing } ! []


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


viewInvoiceReportsDialog : AddEditDataSource -> InvoiceReportsDialog -> Html Msg
viewInvoiceReportsDialog addEditDataSource t =
    div [ class "form-horizontal", style [ ( "padding-left", "40px" ) ] ]
        [ makeControls { controlAttributes = [ class "col-md-8" ] }
            [ dividerLabel "Select Facility"
            , ControlElement "Facility" <|
                Dropdown.view t.facilityDropState (UpdateFacility t) addEditDataSource.facilities t.facilityId
            , dividerLabel "Select Month and Year For Billable Patients"
            , ControlElement "Month" <|
                Dropdown.view t.monthDropState (UpdateMonth t) monthDropdown t.currentMonth
            , ControlElement "Year" <|
                Dropdown.view t.yearDropState (UpdateYear t) yearDropdown t.currentYear
            , CheckInput "Save to Client Portal" Optional t.saveToClientPortal (UpdateSaveToClientPortal t)
            , HtmlElement <|
                div [ class "row" ] []
            , dividerLabel ""
            ]
        ]


decodeBillingCcm : Decode.Decoder Row
decodeBillingCcm =
    Pipeline.decode Row
        |> Pipeline.required "ID" Decode.int
        |> Pipeline.required "Facility" (Decode.maybe Decode.string)
        |> Pipeline.required "FacilityId" Decode.int
        |> Pipeline.required "MainProvider" (Decode.maybe Decode.string)
        |> Pipeline.required "PatientName" (Decode.maybe Decode.string)
        |> Pipeline.required "PatientId" Decode.int
        |> Pipeline.required "DoB" (Decode.maybe Decode.string)
        |> Pipeline.required "PatientFacilityIdNo" (Decode.maybe Decode.string)
        |> Pipeline.required "AssignedTo" (Decode.maybe Decode.string)
        |> Pipeline.required "OpenTasks" Decode.int
        |> Pipeline.required "TotalTimeSpent" (Decode.maybe Decode.int)
        |> Pipeline.required "CcmRegistrationDate" (Decode.maybe Decode.string)
        |> Pipeline.required "BillingDate" (Decode.maybe Decode.string)
        |> Pipeline.required "IsClosed" Decode.bool
        |> Pipeline.required "BatchCloseOnInvoiceCompletion" Decode.bool
        |> Pipeline.required "IsReviewed" Decode.bool
        |> Pipeline.required "DxPresent" Decode.bool
        |> Pipeline.required "CarePlanPresent" Decode.bool
        |> Pipeline.required "MedsPresent" Decode.bool
        |> Pipeline.required "AllergiesPresent" Decode.bool
        |> Pipeline.required "VitalsPresent" Decode.bool
        |> Pipeline.required "RecordingPresent" Decode.bool
        |> Pipeline.required "ChartComplete" Decode.bool
        |> Pipeline.required "Is24HoursSinceBilled" Decode.bool
        |> Pipeline.required "BillingCode" (Decode.maybe Decode.string)


type alias LoadResult =
    { result : List Row
    , serverData : Table.ServerData
    }


jsonDecodeLoad : Decode.Decoder LoadResult
jsonDecodeLoad =
    Pipeline.decode LoadResult
        |> Pipeline.required "Data" (Decode.list decodeBillingCcm)
        |> Pipeline.required "GridOperations" Table.decodeGridOperations


load : Int -> Table.State -> Cmd Msg
load patientId gridOperations =
    Http.request
        { body =
            Encode.object
                [ ( "patientId", Encode.int patientId )
                , ( "gridOperations", Table.encodeGridOperations gridOperations )
                ]
                |> Http.jsonBody
        , expect = Http.expectJson jsonDecodeLoad
        , headers = []
        , method = "POST"
        , timeout = Nothing
        , url = "/Phase2Billing/BillingCcmGridDataSource"
        , withCredentials = False
        }
        |> Http.send Load


gridConfig : Maybe AddEditDataSource -> Table.Config Row Msg
gridConfig maybeAddEditDataSource =
    { domTableId = "BillingTable"
    , rowDropdownItems =
        [ ( "", "Generate Summary Report", GenerateSummaryReport )
        , ( "", "Save Summary Report to Client Portal", ShowSaveSummaryReportDialog )
        , ( "", "Close Billing Session", ShowCloseBillingSessionDialog )
        , ( "", "Edit CCM Billing", ShowEditCCMBillingDialog )
        ]
    , toolbar =
        [ text "Billing"
        , div [ class "submenu_right_items" ]
            [ div [ class "action_bar" ]
                [ text "Actions "
                , case maybeAddEditDataSource of
                    Just addEditDataSource ->
                        button [ class "btn btn-sm btn-default", onClick (ShowInvoiceReportsDialog addEditDataSource) ] [ text "Invoice Reports" ]

                    Nothing ->
                        div [] []
                ]
            ]
        ]
    , columns = columns
    , toMsg = SetGridOperations
    }
