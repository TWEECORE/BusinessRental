/// <summary>
/// Codeunit TWE Rental-Printed (ID 50053).
/// </summary>
codeunit 50053 "TWE Rental-Printed"
{
    TableNo = "TWE Rental Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        OnBeforeModify(Rec);
        Rec.Modify();
        if not SuppressCommit then
            Commit();
        OnAfterOnRun(Rec);
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
    local procedure OnAfterOnRun(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RentalHeader: Record "TWE Rental Header"; var SuppressCommit: Boolean)
    begin
    end;
}

