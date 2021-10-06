/// <summary>
/// Table TWE Rental Shipment Line (ID 50033).
/// </summary>
table 50033 "TWE Rental Shipment Line"
{
    Caption = 'Rental Shipment Line';
    DrillDownPageID = "TWE Post. Rental Ship. Lines";
    LookupPageID = "TWE Post. Rental Ship. Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;

    fields
    {
        field(2; "Rented-to Customer No."; Code[20])
        {
            Caption = 'Rented-to Customer No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Shipment Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(5; Type; Enum "TWE Rental Line Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(6; "No."; Code[20])
        {
            CaptionClass = GetCaptionClass(FieldNo("No."));
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST("Rental Item")) "TWE Main Rental Item"
            ELSE
            IF (Type = CONST(Resource)) Resource;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = IF (Type = CONST("Rental Item")) "Inventory Posting Group";
        }
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            DataClassification = CustomerContent;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            DataClassification = CustomerContent;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            DataClassification = CustomerContent;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            DataClassification = CustomerContent;
        }
        field(39; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            DataClassification = CustomerContent;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Price Group";
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
            TableRelation = Job;
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Type";
        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Qty. Shipped Not Invoiced';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = CustomerContent;
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Customer;
        }
        field(71; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
        }
        field(72; "Purch. Order Line No."; Integer)
        {
            Caption = 'Purch. Order Line No.';
            DataClassification = CustomerContent;
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            DataClassification = CustomerContent;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Product Posting Group";
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = CustomerContent;
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            DataClassification = CustomerContent;
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Shipment Line"."Line No." WHERE("Document No." = FIELD("Document No."));
        }
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            DataClassification = CustomerContent;
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            DataClassification = CustomerContent;
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area";
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = CustomerContent;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Group";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";
        }
        field(91; "Currency Code"; Code[10])
        {
            CalcFormula = Lookup("Sales Shipment Header"."Currency Code" WHERE("No." = FIELD("Document No.")));
            Caption = 'Currency Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Header"."No." WHERE("Document Type" = CONST("Blanket Order"));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            Caption = 'Blanket Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Line"."Line No." WHERE("Document Type" = CONST("Blanket Order"),
                                                           "Document No." = FIELD("Blanket Order No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
        }
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
            DataClassification = CustomerContent;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(826; "Authorized for Credit Card"; Boolean)
        {
            Caption = 'Authorized for Credit Card';
            DataClassification = CustomerContent;
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(1002; "Job Contract Entry No."; Integer)
        {
            Caption = 'Job Contract Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Rental Item")) "Item Variant".Code WHERE("Item No." = FIELD("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                            "Item Filter" = FIELD("No."),
                                            "Variant Filter" = FIELD("Variant Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Rental Item")) "TWE Rental Item Unit Of Meas.".Code WHERE("Item No." = FIELD("No."))
            ELSE
            "Unit of Measure";
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            DataClassification = CustomerContent;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = CustomerContent;
            TableRelation = "Depreciation Book";
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            DataClassification = CustomerContent;
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            DataClassification = CustomerContent;
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            DataClassification = CustomerContent;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            DataClassification = CustomerContent;
            TableRelation = "Responsibility Center";
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Rental Item")) "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            DataClassification = CustomerContent;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            DataClassification = CustomerContent;
            TableRelation = Purchasing;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            DataClassification = CustomerContent;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure (Item Ref.)';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Rental Item")) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
            DataClassification = CustomerContent;
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
            DataClassification = CustomerContent;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';
            DataClassification = CustomerContent;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            DataClassification = CustomerContent;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5795; "Planned Shipment Date"; Date)
        {
            Caption = 'Planned Shipment Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(5812; "Item Charge Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
            DataClassification = CustomerContent;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Return Reason";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            DataClassification = CustomerContent;
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Discount Group";
        }
        field(70704600; "Rental Item"; Code[20])
        {
            Caption = 'Rental Item';
            DataClassification = CustomerContent;
            TableRelation = "Service Item"."No." WHERE("TWE Main Rental Item" = FIELD("No."));
        }
        field(70704601; "Invoicing Date"; Date)
        {
            Caption = 'Invoicing Date';
            DataClassification = CustomerContent;
        }
        field(70704602; "Billing Start Date"; Date)
        {
            Caption = 'Billing Start Date';
            DataClassification = CustomerContent;
        }
        field(70704603; "Billing End Date"; Date)
        {
            Caption = 'Billing End Date';
            DataClassification = CustomerContent;
        }
        field(70704604; "Duration to be billed"; Decimal)
        {
            Caption = 'Duration to be billed';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704606; "Invoiced Duration"; Decimal)
        {
            Caption = 'Invoiced Duration';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704607; "Return Quantity"; Decimal)
        {
            Caption = 'Return Quantity';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70704608; "Quantity returned"; Decimal)
        {
            Caption = 'Quantity returned';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50033; "Rental Rate Code"; Code[20])
        {
            Caption = 'Rental Rate Code';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Rates"."Rate Code";
            Editable = false;
        }
        field(70704621; "Invoicing Period"; Code[20])
        {
            Caption = 'Invoicing Period';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Invoicing Period"."Invoicing Period Code";
        }
        field(70704622; "Line Closed"; Boolean)
        {
            Caption = 'Line Closed';
            DataClassification = CustomerContent;
        }
        field(70704625; "Total Days to Invoice"; Decimal)
        {
            Caption = 'Total Days to Invoice';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key3; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key4; "Item Shpt. Entry No.")
        {
        }
        key(Key5; "Rented-to Customer No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", "Rented-to Customer No.", Type, "No.", "Shipment Date")
        {
        }
    }

    trigger OnDelete()
    var
        ServItem: Record "Service Item";
        RentalDocLineComments: Record "TWE Rental Comment Line";
    begin
        ServItem.Reset();
        ServItem.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServItem.SetRange("Sales/Serv. Shpt. Document No.", "Document No.");
        ServItem.SetRange("Sales/Serv. Shpt. Line No.", "Line No.");
        ServItem.SetRange("Shipment Type", ServItem."Shipment Type"::Sales);
        if ServItem.Find('-') then
            repeat
                ServItem.Validate("Sales/Serv. Shpt. Document No.", '');
                ServItem.Validate("Sales/Serv. Shpt. Line No.", 0);
                ServItem.Modify(true);
            until ServItem.Next() = 0;

        RentalDocLineComments.SetRange("Document Type", RentalDocLineComments."Document Type"::Shipment);
        RentalDocLineComments.SetRange("No.", "Document No.");
        RentalDocLineComments.SetRange("Document Line No.", "Line No.");
        if not RentalDocLineComments.IsEmpty then
            RentalDocLineComments.DeleteAll();
    end;

    var
        Currency: Record Currency;
        RentalShptHeader: Record "TWE Rental Shipment Header";
        DimMgt: Codeunit DimensionManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        Text000Lbl: Label 'Shipment No. %1:', Comment = '%1 is the Shipment No.';
        Text001Lbl: Label 'The program cannot find this Rental line.';
        CurrencyRead: Boolean;

    /// <summary>
    /// GetCurrencyCode.
    /// </summary>
    /// <returns>Return value of type Code[10].</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        if "Document No." = RentalShptHeader."No." then
            exit(RentalShptHeader."Currency Code");
        if RentalShptHeader.Get("Document No.") then
            exit(RentalShptHeader."Currency Code");
        exit('');
    end;

    /// <summary>
    /// ShowDimensions.
    /// </summary>
    procedure ShowDimensions()
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1= TableCaption,%2= "Document No.",%3= "Line No."';
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo(Placeholder001Lbl, TableCaption, "Document No.", "Line No."), 1, 250));
    end;

    /// <summary>
    /// InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="RentalLine">VAR Record "TWE Rental Line".</param>
    procedure InsertInvLineFromShptLine(var RentalLine: Record "TWE Rental Line")
    var
        RentalInvHeader: Record "TWE Rental Header";
        RentalOrderHeader: Record "TWE Rental Header";
        RentalOrderLine: Record "TWE Rental Line";
        TempRentalLine: Record "TWE Rental Line" temporary;
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        TranslationHelper: Codeunit "Translation Helper";
        ExtTextLine: Boolean;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCodeInsertInvLineFromShptLine(Rec, RentalLine, IsHandled);
        if IsHandled then
            exit;

        SetRange("Document No.", "Document No.");

        TempRentalLine := RentalLine;
        if RentalLine.Find('+') then
            NextLineNo := RentalLine."Line No." + 10000
        else
            NextLineNo := 10000;

        if RentalInvHeader."No." <> TempRentalLine."Document No." then
            RentalInvHeader.Get(TempRentalLine."Document Type", TempRentalLine."Document No.");

        if RentalLine."Shipment No." <> "Document No." then begin

            OnInsertInvLineFromShptLineOnBeforeInsertDescriptionLine(
                Rec, RentalLine, TempRentalLine, RentalInvHeader, NextLineNo);

            RentalLine.Init();
            RentalLine."Line No." := NextLineNo;
            RentalLine."Document Type" := TempRentalLine."Document Type";
            RentalLine."Document No." := TempRentalLine."Document No.";
            TranslationHelper.SetGlobalLanguageByCode(RentalInvHeader."Language Code");
            RentalLine.Description := StrSubstNo(Text000Lbl, "Document No.");
            TranslationHelper.RestoreGlobalLanguage();
            IsHandled := false;
            OnBeforeInsertInvLineFromShptLineBeforeInsertTextLine(Rec, RentalLine, NextLineNo, IsHandled);
            if not IsHandled then begin
                RentalLine.Insert();
                OnAfterDescriptionRentalLineInsert(RentalLine, Rec, NextLineNo);
                NextLineNo := NextLineNo + 10000;
            end;
        end;

        TransferOldExtLines.ClearLineNumbers();

        repeat
            ExtTextLine := (TransferOldExtLines.GetNewLineNumber("Attached to Line No.") <> 0);

            if (Type <> Type::" ") and RentalOrderLine.Get(RentalOrderLine."Document Type"::Contract, "Order No.", "Order Line No.")
            then begin
                if (RentalOrderHeader."Document Type" <> RentalOrderLine."Document Type"::Contract) or
                   (RentalOrderHeader."No." <> RentalOrderLine."Document No.")
                then
                    RentalOrderHeader.Get(RentalOrderLine."Document Type"::Contract, "Order No.");

                InitCurrency("Currency Code");

                if RentalInvHeader."Prices Including VAT" then begin
                    if not RentalOrderHeader."Prices Including VAT" then
                        RentalOrderLine."Unit Price" :=
                          Round(
                            RentalOrderLine."Unit Price" * (1 + RentalOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else //begin
                    if RentalOrderHeader."Prices Including VAT" then
                        RentalOrderLine."Unit Price" :=
                          Round(
                            RentalOrderLine."Unit Price" / (1 + RentalOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                //end;
            end else begin
                RentalOrderHeader.Init();
                if ExtTextLine or (Type = Type::" ") then begin
                    RentalOrderLine.Init();
                    RentalOrderLine."Line No." := "Order Line No.";
                    RentalOrderLine.Description := Description;
                    RentalOrderLine."Description 2" := "Description 2";
                    OnInsertInvLineFromShptLineOnAfterAssignDescription(Rec, RentalOrderLine);
                end else
                    Error(Text001Lbl);
            end;

            RentalLine := RentalOrderLine;
            RentalLine."Line No." := NextLineNo;
            RentalLine."Document Type" := TempRentalLine."Document Type";
            RentalLine."Document No." := TempRentalLine."Document No.";
            RentalLine."Variant Code" := "Variant Code";
            RentalLine."Location Code" := "Location Code";
            RentalLine."Drop Shipment" := "Drop Shipment";
            RentalLine."Shipment No." := "Document No.";
            RentalLine."Shipment Line No." := "Line No.";
            ClearSalesLineValues(RentalLine);
            if not ExtTextLine and (RentalLine.Type <> RentalLine.Type::" ") then begin
                IsHandled := false;
                OnInsertInvLineFromShptLineOnBeforeValidateQuantity(Rec, RentalLine, IsHandled);
                if not IsHandled then
                    RentalLine.Validate(Quantity, Quantity - "Quantity Invoiced");
                CalcBaseQuantities(RentalLine, "Quantity (Base)" / Quantity);

                OnInsertInvLineFromShptLineOnAfterCalcQuantities(RentalLine, RentalOrderLine);

                RentalLine.Validate("Unit Price", RentalOrderLine."Unit Price");
                RentalLine."Allow Line Disc." := RentalOrderLine."Allow Line Disc.";
                RentalLine."Allow Invoice Disc." := RentalOrderLine."Allow Invoice Disc.";
                RentalOrderLine."Line Discount Amount" :=
                  Round(
                    RentalOrderLine."Line Discount Amount" * RentalLine.Quantity / RentalOrderLine.Quantity,
                    Currency."Amount Rounding Precision");
                if RentalInvHeader."Prices Including VAT" then begin
                    if not RentalInvHeader."Prices Including VAT" then
                        RentalOrderLine."Line Discount Amount" :=
                          Round(
                            RentalOrderLine."Line Discount Amount" *
                            (1 + RentalOrderLine."VAT %" / 100), Currency."Amount Rounding Precision");
                end else //begin
                    if RentalOrderHeader."Prices Including VAT" then
                        RentalOrderLine."Line Discount Amount" :=
                          Round(
                            RentalOrderLine."Line Discount Amount" /
                            (1 + RentalOrderLine."VAT %" / 100), Currency."Amount Rounding Precision");
                //end;
                RentalLine.Validate("Line Discount Amount", RentalOrderLine."Line Discount Amount");
                RentalLine."Line Discount %" := RentalOrderLine."Line Discount %";
                RentalLine.UpdatePrePaymentAmounts();
                OnInsertInvLineFromShptLineOnAfterUpdatePrepaymentsAmounts(RentalLine, RentalOrderLine, Rec);

                if RentalOrderLine.Quantity = 0 then
                    RentalLine.Validate("Inv. Discount Amount", 0)
                else
                    RentalLine.Validate(
                      "Inv. Discount Amount",
                      Round(
                        RentalOrderLine."Inv. Discount Amount" * RentalLine.Quantity / RentalOrderLine.Quantity,
                        Currency."Amount Rounding Precision"));
            end;

            RentalLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                RentalOrderLine."Line No.",
                NextLineNo,
                "Attached to Line No.");
            RentalLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            RentalLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            RentalLine."Dimension Set ID" := "Dimension Set ID";
            OnBeforeInsertInvLineFromShptLine(Rec, RentalLine, RentalOrderLine);
            RentalLine.Insert();
            OnAfterInsertInvLineFromShptLine(RentalLine, RentalOrderLine, NextLineNo, Rec);

            //ItemTrackingMgt.CopyHandledItemTrkgToInvLine(RentalOrderLine, RentalLine);

            NextLineNo := NextLineNo + 10000;
            if "Attached to Line No." = 0 then
                SetRange("Attached to Line No.", "Line No.");
        until (Next() = 0) or ("Attached to Line No." = 0);

        if RentalOrderHeader.Get(RentalOrderHeader."Document Type"::Contract, "Order No.") then begin
            RentalOrderHeader."Get Shipment Used" := true;
            RentalOrderHeader.Modify();
        end;
    end;

    /// <summary>
    /// GetRentalInvLines.
    /// </summary>
    /// <param name="TempRentalInvLine">Temporary VAR Record "TWE Rental Invoice Line".</param>
    procedure GetRentalInvLines(var TempRentalInvLine: Record "TWE Rental Invoice Line" temporary)
    var
        RentalInvLine: Record "TWE Rental Invoice Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        TempRentalInvLine.Reset();
        TempRentalInvLine.DeleteAll();

        if Type <> Type::"Rental Item" then
            exit;

        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        ItemLedgEntry.SetFilter("Invoiced Quantity", '<>0');
        if ItemLedgEntry.FindSet() then begin
            ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
            ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
            ValueEntry.SetFilter("Invoiced Quantity", '<>0');
            repeat
                ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                if ValueEntry.FindSet() then
                    repeat
                        if ValueEntry."Document Type" = ValueEntry."Document Type"::"Rental Invoice" then
                            if RentalInvLine.Get(ValueEntry."Document No.", ValueEntry."Document Line No.") then begin
                                TempRentalInvLine.Init();
                                TempRentalInvLine := RentalInvLine;
                                if TempRentalInvLine.Insert() then;
                            end;
                    until ValueEntry.Next() = 0;
            until ItemLedgEntry.Next() = 0;
        end;
    end;

    /// <summary>
    /// CalcShippedRentalNotReturned.
    /// </summary>
    /// <param name="ShippedQtyNotReturned">VAR Decimal.</param>
    /// <param name="RevUnitCostLCY">VAR Decimal.</param>
    /// <param name="ExactCostReverse">Boolean.</param>
    procedure CalcShippedRentalNotReturned(var ShippedQtyNotReturned: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TotalCostLCY: Decimal;
        TotalQtyBase: Decimal;
    begin
        ShippedQtyNotReturned := 0;
        if (Type <> Type::"Rental Item") or (Quantity <= 0) then begin
            RevUnitCostLCY := "Unit Cost (LCY)";
            exit;
        end;

        RevUnitCostLCY := 0;
        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        if ItemLedgEntry.FindSet() then
            repeat
                ShippedQtyNotReturned := ShippedQtyNotReturned - ItemLedgEntry."Shipped Qty. Not Returned";
                if ExactCostReverse then begin
                    ItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
                    TotalCostLCY :=
                      TotalCostLCY + ItemLedgEntry."Cost Amount (Expected)" + ItemLedgEntry."Cost Amount (Actual)";
                    TotalQtyBase := TotalQtyBase + ItemLedgEntry.Quantity;
                end;
            until ItemLedgEntry.Next() = 0;

        if ExactCostReverse and (ShippedQtyNotReturned <> 0) and (TotalQtyBase <> 0) then
            RevUnitCostLCY := Abs(TotalCostLCY / TotalQtyBase) * "Qty. per Unit of Measure"
        else
            RevUnitCostLCY := "Unit Cost (LCY)";

        ShippedQtyNotReturned := CalcQty(ShippedQtyNotReturned);
    end;

    local procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            exit(QtyBase);
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    /// <summary>
    /// FilterPstdDocLnItemLedgEntries.
    /// </summary>
    /// <param name="ItemLedgEntry">VAR Record "Item Ledger Entry".</param>
    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", "Document No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    /// <summary>
    /// ShowItemRentalInvLines.
    /// </summary>
    procedure ShowItemRentalInvLines()
    var
        TempRentalInvLine: Record "TWE Rental Invoice Line" temporary;
    begin
        if Type = Type::"Rental Item" then begin
            GetRentalInvLines(TempRentalInvLine);
            PAGE.RunModal(PAGE::"TWE Post. Rental Invoice Lines", TempRentalInvLine);
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if (Currency.Code = CurrencyCode) and CurrencyRead then
            exit;

        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();
        CurrencyRead := true;
    end;

    /// <summary>
    /// ShowLineComments.
    /// </summary>
    procedure ShowLineComments()
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        RentalCommentLine.ShowComments(RentalCommentLine."Document Type"::Shipment.AsInteger(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// ShowAsmToOrder.
    /// </summary>
    procedure ShowAsmToOrder()
    begin
        //   PostedATOLink.ShowPostedAsm(Rec);
    end;

    /// <summary>
    /// ShowShortcutDimCode.
    /// </summary>
    /// <param name="ShortcutDimCode">VAR array[8] of Code[20].</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// AsmToShipmentExists.
    /// </summary>
    /// <param name="PostedAsmHeader">VAR Record "Posted Assembly Header".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure AsmToShipmentExists(var PostedAsmHeader: Record "Posted Assembly Header"): Boolean
    var
        PostedAssembleToOrderLink: Record "Posted Assemble-to-Order Link";
    begin
        //if not PostedAssembleToOrderLink.AsmExistsForPostedShipmentLine(Rec) then
        //exit(false);
        exit(PostedAsmHeader.Get(PostedAssembleToOrderLink."Assembly Document No."));
    end;

    /// <summary>
    /// InitFromRentalLine.
    /// </summary>
    /// <param name="RentalShptHeader">Record "TWE Rental Shipment Header".</param>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    procedure InitFromRentalLine(RentalShptHeader: Record "TWE Rental Shipment Header"; RentalLine: Record "TWE Rental Line")
    begin
        Init();
        TransferFields(RentalLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := RentalShptHeader."Posting Date";
        "Document No." := RentalShptHeader."No.";
        Quantity := RentalLine."Qty. to Ship";
        "Quantity (Base)" := RentalLine."Qty. to Ship (Base)";
        if Abs(RentalLine."Qty. to Invoice") > Abs(RentalLine."Qty. to Ship") then begin
            "Quantity Invoiced" := RentalLine."Qty. to Ship";
            "Qty. Invoiced (Base)" := RentalLine."Qty. to Ship (Base)";
        end else begin
            "Quantity Invoiced" := RentalLine."Qty. to Invoice";
            "Qty. Invoiced (Base)" := RentalLine."Qty. to Invoice (Base)";
        end;
        "Qty. Shipped Not Invoiced" := Quantity - "Quantity Invoiced";
        if RentalLine."Document Type" = RentalLine."Document Type"::Contract then begin
            "Order No." := RentalLine."Document No.";
            "Order Line No." := RentalLine."Line No.";
        end;

        OnAfterInitFromRentalLine(RentalShptHeader, RentalLine, Rec);
    end;

    local procedure ClearSalesLineValues(var RentalLine: Record "TWE Rental Line")
    begin
        RentalLine."Quantity (Base)" := 0;
        RentalLine.Quantity := 0;
        RentalLine."Outstanding Qty. (Base)" := 0;
        RentalLine."Outstanding Quantity" := 0;
        RentalLine."Quantity Shipped" := 0;
        RentalLine."Qty. Shipped (Base)" := 0;
        RentalLine."Quantity Invoiced" := 0;
        RentalLine."Qty. Invoiced (Base)" := 0;
        RentalLine.Amount := 0;
        RentalLine."Amount Including VAT" := 0;
        RentalLine."Purchase Order No." := '';
        RentalLine."Purch. Order Line No." := 0;
        RentalLine."Special Order Purchase No." := '';
        RentalLine."Special Order Purch. Line No." := 0;
        RentalLine."Special Order" := false;
        RentalLine."Appl.-to Item Entry" := 0;
        RentalLine."Appl.-from Item Entry" := 0;

        OnAfterClearRentalLineValues(Rec, RentalLine);
    end;

    /// <summary>
    /// FormatType.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure FormatType(): Text
    var
        RentalLine: Record "TWE Rental Line";
    begin
        if Type = Type::" " then
            exit(RentalLine.FormatType());

        exit(Format(Type));
    end;

    local procedure CalcBaseQuantities(var RentalLine: Record "TWE Rental Line"; QtyFactor: Decimal)
    begin
        RentalLine."Quantity (Base)" :=
          Round(RentalLine.Quantity * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Qty. to Asm. to Order (Base)" :=
          Round(RentalLine."Qty. to Assemble to Order" * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Outstanding Qty. (Base)" :=
          Round(RentalLine."Outstanding Quantity" * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Qty. to Ship (Base)" :=
          Round(RentalLine."Qty. to Ship" * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Qty. Shipped (Base)" :=
          Round(RentalLine."Quantity Shipped" * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Qty. Shipped Not Invd. (Base)" :=
          Round(RentalLine."Qty. Shipped Not Invoiced" * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Qty. to Invoice (Base)" :=
          Round(RentalLine."Qty. to Invoice" * QtyFactor, UOMMgt.QtyRndPrecision());
        RentalLine."Qty. Invoiced (Base)" :=
          Round(RentalLine."Quantity Invoiced" * QtyFactor, UOMMgt.QtyRndPrecision());
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Shipment Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    /// <summary>
    /// GetCaptionClass.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <returns>Return value of type Text[80].</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        Placeholder001Lbl: Label '3,%1', Comment = '%1= Fieldcaption Fieldnumber';
    begin
        case FieldNumber of
            FieldNo("No."):
                exit(CopyStr(StrSubstNo(Placeholder001Lbl, GetFieldCaption(FieldNumber)), 1, 80));
        end;
    end;

    /// <summary>
    /// HasTypeToFillMandatoryFields.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearRentalLineValues(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDescriptionRentalLineInsert(var RentalLine: Record "TWE Rental Line"; RentalShipmentLine: Record "TWE Rental Shipment Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromRentalLine(RentalShptHeader: Record "TWE Rental Shipment Header"; RentalLine: Record "TWE Rental Line"; var RentalShptLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvLineFromShptLine(var RentalLine: Record "TWE Rental Line"; RentalOrderLine: Record "TWE Rental Line"; NextLineNo: Integer; RentalShipmentLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromShptLine(var RentalShptLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line"; RentalOrderLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromShptLineBeforeInsertTextLine(var RentalShptLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line"; var NextLineNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCodeInsertInvLineFromShptLine(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterAssignDescription(var RentalShipmentLine: Record "TWE Rental Shipment Line"; var RentalOrderLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterCalcQuantities(var RentalLine: Record "TWE Rental Line"; RentalOrderLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterUpdatePrepaymentsAmounts(var RentalLine: Record "TWE Rental Line"; var RentalOrderLine: Record "TWE Rental Line"; var RentalShipmentLine: Record "TWE Rental Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnBeforeValidateQuantity(RentalShipmentLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnBeforeInsertDescriptionLine(RentalShipmentLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line"; TempRentalLine: Record "TWE Rental Line" temporary; var RentalInvHeader: Record "TWE Rental Header"; var NextLineNo: integer)
    begin
    end;
}

