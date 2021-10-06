/// <summary>
/// Unknown TWE Rental Price Src. - Campaign (ID 50046) implements Interface TWE Rental Price Source.
/// </summary>
codeunit 50046 "TWE Rental Price Src.-Campaign" implements "TWE Rental Price Source"
{
    var
        Campaign: Record Campaign;
        ParentErr: Label 'Parent Source No. must be blank for Campaign source type.';

    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetNo(var PriceSource: Record "TWE Rental Price Source")
    begin
        if Campaign.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := Campaign."No.";
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetId(var PriceSource: Record "TWE Rental Price Source")
    begin
        if Campaign.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := Campaign.SystemId;
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
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
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var PriceSource: Record "TWE Rental Price Source"): Boolean
    var
        xPriceSource: Record "TWE Rental Price Source";
    begin
        xPriceSource := PriceSource;
        if Campaign.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Campaign List", Campaign) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", Campaign."No.");
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

    local procedure FillAdditionalFields(var PriceSource: Record "TWE Rental Price Source")
    begin
        PriceSource."Starting Date" := Campaign."Starting Date";
        PriceSource."Ending Date" := Campaign."Ending Date";
    end;
}
