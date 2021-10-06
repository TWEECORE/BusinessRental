codeunit 50004 "TWE CancelPstdRentInv(Yes/No)"
{
    Permissions = TableData "TWE Rental Invoice Header" = rm,
                  TableData "TWE Rental Cr.Memo Header" = rm;
    TableNo = "TWE Rental Invoice Header";

    trigger OnRun()
    begin
        CancelInvoice(Rec);
    end;

    var
        CancelPostedInvoiceQst: Label 'The posted sales invoice will be canceled, and a sales credit memo will be created and posted, which reverses the posted sales invoice.\ \Do you want to continue?';
        OpenPostedCreditMemoQst: Label 'A credit memo was successfully created. Do you want to open the posted credit memo?';

    procedure CancelInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"): Boolean
    var
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        CancelledRentalDocument: Record "TWE Cancelled Rental Document";
        CorrectPostedRentalInvoice: Codeunit "TWE Correct Pstd. Rent. Inv.";
    begin
        CorrectPostedRentalInvoice.TestCorrectInvoiceIsAllowed(RentalInvoiceHeader, true);
        if Confirm(CancelPostedInvoiceQst) then
            if CorrectPostedRentalInvoice.CancelPostedInvoice(RentalInvoiceHeader) then
                if Confirm(OpenPostedCreditMemoQst) then begin
                    CancelledRentalDocument.FindRentalCancelledInvoice(RentalInvoiceHeader."No.");
                    RentalCrMemoHeader.Get(CancelledRentalDocument."Cancelled By Doc. No.");
                    PAGE.Run(PAGE::"TWE Posted Rental Credit Memo", RentalCrMemoHeader);
                    exit(true);
                end;

        exit(false);
    end;
}

