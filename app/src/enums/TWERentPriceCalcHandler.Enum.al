/// <summary>
/// EnumExtension TWE Rent Price Type (ID 70704600) extends Record Price Type.
/// </summary>
enum 50012 "TWE Rent Price Calc Handler" implements "TWE Rent Price Calculation"
{
    value(70704600; Rent)
    {
        Caption = 'Business Rental', Locked = true;
        Implementation = "TWE Rent Price Calculation" = "TWE Rent Price Calculation";
    }
}
