/// <summary>
/// Codeunit TWE Rental Price Src Gr. - All (ID 70704653) implements Interface TWE Rental Price Source Group.
/// </summary>
codeunit 50047 "TWE Rental Price Src Gr. - All" implements "TWE Rental Price Source Group"
{
    /// <summary>
    /// IsSourceTypeSupported.
    /// </summary>
    /// <param name="SourceType">Enum "TWE Rental Price Source Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsSourceTypeSupported(SourceType: Enum "TWE Rental Price Source Type"): Boolean;
    begin
        exit(true)
    end;

    /// <summary>
    /// GetGroup.
    /// </summary>
    /// <returns>Return variable SourceGroup of type Enum "TWE Rental Price Source Group".</returns>
    procedure GetGroup() SourceGroup: Enum "TWE Rental Price Source Group";
    begin
        exit(SourceGroup::All);
    end;
}
