/// <summary>
/// Codeunit TWE Rent Price Calculation Mgt. (ID 50041).
/// </summary>
codeunit 50041 "TWE Rental Price Calc Mgt."
{
    trigger OnRun()
    begin
        RefreshSetup();
    end;

    var
        ExtendedPriceFeatureIdTok: Label 'RentPrices', Locked = true;
        NotImplementedMethodErr: Label 'Method %1 does not have active implementations for %2 price type.', Comment = '%1 - method name, %2 - price type name';

    /// <summary>
    /// RefreshSetup.
    /// </summary>
    /// <returns>Return variable Updated of type Boolean.</returns>
    procedure RefreshSetup() Updated: Boolean;
    var
        TempRentalPriceCalculationSetup: Record "TWE Rental Price Calc. Setup" temporary;
        RentalPriceCalculationSetup: Record "TWE Rental Price Calc. Setup";
    begin
        OnFindSupportedSetup(TempRentalPriceCalculationSetup);
        if RentalPriceCalculationSetup.FindSet() then
            repeat
                if TempRentalPriceCalculationSetup.Get(RentalPriceCalculationSetup.Code) then
                    TempRentalPriceCalculationSetup.Delete()
                else begin
                    RentalPriceCalculationSetup.Delete();
                    Updated := true;
                end;
            until RentalPriceCalculationSetup.Next() = 0;
        if RentalPriceCalculationSetup.MoveFrom(TempRentalPriceCalculationSetup) then
            Updated := true;
    end;

    /// <summary>
    /// GetHandler.
    /// </summary>
    /// <param name="LineWithPrice">Interface "TWE Rent Line With Price".</param>
    /// <param name="PriceCalculation">VAR Interface "TWE Rent Price Calculation".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure GetHandler(LineWithPrice: Interface "TWE Rent Line With Price"; var PriceCalculation: Interface "TWE Rent Price Calculation") Result: Boolean;
    var
        TempRentalPriceCalcSetup: Record "TWE Rental Price Calc. Setup" temporary;
        RentPriceCalcHandler: Enum "TWE Rent Price Calc Handler";
    begin
        PriceCalculation := RentPriceCalcHandler::Rent;
        PriceCalculation.Init(LineWithPrice, TempRentalPriceCalcSetup);
    end;

    /// <summary>
    /// VerifyMethodImplemented.
    /// </summary>
    /// <param name="Method">Enum "Price Calculation Method".</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    procedure VerifyMethodImplemented(Method: Enum "Price Calculation Method"; PriceType: Enum "Price Type")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if PriceType = PriceType::Any then
            PriceCalculationSetup.SetFilter(Type, '>%1', PriceType)
        else
            PriceCalculationSetup.SetRange(Type, PriceType);
        PriceCalculationSetup.SetRange(Method, Method);
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.IsEmpty() then
            Error(NotImplementedMethodErr, Method, PriceType);
    end;

    /// <summary>
    /// FindSetup.
    /// </summary>
    /// <param name="LineWithPrice">Interface "TWE Rent Line With Price".</param>
    /// <param name="PriceCalculationSetup">VAR Record "Price Calculation Setup".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure FindSetup(LineWithPrice: Interface "TWE Rent Line With Price"; var PriceCalculationSetup: Record "Price Calculation Setup"): Boolean;
    var
        DtldPriceCalcSetup: Record "Dtld. Price Calculation Setup";
        PriceCalculationDtldSetup: Codeunit "Price Calculation Dtld. Setup";
    begin
        // TODO: Check LineWithPrice.SetAssesSourceForSetup
        // if not LineWithPrice.SetAssetSourceForSetup(DtldPriceCalcSetup) then
        //     exit(false);

        if DtldPriceCalcSetup.Method = DtldPriceCalcSetup.Method::" " then
            DtldPriceCalcSetup.Method := DtldPriceCalcSetup.Method::"Lowest Price";

        if PriceCalculationDtldSetup.FindSetup(DtldPriceCalcSetup) then
            if PriceCalculationSetup.Get(DtldPriceCalcSetup."Setup Code") then
                exit(true);

        PriceCalculationSetup.Reset();
        PriceCalculationSetup.SetRange(Enabled, true);
        PriceCalculationSetup.SetRange(Default, true);
        PriceCalculationSetup.SetRange(Method, DtldPriceCalcSetup.Method);
        PriceCalculationSetup.SetRange(Type, DtldPriceCalcSetup.Type);
        PriceCalculationSetup.SetRange("Asset Type", DtldPriceCalcSetup."Asset Type");
        if PriceCalculationSetup.FindFirst() then
            exit(true);
        PriceCalculationSetup.SetRange("Asset Type", PriceCalculationSetup."Asset Type"::" ");
        if PriceCalculationSetup.FindFirst() then
            exit(true);

        Clear(PriceCalculationSetup);
        exit(false);
    end;

    /// <summary>
    /// GetFeatureKey.
    /// </summary>
    /// <returns>Return value of type Text[50].</returns>
    procedure GetFeatureKey(): Text[50]
    begin
        exit(ExtendedPriceFeatureIdTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSupportedSetup(var TempRentalPriceCalcSetup: Record "TWE Rental Price Calc. Setup" temporary)
    begin
    end;
}
