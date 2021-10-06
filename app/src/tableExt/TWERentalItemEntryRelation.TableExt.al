tableextension 50008 "TWE Rental Item Entry Relation" extends "Item Entry Relation"
{
    procedure TransferFieldsRentalShptLine(var RentalShptLine: Record "TWE Rental Shipment Line")
    begin
        SetSource(DATABASE::"TWE Rental Shipment Line", 0, RentalShptLine."Document No.", RentalShptLine."Line No.");
        SetOrderInfo(RentalShptLine."Order No.", RentalShptLine."Order Line No.");
    end;
}
