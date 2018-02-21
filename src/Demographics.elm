port module Demographics exposing (..)

import Html exposing (Html, text, div, span, input, label, h4)
import Html.Attributes exposing (class, id, type_, style, value, title, checked, hidden, attribute, maxlength, name)
import Html.Events exposing (onClick, onInput, onCheck)
import Common.Types exposing (DropdownItem, Flags)
import Common.Dropdown as Dropdown
import Common.Functions as Functions exposing (decodeDropdownItem)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Http
import Char
import MaskedInput.Number as MaskedNumber


port initDemographics : SfData -> Cmd msg


port initDemographicsDone : (String -> msg) -> Sub msg


port initContactHours : Maybe Decode.Value -> Cmd msg


port updateDemographics : (SfData -> msg) -> Sub msg


port startSave : (Bool -> msg) -> Sub msg


port save : Encode.Value -> Cmd msg


port scrollTo : String -> Cmd msg


scrollToError : Cmd msg
scrollToError =
    scrollTo "#ErrorDiv"


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ updateDemographics UpdateDemographics
        , initDemographicsDone InitDemographicsDone
        , startSave Save
        ]


init : Int -> Cmd Msg
init patientId =
    decodeServerResponse
        |> Http.get ("/People/GetDemographicsInformation?patientId=" ++ toString patientId)
        |> Http.send Load



-- Types


type alias Model =
    { patientPhoneNumbers : List PatientPhoneNumber
    , patientAddresses : List PatientAddress
    , phoneNumberTypeDropdown : List DropdownItem
    , stateDropdown : List DropdownItem
    , primaryAddressIndex : Int
    , preferredPhoneIndex : Int
    , patientId : Int
    , demographicsId : Maybe Int
    , nickName : Maybe String
    , ssn : Maybe String
    , lastName : Maybe String
    , firstName : Maybe String
    , middle : Maybe String
    , birthPlace : Maybe String
    , mrn : Maybe String
    , patientAccountNumber : Maybe String
    , facilityPtID : Maybe String
    , sexualOrientationNote : Maybe String
    , genderIdentityNote : Maybe String
    , email : Maybe String
    , preferredLanguageIndex : Int
    , sfData : SfData
    , patientLanguagesMap : List PatientLanguagesMap
    , contactHoursModel : Maybe Decode.Value
    , showValidationErrors : Bool
    , suffixId : Maybe Int
    , suffixDropState : Dropdown.DropState
    , prefixId : Maybe Int
    , prefixDropState : Dropdown.DropState
    , raceId : Maybe Int
    , raceDropState : Dropdown.DropState
    , ethnicityId : Maybe Int
    , ethnicityDropState : Dropdown.DropState
    , nodeCounter : Int
    , drops : DropdownSource
    }


type alias SfData =
    { facilityId : Maybe Int
    , mainProviderId : Maybe Int
    , careCoordinatorId : Maybe Int
    , sexTypeId : Maybe Int
    , sexualOrientationId : Maybe Int
    , genderIdentityId : Maybe Int
    , uSVeteranId : Maybe Int
    , religionId : Maybe Int
    , dateOfBirth : Maybe String
    , dateOfDeath : Maybe String
    , vip : Maybe Bool
    , drops : DropdownSource
    }


type alias PatientLanguagesMap =
    { id : Maybe Int
    , languageId : Maybe Int
    , isPreferred : Bool
    , dropState : Dropdown.DropState
    , nodeId : Int
    }


type alias PatientPhoneNumber =
    { id : Maybe Int
    , phoneNumber : Maybe String
    , phoneNumberTypeId : Maybe Int
    , isPreferred : Bool
    , maskState : MaskedNumber.State
    , dropState : Dropdown.DropState
    , nodeId : Int
    }


type alias PatientAddress =
    { id : Maybe Int
    , addressLine1 : Maybe String
    , addressLine2 : Maybe String
    , addressLine3 : Maybe String
    , city : Maybe String
    , stateId : Maybe Int
    , zipCode : Maybe String
    , isPreferred : Bool
    , dropState : Dropdown.DropState
    , nodeId : Int
    }



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "demographicInformationForm", class "col-xs-12 padding-h-0" ]
        [ h4 [ class "col-xs-12 padding-h-0" ] [ text "Assigned To" ]
        , div [ class "col-xs-12 padding-h-0 padding-bottom-10", id "ErrorDiv" ]
            [ viewValidationErrors model
            ]
        , div rowStyle
            [ sfbox "Facility" True
            , textbox "Patient's Facility ID No" True model.facilityPtID UpdateFacilityPtID
            , textbox "Medical Record No" False model.mrn UpdateMedicalRecordNo
            , textbox "Patient Account No" False model.patientAccountNumber UpdatePatientAccountNo
            ]
        , div rowStyle
            [ sfbox "Main Provider" True
            , sfbox "Care Coordinator" True
            ]
        , h4 [ class "col-xs-12 padding-h-0 padding-top-10" ] [ text "Demographic Information" ]
        , div rowStyle
            [ dropbox "Prefix" False <|
                Html.map UpdatePrefix <|
                    Dropdown.view model.prefixDropState model.drops.prefixDropdown model.prefixId
            , nonumberbox "First Name" True model.firstName UpdateFirstName
            , nonumberbox "Middle Name" False model.middle UpdateMiddle
            , nonumberbox "Last Name" True model.lastName UpdateLastName
            , dropbox "Suffix" False <|
                Html.map UpdateSuffix <|
                    Dropdown.view model.suffixDropState model.drops.suffixDropdown model.suffixId
            , textbox "Nickname" False model.nickName UpdateNickname
            , sfbox "Date of Birth" True
            , textbox "Birth Place" False model.birthPlace UpdateBirthPlace
            , sfbox "Date of Death" False
            , textbox "SSN" False model.ssn UpdateSSN
            ]
        , div rowStyle
            [ sfbox "VIP" False
            , sfbox "Sex at Birth" True
            , sfbox "Sexual Orientation" False
            , textbox "Sexual Orientation Note" False model.sexualOrientationNote UpdateSexualOrientationNote
            , sfbox "Gender Identity" False
            , textbox "Gender Identity Note" False model.genderIdentityNote UpdateGenderIdentityNote
            , dropbox "Race" False <|
                Html.map UpdateRace <|
                    Dropdown.view model.raceDropState model.drops.raceDropdown model.raceId
            , dropbox "Ethnicity" False <|
                Html.map UpdateEthnicity <|
                    Dropdown.view model.ethnicityDropState model.drops.ethnicityDropdown model.ethnicityId
            , sfbox "US Veteran" False
            , sfbox "Religion" False
            , textbox "Email" False model.email UpdateEmail
            ]
        , div [ class "col-xs-12 padding-h-0 padding-top-10" ]
            [ div [ class "col-xs-12 col-sm-12 col-md-10 col-lg-8 padding-h-0" ]
                [ h4 [ class "inline-block" ] [ text "Languages" ]
                , div [ class "inline-block e-tooltxt pointer", title "Add new language", onClick AddNewLanguage ]
                    [ span [ class "e-addnewitem e-toolbaricons e-icon e-addnew" ] []
                    ]
                , div [] (List.map (viewLanguages model.drops.languageDropdown) model.patientLanguagesMap)
                ]
            ]
        , div [ class "col-xs-12 padding-h-0" ]
            [ div [ class "col-xs-12 col-sm-12 col-md-10 col-lg-8 padding-h-0" ]
                [ h4 [ class "inline-block required" ] [ text "Phones" ]
                , div [ class "inline-block e-tooltxt pointer", title "Add new phone number", onClick AddNewPhone ]
                    [ span [ class "e-addnewitem e-toolbaricons e-icon e-addnew" ] []
                    ]
                , div [] (List.map (viewPhones model.phoneNumberTypeDropdown) model.patientPhoneNumbers)
                ]
            ]
        , div [ class "col-xs-12 padding-h-0 margin-bottom-5" ]
            [ div [ class "col-xs-12 col-sm-12 col-md-10 col-lg-8 padding-h-0" ]
                [ h4 [ class "inline-block required" ] [ text "Addresses" ]
                , div [ class "inline-block e-tooltxt pointer", title "Add new address", onClick AddNewAddress ]
                    [ span [ class "e-addnewitem e-toolbaricons e-icon e-addnew" ] []
                    ]
                , div [] (List.map (viewAddress model.stateDropdown) model.patientAddresses)
                ]
            ]
        ]


