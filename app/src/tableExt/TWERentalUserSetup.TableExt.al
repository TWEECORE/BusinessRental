tableextension 50011 "TWE Rental User Setup" extends "User Setup"
{
    fields
    {
        field(70704600; "TWE Rent. Amount Appr. Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Rental Amount Approval Limit';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "TWE Unlimited Rental Approval" and ("TWE Rent. Amount Appr. Limit" <> 0) then
                    Error(Text003Lbl, FieldCaption("TWE Rent. Amount Appr. Limit"), FieldCaption("TWE Unlimited Rental Approval"));
                if "TWE Rent. Amount Appr. Limit" < 0 then
                    Error(Text005Lbl);
            end;
        }
        field(70704601; "TWE Unlimited Rental Approval"; Boolean)
        {
            Caption = 'Unlimited Rental Approval';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "TWE Unlimited Rental Approval" then
                    "TWE Rent. Amount Appr. Limit" := 0;
            end;
        }
    }

    var
        Text003Lbl: Label 'You cannot have both a %1 and %2.', Comment = '%1 FieldCaption "TWE Rent. Amount Appr. Limit" %2 FieldCaption "TWE Unlimited Rental Approval"';
        Text005Lbl: Label 'You cannot have approval limits less than zero.';
}
