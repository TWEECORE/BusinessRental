/// <summary>
/// Enum TWE Rental Price Source Type (ID 70704611) implements Interface TWE Rental Price Source, Price Source Group.
/// </summary>
enum 50008 "TWE Rental Price Source Type" implements "TWE Rental Price Source", "TWE Rental Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Caption = '(All)';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Src. - All", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - All";
    }
    value(10; "All Customers")
    {
        Caption = 'All Customers';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Src. - All", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr.-Cust";
    }
    value(11; Customer)
    {
        Caption = 'Customer';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Source - Cust", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr.-Cust";
    }
    value(12; "Customer Price Group")
    {
        Caption = 'Customer Price Group';
        Implementation = "TWE Rental Price Source" = "TWE Rental PrSrc.-Cust.DiscGr.", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr.-Cust";
    }
    value(13; "Customer Disc. Group")
    {
        Caption = 'Customer Disc. Group';
        Implementation = "TWE Rental Price Source" = "TWE Rental PrSrc.-Cust.DiscGr.", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr.-Cust";
    }
    value(30; "All Jobs")
    {
        Caption = 'All Jobs';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Src. - All", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - Job";
    }
    value(31; Job)
    {
        Caption = 'Job';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Src. - Job", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - Job";
    }
    value(32; "Job Task")
    {
        Caption = 'Job Task';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Src.-Job Task", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - Job";
    }
    value(50; Campaign)
    {
        Caption = 'Campaign';
        Implementation = "TWE Rental Price Source" = "TWE Rental Price Src.-Campaign", "TWE Rental Price Source Group" = "TWE Rental Price Src Gr. - All";
    }
}
