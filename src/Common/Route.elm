module Common.Route exposing (Route(..), getPatientId, fromLocation, href, modifyUrl)

import Navigation
import Common.Types as Common
import Html exposing (Attribute)
import Html.Attributes as Attr
import UrlParser as Url exposing ((</>), (<?>), Parser, oneOf, parseHash, s, int, string, parsePath, intParam)


type Route
    = None
    | Billing
    | ClinicalSummary
    | Records Common.RecordType
    | RecordAddNew Common.RecordType
    | Hospitilizations
    | PastMedicalHistory
    | HospitilizationsAdd
    | HospitilizationsEdit Int
    | Error String


recordTypeToString : Common.RecordType -> String
recordTypeToString recordType =
    case recordType of
        Common.PrimaryCare ->
            "_primarycarerecords"

        Common.Specialty ->
            "_specialtyrecords"

        Common.Labs ->
            "_labrecords"

        Common.Radiology ->
            "_radiologyrecords"

        Common.Hospitalizations ->
            "_hospitalizationrecords"

        Common.Legal ->
            "_legalrecords"

        Common.CallRecordings ->
            "_callrecordingrecords"

        Common.PreviousHistories ->
            "_previoushistoryrecords"

        Common.Enrollment ->
            "_enrollmentrecords"

        Common.Misc ->
            "_miscrecords"


routeToString : Route -> String
routeToString route =
    case route of
        None ->
            "#"

        Billing ->
            "#"

        ClinicalSummary ->
            "#/people/_clinicalsummary"

        Records recordType ->
            "#/people/" ++ recordTypeToString recordType

        RecordAddNew recordType ->
            "#/people/" ++ recordTypeToString recordType ++ "/addedit"

        PastMedicalHistory ->
            "#/people/_pastmedicalhistory"

        Hospitilizations ->
            "#/people/_hospitalizations"

        HospitilizationsAdd ->
            "#/people/_hospitalizations/add"

        HospitilizationsEdit rowId ->
            "#/people/_hospitalizations/edit/" ++ toString rowId

        Error t ->
            "#/Error" ++ t


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map None (s "")

        -- Clinical Summary
        , Url.map ClinicalSummary (s "people" </> s "_clinicalsummary")
        , Url.map PastMedicalHistory (s "people" </> s "_pastmedicalhistory")
        , Url.map Hospitilizations (s "people" </> s "_hospitalizations")
        , Url.map HospitilizationsAdd (s "people" </> s "_hospitalizations" </> s "add")
        , Url.map HospitilizationsEdit (s "people" </> s "_hospitalizations" </> s "edit" </> int)

        -- Records Grid
        , Url.map (Records Common.PrimaryCare) (s "people" </> s "_primarycarerecords")
        , Url.map (Records Common.Specialty) (s "people" </> s "_specialtyrecords")
        , Url.map (Records Common.Labs) (s "people" </> s "_labrecords")
        , Url.map (Records Common.Radiology) (s "people" </> s "_radiologyrecords")
        , Url.map (Records Common.Hospitalizations) (s "people" </> s "_hospitalizationrecords")
        , Url.map (Records Common.Legal) (s "people" </> s "_legalrecords")
        , Url.map (Records Common.CallRecordings) (s "people" </> s "_callrecordingrecords")
        , Url.map (Records Common.PreviousHistories) (s "people" </> s "_previoushistoryrecords")
        , Url.map (Records Common.Enrollment) (s "people" </> s "_enrollmentrecords")
        , Url.map (Records Common.Misc) (s "people" </> s "_miscrecords")

        -- Records Edit
        , Url.map (RecordAddNew Common.PrimaryCare) (s "people" </> s "_primarycarerecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Specialty) (s "people" </> s "_specialtyrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Labs) (s "people" </> s "_labrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Radiology) (s "people" </> s "_radiologyrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Hospitalizations) (s "people" </> s "_hospitalizationrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Legal) (s "people" </> s "_legalrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.CallRecordings) (s "people" </> s "_callrecordingrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.PreviousHistories) (s "people" </> s "_previoushistoryrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Enrollment) (s "people" </> s "_enrollmentrecords" </> s "addedit")
        , Url.map (RecordAddNew Common.Misc) (s "people" </> s "_miscrecords" </> s "addedit")

        -- Other
        , Url.map Error (s "article" </> string)
        ]


getPatientId : Navigation.Location -> Maybe Int
getPatientId location =
    location
        |> parsePath (s "people" <?> intParam "patientId")
        |> Maybe.andThen identity


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.newUrl


fromLocation : Navigation.Location -> Maybe Route
fromLocation location =
    if String.isEmpty location.hash then
        Just None
    else
        parseHash route location
