/// <summary>
/// Enum TWE Price Source Group (ID 50007) implements Interface TWE Rental Price Source Group.
/// </summary>
enum 50007 "TWE Rental Price Source Group" implements "TWE Rental Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Caption = '(All)';
        Implementation = "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - All";
    }
    value(11; Customer)
    {
        Caption = 'Customer';
        Implementation = "TWE Rental Price Source Group" = "TWE Rental Price Src Gr.-Cust";
    }
    value(31; Job)
    {
        Caption = 'Job';
        Implementation = "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - Job";
    }
}