vertCent : ( String, String )
vertCent =
    ( "vertical-align", "middle" )


maybeToInt : Maybe String -> Maybe Int
maybeToInt maybeStr =
    case maybeStr of
        Just str ->
            case String.filter isNumber str |> String.toInt of
                Ok t ->
                    Just t

                Err _ ->
                    Nothing

        Nothing ->
            Nothing


viewLanguages : List DropdownItem -> PatientLanguagesMap -> Html Msg
viewLanguages dropdownItems lang =
    div [ class "margin-bottom-5", style [ ( "width", "350px" ) ] ]
        [ div [ class "inline-block ", style [ ( "width", "22px" ), ( "padding-top", "5px" ), ( "vertical-align", "middle" ) ], title "Mark as preferred" ]
            [ input [ type_ "radio", checked lang.isPreferred, name "languageGroup", onCheck (UpdatePreferredLanguage lang) ] [] ]
        , div [ class "inline-block", style [ ( "width", "calc(100% - 50px)" ), ( "vertical-align", "middle" ) ], title "Choose language" ]
            [ Html.map (UpdateLanguage lang) <| Dropdown.view lang.dropState dropdownItems lang.languageId ]
        , div [ class "inline-block", style [ ( "width", "20px" ), ( "vertical-align", "middle" ) ], title "Remove", onClick (RemoveLanguage lang) ]
            [ span [ class "e-cancel e-toolbaricons e-icon e-cancel margin-bottom-5 pointer" ] []
            ]
        ]


viewPhones : List DropdownItem -> PatientPhoneNumber -> Html Msg
viewPhones dropdownItems phone =
    div [ class "margin-bottom-5", style [ ( "width", "350px" ) ] ]
        [ div [ class "inline-block ", style [ ( "width", "22px" ), ( "padding-top", "5px" ), ( "vertical-align", "middle" ) ], title "Mark as preferred" ]
            [ input [ type_ "radio", checked phone.isPreferred, name "phoneGroup", onCheck (UpdatePreferredPhone phone) ] [] ]
        , div [ class "inline-block", style [ ( "width", "100px" ), ( "vertical-align", "middle" ) ], title "Mark as primary" ]
            [ Html.map (UpdatePhoneType phone) <| Dropdown.view phone.dropState dropdownItems phone.phoneNumberTypeId ]
        , div [ class "inline-block", style [ ( "width", "calc(100% - 155px)" ), ( "vertical-align", "middle" ) ] ]
            [ MaskedNumber.input (inputOptions phone) [ class "e-textbox", maskStyle ] phone.maskState (maybeToInt phone.phoneNumber) ]
        , div [ class "inline-block", style [ ( "width", "32px" ), ( "vertical-align", "middle" ) ], title "remove", onClick (RemovePhone phone) ]
            [ span [ class "e-cancel e-toolbaricons e-icon e-cancel margin-bottom-5 pointer" ] []
            ]
        ]


viewAddress : List DropdownItem -> PatientAddress -> Html Msg
viewAddress dropdownItems address =
    div [ class "multi-address-template" ]
        [ div [ class "col-xs-12 padding-h-0 margin-bottom-5" ]
            [ div [ title "Mark as primary", class "col-xs-6 padding-h-0 inline-block" ]
                [ input [ type_ "radio", checked address.isPreferred, style [ ( "margin-top", "0px" ), vertCent ], onCheck (UpdatePreferredAddress address), name "addressGroup" ] []
                , label [ style [ ( "margin-bottom", "0px" ), ( "margin-left", "4px" ) ] ] [ text "Primary" ]
                ]
            , div [ class "col-xs-6 padding-h-0 inline-block", style [ vertCent ], title "Remove", onClick (RemoveAddress address) ]
                [ span [ style [ ( "padding-right", "20px" ), ( "padding-top", "5px" ) ], class "e-cancel e-toolbaricons e-icon e-cancel margin-bottom-5 pointer pull-right" ] []
                ]
            ]
        , div [ class "col-xs-12 padding-h-0", style [ ( "padding-bottom", "20px" ) ] ]
            [ div [ class "col-xs-12 col-sm-6 padding-h-0" ]
                [ div []
                    [ label [ class "required" ] [ text "Address Line 1:" ]
                    , div [ class "form-column" ]
                        [ input [ class "e-textbox", type_ "text", maybeValue address.addressLine1, onInput (UpdateAddressLine1 address) ] []
                        ]
                    ]
                , div []
                    [ label [] [ text "Address Line 2:" ]
                    , div [ class "form-column" ]
                        [ input [ class "e-textbox", type_ "text", maybeValue address.addressLine2, onInput (UpdateAddressLine2 address) ] []
                        ]
                    ]
                , div []
                    [ label [] [ text "Apt./Room No.:" ]
                    , div [ class "form-column" ]
                        [ input [ class "e-textbox", type_ "text", maybeValue address.addressLine3, onInput (UpdateAddressLine3 address) ] []
                        ]
                    ]
                ]
            , div [ class "col-xs-12 col-sm-6 padding-h-0" ]
                [ div []
                    [ label [ class "required" ] [ text "City:" ]
                    , div [ class "form-column" ]
                        [ input [ class "e-textbox", type_ "text", maybeValue address.city, onInput (UpdateCity address) ] []
                        ]
                    ]
                , div [ class "margin-bottom-5" ]
                    [ label [ class "required" ] [ text "State:" ]
                    , div [ class "form-column" ]
                        [ Html.map (UpdateState address) <| Dropdown.view address.dropState dropdownItems address.stateId
                        ]
                    ]
                , div []
                    [ label [ class "required" ] [ text "Zip Code:" ]
                    , div [ class "form-column" ]
                        [ input [ class "e-textbox", type_ "text", maybeValue address.zipCode, onInput (UpdateZipcode address), maxlength 5 ] []
                        ]
                    ]
                ]
            ]
        ]



