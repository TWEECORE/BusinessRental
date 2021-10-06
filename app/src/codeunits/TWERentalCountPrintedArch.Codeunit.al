/// <summary>
/// Codeunit TWE RentalCount-PrintedArch (ID 70704668).
/// </summary>
codeunit 50017 "TWE RentalCount-PrintedArch"
{
    TableNo = "TWE Rental Header Archive";

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
    local procedure OnBeforeModify(var RentalHeaderArchive: Record "TWE Rental Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RentalHeaderArchive: Record "TWE Rental Header Archive"; var SuppressCommit: Boolean)
    begin
    end;
}

