/// <summary>
/// Codeunit TWE Rental Price Source - Cust (ID 70704660) implements Interface TWE Rental Price Source.
/// </summary>
codeunit 50043 "TWE Rental Price Source - Cust" implements "TWE Rental Price Source"
{
    var
        Customer: Record Customer;
        ParentErr: Label 'Parent Source No. must be blank for Customer source type.';

    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetNo(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
        if Customer.GetBySystemId(RentalPriceSource."Source ID") then begin
            RentalPriceSource."Source No." := Customer."No.";
            FillAdditionalFields(RentalPriceSource);
        end else
            RentalPriceSource.InitSource();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetId(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
        if Customer.Get(RentalPriceSource."Source No.") then begin
            RentalPriceSource."Source ID" := Customer.SystemId;
            FillAdditionalFields(RentalPriceSource);
        end else
            RentalPriceSource.InitSource();
    end;

    /// <summary>
    /// IsForAmountType.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
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
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var RentalPriceSource: Record "TWE Rental Price Source"): Boolean
    var
        xRentalPriceSource: Record "TWE Rental Price Source";
    begin
        xRentalPriceSource := RentalPriceSource;
        if Customer.Get(xRentalPriceSource."Source No.") then;
        if Page.RunModal(Page::"Customer List", Customer) = ACTION::LookupOK then begin
            xRentalPriceSource.Validate("Source No.", Customer."No.");
            RentalPriceSource := xRentalPriceSource;
            exit(true);
        end;
    end;

    /// <summary>
    /// VerifyParent.
    /// </summary>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure VerifyParent(var RentalPriceSource: Record "TWE Rental Price Source") Result: Boolean
    begin
        if RentalPriceSource."Parent Source No." <> '' then
            Error(ParentErr);
    end;

    /// <summary>
    /// GetGroupNo.
    /// </summary>
    /// <param name="RentalPriceSource">Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetGroupNo(RentalPriceSource: Record "TWE Rental Price Source"): Code[20];
    begin
        exit(RentalPriceSource."Source No.");
    end;

    local procedure FillAdditionalFields(var RentalPriceSource: Record "TWE Rental Price Source")
    begin
        RentalPriceSource."Currency Code" := Customer."Currency Code";
        RentalPriceSource."Allow Line Disc." := Customer."Allow Line Disc.";
        RentalPriceSource."Price Includes VAT" := Customer."Prices Including VAT";
        RentalPriceSource."VAT Bus. Posting Gr. (Price)" := Customer."VAT Bus. Posting Group";
    end;
}
