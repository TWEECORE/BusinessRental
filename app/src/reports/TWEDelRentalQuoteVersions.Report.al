/// <summary>
/// Report TWE Del. Rental Quote Versions (ID 50006).
/// </summary>
report 50006 "TWE Del. Rental Quote Versions"
{
    Caption = 'Delete Archived Rental Quote Versions';
    ProcessingOnly = true;

    dataset
    {
        dataitem("TWE Rental Header Archive"; "TWE Rental Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.", "Doc. No. Occurrence", "Version No.") WHERE("Document Type" = CONST(Quote));
            RequestFilterFields = "No.", "Date Archived", "Rented-to Customer No.";

            trigger OnAfterGetRecord()
            var
                RentalHeader: Record "TWE Rental Header";
            begin
                RentalHeader.SetRange("Document Type", RentalHeader."Document Type"::Quote);
                RentalHeader.SetRange("No.", "No.");
                RentalHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                if RentalHeader.IsEmpty() then begin
                    Delete(true);
                    DeletedDocuments += 1;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        DeletedDocuments := 0;
    end;

    trigger OnPostReport()
    begin
        Message(Text000Lbl, DeletedDocuments);
    end;

    var
        Text000Lbl: Label '%1 archived versions deleted.', Comment = '%1=Count of deleted documents';
        DeletedDocuments: Integer;
}

