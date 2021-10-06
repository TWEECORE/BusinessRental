codeunit 50008 "TWE Corr.PstdRentalInv(Yes/No)"
{
    Permissions = TableData "TWE Rental Invoice Header" = rm,
                  TableData "TWE Rental Cr.Memo Header" = rm;
    TableNo = "TWE Rental Invoice Header";

    trigger OnRun()
    begin
        CorrectInvoice(Rec);
    end;

    var
        CorrectPostedInvoiceQst: Label 'The posted sales invoice will be canceled, and a new version of the sales invoice will be created so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromSingleOrderQst: Label 'The invoice was posted from an order. The invoice will be cancelled, and the order will open so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromDeletedOrderQst: Label 'The invoice was posted from an order. The order has been deleted, and the invoice will be cancelled. You can create a new invoice or order by using the Copy Document action.\ \Do you want to continue?';
        CorrectPostedInvoiceFromMultipleOrderQst: Label 'The invoice was posted from multiple orders. It will now be cancelled, and you can make a correction manually in the original orders.\ \Do you want to continue?';

    procedure CorrectInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"): Boolean
    var
        RentalHeader: Record "TWE Rental Header";
        CorrectPostedRentalInvoice: Codeunit "TWE Correct Pstd. Rent. Inv.";
        RelatedOrderNo: Code[20];
        MultipleOrderRelated: Boolean;
        RentalHeaderExists: Boolean;
    begin
        CorrectPostedRentalInvoice.TestCorrectInvoiceIsAllowed(RentalInvoiceHeader, false);
        GetRelatedOrder(RentalInvoiceHeader, RelatedOrderNo, MultipleOrderRelated);
        if RelatedOrderNo = '' then
            exit(CancelPostedInvoiceAndOpenNewSalesInvoice(RentalInvoiceHeader));

        RentalHeaderExists := RentalHeader.Get(RentalHeader."Document Type"::Contract, RelatedOrderNo);
        case true of
            MultipleOrderRelated:
                exit(CancelPostedInvoice(RentalInvoiceHeader, Format(CorrectPostedInvoiceFromMultipleOrderQst)));
            not RentalHeaderExists:
                exit(CancelPostedInvoice(RentalInvoiceHeader, Format(CorrectPostedInvoiceFromDeletedOrderQst)));
            else
                exit(CancelPostedInvoiceAndOpenRentalContract(RentalInvoiceHeader, RentalHeader))
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoiceAndOpenNewSalesInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"): Boolean
    var
        RentalHeader: Record "TWE Rental Header";
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedRentalInvoice: Codeunit "TWE Correct Pstd. Rent. Inv.";
        IsHandled: Boolean;
    begin
        if ConfirmManagement.GetResponse(CorrectPostedInvoiceQst, false) then begin
            CorrectPostedRentalInvoice.CancelPostedInvoiceCreateNewInvoice(RentalInvoiceHeader, RentalHeader);
            IsHandled := false;
            OnCorrectInvoiceOnBeforeOpenSalesInvoicePage(RentalHeader, IsHandled);
            if not IsHandled then
                PAGE.Run(PAGE::"TWE Rental Invoice", RentalHeader);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoiceAndOpenRentalContract(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalHeader: Record "TWE Rental Header"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedRentalInvoice: Codeunit "TWE Correct Pstd. Rent. Inv.";
        IsHandled: Boolean;
    begin
        if ConfirmManagement.GetResponse(CorrectPostedInvoiceFromSingleOrderQst, false) then begin
            if not CorrectPostedRentalInvoice.CancelPostedInvoice(RentalInvoiceHeader) then
                exit(false);

            RentalHeader.Find();
            OnCorrectInvoiceOnBeforeOpenSalesOrderPage(RentalHeader, IsHandled);
            if not IsHandled then
                PAGE.Run(PAGE::"TWE Rental Contract", RentalHeader);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; ConfirmationText: Text): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedRentalInvoice: Codeunit "TWE Correct Pstd. Rent. Inv.";
    begin
        if ConfirmManagement.GetResponse(ConfirmationText, true) then
            exit(CorrectPostedRentalInvoice.CancelPostedInvoice(RentalInvoiceHeader));

        exit(false);
    end;

    local procedure GetRelatedOrder(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RelatedOrderNo: Code[20]; var MultipleOrderRelated: Boolean)
    var
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
    begin
        MultipleOrderRelated := false;
        RelatedOrderNo := '';

        RentalInvoiceLine.SetRange("Document No.", RentalInvoiceHeader."No.");
        RentalInvoiceLine.SetFilter("Order No.", '<>''''');
        if RentalInvoiceLine.FindFirst() then begin
            RelatedOrderNo := RentalInvoiceLine."Order No.";
            RentalInvoiceLine.SetFilter("Order No.", '<>''''&<>%1', RentalInvoiceLine."Order No.");
            MultipleOrderRelated := not RentalInvoiceLine.IsEmpty();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectInvoiceOnBeforeOpenSalesInvoicePage(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectInvoiceOnBeforeOpenSalesOrderPage(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;
}

