/// <summary>
/// Page TWE Post. Rent. Ship. - Update (ID 50002).
/// </summary>
page 50002 "TWE Post. Rent. Ship. - Update"
{
    Caption = 'TWE Posted Rental Ship. - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "TWE Rental Shipment Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Rented-to Customer Name"; Rec."Rented-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the Rented-to address.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent is used to transport the items on the rental document to the customer.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Agent Service';
                    Editable = true;
                    ToolTip = 'Specifies which shipping agent service is used to transport the items on the rental document to the customer.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Suite;
                    Editable = true;
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xRentalShipmentHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"TWE Rental Ship. Header - Edit", Rec);
    end;

    var
        xRentalShipmentHeader: Record "TWE Rental Shipment Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged :=
          (Rec."Shipping Agent Code" <> xRentalShipmentHeader."Shipping Agent Code") or
          (Rec."Package Tracking No." <> xRentalShipmentHeader."Package Tracking No.") or
          (Rec."Shipping Agent Service Code" <> xRentalShipmentHeader."Shipping Agent Service Code");

        OnAfterRecordChanged(Rec, xRentalShipmentHeader, IsChanged);
    end;

    /// <summary>
    /// SetRec.
    /// </summary>
    /// <param name="RentalShipmentHeader">Record "TWE Rental Shipment Header".</param>
    procedure SetRec(RentalShipmentHeader: Record "TWE Rental Shipment Header")
    begin
        Rec := RentalShipmentHeader;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var RentalShipmentHeader: Record "TWE Rental Shipment Header"; xRentalShipmentHeader: Record "TWE Rental Shipment Header"; var IsChanged: Boolean)
    begin
    end;
}

