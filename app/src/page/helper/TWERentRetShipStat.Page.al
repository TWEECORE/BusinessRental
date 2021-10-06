/// <summary>
/// Page TWE Rent. Ret.-Ship. Stat. (ID 70704662).
/// </summary>
page 50021 "TWE Rent. Ret.-Ship. Stat."
{
    Caption = 'Rental Return Shipment Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "TWE Rental Return Ship. Header";

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
        RentalReturnShptLine: Record "TWE Rental Return Ship. Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(Rec, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        RentalReturnShptLine.SetRange("Document No.", Rec."No.");
        if RentalReturnShptLine.Find('-') then
            repeat
                LineQty += RentalReturnShptLine.Quantity;
                TotalNetWeight += RentalReturnShptLine.Quantity * RentalReturnShptLine."Net Weight";
                TotalGrossWeight += RentalReturnShptLine.Quantity * RentalReturnShptLine."Gross Weight";
                TotalVolume += RentalReturnShptLine.Quantity * RentalReturnShptLine."Unit Volume";
                if RentalReturnShptLine."Units per Parcel" > 0 then
                    TotalParcels += Round(RentalReturnShptLine.Quantity / RentalReturnShptLine."Units per Parcel", 1, '>');
                OnCalculateTotalsOnAfterAddLineTotals(
                    RentalReturnShptLine, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels)
            until RentalReturnShptLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(RentalReturnShipmentHeader: Record "TWE Rental Return Ship. Header"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var RentalReturnShipmentLine: Record "TWE Rental Return Ship. Line"; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;
}

