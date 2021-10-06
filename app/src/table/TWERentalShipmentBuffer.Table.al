/// <summary>
/// Table TWE Rental Shipment Buffer (ID 70704660).
/// </summary>
table 50031 "TWE Rental Shipment Buffer"
{
    Caption = 'Rental Shipment Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            TableRelation = "TWE Rental Invoice Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST(Item)) Item
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge";
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Posting Date")
        {
        }
    }

    var
        UOMMgt: Codeunit "Unit of Measure Management";
        NextEntryNo: Integer;

    /// <summary>
    /// GetLinesForRentalInvoiceLine.
    /// </summary>
    /// <param name="RentalInvoiceLine">VAR Record "TWE Rental Invoice Line".</param>
    /// <param name="RentalInvoiceHeader">VAR Record "TWE Rental Invoice Header".</param>
    procedure GetLinesForRentalInvoiceLine(var RentalInvoiceLine: Record "TWE Rental Invoice Line"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        ValueEntry: Record "Value Entry";
    begin
        case RentalInvoiceLine.Type of
            RentalInvoiceLine.Type::"Rental Item":
                GenerateBufferFromValueEntry(
                  ValueEntry."Document Type"::"Rental Invoice",
                  RentalInvoiceLine."Document No.",
                  RentalInvoiceLine."Line No.",
                  RentalInvoiceLine.Type,
                  RentalInvoiceLine."No.",
                  RentalInvoiceHeader."Posting Date",
                  RentalInvoiceLine."Quantity (Base)",
                  RentalInvoiceLine."Qty. per Unit of Measure");
            RentalInvoiceLine.Type::"G/L Account", RentalInvoiceLine.Type::Resource:
                GenerateBufferFromShipment(RentalInvoiceLine, RentalInvoiceHeader);
        end;
    end;

    /// <summary>
    /// GetLinesForRentalCreditMemoLine.
    /// </summary>
    /// <param name="RentalCrMemoLine">Record "TWE Rental Cr.Memo Line".</param>
    /// <param name="RentalCrMemoHeader">Record "TWE Rental Cr.Memo Header".</param>
    procedure GetLinesForRentalCreditMemoLine(RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        ValueEntry: Record "Value Entry";
    begin
        case RentalCrMemoLine.Type of
            RentalCrMemoLine.Type::"Rental Item":
                GenerateBufferFromValueEntry(
                  ValueEntry."Document Type"::"Rental Credit Memo",
                  RentalCrMemoLine."Document No.",
                  RentalCrMemoLine."Line No.",
                  RentalCrMemoLine.Type,
                  RentalCrMemoLine."No.",
                  RentalCrMemoHeader."Posting Date",
                  -RentalCrMemoLine."Quantity (Base)",
                  RentalCrMemoLine."Qty. per Unit of Measure");
        /* SalesCrMemoLine.Type::"G/L Account", SalesCrMemoLine.Type::Resource,
          SalesCrMemoLine.Type::"Charge (Item)", SalesCrMemoLine.Type::"Fixed Asset":
             GenerateBufferFromReceipt(SalesCrMemoLine, SalesCrMemoHeader); */
        end;
    end;

    local procedure GenerateBufferFromValueEntry(ValueEntryDocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer; LineType: Enum "Sales Line Type"; ItemNo: Code[20]; PostingDate: Date; QtyBase: Decimal; QtyPerUOM: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        localQuantity: Decimal;
    begin
        TotalQuantity := QtyBase;
        ValueEntry.SetRange("Document Type", ValueEntryDocType);
        ValueEntry.SetRange("Document No.", DocNo);
        ValueEntry.SetRange("Document Line No.", DocLineNo);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetRange("Item No.", ItemNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if QtyPerUOM <> 0 then
                        localQuantity := Round(ValueEntry."Invoiced Quantity" / QtyPerUOM, UOMMgt.QtyRndPrecision())
                    else
                        localQuantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      Abs(localQuantity),
                      ItemLedgerEntry."Posting Date",
                      ItemLedgerEntry."Document No.",
                      DocLineNo, LineType, ItemNo);
                    TotalQuantity := TotalQuantity + ValueEntry."Invoiced Quantity";
                end;
            until (ValueEntry.Next() = 0) or (TotalQuantity = 0);
    end;

    local procedure GenerateBufferFromShipment(RentalInvoiceLine2: Record "TWE Rental Invoice Line"; RentalInvoiceHeader2: Record "TWE Rental Invoice Header")
    var
        RentalInvoiceHeader: Record "TWE Rental Invoice Header";
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
        RentalShipmentHeader: Record "TWE Rental Shipment Header";
        RentalShipmentLine: Record "TWE Rental Shipment Line";
        TotalQuantity: Decimal;
        localQuantity: Decimal;
    begin
        if RentalInvoiceHeader2."Order No." = '' then
            exit;

        TotalQuantity := 0;
        RentalInvoiceHeader.SetCurrentKey("Order No.");
        RentalInvoiceHeader.SetFilter("No.", '..%1', RentalInvoiceHeader2."No.");
        RentalInvoiceHeader.SetRange("Order No.", RentalInvoiceHeader2."Order No.");
        if RentalInvoiceHeader.FindSet() then
            repeat
                RentalInvoiceLine.SetRange("Document No.", RentalInvoiceHeader."No.");
                RentalInvoiceLine.SetRange("Line No.", RentalInvoiceLine2."Line No.");
                RentalInvoiceLine.SetRange(Type, RentalInvoiceLine2.Type);
                RentalInvoiceLine.SetRange("No.", RentalInvoiceLine2."No.");
                RentalInvoiceLine.SetRange("Unit of Measure Code", RentalInvoiceLine2."Unit of Measure Code");
                if not RentalInvoiceLine.IsEmpty then begin
                    RentalInvoiceLine.CalcSums(Quantity);
                    TotalQuantity += RentalInvoiceLine.Quantity;
                end;
            until RentalInvoiceHeader.Next() = 0;

        RentalShipmentLine.SetCurrentKey("Order No.", "Order Line No.", "Posting Date");
        RentalShipmentLine.SetRange("Order No.", RentalInvoiceHeader2."Order No.");
        RentalShipmentLine.SetRange("Order Line No.", RentalInvoiceLine2."Line No.");
        RentalShipmentLine.SetRange("Line No.", RentalInvoiceLine2."Line No.");
        RentalShipmentLine.SetRange(Type, RentalInvoiceLine2.Type);
        RentalShipmentLine.SetRange("No.", RentalInvoiceLine2."No.");
        RentalShipmentLine.SetRange("Unit of Measure Code", RentalInvoiceLine2."Unit of Measure Code");
        RentalShipmentLine.SetFilter(Quantity, '<>%1', 0);
        if RentalShipmentLine.FindSet() then
            repeat
                if RentalInvoiceHeader2."Get Shipment Used" then
                    CorrectShipment(RentalShipmentLine);
                if Abs(RentalShipmentLine.Quantity) <= Abs(TotalQuantity - RentalInvoiceLine2.Quantity) then
                    TotalQuantity := TotalQuantity - RentalShipmentLine.Quantity
                else begin
                    if Abs(RentalShipmentLine.Quantity) > Abs(TotalQuantity) then
                        RentalShipmentLine.Quantity := TotalQuantity;
                    localQuantity :=
                      RentalShipmentLine.Quantity - (TotalQuantity - RentalInvoiceLine2.Quantity);

                    TotalQuantity := TotalQuantity - RentalShipmentLine.Quantity;
                    RentalInvoiceLine.Quantity := RentalInvoiceLine.Quantity - localQuantity;

                    if RentalShipmentHeader.Get(RentalShipmentLine."Document No.") then
                        AddBufferEntry(
                          localQuantity,
                          RentalShipmentHeader."Posting Date",
                          RentalShipmentHeader."No.",
                          RentalInvoiceLine2."Line No.",
                          RentalInvoiceLine2.Type,
                          RentalInvoiceLine2."No.");
                end;
            until (RentalShipmentLine.Next() = 0) or (TotalQuantity = 0);
    end;

    /*   local procedure GenerateBufferFromReceipt(SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
      var
          SalesCrMemoHeader2: Record "Sales Cr.Memo Header";
          SalesCrMemoLine2: Record "Sales Cr.Memo Line";
          ReturnReceiptHeader: Record "Return Receipt Header";
          ReturnReceiptLine: Record "Return Receipt Line";
          TotalQuantity: Decimal;
          Quantity: Decimal;
      begin
          if SalesCrMemoHeader."Return Order No." = '' then
              exit;

          TotalQuantity := 0;
          SalesCrMemoHeader2.SetCurrentKey("Return Order No.");
          SalesCrMemoHeader2.SetFilter("No.", '..%1', SalesCrMemoHeader."No.");
          SalesCrMemoHeader2.SetRange("Return Order No.", SalesCrMemoHeader."Return Order No.");
          if SalesCrMemoHeader2.Find('-') then
              repeat
                  SalesCrMemoLine2.SetRange("Document No.", SalesCrMemoHeader2."No.");
                  SalesCrMemoLine2.SetRange("Line No.", SalesCrMemoLine."Line No.");
                  SalesCrMemoLine2.SetRange(Type, SalesCrMemoLine.Type);
                  SalesCrMemoLine2.SetRange("No.", SalesCrMemoLine."No.");
                  SalesCrMemoLine2.SetRange("Unit of Measure Code", SalesCrMemoLine."Unit of Measure Code");
                  SalesCrMemoLine2.CalcSums(Quantity);
                  TotalQuantity := TotalQuantity + SalesCrMemoLine2.Quantity;
              until SalesCrMemoHeader2.Next() = 0;

          ReturnReceiptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
          ReturnReceiptLine.SetRange("Return Order No.", SalesCrMemoHeader."Return Order No.");
          ReturnReceiptLine.SetRange("Return Order Line No.", SalesCrMemoLine."Line No.");
          ReturnReceiptLine.SetRange("Line No.", SalesCrMemoLine."Line No.");
          ReturnReceiptLine.SetRange(Type, SalesCrMemoLine.Type);
          ReturnReceiptLine.SetRange("No.", SalesCrMemoLine."No.");
          ReturnReceiptLine.SetRange("Unit of Measure Code", SalesCrMemoLine."Unit of Measure Code");
          ReturnReceiptLine.SetFilter(Quantity, '<>%1', 0);

          if ReturnReceiptLine.Find('-') then
              repeat
                  if SalesCrMemoHeader."Get Return Receipt Used" then
                      CorrectReceipt(ReturnReceiptLine);
                  if Abs(ReturnReceiptLine.Quantity) <= Abs(TotalQuantity - SalesCrMemoLine.Quantity) then
                      TotalQuantity := TotalQuantity - ReturnReceiptLine.Quantity
                  else begin
                      if Abs(ReturnReceiptLine.Quantity) > Abs(TotalQuantity) then
                          ReturnReceiptLine.Quantity := TotalQuantity;
                      Quantity :=
                        ReturnReceiptLine.Quantity - (TotalQuantity - SalesCrMemoLine.Quantity);

                      SalesCrMemoLine.Quantity := SalesCrMemoLine.Quantity - Quantity;
                      TotalQuantity := TotalQuantity - ReturnReceiptLine.Quantity;

                      if ReturnReceiptHeader.Get(ReturnReceiptLine."Document No.") then
                          AddBufferEntry(
                            Quantity,
                            ReturnReceiptHeader."Posting Date",
                            ReturnReceiptHeader."No.",
                            SalesCrMemoLine."Line No.",
                            SalesCrMemoLine.Type,
                            SalesCrMemoLine."No.");
                  end;
              until (ReturnReceiptLine.Next() = 0) or (TotalQuantity = 0);
      end; */

    local procedure AddBufferEntry(QtyOnShipment: Decimal; PostingDate: Date; ShipmentNo: Code[20]; DocLineNo: Integer; LineType: Enum "Sales Line Type"; ItemNo: Code[20])
    begin
        SetRange("Document No.", ShipmentNo);
        SetRange("Line No.", DocLineNo);
        SetRange("Posting Date", PostingDate);
        if FindFirst() then begin
            Quantity += QtyOnShipment;
            Modify();
            exit;
        end;

        NextEntryNo := NextEntryNo + 1;
        "Document No." := ShipmentNo;
        "Line No." := DocLineNo;
        "Entry No." := NextEntryNo;
        Type := LineType;
        "No." := ItemNo;
        Quantity := QtyOnShipment;
        "Posting Date" := PostingDate;
        Insert();
    end;

    local procedure CorrectShipment(var RentalShipmentLine: Record "TWE Rental Shipment Line")
    var
        RentalInvoiceLine: Record "TWE Rental Invoice Line";
    begin
        RentalInvoiceLine.SetCurrentKey("Shipment No.", "Shipment Line No.");
        RentalInvoiceLine.SetRange("Shipment No.", RentalShipmentLine."Document No.");
        RentalInvoiceLine.SetRange("Shipment Line No.", RentalShipmentLine."Line No.");
        RentalInvoiceLine.CalcSums(Quantity);
        RentalShipmentLine.Quantity := RentalShipmentLine.Quantity - RentalInvoiceLine.Quantity;
    end;

    // local procedure CorrectReceipt(var ReturnReceiptLine: Record "Return Receipt Line")
    // var
    //     SalesCrMemoLine: Record "Sales Cr.Memo Line";
    // begin
    //     SalesCrMemoLine.SetCurrentKey("Return Receipt No.", "Return Receipt Line No.");
    //     SalesCrMemoLine.SetRange("Return Receipt No.", ReturnReceiptLine."Document No.");
    //     SalesCrMemoLine.SetRange("Return Receipt Line No.", ReturnReceiptLine."Line No.");
    //     SalesCrMemoLine.CalcSums(Quantity);
    //     ReturnReceiptLine.Quantity := ReturnReceiptLine.Quantity - SalesCrMemoLine.Quantity;
    // end;
}

