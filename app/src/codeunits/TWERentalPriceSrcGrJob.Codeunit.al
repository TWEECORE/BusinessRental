/// <summary>
/// Codeunit TWE Rental Price Src Gr. - Job (ID 70704656) implements Interface TWE Rental Price Source Group.
/// </summary>
codeunit 50049 "TWE Rental Price Src Gr. - Job" implements "TWE Rental Price Source Group"
{
    var
        JobSourceType: Enum "Job Price Source Type";

    /// <summary>
    /// IsSourceTypeSupported.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsSourceTypeSupported(SourceType: Enum "TWE Rental Price Source Type"): Boolean;
    var
        Ordinals: list of [Integer];
    begin
        Ordinals := JobSourceType.Ordinals();
        exit(Ordinals.Contains(SourceType.AsInteger()))
    end;

    /// <summary>
    /// GetGroup.
    /// </summary>
    /// <returns>Return variable SourceGroup of type Enum "TWE Rental Price Source Group".</returns>
    procedure GetGroup() SourceGroup: Enum "TWE Rental Price Source Group";
    begin
        exit(SourceGroup::Job);
    end;
}
