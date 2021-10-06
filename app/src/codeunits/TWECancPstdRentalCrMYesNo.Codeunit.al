codeunit 50005 "TWE CancPstdRentalCrM(Yes/No)"
{
    Permissions = TableData "TWE Rental Invoice Header" = rm,
                  TableData "TWE Rental Cr.Memo Header" = rm;
    TableNo = "TWE Rental Cr.Memo Header";

    trigger OnRun()
    begin
        CancelCrMemo(Rec);
    end;

    var
        CancelPostedCrMemoQst: Label 'The posted sales credit memo will be canceled, and a sales invoice will be created and posted, which reverses the posted sales credit memo. Do you want to continue?';
        OpenPostedInvQst: Label 'The invoice was successfully created. Do you want to open the posted invoice?';

    local procedure CancelCrMemo(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"): Boolean
    var
        RentalInvHeader: Record "TWE Rental Invoice Header";
        CancelledDocument: Record "Cancelled Document";
        CancelPostedRentalCrMemo: Codeunit "TWE Cancel Pstd. Rent.Cr. Memo";
    begin
        CancelPostedRentalCrMemo.TestCorrectCrMemoIsAllowed(RentalCrMemoHeader);
        if Confirm(CancelPostedCrMemoQst) then
            if CancelPostedRentalCrMemo.CancelPostedCrMemo(RentalCrMemoHeader) then
                if Confirm(OpenPostedInvQst) then begin
                    CancelledDocument.FindSalesCancelledCrMemo(RentalCrMemoHeader."No.");
                    RentalInvHeader.Get(CancelledDocument."Cancelled By Doc. No.");
                    PAGE.Run(PAGE::"Posted Sales Invoice", RentalInvHeader);
                    exit(true);
                end;

        exit(false);
    end;
}

