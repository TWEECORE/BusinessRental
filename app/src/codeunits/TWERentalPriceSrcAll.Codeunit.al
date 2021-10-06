/// <summary>
/// Codeunit TWE Rental Price Src. - All (ID 70704657) implements Interface TWE Rental Price Source.
/// </summary>
codeunit 50045 "TWE Rental Price Src. - All" implements "TWE Rental Price Source"
{
    /// <summary>
    /// GetNo.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetNo(var PriceSource: Record "TWE Rental Price Source")
    begin
        PriceSource.InitSource();
    end;

    /// <summary>
    /// GetId.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    procedure GetId(var PriceSource: Record "TWE Rental Price Source")
    begin
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
        Result := false;
    end;

    /// <summary>
    /// IsLookupOK.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsLookupOK(var PriceSource: Record "TWE Rental Price Source"): Boolean
    begin
        exit(false)
    end;

    /// <summary>
    /// VerifyParent.
    /// </summary>
    /// <param name="PriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure VerifyParent(var PriceSource: Record "TWE Rental Price Source") Result: Boolean
    begin
        PriceSource.InitSource();
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
