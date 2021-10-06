/// <summary>
/// Codeunit TWE Rental Info-Pane Mgt. (ID 50023).
/// </summary>
codeunit 50023 "TWE Rental Info-Pane Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        MainRentalItem: Record "TWE Main Rental Item";
        AvailableToPromise: Codeunit "Available to Promise";

    /// <summary>
    /// CalcScheduledReceipt.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcScheduledReceipt(var RentalLine: Record "TWE Rental Line"): Decimal
    begin
        if GetItem(RentalLine) then
            SetItemFilter(MainRentalItem, RentalLine);
    end;

    /// <summary>
    /// CalcGrossRequirements.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcGrossRequirements(var RentalLine: Record "TWE Rental Line"): Decimal
    begin
        if GetItem(RentalLine) then
            SetItemFilter(MainRentalItem, RentalLine);
    end;

    /// <summary>
    /// CalcReservedRequirements.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcReservedRequirements(var RentalLine: Record "TWE Rental Line"): Decimal
    begin
        if GetItem(RentalLine) then
            SetItemFilter(MainRentalItem, RentalLine);
    end;

    /// <summary>
    /// CalcReservedDemand.
    /// </summary>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcReservedDemand(RentalLine: Record "TWE Rental Line"): Decimal
    begin
        if GetItem(RentalLine) then
            SetItemFilter(MainRentalItem, RentalLine);
    end;

    /// <summary>
    /// CalcNoOfRentalPrices.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <returns>Return value of type Integer.</returns>
    procedure CalcNoOfRentalPrices(var RentalLine: Record "TWE Rental Line"): Integer
    begin
        exit(RentalLine.CountPrice(true));
    end;

    /// <summary>
    /// CalcNoOfRentalLineDisc.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    /// <returns>Return value of type Integer.</returns>
    procedure CalcNoOfRentalLineDisc(var RentalLine: Record "TWE Rental Line"): Integer
    begin
        exit(RentalLine.CountDiscount(true));
    end;

    /// <summary>
    /// LookupItem.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    procedure LookupItem(var RentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeLookupItem(RentalLine, MainRentalItem, IsHandled);
        if IsHandled then
            exit;

        RentalLine.TestField(Type, RentalLine.Type::"Rental Item");
        RentalLine.TestField("No.");
        GetItem(RentalLine);
        PAGE.RunModal(PAGE::"TWE Main Rental Item Card", MainRentalItem);
    end;

    /// <summary>
    /// ResetItemNo.
    /// </summary>
    procedure ResetItemNo()
    begin
        AvailableToPromise.ResetItemNo();
    end;

    local procedure GetItem(var RentalLine: Record "TWE Rental Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(RentalLine, MainRentalItem, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if (RentalLine.Type <> RentalLine.Type::"Rental Item") or (RentalLine."No." = '') then
            exit(false);

        if RentalLine."No." <> MainRentalItem."No." then
            MainRentalItem.Get(RentalLine."No.");
        exit(true);
    end;

    local procedure SetItemFilter(var MainRentalItem: Record "TWE Main Rental Item"; var RentalLine: Record "TWE Rental Line")
    begin
        MainRentalItem.Reset();
        MainRentalItem.SetRange("Location Filter", RentalLine."Location Code");
        MainRentalItem.SetRange("Drop Shipment Filter", RentalLine."Drop Shipment");
        OnAfterSetItemFilter(MainRentalItem, RentalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemFilter(var MainRentalItem: Record "TWE Main Rental Item"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(RentalLine: Record "TWE Rental Line"; var MainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItem(var RentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
    end;
}

