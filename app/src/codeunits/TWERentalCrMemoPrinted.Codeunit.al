/// <summary>
/// Codeunit TWE Rental Cr. Memo-Printed (ID 50018).
/// </summary>
codeunit 50018 "TWE Rental Cr. Memo-Printed"
{
    Permissions = TableData "TWE Rental Cr.Memo Header" = rimd;
    TableNo = "TWE Rental Cr.Memo Header";

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
    local procedure OnBeforeModify(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var SuppressCommit: Boolean)
    begin
    end;
}

