/// <summary>
/// Interface 50004 Rent Price Calculation."
/// </summary>
interface 50004 Rent Price Calculation"
{

    /// <summary>
    /// Init.
    /// </summary>
    /// <param name="LineWithPrice">Interface 50004 Rent Line With Price".</param>
    /// <param name="PriceCalculationSetup">Record "Price Calculation Setup".</param>
    procedure Init(LineWithPrice: Interface 50004 Rent Line With Price"; PriceCalculationSetup: Record 50004 Rental Price Calc. Setup")

    /// <summary>
    /// After the calculation is done by calling ApplyPrice() or ApplyDiscount() 
    /// the updated line is retrieved by this method. 
    /// </summary>
    /// <param name="Line">The updated source line.</param>
    procedure GetLine(var Line: Variant)

    /// <summary>
    /// Executes the calcluation of the discount amount. 
    /// </summary>
    procedure ApplyDiscount()

    /// <summary>
    /// Executes the calculation of the price or cost.
    /// </summary>
    /// <param name="CalledByFieldNo">The id of the field that caused the calculation.</param>
    procedure ApplyPrice(CalledByFieldNo: Integer)

    /// <summary>
    /// Returns the number of price list lines with discounts that fit the source line.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>Number of price list lines with discounts that fit the source line.</returns>
    procedure CountDiscount(ShowAll: Boolean) Result: Integer;

    /// <summary>
    /// Returnes the number of price list lines with prices that fit the source line.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>Number of price list lines with prices that fit the source line.</returns>
    procedure CountPrice(ShowAll: Boolean) Result: Integer;

    /// <summary>
    /// Returns the list of price list lines with discount that fit the source line.
    /// </summary>
    /// <param name="TempRentalPriceListLine">VAR Record 50004 Rental Price List Line".</param>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure FindDiscount(var TempRentalPriceListLine: Record 50004 Rental Price List Line"; ShowAll: Boolean) Found: Boolean;

    /// <summary>
    /// FindPrice.
    /// </summary>
    /// <param name="TempRentalPriceListLine">VAR Record 50004 Rental Price List Line".</param>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return variable Found of type Boolean.</returns>
    procedure FindPrice(var TempRentalPriceListLine: Record 50004 Rental Price List Line"; ShowAll: Boolean) Found: Boolean;

    /// <summary>
    /// Returns true if exists any price list line with discount that fit the source line. 
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure IsDiscountExists(ShowAll: Boolean) Result: Boolean;

    /// <summary>
    /// Returns true if exists any price list line with price or cost that fit the source line. 
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>true if any price list line is found</returns>
    procedure IsPriceExists(ShowAll: Boolean) Result: Boolean;

    /// <summary>
    /// Allows to pick from the list of price list lines with disocunt that fit the source line.
    /// </summary>
    procedure PickDiscount()

    /// <summary>
    /// Allows to pick from the list of price list lines with price or cost that fit the source line.
    /// </summary>
    procedure PickPrice()

    /// <summary>
    /// Opens the list page for reviewing existing prices. 
    /// </summary>
    /// <param name="TempRentalPriceListLine">The buffer with the found price list lines.</param>
    procedure ShowPrices(var TempRentalPriceListLine: Record 50004 Rental Price List Line")
}
