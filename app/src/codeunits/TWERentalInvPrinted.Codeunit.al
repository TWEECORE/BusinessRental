/// <summary>
/// Codeunit TWE Rental Inv.-Printed (ID 70704670).
/// </summary>
codeunit 50024 "TWE Rental Inv.-Printed"
{
    Permissions = TableData "TWE Rental Invoice Header" = rimd;
    TableNo = "TWE Rental Invoice Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    /// <summary>
    /// SetSuppressCommit.
    /// </summary>
    /// <param name="NewSuppressCommit">Boolean.</param>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var SuppressCommit: Boolean)
    begin
    end;
}

