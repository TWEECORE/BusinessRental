table 50000 "TWE Cancelled Rental Document"
{
    Caption = 'Cancelled Rental Document';
    Permissions = TableData "TWE Cancelled Rental Document" = rimd;

    fields
    {
        field(1; "Source ID"; Integer)
        {
            Caption = 'Source ID';
            DataClassification = CustomerContent;
        }
        field(2; "Cancelled Doc. No."; Code[20])
        {
            Caption = 'Cancelled Doc. No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Source ID" = CONST(70704615)) "TWE Rental Invoice Header"."No."
            ELSE
            IF ("Source ID" = CONST(70704617)) "TWE Rental Cr.Memo Header"."No.";
        }
        field(3; "Cancelled By Doc. No."; Code[20])
        {
            Caption = 'Cancelled By Doc. No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Source ID" = CONST(70704615)) "TWE Rental Invoice Header"."No."
            ELSE
            IF ("Source ID" = CONST(70704617)) "TWE Rental Cr.Memo Header"."No.";
        }
    }

    keys
    {
        key(Key1; "Source ID", "Cancelled Doc. No.")
        {
            Clustered = true;
        }
        key(Key2; "Cancelled By Doc. No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InsertRentalInvToCrMemoCancelledDocument(InvNo: Code[20]; CrMemoNo: Code[20])
    begin
        InsertEntry(DATABASE::"TWE Rental Invoice Header", InvNo, CrMemoNo);
    end;

    procedure InsertRentalCrMemoToInvCancelledDocument(CrMemoNo: Code[20]; InvNo: Code[20])
    begin
        InsertEntry(DATABASE::"TWE Rental Cr.Memo Header", CrMemoNo, InvNo);
        RemoveRentalInvCancelledDocument();
    end;

    local procedure InsertEntry(SourceID: Integer; CanceledDocNo: Code[20]; CanceledByDocNo: Code[20])
    begin
        Init();
        Validate("Source ID", SourceID);
        Validate("Cancelled Doc. No.", CanceledDocNo);
        Validate("Cancelled By Doc. No.", CanceledByDocNo);
        Insert(true);
    end;

    local procedure RemoveRentalInvCancelledDocument()
    begin
        FindRentalCorrectiveCrMemo("Cancelled Doc. No.");
        DeleteAll(true);
    end;

    procedure FindRentalCancelledInvoice(CanceledDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledDocNo(DATABASE::"TWE Rental Invoice Header", CanceledDocNo));
    end;

    procedure FindRentalCorrectiveInvoice(CanceledByDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledByDocNo(DATABASE::"TWE Rental Cr.Memo Header", CanceledByDocNo));
    end;

    procedure FindRentalCorrectiveCrMemo(CanceledByDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledByDocNo(DATABASE::"TWE Rental Invoice Header", CanceledByDocNo));
    end;

    procedure FindRentalCancelledCrMemo(CanceledDocNo: Code[20]): Boolean
    begin
        exit(FindWithCancelledDocNo(DATABASE::"TWE Rental Cr.Memo Header", CanceledDocNo));
    end;

    local procedure FindWithCancelledDocNo(SourceID: Integer; CanceledDocNo: Code[20]): Boolean
    begin
        exit(Get(SourceID, CanceledDocNo));
    end;

    local procedure FindWithCancelledByDocNo(SourceID: Integer; CanceledByDocNo: Code[20]): Boolean
    begin
        Reset();
        SetRange("Source ID", SourceID);
        SetRange("Cancelled By Doc. No.", CanceledByDocNo);
        exit(FindFirst());
    end;
}

