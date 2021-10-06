codeunit 50062 "TWE Rental Upd. Curr. Factor"
{
    Permissions = TableData "TWE Rental Invoice Header" = rm,
                  TableData "TWE Rental Cr.Memo Header" = rm;

    trigger OnRun()
    begin
    end;

    procedure ModifyPostedRentalInvoice(var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
        RentalInvoiceHeader.Modify();
    end;

    procedure ModifyPostedRentalCreditMemo(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
        RentalCrMemoHeader.Modify();
    end;
}

