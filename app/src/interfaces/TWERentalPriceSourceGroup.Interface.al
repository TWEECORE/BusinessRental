/// <summary>
/// Interface 50002 Rental Price Source Group."
/// </summary>
interface 50002 Rental Price Source Group"
{

    /// <summary>
    /// IsSourceTypeSupported.
    /// </summary>
    /// <param name="SourceType">Enum 50002 Rental Price Source Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsSourceTypeSupported(SourceType: Enum 50002 Rental Price Source Type"): Boolean;

    /// <summary>
    /// Some of source types are mapped to the price source groups that is used in setup. 
    /// If the source type does not belong to one group then it returns group All.
    /// </summary>
    /// <returns>the source group.</returns>
    procedure GetGroup() SourceGroup: Enum 50002 Rental Price Source Group";
}