--UPDATE


type Msg
    = Load (Result Http.Error ServerResponse)
    | UpdateDemographics SfData
    | InitDemographicsDone String
    | Save Bool
    | SaveCompleted (Result Http.Error String)
    | AddNewLanguage
    | RemoveLanguage PatientLanguagesMap
    | AddNewPhone
    | RemovePhone PatientPhoneNumber
    | AddNewAddress
    | RemoveAddress PatientAddress
      -- Nested Controls
    | UpdateAddressLine1 PatientAddress String
    | UpdateAddressLine2 PatientAddress String
    | UpdateAddressLine3 PatientAddress String
    | UpdateCity PatientAddress String
    | UpdateZipcode PatientAddress String
    | UpdatePreferredAddress PatientAddress Bool
    | UpdatePreferredPhone PatientPhoneNumber Bool
    | UpdatePreferredLanguage PatientLanguagesMap Bool
    | UpdateState PatientAddress Dropdown.Msg
    | UpdatePhoneType PatientPhoneNumber Dropdown.Msg
    | UpdateLanguage PatientLanguagesMap Dropdown.Msg
      -- Edit
    | UpdateFacilityPtID String
    | UpdateMedicalRecordNo String
    | UpdatePatientAccountNo String
    | UpdateFirstName String
    | UpdateMiddle String
    | UpdateLastName String
    | UpdateNickname String
    | UpdateBirthPlace String
    | UpdateSSN String
    | UpdateSexualOrientationNote String
    | UpdateGenderIdentityNote String
    | UpdateEmail String
    | UpdatePrefix Dropdown.Msg
    | UpdateSuffix Dropdown.Msg
    | UpdateRace Dropdown.Msg
    | UpdateEthnicity Dropdown.Msg
    | InputChanged PatientPhoneNumber (Maybe Int)
    | InputStateChanged PatientPhoneNumber MaskedNumber.State


updateAddress : Model -> PatientAddress -> Model
updateAddress model newPatientAddress =
    let
        newAddresses =
            List.map
                (\t ->
                    if t.nodeId == newPatientAddress.nodeId then
                        newPatientAddress
                    else
                        t
                )
                model.patientAddresses
    in
        { model | patientAddresses = newAddresses }


updatePhones : Model -> PatientPhoneNumber -> Model
updatePhones model patientPhoneNumber =
    let
        newPhoneNumber =
            List.map
                (\t ->
                    if t.nodeId == patientPhoneNumber.nodeId then
                        patientPhoneNumber
                    else
                        t
                )
                model.patientPhoneNumbers
    in
        { model | patientPhoneNumbers = newPhoneNumber }


updateLanguage : Model -> PatientLanguagesMap -> Model
updateLanguage model patientLanguagesMap =
    let
        newPatientLanguagesMap =
            List.map
                (\t ->
                    if t.nodeId == patientLanguagesMap.nodeId then
                        patientLanguagesMap
                    else
                        t
                )
                model.patientLanguagesMap
    in
        { model | patientLanguagesMap = newPatientLanguagesMap }


togglePreferred : Int -> { c | nodeId : Int, isPreferred : a } -> { c | isPreferred : Bool, nodeId : Int }
togglePreferred nodeId t =
    if t.nodeId == nodeId then
        { t | isPreferred = True }
    else
        { t | isPreferred = False }


