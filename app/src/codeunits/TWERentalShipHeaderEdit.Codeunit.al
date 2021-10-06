/// <summary>
/// Codeunit TWE Rental Ship. Header - Edit (ID 50057).
/// </summary>
codeunit 50057 "TWE Rental Ship. Header - Edit"
{
    Permissions = TableData "TWE Rental Shipment Header" = rm;
    TableNo = "TWE Rental Shipment Header";

    trigger OnRun()
    begin
        RentalShptHeader := Rec;
        RentalShptHeader.LockTable();
        RentalShptHeader.Find();
        RentalShptHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        RentalShptHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        RentalShptHeader."Package Tracking No." := Rec."Package Tracking No.";
        OnBeforeRentalShptHeaderModify(RentalShptHeader, Rec);
        RentalShptHeader.TestField("No.", Rec."No.");
        RentalShptHeader.Modify();
        Rec := RentalShptHeader;
    end;

    var
        RentalShptHeader: Record "TWe Rental Shipment Header";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalShptHeaderModify(var RentalShptHeader: Record "TWE Rental Shipment Header"; FromRentalShptHeader: Record "TWE Rental Shipment Header")
    begin
    end;
}

