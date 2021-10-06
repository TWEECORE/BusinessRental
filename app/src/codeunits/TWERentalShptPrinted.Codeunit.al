/// <summary>
/// Codeunit TWE Rental Shpt.-Printed (ID 50058).
/// </summary>
codeunit 50058 "TWE Rental Shpt.-Printed"
{
    Permissions = TableData "TWE Rental Shipment Header" = rimd;
    TableNo = "TWE Rental Shipment Header";

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
    local procedure OnBeforeModify(var RentalShipmentHeader: Record "TWE Rental Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var SuppressCommit: Boolean)
    begin
    end;
}