update : Msg -> Model -> Int -> ( Model, Cmd Msg )
update msg model patientId =
    case msg of
        Load (Ok serverResponse) ->
            let
                newModel =
                    updateModelFromServerMessage serverResponse model

                newPatientLanguagesMap =
                    if List.length newModel.patientLanguagesMap == 0 then
                        [ emptyPatientLanguagesMap 0 True ]
                    else
                        newModel.patientLanguagesMap
                            |> List.indexedMap (\idx t -> { t | nodeId = idx })

                newPatientPhoneNumber =
                    if List.length newModel.patientPhoneNumbers == 0 then
                        [ emptyPatientPhoneNumber 0 True ]
                    else
                        newModel.patientPhoneNumbers
                            |> List.indexedMap (\idx t -> { t | nodeId = idx })

                newPatientAddress =
                    if List.length newModel.patientAddresses == 0 then
                        [ emptyPatientAddress 0 True ]
                    else
                        newModel.patientAddresses
                            |> List.indexedMap (\idx t -> { t | nodeId = idx })
            in
                { newModel
                    | patientLanguagesMap = newPatientLanguagesMap
                    , patientPhoneNumbers = newPatientPhoneNumber
                    , patientAddresses = newPatientAddress
                    , nodeCounter = 3
                }
                    ! [ initDemographics newModel.sfData, Functions.setLoadingStatus False ]

        Load (Err t) ->
            model ! [ Functions.displayErrorMessage (toString t) ]

        InitDemographicsDone _ ->
            model ! [ initContactHours model.contactHoursModel ]

        UpdateDemographics sfData ->
            { model | sfData = sfData } ! []

        Save _ ->
            let
                newLangs =
                    model.patientLanguagesMap |> List.filter (\t -> t.languageId /= Nothing)

                newPhones =
                    model.patientPhoneNumbers |> List.filter (\t -> t.phoneNumber /= Nothing)

                newAddresses =
                    model.patientAddresses
                        |> List.filter (\t -> t.addressLine1 /= Nothing && t.city /= Nothing && t.stateId /= Nothing && t.zipCode /= Nothing)

                newModel =
                    { model
                        | patientLanguagesMap = newLangs
                        , patientPhoneNumbers = newPhones
                        , patientAddresses = newAddresses
                        , showValidationErrors = False
                    }
            in
                if List.length (validatationErrors newModel) > 0 then
                    { model | showValidationErrors = True } ! [ scrollToError ]
                else
                    newModel ! [ save (encodeBody newModel), Functions.setLoadingStatus True ]

        SaveCompleted (Ok responseMsg) ->
            case Functions.getResponseError responseMsg of
                Just t ->
                    model ! [ Functions.displayErrorMessage t, Functions.setLoadingStatus False ]

                Nothing ->
                    model ! [ Functions.displaySuccessMessage "Save completed successfully!", Functions.setLoadingStatus False ]

        SaveCompleted (Err t) ->
            model ! [ Functions.displayErrorMessage (toString t) ]

        AddNewLanguage ->
            { model
                | patientLanguagesMap = model.patientLanguagesMap ++ [ emptyPatientLanguagesMap model.nodeCounter False ]
                , nodeCounter = model.nodeCounter + 1
            }
                ! [ Functions.setUnsavedChanges True ]

        RemoveLanguage lang ->
            let
                newPatientLanguagesMap =
                    model.patientLanguagesMap
                        |> List.filter (\t -> t.nodeId /= lang.nodeId)

                updatedPatientLanguagesMap =
                    case List.any (\t -> t.isPreferred == True) newPatientLanguagesMap of
                        True ->
                            newPatientLanguagesMap

                        False ->
                            List.indexedMap
                                (\t y ->
                                    if t == 0 then
                                        { y | isPreferred = True }
                                    else
                                        y
                                )
                                newPatientLanguagesMap
            in
                { model | patientLanguagesMap = updatedPatientLanguagesMap } ! [ Functions.setUnsavedChanges True ]

        AddNewPhone ->
            { model
                | patientPhoneNumbers = model.patientPhoneNumbers ++ [ emptyPatientPhoneNumber model.nodeCounter False ]
                , nodeCounter = model.nodeCounter + 1
            }
                ! [ Functions.setUnsavedChanges True ]

        RemovePhone phone ->
            let
                newPatientPhoneNumber =
                    model.patientPhoneNumbers
                        |> List.filter (\t -> t.nodeId /= phone.nodeId)

                updatedPatientPhoneNumber =
                    case List.any (\t -> t.isPreferred == True) newPatientPhoneNumber of
                        True ->
                            newPatientPhoneNumber

                        False ->
                            List.indexedMap
                                (\t y ->
                                    if t == 0 then
                                        { y | isPreferred = True }
                                    else
                                        y
                                )
                                newPatientPhoneNumber
            in
                { model | patientPhoneNumbers = updatedPatientPhoneNumber } ! [ Functions.setUnsavedChanges True ]

        AddNewAddress ->
            { model
                | patientAddresses = model.patientAddresses ++ [ emptyPatientAddress model.nodeCounter False ]
                , nodeCounter = model.nodeCounter + 1
            }
                ! [ Functions.setUnsavedChanges True ]

        RemoveAddress address ->
            let
                newAddress =
                    model.patientAddresses
                        |> List.filter (\t -> t.nodeId /= address.nodeId)

                updatedAddress =
                    case List.any (\t -> t.isPreferred == True) newAddress of
                        True ->
                            newAddress

                        False ->
                            List.indexedMap
                                (\t y ->
                                    if t == 0 then
                                        { y | isPreferred = True }
                                    else
                                        y
                                )
                                newAddress
            in
                { model | patientAddresses = updatedAddress } ! [ Functions.setUnsavedChanges True ]

        -- Nested Controls
        UpdateAddressLine1 patientAddress str ->
            updateAddress model { patientAddress | addressLine1 = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateAddressLine2 patientAddress str ->
            updateAddress model { patientAddress | addressLine2 = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateAddressLine3 patientAddress str ->
            updateAddress model { patientAddress | addressLine3 = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateCity patientAddress str ->
            updateAddress model { patientAddress | city = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateZipcode patientAddress str ->
            updateAddress model { patientAddress | zipCode = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdatePreferredAddress address _ ->
            { model | patientAddresses = List.map (togglePreferred address.nodeId) model.patientAddresses } ! [ Functions.setUnsavedChanges True ]

        UpdatePreferredPhone phone _ ->
            { model | patientPhoneNumbers = List.map (togglePreferred phone.nodeId) model.patientPhoneNumbers } ! [ Functions.setUnsavedChanges True ]

        UpdatePreferredLanguage language _ ->
            { model | patientLanguagesMap = List.map (togglePreferred language.nodeId) model.patientLanguagesMap } ! [ Functions.setUnsavedChanges True ]

        UpdateState t dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg t.dropState t.stateId model.stateDropdown
            in
                updateAddress model { t | dropState = newDropState, stateId = newId } ! [ newMsg, Functions.setUnsavedChanges True ]

        UpdatePhoneType t dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg t.dropState t.phoneNumberTypeId model.phoneNumberTypeDropdown
            in
                updatePhones model { t | dropState = newDropState, phoneNumberTypeId = newId } ! [ newMsg, Functions.setUnsavedChanges True ]

        UpdateLanguage t dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg t.dropState t.languageId model.drops.languageDropdown
            in
                updateLanguage model { t | dropState = newDropState, languageId = newId }
                    ! [ newMsg, Functions.setUnsavedChanges True ]

        InputChanged patientPhoneNumber value ->
            updatePhones model { patientPhoneNumber | phoneNumber = Maybe.map toString value } ! [ Functions.setUnsavedChanges True ]

        InputStateChanged patientPhoneNumber maskState ->
            updatePhones model { patientPhoneNumber | maskState = maskState } ! [ Functions.setUnsavedChanges True ]

        -- Edit
        UpdateFacilityPtID str ->
            { model | facilityPtID = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateMedicalRecordNo str ->
            { model | mrn = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdatePatientAccountNo str ->
            { model | patientAccountNumber = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateFirstName str ->
            { model | firstName = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateMiddle str ->
            { model | middle = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateLastName str ->
            { model | lastName = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateNickname str ->
            { model | nickName = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateBirthPlace str ->
            { model | birthPlace = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateSSN str ->
            { model | ssn = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateSexualOrientationNote str ->
            { model | sexualOrientationNote = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateGenderIdentityNote str ->
            { model | genderIdentityNote = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdateEmail str ->
            { model | email = Just str } ! [ Functions.setUnsavedChanges True ]

        UpdatePrefix dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg model.prefixDropState model.prefixId model.drops.prefixDropdown
            in
                { model | prefixDropState = newDropState, prefixId = newId } ! [ newMsg, Functions.setUnsavedChanges True ]

        UpdateSuffix dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg model.suffixDropState model.suffixId model.drops.suffixDropdown
            in
                { model | suffixDropState = newDropState, suffixId = newId } ! [ newMsg, Functions.setUnsavedChanges True ]

        UpdateRace dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg model.raceDropState model.raceId model.drops.raceDropdown
            in
                { model | raceDropState = newDropState, raceId = newId } ! [ newMsg, Functions.setUnsavedChanges True ]

        UpdateEthnicity dropdownMsg ->
            let
                ( newDropState, newId, newMsg ) =
                    Dropdown.update dropdownMsg model.ethnicityDropState model.ethnicityId model.drops.ethnicityDropdown
            in
                { model | ethnicityDropState = newDropState, ethnicityId = newId } ! [ newMsg, Functions.setUnsavedChanges True ]



-- HELPER Functions


inputOptions : PatientPhoneNumber -> MaskedNumber.Options Msg
inputOptions patientPhoneNumber =
    let
        defaultOptions =
            MaskedNumber.defaultOptions (InputChanged patientPhoneNumber) (InputStateChanged patientPhoneNumber)
    in
        if patientPhoneNumber.phoneNumberTypeId == Just 3 then
            { defaultOptions
                | pattern = "(###) ###-#### ext.#####"
            }
        else
            { defaultOptions
                | pattern = "(###) ###-####"
            }


maybeValue : Maybe String -> Html.Attribute msg
maybeValue str =
    value (Maybe.withDefault "" str)


rowStyle : List (Html.Attribute msg)
rowStyle =
    [ class "col-xs-12 col-sm-12 col-md-5 col-lg-4 padding-left-0" ]


idAttr : String -> Html.Attribute msg
idAttr str =
    id (String.filter isAlpha str ++ "Id")


isAlpha : Char -> Bool
isAlpha char =
    Char.isLower char || Char.isUpper char


isNumber : Char -> Bool
isNumber char =
    Char.isDigit char


isRequiredClass : Bool -> Html.Attribute msg
isRequiredClass isRequired =
    case isRequired of
        True ->
            class "required "

        False ->
            class ""


commonStructureWithCustomAttr : String -> Bool -> Html.Attribute msg -> Html msg -> Html msg
commonStructureWithCustomAttr displayText isRequired attr t =
    div [ class "col-xs-12 padding-h-0", attr ]
        [ label [ isRequiredClass isRequired ] [ text (displayText ++ ":") ]
        , div [ class "DemographicsInputDiv padding-h-0" ]
            [ t ]
        ]


commonStructure : String -> Bool -> Html msg -> Html msg
commonStructure displayText isRequired t =
    commonStructureWithCustomAttr displayText isRequired (class "") t


onlyNumbers : Html.Attribute msg
onlyNumbers =
    attribute "onkeypress" "return event.charCode >= 48 && event.charCode <= 57"


noNumbers : Html.Attribute msg
noNumbers =
    attribute "onkeypress" "return event.charCode < 48 || event.charCode > 57"


maskStyle : Html.Attribute msg
maskStyle =
    style [ ( "margin-left", "5px" ), ( "margin-top", "5px" ) ]


maxLength : Maybe Int -> Html.Attribute msg
maxLength maybeMax =
    case maybeMax of
        Just t ->
            maxlength t

        Nothing ->
            maxlength -1


textboxInner : Maybe Int -> String -> Bool -> Maybe String -> (String -> msg) -> Html msg
textboxInner maybeMax displayText isRequired maybeStr event =
    commonStructure displayText isRequired <|
        input [ type_ "text", idAttr displayText, maybeValue maybeStr, class "e-textbox", onInput event, maxLength maybeMax ] []


textbox : String -> Bool -> Maybe String -> (String -> msg) -> Html msg
textbox displayText isRequired maybeStr event =
    textboxInner Nothing displayText isRequired maybeStr event


textboxWithMax : Int -> String -> Bool -> Maybe String -> (String -> msg) -> Html msg
textboxWithMax maxLength displayText isRequired maybeStr event =
    textboxInner (Just maxLength) displayText isRequired maybeStr event


numberbox : String -> Bool -> Maybe String -> (String -> msg) -> Html msg
numberbox displayText isRequired maybeStr event =
    commonStructure displayText isRequired <|
        input [ type_ "text", idAttr displayText, maybeValue maybeStr, onlyNumbers, class "e-textbox", onInput event ] []


nonumberbox : String -> Bool -> Maybe String -> (String -> msg) -> Html msg
nonumberbox displayText isRequired maybeStr event =
    commonStructure displayText isRequired <|
        input [ type_ "text", idAttr displayText, maybeValue maybeStr, noNumbers, class "e-textbox", onInput event ] []


dropbox : String -> Bool -> Html msg -> Html msg
dropbox displayText isRequired t =
    commonStructure displayText isRequired <|
        t


sfbox : String -> Bool -> Html msg
sfbox displayText isRequired =
    commonStructure displayText isRequired <|
        input [ type_ "text", idAttr displayText, class "e-textbox" ] []


sfcheckbox : String -> Bool -> Maybe String -> Html msg
sfcheckbox displayText isRequired maybeStr =
    commonStructureWithCustomAttr displayText isRequired (style [ ( "height", "34px" ) ]) <|
        input [ type_ "checkbox", idAttr displayText, class "e-checkbox" ] []


defaultErrorMsg : String
defaultErrorMsg =
    "Please provide a value for all required(*) fields."


requireInt : String -> Maybe Int -> Maybe String
requireInt fieldName maybeInt =
    case maybeInt of
        Nothing ->
            -- Just (fieldName ++ " is required")
            Just defaultErrorMsg

        Just _ ->
            Nothing


requireString : String -> Maybe String -> Maybe String
requireString _ maybeStr =
    if Maybe.withDefault "" maybeStr == "" then
        -- Just (fieldName ++ " is required")
        Just defaultErrorMsg
    else
        Nothing


phoneValidation : PatientPhoneNumber -> Maybe String
phoneValidation phone =
    let
        num =
            Maybe.withDefault "" phone.phoneNumber

        toError str =
            Just (str ++ " '" ++ num ++ "'")
    in
        if String.length num < 10 then
            toError "Incomplete Phone Number"
        else if String.length num > 0 && phone.phoneNumberTypeId == Nothing then
            toError "Missing phone type for"
        else
            Nothing


addressValidation : PatientAddress -> Maybe String
addressValidation address =
    [ requireString "Address Line 1" address.addressLine1
    , requireString "City" address.city
    , requireInt "State" address.stateId
    , requireString "Zip Code" address.zipCode
    ]
        |> List.filterMap identity
        |> List.head


phoneDuplicateValidation : Model -> Maybe String
phoneDuplicateValidation model =
    let
        uniquePhones =
            model.patientPhoneNumbers
                |> Functions.uniqueBy (\t -> Maybe.withDefault "" t.phoneNumber)

        duplicatePhone =
            List.head uniquePhones
    in
        if List.length model.patientPhoneNumbers == List.length uniquePhones then
            Nothing
        else
            case duplicatePhone of
                Just t ->
                    Just ("Duplicate phone number \"" ++ Maybe.withDefault "" t.phoneNumber ++ "\"")

                Nothing ->
                    Just "Duplicate phone number"


atleast1 : List a -> String -> Maybe String
atleast1 items msg =
    case List.head items of
        Just _ ->
            Nothing

        Nothing ->
            Just msg


validatationErrors : Model -> List String
validatationErrors model =
    [ requireInt "Facility" model.sfData.facilityId
    , requireString "Patient's Facility ID No" model.facilityPtID
    , requireInt "Main Provider" model.sfData.mainProviderId
    , requireInt "Care Coordinator" model.sfData.careCoordinatorId
    , requireString "First Name" model.firstName
    , requireString "Last Name" model.lastName
    , requireString "Date of Birth" model.sfData.dateOfBirth
    , requireInt "Sex at Birth" model.sfData.sexTypeId
    , model.patientPhoneNumbers
        |> Functions.uniqueBy (\t -> Maybe.withDefault "" t.phoneNumber)
        |> List.filterMap phoneValidation
        |> List.head
    , model.patientAddresses
        |> List.filterMap addressValidation
        |> List.head
    , phoneDuplicateValidation model
    , atleast1 model.patientAddresses "At least one address is required."
    , atleast1 model.patientPhoneNumbers "At least one phone is required."
    ]
        |> List.filterMap identity


viewValidationErrorsDiv : Model -> List String -> Html msg
viewValidationErrorsDiv model errors =
    div [ class "error", hidden (List.length errors == 0 || model.showValidationErrors == False) ]
        (List.map (\t -> div [] [ text t ]) errors)


viewValidationErrors : Model -> Html msg
viewValidationErrors model =
    viewValidationErrorsDiv model (validatationErrors model)


emptyModel : Int -> Model
emptyModel patientId =
    { patientId = patientId
    , demographicsId = Nothing
    , nickName = Nothing
    , ssn = Nothing
    , lastName = Nothing
    , firstName = Nothing
    , middle = Nothing
    , birthPlace = Nothing
    , mrn = Nothing
    , patientAccountNumber = Nothing
    , facilityPtID = Nothing
    , sexualOrientationNote = Nothing
    , genderIdentityNote = Nothing
    , email = Nothing
    , preferredLanguageIndex = 0
    , sfData = emptySfData
    , patientLanguagesMap = []
    , patientPhoneNumbers = []
    , patientAddresses = []
    , phoneNumberTypeDropdown = []
    , stateDropdown = []
    , primaryAddressIndex = 0
    , preferredPhoneIndex = 0
    , contactHoursModel = Nothing
    , showValidationErrors = False
    , suffixId = Nothing
    , suffixDropState = Dropdown.init "suffixDropdown"
    , prefixId = Nothing
    , prefixDropState = Dropdown.init "prefixDropdown"
    , raceId = Nothing
    , raceDropState = Dropdown.init "raceDropdown"
    , ethnicityId = Nothing
    , ethnicityDropState = Dropdown.init "ethnicityDropdown"
    , nodeCounter = 0
    , drops = emptyDrops
    }


emptySfData : SfData
emptySfData =
    { facilityId = Nothing
    , careCoordinatorId = Nothing
    , mainProviderId = Nothing
    , sexTypeId = Nothing
    , sexualOrientationId = Nothing
    , genderIdentityId = Nothing
    , uSVeteranId = Nothing
    , religionId = Nothing
    , dateOfBirth = Nothing
    , dateOfDeath = Nothing
    , vip = Nothing
    , drops = emptyDrops
    }


emptyPatientLanguagesMap : Int -> Bool -> PatientLanguagesMap
emptyPatientLanguagesMap nodeCounter isPreferred =
    { id = Nothing
    , languageId = Nothing
    , isPreferred = isPreferred
    , dropState = Dropdown.init "languageDropdown"
    , nodeId = nodeCounter
    }


emptyPatientPhoneNumber : Int -> Bool -> PatientPhoneNumber
emptyPatientPhoneNumber nodeCounter isPreferred =
    { id = Nothing
    , phoneNumber = Nothing
    , phoneNumberTypeId = Nothing
    , isPreferred = isPreferred
    , maskState = MaskedNumber.initialState
    , dropState = Dropdown.init "phoneDropdown"
    , nodeId = nodeCounter
    }


emptyPatientAddress : Int -> Bool -> PatientAddress
emptyPatientAddress nodeCounter isPreferred =
    { id = Nothing
    , addressLine1 = Nothing
    , addressLine2 = Nothing
    , addressLine3 = Nothing
    , city = Nothing
    , stateId = Nothing
    , zipCode = Nothing
    , isPreferred = isPreferred
    , dropState = Dropdown.init "stateDropdown"
    , nodeId = nodeCounter
    }


emptyDrops : DropdownSource
emptyDrops =
    { languageDropdown = []
    , ethnicityDropdown = []
    , sexTypeDropdown = []
    , sexualOrientationDropdown = []
    , genderIdentityDropdown = []
    , raceDropdown = []
    , suffixDropdown = []
    , prefixDropdown = []
    , uSVeteranDropdown = []
    , religionDropdown = []
    , careCoordinatorDropdown = []
    , facilityDropdown = []
    , mainProviderDropdown = []
    }


updateModelFromServerMessage : ServerResponse -> Model -> Model
updateModelFromServerMessage serverResponse model =
    case serverResponse of
        ServerSuccess d c h ds ->
            let
                sfDrops =
                    d.sfData
            in
                { model
                    | demographicsId = d.demographicsId
                    , nickName = d.nickName
                    , ssn = d.ssn
                    , lastName = d.lastName
                    , firstName = d.firstName
                    , middle = d.middle
                    , birthPlace = d.birthPlace
                    , mrn = d.mrn
                    , patientAccountNumber = d.patientAccountNumber
                    , facilityPtID = d.facilityPtID
                    , sexualOrientationNote = d.sexualOrientationNote
                    , genderIdentityNote = d.genderIdentityNote
                    , email = d.email
                    , preferredLanguageIndex = d.preferredLanguageIndex
                    , sfData = { sfDrops | drops = ds }
                    , patientLanguagesMap = d.patientLanguagesMap
                    , patientPhoneNumbers = c.patientPhoneNumbers
                    , patientAddresses = c.patientAddresses
                    , primaryAddressIndex = c.primaryAddressIndex
                    , preferredPhoneIndex = c.preferredPhoneIndex
                    , contactHoursModel = Just h
                    , suffixId = d.suffixId
                    , prefixId = d.prefixId
                    , raceId = d.raceId
                    , ethnicityId = d.ethnicityId
                    , stateDropdown = c.stateDropdown
                    , phoneNumberTypeDropdown = c.phoneNumberTypeDropdown
                    , drops = ds
                }

        ServerFail _ ->
            model



-- JSON Decoding


type alias DemographicsInformationModel =
    { patientId : Int
    , demographicsId : Maybe Int
    , nickName : Maybe String
    , ssn : Maybe String
    , lastName : Maybe String
    , firstName : Maybe String
    , middle : Maybe String
    , birthPlace : Maybe String
    , mrn : Maybe String
    , patientAccountNumber : Maybe String
    , facilityPtID : Maybe String
    , sexualOrientationNote : Maybe String
    , genderIdentityNote : Maybe String
    , email : Maybe String
    , preferredLanguageIndex : Int
    , sfData : SfData
    , patientLanguagesMap : List PatientLanguagesMap
    , suffixId : Maybe Int
    , prefixId : Maybe Int
    , raceId : Maybe Int
    , ethnicityId : Maybe Int
    }


type alias ContactInformationModel =
    { patientPhoneNumbers : List PatientPhoneNumber
    , patientAddresses : List PatientAddress
    , phoneNumberTypeDropdown : List DropdownItem
    , stateDropdown : List DropdownItem
    , primaryAddressIndex : Int
    , preferredPhoneIndex : Int
    }


type ServerResponse
    = ServerSuccess DemographicsInformationModel ContactInformationModel Decode.Value DropdownSource
    | ServerFail String


decodeServerResponse : Decode.Decoder ServerResponse
decodeServerResponse =
    Pipeline.decode ServerSuccess
        |> Pipeline.required "demographicsInformationModel" decodeDemographicsInformationModel
        |> Pipeline.required "contactInformationModel" decodeContactInformationModel
        |> Pipeline.required "contactHoursModel" Decode.value
        |> Pipeline.required "demographicLists" decodeLists


decodeDemographicsInformationModel : Decode.Decoder DemographicsInformationModel
decodeDemographicsInformationModel =
    Pipeline.decode DemographicsInformationModel
        |> Pipeline.required "PatientId" Decode.int
        |> Pipeline.required "DemographicsId" (Decode.maybe Decode.int)
        |> Pipeline.required "NickName" (Decode.maybe Decode.string)
        |> Pipeline.required "SSN" (Decode.maybe Decode.string)
        |> Pipeline.required "LastName" (Decode.maybe Decode.string)
        |> Pipeline.required "FirstName" (Decode.maybe Decode.string)
        |> Pipeline.required "Middle" (Decode.maybe Decode.string)
        |> Pipeline.required "BirthPlace" (Decode.maybe Decode.string)
        |> Pipeline.required "MRN" (Decode.maybe Decode.string)
        |> Pipeline.required "PatientAccountNumber" (Decode.maybe Decode.string)
        |> Pipeline.required "FacilityPtID" (Decode.maybe Decode.string)
        |> Pipeline.required "SexualOrientationNote" (Decode.maybe Decode.string)
        |> Pipeline.required "GenderIdentityNote" (Decode.maybe Decode.string)
        |> Pipeline.required "Email" (Decode.maybe Decode.string)
        |> Pipeline.required "PreferredLanguageIndex" Decode.int
        |> Pipeline.custom decodeSfData
        |> Pipeline.required "PatientLanguagesMap" (Decode.list decodePatientLanguagesMap)
        |> Pipeline.required "SuffixId" (Decode.maybe Decode.int)
        |> Pipeline.required "PrefixId" (Decode.maybe Decode.int)
        |> Pipeline.required "RaceId" (Decode.maybe Decode.int)
        |> Pipeline.required "EthnicityId" (Decode.maybe Decode.int)


decodeContactInformationModel : Decode.Decoder ContactInformationModel
decodeContactInformationModel =
    Pipeline.decode ContactInformationModel
        |> Pipeline.required "PatientPhoneNumbers" (Decode.list decodePatientPhoneNumber)
        |> Pipeline.required "PatientAddresses" (Decode.list decodePatientAddress)
        |> Pipeline.required "PhoneNumberTypeDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "StateDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "PrimaryAddressIndex" Decode.int
        |> Pipeline.required "PreferredPhoneIndex" Decode.int


decodePatientLanguagesMap : Decode.Decoder PatientLanguagesMap
decodePatientLanguagesMap =
    Pipeline.decode PatientLanguagesMap
        |> Pipeline.required "Id" (Decode.maybe Decode.int)
        |> Pipeline.required "LanguageId" (Decode.maybe Decode.int)
        |> Pipeline.required "IsPreferred" Decode.bool
        |> Pipeline.hardcoded (Dropdown.init "languageDropdown")
        |> Pipeline.hardcoded 0


decodePatientPhoneNumber : Decode.Decoder PatientPhoneNumber
decodePatientPhoneNumber =
    Pipeline.decode PatientPhoneNumber
        |> Pipeline.required "Id" (Decode.maybe Decode.int)
        |> Pipeline.required "PhoneNumber" (Decode.maybe Decode.string)
        |> Pipeline.required "PhoneNumberTypeId" (Decode.maybe Decode.int)
        |> Pipeline.required "IsPreferred" Decode.bool
        |> Pipeline.hardcoded MaskedNumber.initialState
        |> Pipeline.hardcoded (Dropdown.init "phoneTypeDropdown")
        |> Pipeline.hardcoded 0


decodePatientAddress : Decode.Decoder PatientAddress
decodePatientAddress =
    Pipeline.decode PatientAddress
        |> Pipeline.required "Id" (Decode.maybe Decode.int)
        |> Pipeline.required "AddressLine1" (Decode.maybe Decode.string)
        |> Pipeline.required "AddressLine2" (Decode.maybe Decode.string)
        |> Pipeline.required "AddressLine3" (Decode.maybe Decode.string)
        |> Pipeline.required "City" (Decode.maybe Decode.string)
        |> Pipeline.required "StateId" (Decode.maybe Decode.int)
        |> Pipeline.required "ZipCode" (Decode.maybe Decode.string)
        |> Pipeline.required "IsPrimary" Decode.bool
        |> Pipeline.hardcoded (Dropdown.init "stateDropdown")
        |> Pipeline.hardcoded 0


decodeSfData : Decode.Decoder SfData
decodeSfData =
    Pipeline.decode SfData
        |> Pipeline.required "FacilityId" (Decode.maybe Decode.int)
        |> Pipeline.required "MainProviderId" (Decode.maybe Decode.int)
        |> Pipeline.required "CareCoordinatorId" (Decode.maybe Decode.int)
        |> Pipeline.required "SexTypeId" (Decode.maybe Decode.int)
        |> Pipeline.required "SexualOrientationId" (Decode.maybe Decode.int)
        |> Pipeline.required "GenderIdentityId" (Decode.maybe Decode.int)
        |> Pipeline.required "USVeteranId" (Decode.maybe Decode.int)
        |> Pipeline.required "ReligionId" (Decode.maybe Decode.int)
        |> Pipeline.required "DateOfBirth" (Decode.maybe Decode.string)
        |> Pipeline.required "DateOfDeath" (Decode.maybe Decode.string)
        |> Pipeline.required "VIP" (Decode.maybe Decode.bool)
        |> Pipeline.hardcoded emptyDrops


type alias DropdownSource =
    { languageDropdown : List DropdownItem
    , ethnicityDropdown : List DropdownItem
    , sexTypeDropdown : List DropdownItem
    , sexualOrientationDropdown : List DropdownItem
    , genderIdentityDropdown : List DropdownItem
    , raceDropdown : List DropdownItem
    , suffixDropdown : List DropdownItem
    , prefixDropdown : List DropdownItem
    , uSVeteranDropdown : List DropdownItem
    , religionDropdown : List DropdownItem
    , careCoordinatorDropdown : List DropdownItem
    , facilityDropdown : List DropdownItem
    , mainProviderDropdown : List DropdownItem
    }


decodeLists : Decode.Decoder DropdownSource
decodeLists =
    Pipeline.decode DropdownSource
        |> Pipeline.required "LanguageDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "EthnicityDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "SexTypeDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "SexualOrientationDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "GenderIdentityDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "RaceDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "SuffixDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "PrefixDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "USVeteranDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "ReligionDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "CareCoordinatorDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "FacilityDropdown" (Decode.list decodeDropdownItem)
        |> Pipeline.required "MainProviderDropdown" (Decode.list decodeDropdownItem)



-- ENCODING


encodePatientLanguagesMap : PatientLanguagesMap -> Encode.Value
encodePatientLanguagesMap lang =
    Encode.object
        [ ( "Id ", maybeVal Encode.int lang.id )
        , ( "LanguageId", maybeVal Encode.int lang.languageId )
        , ( "IsPreferred", Encode.bool lang.isPreferred )
        ]


maybeVal : (a -> Encode.Value) -> Maybe a -> Encode.Value
maybeVal encoder =
    Maybe.map encoder >> Maybe.withDefault Encode.null


encodeDemographicsInformationModel : Model -> Encode.Value
encodeDemographicsInformationModel model =
    Encode.object
        [ ( "PatientId", Encode.int model.patientId )
        , ( "DemographicsId", maybeVal Encode.int model.demographicsId )
        , ( "NickName", maybeVal Encode.string model.nickName )
        , ( "SSN", maybeVal Encode.string model.ssn )
        , ( "LastName", maybeVal Encode.string model.lastName )
        , ( "FirstName", maybeVal Encode.string model.firstName )
        , ( "Middle", maybeVal Encode.string model.middle )
        , ( "BirthPlace", maybeVal Encode.string model.birthPlace )
        , ( "MRN", maybeVal Encode.string model.mrn )
        , ( "PatientAccountNumber", maybeVal Encode.string model.patientAccountNumber )
        , ( "FacilityPtID", maybeVal Encode.string model.facilityPtID )
        , ( "SexualOrientationNote", maybeVal Encode.string model.sexualOrientationNote )
        , ( "GenderIdentityNote", maybeVal Encode.string model.genderIdentityNote )
        , ( "Email", maybeVal Encode.string model.email )
        , ( "FacilityId", maybeVal Encode.int model.sfData.facilityId )
        , ( "MainProviderId", maybeVal Encode.int model.sfData.mainProviderId )
        , ( "CareCoordinatorId", maybeVal Encode.int model.sfData.careCoordinatorId )
        , ( "PrefixId", maybeVal Encode.int model.prefixId )
        , ( "SexTypeId", maybeVal Encode.int model.sfData.sexTypeId )
        , ( "SexualOrientationId", maybeVal Encode.int model.sfData.sexualOrientationId )
        , ( "SuffixId", maybeVal Encode.int model.suffixId )
        , ( "GenderIdentityId", maybeVal Encode.int model.sfData.genderIdentityId )
        , ( "RaceId", maybeVal Encode.int model.raceId )
        , ( "EthnicityId", maybeVal Encode.int model.ethnicityId )
        , ( "USVeteranId", maybeVal Encode.int model.sfData.uSVeteranId )
        , ( "ReligionId", maybeVal Encode.int model.sfData.religionId )
        , ( "DateOfBirth", maybeVal Encode.string model.sfData.dateOfBirth )
        , ( "DateOfDeath", maybeVal Encode.string model.sfData.dateOfDeath )
        , ( "VIP", maybeVal Encode.bool model.sfData.vip )
        , ( "PatientLanguagesMap", Encode.list (List.map encodePatientLanguagesMap model.patientLanguagesMap) )
        ]


encodeContactInformationModel : Model -> Encode.Value
encodeContactInformationModel model =
    Encode.object
        [ ( "PatientAddresses", Encode.list (List.map encodePatientAddress model.patientAddresses) )
        , ( "PatientPhoneNumbers", Encode.list (List.map encodePatientPhoneNumber model.patientPhoneNumbers) )
        ]


encodePatientAddress : PatientAddress -> Encode.Value
encodePatientAddress address =
    Encode.object
        [ ( "Id ", maybeVal Encode.int address.id )
        , ( "AddressLine1", maybeVal Encode.string address.addressLine1 )
        , ( "AddressLine2", maybeVal Encode.string address.addressLine2 )
        , ( "AddressLine3", maybeVal Encode.string address.addressLine3 )
        , ( "City", maybeVal Encode.string address.city )
        , ( "StateId", maybeVal Encode.int address.stateId )
        , ( "ZipCode", maybeVal Encode.string address.zipCode )
        , ( "IsPrimary", Encode.bool address.isPreferred )
        ]


encodePatientPhoneNumber : PatientPhoneNumber -> Encode.Value
encodePatientPhoneNumber phone =
    Encode.object
        [ ( "Id ", maybeVal Encode.int phone.id )
        , ( "PhoneNumber", maybeVal Encode.string phone.phoneNumber )
        , ( "PhoneNumberTypeId", maybeVal Encode.int phone.phoneNumberTypeId )
        , ( "IsPreferred", Encode.bool phone.isPreferred )
        ]



-- type alias ContactsData =
--     { tZ : String
--     , wDStr : String
--     }


encodeBody : Model -> Encode.Value
encodeBody model =
    Encode.object
        [ ( "demographicsInformation", encodeDemographicsInformationModel model )
        , ( "contactInformation", encodeContactInformationModel model )
        , ( "phones", Encode.list (List.map encodePatientPhoneNumber model.patientPhoneNumbers) )
        , ( "addresses", Encode.list (List.map encodePatientAddress model.patientAddresses) )
        , ( "languages", Encode.list (List.map encodePatientLanguagesMap model.patientLanguagesMap) )

        -- , ( "TZ", Encode.string contactsData.tZ )
        -- , ( "WDStr", Encode.string contactsData.wDStr )
        ]
