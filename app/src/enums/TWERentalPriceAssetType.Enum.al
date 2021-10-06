/// <summary>
/// Enum TWE Rental Price Asset Type (ID 7004) implements Interface TWE Rental Price Asset.
/// </summary>
enum 50006 "TWE Rental Price Asset Type" implements "TWE Rental Price Asset"
{
    Extensible = true;
    value(0; " ")
    {
        Caption = '(All)';
        Implementation = "TWE Rental Price Asset" = "TWE Rental Price Asset - All";
    }
    value(1; "Rental Item")
    {
        Caption = 'Rental Item';
        Implementation = "TWE Rental Price Asset" = "TWE Price Asset - Rental Item";
    }
    value(2; "Rental Item Discount Group")
    {
        Caption = 'Rental Item Discount Group';
        Implementation = "TWE Rental Price Asset" = "TWE Price Asset - Rental Item";
    }
    value(3; Resource)
    {
        Caption = 'Resource';
        Implementation = "TWE Rental Price Asset" = "TWE Price Asset - Rental Item";
    }
}
