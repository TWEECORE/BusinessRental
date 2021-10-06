/// <summary>
/// Table Rental Comment Line Archive (ID 50003).
/// </summary>
table 50003 "TWE Rental Comment Line Arch."
{
    Caption = 'Rental Comment Line Archive';
    DrillDownPageID = "TWE Rental Arch. Comment Sheet";
    LookupPageID = "TWE Rental Arch. Comment Sheet";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Quote,Contract,Invoice,Credit Memo,Return Shipment,Posted Invoice,Posted Credit Memo,Posted Return Shipment';
            OptionMembers = Quote,"Contract",Invoice,"Credit Memo","Return Shipment","Posted Invoice","Posted Credit Memo","Posted Return Shipment";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(4; "Date"; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
        }
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            DataClassification = CustomerContent;
        }
        field(8; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
            DataClassification = CustomerContent;
        }
        field(9; "Version No."; Integer)
        {
            Caption = 'Version No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// SetUpNewLine.
    /// </summary>
    procedure SetUpNewLine()
    var
        RentalCommentLine: Record "TWE Rental Comment Line Arch.";
    begin
        RentalCommentLine.SetRange("Document Type", "Document Type");
        RentalCommentLine.SetRange("No.", "No.");
        RentalCommentLine.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        RentalCommentLine.SetRange("Version No.", "Version No.");
        RentalCommentLine.SetRange("Document Line No.", "Line No.");
        RentalCommentLine.SetRange(Date, WorkDate());
        if RentalCommentLine.IsEmpty() then
            Date := WorkDate();
    end;
}

