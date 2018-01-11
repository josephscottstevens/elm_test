port module Demographics exposing (..)

import Html exposing (Html, text, div, button, ul, li, a, input, label, h4)
import Html.Attributes exposing (class, id, type_, value, style)
import Utils.CommonTypes exposing (DropDownItem, Flags)
import Utils.CommonFunctions exposing (decodeDropDownItem)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Http


port initDemographics : SfData -> Cmd msg


port updateDemographics : (SfData -> msg) -> Sub msg


type alias Model =
    { patientId : Int
    , demographicsId : Maybe Int
    , nickName : Maybe String
    , vip : Maybe Bool
    , ssn : Maybe String
    , lastName : Maybe String
    , firstName : Maybe String
    , middle : Maybe String
    , dateOfBirth : Maybe String
    , birthPlace : Maybe String
    , dateOfDeath : Maybe String
    , mrn : Maybe String
    , patientAccountNumber : Maybe String
    , facilityPtID : Maybe String
    , sexualOrientationNote : Maybe String
    , genderIdentityNote : Maybe String
    , email : Maybe String
    , careCoordinatorId : Maybe Int
    , facilityId : Maybe Int
    , mainProviderId : Maybe Int
    , patientLanguagesMap : List PatientLanguagesMap
    , preferredLanguageIndex : Int
    , sfData : SfData
    }


type alias SfData =
    { prefixId : Maybe Int
    , sexTypeId : Maybe Int
    , sexualOrientationId : Maybe Int
    , suffixId : Maybe Int
    , genderIdentityId : Maybe Int
    , raceId : Maybe Int
    , ethnicityId : Maybe Int
    , uSVeteranId : Maybe Int
    , religionId : Maybe Int
    , patientLanguageDropdown : List DropDownItem
    , careCoordinatorDropdown : List DropDownItem
    , languageDropdown : List DropDownItem
    , ethnicityDropdown : List DropDownItem
    , sexTypeDropdown : List DropDownItem
    , sexualOrientationDropdown : List DropDownItem
    , genderIdentityDropdown : List DropDownItem
    , facilityDropdown : List DropDownItem
    , mainProviderDropdown : List DropDownItem
    , raceDropdown : List DropDownItem
    , suffixDropdown : List DropDownItem
    , prefixDropdown : List DropDownItem
    , uSVeteranDropdown : List DropDownItem
    , religionDropdown : List DropDownItem
    }


type alias PatientLanguagesMap =
    { bob : String }


subscriptions : Sub Msg
subscriptions =
    updateDemographics UpdateDemographics


init : Flags -> Cmd Msg
init flag =
    Decode.field "demographicsInformationModel" decodeSfData
        |> Http.get ("/People/GetDemographicsInformation?patientId=" ++ toString flag.patientId)
        |> Http.send Load


view : Model -> Html Msg
view model =
    div []
        [ h4 [] [ text "Assigned To" ]
        , div [ class "row" ]
            [ label [ class "col-md-2" ] [ text "Facility" ]
            , div [ class "col-md-2" ] [ input [ id "FacilityId" ] [] ]
            , label [ class "col-md-2" ] [ text "Main Provider" ]
            , input [ class "col-md-6", id "MainProviderId" ] []
            ]
        , div [ class "row" ]
            [ label [ class "col-md-2" ] [ text "Patient's Facility ID No" ]
            , input [ class "col-md-2", id "FacilityPtIDId" ] []
            , label [ class "col-md-2" ] [ text "Care Coordinator" ]
            , input [ class "col-md-6", id "CareCoordinatorId" ] []
            ]
        , div [ class "row" ]
            [ label [ class "col-md-2" ] [ text "Medical Record No" ]
            , input [ class "col-md-10", id "MRNId" ] []
            ]
        , div [ class "row" ]
            [ label [ class "col-md-2" ] [ text "Patient Account No" ]
            , input [ class "col-md-10", id "PatientAccountNumberId" ] []
            ]
        , h4 [] [ text "Demographic Information" ]
        , div [ class "row" ]
            [ label [ class "col-md-2" ] [ text "aaa" ]
            , input [ class "col-md-10", id "aaaa" ] []
            , label [ class "col-md-2" ] [ text "aaa" ]
            , input [ class "col-md-10", id "aaaa" ] []
            ]
        , div [ class "row" ]
            [ label [ class "col-md-4" ] [ text "comments" ]
            , input [ class "col-md-8 e-textbox" ] []
            ]
        ]


type Msg
    = Load (Result Http.Error SfData)
    | UpdateDemographics SfData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Load (Ok sfData) ->
            { model | sfData = sfData } ! [ initDemographics sfData ]

        Load (Err t) ->
            model ! []

        UpdateDemographics sfData ->
            { model | sfData = sfData } ! []



--  Functions.displayErrorMessage (toString t)


emptyModel : Flags -> Model
emptyModel flags =
    { patientId = flags.patientId
    , demographicsId = Nothing
    , nickName = Nothing
    , vip = Nothing
    , ssn = Nothing
    , lastName = Nothing
    , firstName = Nothing
    , middle = Nothing
    , dateOfBirth = Nothing
    , birthPlace = Nothing
    , dateOfDeath = Nothing
    , mrn = Nothing
    , patientAccountNumber = Nothing
    , facilityPtID = Nothing
    , sexualOrientationNote = Nothing
    , genderIdentityNote = Nothing
    , email = Nothing
    , careCoordinatorId = Nothing
    , facilityId = Nothing
    , mainProviderId = Nothing
    , patientLanguagesMap = []
    , preferredLanguageIndex = 0
    , sfData = emptySfData
    }


emptySfData : SfData
emptySfData =
    { prefixId = Nothing
    , sexTypeId = Nothing
    , sexualOrientationId = Nothing
    , suffixId = Nothing
    , genderIdentityId = Nothing
    , raceId = Nothing
    , ethnicityId = Nothing
    , uSVeteranId = Nothing
    , religionId = Nothing
    , patientLanguageDropdown = []
    , careCoordinatorDropdown = []
    , languageDropdown = []
    , ethnicityDropdown = []
    , sexTypeDropdown = []
    , sexualOrientationDropdown = []
    , genderIdentityDropdown = []
    , facilityDropdown = []
    , mainProviderDropdown = []
    , raceDropdown = []
    , suffixDropdown = []
    , prefixDropdown = []
    , uSVeteranDropdown = []
    , religionDropdown = []
    }


decodeSfData : Decode.Decoder SfData
decodeSfData =
    Pipeline.decode SfData
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.hardcoded Nothing
        |> Pipeline.required "PatientLanguageDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "CareCoordinatorDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "LanguageDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "EthnicityDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "SexTypeDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "SexualOrientationDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "GenderIdentityDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "FacilityDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "MainProviderDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "RaceDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "SuffixDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "PrefixDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "USVeteranDropdown" (Decode.list decodeDropDownItem)
        |> Pipeline.required "ReligionDropdown" (Decode.list decodeDropDownItem)
