module Main exposing (..)

import Model exposing (..)
import Html exposing (text, div)
import Records.Main as Records
import RecordAddNew.Main as RecordAddNew
import Utils.CommonFunctions exposing (..)
import Utils.CommonTypes exposing (..)
import Functions exposing (..)


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Sub.map RecordsMsg Records.subscriptions
        , Sub.map RecordAddNewMsg RecordAddNew.subscriptions
        ]


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            emptyModel flags
    in
        if flags.pageFlag == "billing" then
            { model | page = BillingPage } ! []
        else if flags.pageFlag == "records" then
            { model | page = RecordsPage }
                ! [ Cmd.map RecordsMsg (Records.init flags)
                  , getDropDowns flags.patientId AddEditDataSourceLoaded
                  ]
        else
            ( model, Cmd.none )


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


view : Model -> Html.Html Msg
view model =
    case model.page of
        NoPage ->
            div [] []

        BillingPage ->
            div [] []

        RecordsPage ->
            Html.map RecordsMsg (Records.view model.recordsState model.addEditDataSource)

        RecordAddNewPage ->
            Html.map RecordAddNewMsg (RecordAddNew.view model.recordAddNewState)

        Error str ->
            div [] [ text str ]


update : Msg -> Model -> ( Model, Cmd Model.Msg )
update msg model =
    case msg of
        BillingMsg billingMsg ->
            model ! []

        RecordsMsg recordsMsg ->
            let
                ( ( newModel, pageCmd ), addEditDataSource ) =
                    Records.update recordsMsg model.recordsState
            in
                case addEditDataSource of
                    Just t ->
                        { model | page = RecordAddNewPage } ! [ Cmd.map RecordAddNewMsg (RecordAddNew.init model.flags t) ]

                    Nothing ->
                        { model | recordsState = newModel } ! [ Cmd.map RecordsMsg pageCmd ]

        RecordAddNewMsg recordAddNewMsg ->
            let
                ( ( newModel, pageCmd ), isDone ) =
                    RecordAddNew.update recordAddNewMsg model.recordAddNewState
            in
                case isDone of
                    True ->
                        { model | page = RecordsPage } ! [ Cmd.map RecordsMsg (Records.init model.flags) ]

                    False ->
                        { model | recordAddNewState = newModel } ! [ Cmd.map RecordAddNewMsg pageCmd ]

        AddEditDataSourceLoaded (Ok t) ->
            { model | addEditDataSource = Just t } ! []

        AddEditDataSourceLoaded (Err httpError) ->
            { model | page = Error (toString httpError) } ! [ setLoadingStatus False ]
