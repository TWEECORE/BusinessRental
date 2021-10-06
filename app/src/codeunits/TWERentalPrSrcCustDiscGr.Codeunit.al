/// <summary>
/// Codeunit TWE Rental PrSrc.-Cust.DiscGr. (ID 70704660) implements Interface TWE Rental Price Source.
/// </summary>
codeunit 50054 "TWE Rental PrSrc.-Cust.DiscGr." implements "TWE Rental Price Source"
{
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        ParentErr: Label 'Parent Source No. must be blank for Customer Disc. Group source type.';

    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetNo(var PriceSource: Record "TWE Rental Price Source")
    begin
        if CustomerDiscountGroup.GetBySystemId(PriceSource."Source ID") then
            PriceSource."Source No." := CustomerDiscountGroup.Code
        else
            PriceSource.InitSource();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="TWERentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetId(var TWERentalPriceSource: Record "TWE Rental Price Source")
    begin
        if CustomerDiscountGroup.Get(TWERentalPriceSource."Source No.") then
            TWERentalPriceSource."Source ID" := CustomerDiscountGroup.SystemId
        else
            TWERentalPriceSource.InitSource();
    end;

    /// <summary>
    /// IsForAmountType.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(AmountType = AmountType::Discount);
    end;

    /// <summary>
    /// IsSourceNoAllowed.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    /// <summary>
    /// IsLookupOK.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var PriceSource: Record "TWE Rental Price Source"): Boolean
    var
        xPriceSource: Record "TWE Rental Price Source";
    begin
        xPriceSource := PriceSource;
        if CustomerDiscountGroup.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Customer Disc. Groups", CustomerDiscountGroup) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", CustomerDiscountGroup.Code);
            PriceSource := xPriceSource;
            exit(true);
        end;
    end;

    /// <summary>
    /// VerifyParent.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure VerifyParent(var PriceSource: Record "TWE Rental Price Source") Result: Boolean
    begin
        if PriceSource."Parent Source No." <> '' then
            Error(ParentErr);
    end;

    /// <summary>
    /// GetGroupNo.
    /// </summary>
    /// <param name="PriceSource">Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetGroupNo(PriceSource: Record "TWE Rental Price Source"): Code[20];
    begin
    end;
}
