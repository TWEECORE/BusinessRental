/// <summary>
/// Table TWE Rental Cr.Memo Line (ID 50005).
/// </summary>
table 50005 "TWE Rental Cr.Memo Line"
{
    Caption = 'Rental Cr.Memo Line';
    DrillDownPageID = "TWE Post. Rent. Cr. Memo Lines";
    LookupPageID = "TWE Post. Rent. Cr. Memo Lines";
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
            TableRelation = "TWE Rental Cr.Memo Header";
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
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
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
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            DataClassification = CustomerContent;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            DataClassification = CustomerContent;
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
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
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
            TableRelation = "Sales Cr.Memo Line"."Line No." WHERE("Document No." = FIELD("Document No."));
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
        field(84; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
            DataClassification = CustomerContent;
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
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            DataClassification = CustomerContent;
            TableRelation = "VAT Clause";
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
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            DataClassification = CustomerContent;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            DataClassification = CustomerContent;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
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
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            TableRelation = "IC Partner";
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
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
            DataClassification = CustomerContent;
        }
        field(180; "Line Discount Calculation"; Option)
        {
            Caption = 'Line Discount Calculation';
            DataClassification = CustomerContent;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
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
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = CustomerContent;
            TableRelation = "Deferral Template"."Deferral Code";
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
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            DataClassification = CustomerContent;
        }
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
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
        field(70704620; "Rental Rate Code"; Code[20])
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
            MaintainSIFTIndex = false;
        }
        key(Key2; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key3; "Rented-to Customer No.")
        {
        }
        key(Key4; "Return Receipt No.", "Return Receipt Line No.")
        {
        }
        key(Key5; "Job Contract Entry No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key8; "Document No.", "Location Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount Including VAT";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        RentalDocLineComments: Record "TWE Rental Comment Line";
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        RentalDocLineComments.SetRange("Document Type", RentalDocLineComments."Document Type"::"Posted Credit Memo");
        RentalDocLineComments.SetRange("No.", "Document No.");
        RentalDocLineComments.SetRange("Document Line No.", "Line No.");
        if not RentalDocLineComments.IsEmpty then
            RentalDocLineComments.DeleteAll();

        PostedDeferralHeader.DeleteHeader(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            RentalDocLineComments."Document Type"::"Posted Credit Memo".AsInteger(), "Document No.", "Line No.");
    end;

    var
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        Currency: Record Currency;
        DimMgt: Codeunit DimensionManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";

    /// <summary>
    /// GetCurrencyCode.
    /// </summary>
    /// <returns>Return value of type Code[10].</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        GetHeader();
        exit(RentalCrMemoHeader."Currency Code");
    end;

    /// <summary>
    /// ShowDimensions.
    /// </summary>
    procedure ShowDimensions()
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1 = TableCaption,%2 = "Document No.",%3 = "Line No."';
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo(Placeholder001Lbl, TableCaption, "Document No.", "Line No."), 1, 250));
    end;

    /// <summary>
    /// ShowItemTrackingLines.
    /// </summary>
    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(RowID1());
    end;

    /// <summary>
    /// CalcVATAmountLines.
    /// </summary>
    /// <param name="RentalCrMemoHeader">Record "TWE Rental Cr.Memo Header".</param>
    /// <param name="TempVATAmountLine">Temporary VAR Record "VAT Amount Line".</param>
    procedure CalcVATAmountLines(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempVATAmountLine.DeleteAll();
        SetRange("Document No.", RentalCrMemoHeader."No.");
        if Find('-') then
            repeat
                TempVATAmountLine.Init();
                //TempVATAmountLine.CopyFromSalesCrMemoLine(Rec);
                TempVATAmountLine.InsertLine();
            until Next() = 0;
    end;

    /// <summary>
    /// GetLineAmountExclVAT.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetLineAmountExclVAT(): Decimal
    begin
        GetHeader();
        if not RentalCrMemoHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// GetLineAmountInclVAT.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetLineAmountInclVAT(): Decimal
    begin
        GetHeader();
        if RentalCrMemoHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    local procedure GetHeader()
    begin
        if RentalCrMemoHeader."No." = "Document No." then
            exit;
        if not RentalCrMemoHeader.Get("Document No.") then
            RentalCrMemoHeader.Init();

        if RentalCrMemoHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            if not Currency.Get(RentalCrMemoHeader."Currency Code") then
                Currency.InitRoundingPrecision();
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Cr.Memo Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    /// <summary>
    /// GetCaptionClass.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <returns>Return value of type Text[80].</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        Placeholder001Lbl: Label '3,%1', Comment = '%1 FieldNumber Field Caption';
    begin
        GetHeader();
        case FieldNumber of
            FieldNo("No."):
                exit(CopyStr(StrSubstNo(Placeholder001Lbl, GetFieldCaption(FieldNumber)), 1, 80));
            else begin
                    if RentalCrMemoHeader."Prices Including VAT" then
                        exit(CopyStr('2,1,' + GetFieldCaption(FieldNumber), 1, 80));
                    exit(CopyStr('2,0,' + GetFieldCaption(FieldNumber), 1, 80));
                end
        end;
    end;

    /// <summary>
    /// RowID1.
    /// </summary>
    /// <returns>Return value of type Text[250].</returns>
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"TWE Rental Cr.Memo Line",
            0, "Document No.", '', 0, "Line No."));
    end;

    /// <summary>
    /// GetReturnRcptLines.
    /// </summary>
    /// <param name="TempReturnRcptLine">Temporary VAR Record "Return Receipt Line".</param>
    procedure GetReturnRcptLines(var TempReturnRcptLine: Record "Return Receipt Line" temporary)
    var
        ReturnRcptLine: Record "Return Receipt Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        TempReturnRcptLine.Reset();
        TempReturnRcptLine.DeleteAll();

        if Type <> Type::"Rental Item" then
            exit;

        FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        if ValueEntry.FindSet() then
            repeat
                ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                if ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Sales Return Receipt" then
                    if ReturnRcptLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then begin
                        TempReturnRcptLine.Init();
                        TempReturnRcptLine := ReturnRcptLine;
                        if TempReturnRcptLine.Insert() then;
                    end;
            until ValueEntry.Next() = 0;
    end;

    /// <summary>
    /// GetItemLedgEntries.
    /// </summary>
    /// <param name="TempItemLedgEntry">Temporary VAR Record "Item Ledger Entry".</param>
    /// <param name="SetQuantity">Boolean.</param>
    procedure GetItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if SetQuantity then begin
            TempItemLedgEntry.Reset();
            TempItemLedgEntry.DeleteAll();

            if Type <> Type::"Rental Item" then
                exit;
        end;

        FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        if ValueEntry.FindSet() then
            repeat
                ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                if SetQuantity then begin
                    TempItemLedgEntry.Quantity := ValueEntry."Invoiced Quantity";
                    if Abs(TempItemLedgEntry."Shipped Qty. Not Returned") > Abs(TempItemLedgEntry.Quantity) then
                        TempItemLedgEntry."Shipped Qty. Not Returned" := TempItemLedgEntry.Quantity;
                end;
                OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(TempItemLedgEntry, ValueEntry, SetQuantity);
                if TempItemLedgEntry.Insert() then;
            until ValueEntry.Next() = 0;
    end;

    /// <summary>
    /// FilterPstdDocLineValueEntries.
    /// </summary>
    /// <param name="ValueEntry">VAR Record "Value Entry".</param>
    procedure FilterPstdDocLineValueEntries(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Rental Credit Memo");
        ValueEntry.SetRange("Document Line No.", "Line No.");
    end;

    /// <summary>
    /// ShowItemReturnRcptLines.
    /// </summary>
    procedure ShowItemReturnRcptLines()
    var
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
    begin
        if Type = Type::"Rental Item" then begin
            GetReturnRcptLines(TempReturnRcptLine);
            PAGE.RunModal(0, TempReturnRcptLine);
        end;
    end;

    /// <summary>
    /// ShowLineComments.
    /// </summary>
    procedure ShowLineComments()
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        RentalCommentLine.ShowComments(RentalCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "Document No.", "Line No.");
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
    /// InitFromRentalLine.
    /// </summary>
    /// <param name="RentalCrMemoHeader">Record "TWE Rental Cr.Memo Header".</param>
    /// <param name="RentalLine">Record "TWE Rental Line".</param>
    procedure InitFromRentalLine(RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalLine: Record "TWE Rental Line")
    begin
        Init();
        TransferFields(RentalLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := RentalCrMemoHeader."Posting Date";
        "Document No." := RentalCrMemoHeader."No.";
        if RentalLine.Type <> RentalLine.Type::"Rental Item" then begin
            Quantity := RentalLine."Qty. to Invoice";
            "Quantity (Base)" := RentalLine."Qty. to Invoice (Base)";
        end else begin
            Quantity := RentalLine.Quantity;
            "Quantity (Base)" := RentalLine."Quantity (Base)";
        end;

        OnAfterInitFromRentalLine(Rec, RentalCrMemoHeader, RentalLine);
    end;

    /// <summary>
    /// ShowDeferrals.
    /// </summary>
    procedure ShowDeferrals()
    begin
        DeferralUtilities.OpenLineScheduleView(
            "Deferral Code", "Deferral Document Type"::Sales.AsInteger(), '', '',
            GetDocumentType(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// GetDocumentType.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    procedure GetDocumentType(): Integer
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        exit(RentalCommentLine."Document Type"::"Posted Credit Memo".AsInteger())
    end;

    /// <summary>
    /// HasTypeToFillMandatoryFields.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromRentalLine(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry"; SetQuantity: Boolean)
    begin
    end;
}

