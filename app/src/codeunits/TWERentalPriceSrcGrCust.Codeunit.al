/// <summary>
/// Codeunit TWE Rental Price Src Gr.-Cust (ID 70704655) implements Interface TWE Rental Price Source Group.
/// </summary>
codeunit 50048 "TWE Rental Price Src Gr.-Cust" implements "TWE Rental Price Source Group"
{
    var
        SalesSourceType: Enum "Sales Price Source Type";

    /// <summary>
    /// IsSourceTypeSupported.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsSourceTypeSupported(SourceType: Enum "TWE Rental Price Source Type"): Boolean;
    var
        Ordinals: list of [Integer];
    begin
        Ordinals := SalesSourceType.Ordinals();
        exit(Ordinals.Contains(SourceType.AsInteger()))
    end;

    /// <summary>
    /// GetGroup.
    /// </summary>
    /// <returns>Return variable SourceGroup of type Enum "TWE Rental Price Source Group".</returns>
    procedure GetGroup() SourceGroup: Enum "TWE Rental Price Source Group";
    begin
        exit(SourceGroup::Customer);
    end;
}
