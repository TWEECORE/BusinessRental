/// <summary>
/// Interface 50001 Rental Price Source."
/// </summary>
interface 50001 Rental Price Source"
{
    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceSource">....</param>
    /// <returns>  .</returns>
    procedure GetNo(var PriceSource: Record 50001 Rental Price Source")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceSource">....</param>
    /// <returns>  .</returns>
    procedure GetId(var PriceSource: Record 50001 REntal Price Source")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="AmountType">....</param>
    /// <returns>  .</returns>
    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceSource">....</param>
    /// <returns>  .</returns>
    procedure IsLookupOK(var PriceSource: Record 50001 Rental Price Source"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceSource">....</param>
    /// <returns>  .</returns>
    procedure VerifyParent(var PriceSource: Record 50001 Rental Price Source") Result: Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <returns>  .</returns>
    procedure IsSourceNoAllowed() Result: Boolean;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="PriceSource">....</param>
    /// <returns>  .</returns>
    procedure GetGroupNo(PriceSource: Record 50001 Rental Price Source"): Code[20];
}
