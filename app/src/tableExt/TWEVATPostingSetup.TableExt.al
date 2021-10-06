tableextension 50013 "TWE VAT Posting Setup" extends "VAT Posting Setup"
{
    fields
    {
        field(70704600; "TWE Rental VAT Account"; Code[20])
        {
            Caption = 'Rental VAT Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(CopyStr(FieldCaption("TWE Rental VAT Account"), 1, 100));

                CheckGLAcc("TWE Rental VAT Account");
            end;
        }
    }
}
