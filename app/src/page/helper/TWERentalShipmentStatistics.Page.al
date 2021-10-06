/// <summary>
/// Page TWE Rental Shipment Statistics (ID 50017).
/// </summary>
page 50017 "TWE Rental Shipment Statistics"
{
    Caption = 'Rental Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "TWE Rental Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the rental document that were shipped.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels shipped from the rental document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items shipped from the rental document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items shipped from the rental document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items shipped from the rental document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll();

        CalculateTotals();
    end;

    var
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;

    local procedure CalculateTotals()
    var
        RentalShptLine: Record "TWE Rental Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(Rec, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        RentalShptLine.SetRange("Document No.", Rec."No.");
        if RentalShptLine.Find('-') then
            repeat
                LineQty += RentalShptLine.Quantity;
                TotalNetWeight += RentalShptLine.Quantity * RentalShptLine."Net Weight";
                TotalGrossWeight += RentalShptLine.Quantity * RentalShptLine."Gross Weight";
                TotalVolume += RentalShptLine.Quantity * RentalShptLine."Unit Volume";
                if RentalShptLine."Units per Parcel" > 0 then
                    TotalParcels += Round(RentalShptLine.Quantity / RentalShptLine."Units per Parcel", 1, '>');
                OnCalculateTotalsOnAfterAddLineTotals(
                    RentalShptLine, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels)
            until RentalShptLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(RentalShipmentHeader: Record "TWE Rental Shipment Header"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;
}

