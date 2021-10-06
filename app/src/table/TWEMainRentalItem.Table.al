/// <summary>
/// Table TWE Main Rental Item (ID 50100).
/// </summary>
table 50001 "TWE Main Rental Item"
{
    DataClassification = CustomerContent;
    DataCaptionFields = "No.", Description;
    Permissions = TableData "Service Item" = rm,
                  TableData "Service Item Component" = rm;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetRentalSetup();
                    NoSeriesMgt.TestManual(RentalSetup."Main Rental Item Nos.");
                    "No. Series" := '';
                    if xRec."No." = '' then
                        "Costing Method" := RentalSetup."Default Costing Method";
                end;
            end;
        }

        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := CopyStr(Description, 1, MaxStrLen("Search Description"));
            end;
        }
        field(3; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            DataClassification = CustomerContent;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        field(5; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UnitOfMeasure: Record "Unit of Measure";
            begin
                UpdateUnitOfMeasureId();

                if "Base Unit of Measure" <> xRec."Base Unit of Measure" then begin
                    TestNoOpenEntriesExist(FieldCaption("Base Unit of Measure"));

                    if "Base Unit of Measure" <> '' then begin
                        // If we can't find a Unit of Measure with a GET,
                        // then try with International Standard Code, as some times it's used as Code
                        if not UnitOfMeasure.Get("Base Unit of Measure") then begin
                            UnitOfMeasure.SetRange("International Standard Code", "Base Unit of Measure");
                            if not UnitOfMeasure.FindFirst() then
                                Error(UnitOfMeasureNotExistErr, "Base Unit of Measure");
                            "Base Unit of Measure" := UnitOfMeasure.Code;
                        end;

                        if not TWERentalItemUnitOfMeasure.Get("No.", "Base Unit of Measure") then begin
                            TWERentalItemUnitOfMeasure.Init();
                            if IsTemporary then
                                TWERentalItemUnitOfMeasure."Item No." := "No."
                            else
                                TWERentalItemUnitOfMeasure.Validate("Item No.", "No.");
                            TWERentalItemUnitOfMeasure.Validate(Code, "Base Unit of Measure");
                            TWERentalItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                            TWERentalItemUnitOfMeasure.Insert();
                        end else
                            if TWERentalItemUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                Error(BaseUnitOfMeasureQtyMustBeOneErr, "Base Unit of Measure", TWERentalItemUnitOfMeasure."Qty. per Unit of Measure");
                    end;
                    "Sales Unit of Measure" := "Base Unit of Measure";
                    "Purch. Unit of Measure" := "Base Unit of Measure";
                end;
            end;
        }
        field(10; "Price Unit Conversion"; Integer)
        {
            Caption = 'Price Unit Conversion';
            DataClassification = CustomerContent;
        }
        field(12; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            begin
            end;
        }
        field(13; "Rental Item Disc. Group"; Code[20])
        {
            Caption = 'Rental Item Disc. Group';
            DataClassification = CustomerContent;
            TableRelation = "Item Discount Group";
        }
        field(14; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(15; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
            DataClassification = CustomerContent;
        }
        field(20; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(21; "Price/Profit Calculation"; Option)
        {
            Caption = 'Price/Profit Calculation';
            OptionCaption = 'Profit=Price-Cost,Price=Cost+Profit,No Relationship';
            DataClassification = CustomerContent;
            OptionMembers = "Profit=Price-Cost","Price=Cost+Profit","No Relationship";

            trigger OnValidate()
            begin
                case "Price/Profit Calculation" of
                    "Price/Profit Calculation"::"Profit=Price-Cost":
                        if "Unit Price" <> 0 then
                            if "Unit Cost" = 0 then
                                "Profit %" := 0
                            else
                                "Profit %" :=
                                  Round(
                                    100 * (1 - "Unit Cost" /
                                           ("Unit Price" / (1 + CalcVAT()))), 0.00001)
                        else
                            "Profit %" := 0;
                    "Price/Profit Calculation"::"Price=Cost+Profit":
                        if "Profit %" < 100 then begin
                            GetGLSetup();
                            "Unit Price" :=
                              Round(
                                ("Unit Cost" / (1 - "Profit %" / 100)) *
                                (1 + CalcVAT()),
                                GLSetup."Unit-Amount Rounding Precision");
                        end;
                end;
            end;
        }
        field(22; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(23; "Costing Method"; Enum "Costing Method")
        {
            Caption = 'Costing Method';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Costing Method" = xRec."Costing Method" then
                    exit;

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018Lbl,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption, ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoEntriesExist(FieldCaption("Costing Method"));

                //ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Costing Method"));
            end;
        }
        field(24; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                if IsNonInventoriableType() then
                    exit;

                if "Costing Method" = "Costing Method"::Standard then
                    Validate("Standard Cost", "Unit Cost")
                else
                    TestNoEntriesExist(FieldCaption("Unit Cost"));
                Validate("Price/Profit Calculation");
            end;
        }
        field(25; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Standard Cost';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStandardCost(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if ("Costing Method" = "Costing Method"::Standard) and (CurrFieldNo <> 0) then
                    if not GuiAllowed then begin
                        "Standard Cost" := xRec."Standard Cost";
                        exit;
                    end else
                        if not
                           Confirm(
                             Text020Lbl +
                             Text021Lbl +
                             Text022Lbl, false,
                             FieldCaption("Standard Cost"))
                        then begin
                            "Standard Cost" := xRec."Standard Cost";
                            exit;
                        end;

                //ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Standard Cost"));
            end;
        }
        field(26; "Last Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Last Direct Cost';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(27; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                //ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Indirect Cost %"));
            end;
        }
        field(30; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
            ValidateTableRelation = true;

            trigger OnValidate()
            begin
                if (xRec."Vendor No." <> "Vendor No.") and
                   ("Vendor No." <> '')
                then
                    ;
            end;
        }
        field(31; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
            DataClassification = CustomerContent;
        }
        field(35; "Alternative Item No."; Code[20])
        {
            Caption = 'Alternative Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
        }
        field(40; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit List Price';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(45; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(46; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(32; "Country/Region Purchased Code"; Code[10])
        {
            Caption = 'Country/Region Purchased Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(50; Comment; Boolean)
        {
            CalcFormula = Exist("Comment Line" WHERE("Table Name" = CONST(Item),
                                                      "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not Blocked then
                    "Block Reason" := '';
            end;
        }
        field(100; "Cost is Posted to G/L"; Boolean)
        {
            CalcFormula = - Exist("Post Value Entry to G/L" WHERE("Item No." = FIELD("No.")));
            Caption = 'Cost is Posted to G/L';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField(Blocked, true);
            end;
        }
        field(101; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(102; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(103; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(104; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(150; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(151; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(105; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(106; Inventory; Integer)
        {
            CalcFormula = Count("Service Item" WHERE("TWE Rental Item" = const(true), "TWE Main Rental Item" = Field("No.")));

            Caption = 'Inventory';
            Editable = false;
            FieldClass = FlowField;
        }

        field(107; "Invoiced Days"; Decimal)
        {
            CalcFormula = Sum("TWE Rental Invoice Line"."Duration to be billed" WHERE("No." = FIELD("No."),
                                                                                        Type = const(2)));
            Caption = 'Invoiced Days';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(108; "Net Change"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry".Quantity WHERE("Item No." = FIELD("No."),
                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                  "Location Code" = FIELD("Location Filter"),
                                                                  "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                  "Posting Date" = FIELD("Date Filter"),
                                                                  "Lot No." = FIELD("Lot No. Filter"),
                                                                  "Serial No." = FIELD("Serial No. Filter"),
                                                                  "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
            Caption = 'Net Change';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(111; "Positive Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST("Positive Adjmt."),
                                                                             "Item No." = FIELD("No."),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Lot No." = FIELD("Lot No. Filter"),
                                                                             "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Positive Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(112; "Negative Adjmt. (Qty.)"; Decimal)
        {
            CalcFormula = - Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST("Negative Adjmt."),
                                                                              "Item No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Location Code" = FIELD("Location Filter"),
                                                                              "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                              "Posting Date" = FIELD("Date Filter"),
                                                                              "Lot No." = FIELD("Lot No. Filter"),
                                                                              "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Negative Adjmt. (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(114; "Rental (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Sales Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST(Sale),
                                                                           "Item No." = FIELD("No."),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                           "Posting Date" = FIELD("Date Filter")));
            Caption = 'Rental (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(120; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if "Price Includes VAT" then begin
                    SalesSetup.Get();
                    if SalesSetup."VAT Bus. Posting Gr. (Price)" <> '' then
                        "VAT Bus. Posting Gr. (Price)" := SalesSetup."VAT Bus. Posting Gr. (Price)";
                    VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
                end;
                Validate("Price/Profit Calculation");
            end;
        }
        field(121; "Drop Shipment Filter"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment Filter';
            FieldClass = FlowFilter;
        }
        field(122; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(123; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then begin
                    if CurrFieldNo <> 0 then
                        if (ProdOrderExist()) then
                            if not Confirm(
                                 Text024Lbl +
                                 Text022Lbl, false,
                                 FieldCaption("Gen. Prod. Posting Group"))
                            then begin
                                "Gen. Prod. Posting Group" := xRec."Gen. Prod. Posting Group";
                                exit;
                            end;

                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
                end;

                Validate("Price/Profit Calculation");
            end;
        }
        field(124; Picture; MediaSet)
        {
            Caption = 'Picture';
            DataClassification = CustomerContent;
        }
        field(125; "Transferred (Qty.)"; Decimal)
        {
            CalcFormula = Sum("Item Ledger Entry"."Invoiced Quantity" WHERE("Entry Type" = CONST(Transfer),
                                                                             "Item No." = FIELD("No."),
                                                                             "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Location Code" = FIELD("Location Filter"),
                                                                             "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                             "Posting Date" = FIELD("Date Filter"),
                                                                             "Lot No." = FIELD("Lot No. Filter"),
                                                                             "Serial No." = FIELD("Serial No. Filter")));
            Caption = 'Transferred (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(126; "Transferred (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Value Entry"."Sales Amount (Actual)" WHERE("Item Ledger Entry Type" = CONST(Transfer),
                                                                           "Item No." = FIELD("No."),
                                                                           "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                           "Posting Date" = FIELD("Date Filter")));
            Caption = 'Transferred (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(127; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
            DataClassification = CustomerContent;
        }
        field(152; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "No. Series";
        }
        field(128; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                UpdateTaxGroupId();
            end;
        }
        field(129; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                Validate("Price/Profit Calculation");
            end;
        }
        field(130; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Reserve';
            DataClassification = CustomerContent;
            InitValue = Optional;

            trigger OnValidate()
            begin
            end;
        }
        field(131; "Reserved Qty. on Inventory"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(32),
                                                                           "Source Subtype" = CONST("0"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Serial No." = FIELD("Serial No. Filter"),
                                                                           "Lot No." = FIELD("Lot No. Filter"),
                                                                           "Location Code" = FIELD("Location Filter")));
            Caption = 'Reserved Qty. on Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(132; "Reserved Qty. on Purch. Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(39),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Reserved Qty. on Purch. Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(133; "Reserved Qty. on Sales Orders"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(37),
                                                                            "Source Subtype" = CONST("1"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Reserved Qty. on Sales Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(134; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(135; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(136; "Res. Qty. on Outbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(5741),
                                                                            "Source Subtype" = CONST("0"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Outbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(137; "Res. Qty. on Inbound Transfer"; Decimal)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(5741),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Inbound Transfer';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(138; "Res. Qty. on Sales Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(37),
                                                                           "Source Subtype" = CONST("5"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Sales Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(139; "Res. Qty. on Purch. Returns"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(39),
                                                                            "Source Subtype" = CONST("5"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Purch. Returns';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(140; "Assembly Policy"; Enum "Assembly Policy")
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Assembly Policy" = "Assembly Policy"::"Assemble-to-Order" then
                    if IsNonInventoriableType() then
                        TestField("Assembly Policy", "Assembly Policy"::"Assemble-to-Stock");
            end;
        }
        field(141; "Res. Qty. on Assembly Order"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                           "Source Type" = CONST(900),
                                                                           "Source Subtype" = CONST("1"),
                                                                           "Reservation Status" = CONST(Reservation),
                                                                           "Location Code" = FIELD("Location Filter"),
                                                                           "Expected Receipt Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(142; "Res. Qty. on  Asm. Comp."; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(901),
                                                                            "Source Subtype" = CONST("1"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on  Asm. Comp.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(143; "Qty. on Assembly Order"; Decimal)
        {
            CalcFormula = Sum("Assembly Header"."Remaining Quantity (Base)" WHERE("Document Type" = CONST(Order),
                                                                                   "Item No." = FIELD("No."),
                                                                                   "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Location Code" = FIELD("Location Filter"),
                                                                                   "Due Date" = FIELD("Date Filter"),
                                                                                   "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
            Caption = 'Qty. on Assembly Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(144; "Qty. on Asm. Component"; Decimal)
        {
            CalcFormula = Sum("Assembly Line"."Remaining Quantity (Base)" WHERE("Document Type" = CONST(Order),
                                                                                 Type = CONST(Item),
                                                                                 "No." = FIELD("No."),
                                                                                 "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                 "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                 "Location Code" = FIELD("Location Filter"),
                                                                                 "Due Date" = FIELD("Date Filter"),
                                                                                 "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
            Caption = 'Qty. on Asm. Component';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }

        field(1002; "Res. Qty. on Job Order"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(1003),
                                                                            "Source Subtype" = CONST("2"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Job Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5402; "Serial Nos."; Code[20])
        {
            Caption = 'Serial Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Serial Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(200; "Last Unit Cost Calc. Date"; Date)
        {
            Caption = 'Last Unit Cost Calc. Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(201; "Rounding Precision"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Rounding Precision';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                if "Rounding Precision" <= 0 then
                    FieldError("Rounding Precision", Text027Lbl);
            end;
        }
        field(202; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Filter"));
        }
        field(250; "Sales Unit of Measure"; Code[10])
        {
            Caption = 'Sales Unit of Measure';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Item Unit Of Meas.".Code WHERE("Item No." = FIELD("No."));
        }
        field(251; "Purch. Unit of Measure"; Code[10])
        {
            Caption = 'Purch. Unit of Measure';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Item Unit Of Meas.".Code WHERE("Item No." = FIELD("No."));
        }
        field(253; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        field(300; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            DataClassification = CustomerContent;
            TableRelation = Manufacturer;
        }
        field(301; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Category";

            trigger OnValidate()
            var
            //ItemAttributeManagement: Codeunit "Item Attribute Management";
            begin
                if not IsTemporary then
                    //ItemAttributeManagement.InheritAttributesFromItemCategory(Rec, "Item Category Code", xRec."Item Category Code");
                UpdateItemCategoryId();
            end;
        }
        field(350; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            DataClassification = CustomerContent;
            TableRelation = Purchasing;
        }
        field(5900; "Service Item Group"; Code[10])
        {
            Caption = 'Service Item Group';
            DataClassification = CustomerContent;
            TableRelation = "Service Item Group".Code;

            trigger OnValidate()
            var
                ResSkill: Record "Resource Skill";
            begin
                if xRec."Service Item Group" <> "Service Item Group" then begin
                    if not ResSkillMgt.ChangeResSkillRelationWithGroup(
                         ResSkill.Type::Item,
                         "No.",
                         ResSkill.Type::"Service Item Group",
                         "Service Item Group",
                         xRec."Service Item Group")
                    then
                        "Service Item Group" := xRec."Service Item Group";
                end else
                    ResSkillMgt.RevalidateResSkillRelation(
                      ResSkill.Type::Item,
                      "No.",
                      ResSkill.Type::"Service Item Group",
                      "Service Item Group")
            end;
        }
        field(5901; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = Sum("Service Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST(Order),
                                                                              Type = CONST(Item),
                                                                              "No." = FIELD("No."),
                                                                              "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Location Code" = FIELD("Location Filter"),
                                                                              "Needed by Date" = FIELD("Date Filter"),
                                                                              "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5902; "Res. Qty. on Service Orders"; Decimal)
        {
            AccessByPermission = TableData "Service Header" = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Item No." = FIELD("No."),
                                                                            "Source Type" = CONST(5902),
                                                                            "Source Subtype" = CONST("1"),
                                                                            "Reservation Status" = CONST(Reservation),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter")));
            Caption = 'Res. Qty. on Service Orders';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Tracking Code";

            trigger OnValidate()
            var
                EmptyDateFormula: DateFormula;
            begin
                if "Item Tracking Code" = xRec."Item Tracking Code" then
                    exit;

                if not ItemTrackingCode.Get("Item Tracking Code") then
                    Clear(ItemTrackingCode);

                if not ItemTrackingCode2.Get(xRec."Item Tracking Code") then
                    Clear(ItemTrackingCode2);

                if (ItemTrackingCode."SN Specific Tracking" <> ItemTrackingCode2."SN Specific Tracking") or
                   (ItemTrackingCode."Lot Specific Tracking" <> ItemTrackingCode2."Lot Specific Tracking")
                then
                    TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                if (ItemTrackingCode."SN Warehouse Tracking" <> ItemTrackingCode2."SN Warehouse Tracking") or
                   (ItemTrackingCode."Lot Warehouse Tracking" <> ItemTrackingCode2."Lot Warehouse Tracking")
                then
                    TestNoWhseEntriesExist(FieldCaption("Item Tracking Code"));

                if "Costing Method" = "Costing Method"::Specific then begin
                    TestNoEntriesExist(FieldCaption("Item Tracking Code"));

                    TestField("Item Tracking Code");

                    ItemTrackingCode.Get("Item Tracking Code");
                    if not ItemTrackingCode."SN Specific Tracking" then
                        Error(
                          Text018Lbl,
                          ItemTrackingCode.FieldCaption("SN Specific Tracking"),
                          Format(true), ItemTrackingCode.TableCaption, ItemTrackingCode.Code,
                          FieldCaption("Costing Method"), "Costing Method");
                end;

                TestNoOpenDocumentsWithTrackingExist();

                if "Expiration Calculation" <> EmptyDateFormula then
                    if not ItemTrackingCodeUseExpirationDates() then
                        Error(ItemTrackingCodeIgnoresExpirationDateErr, "No.");
            end;
        }
        field(6501; "Lot Nos."; Code[20])
        {
            Caption = 'Lot Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Lot Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(6502; "Expiration Calculation"; DateFormula)
        {
            Caption = 'Expiration Calculation';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Format("Expiration Calculation") <> '' then
                    if not ItemTrackingCodeUseExpirationDates() then
                        Error(ItemTrackingCodeIgnoresExpirationDateErr, "No.");
            end;
        }
        field(6503; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(6504; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(6650; "Qty. on Purch. Return"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Sum("Purchase Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST("Return Order"),
                                                                               Type = CONST(Item),
                                                                               "No." = FIELD("No."),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Location Code" = FIELD("Location Filter"),
                                                                               "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                               "Expected Receipt Date" = FIELD("Date Filter"),
                                                                               "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
            Caption = 'Qty. on Purch. Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6660; "Qty. on Sales Return"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = Sum("Sales Line"."Outstanding Qty. (Base)" WHERE("Document Type" = CONST("Return Order"),
                                                                            Type = CONST(Item),
                                                                            "No." = FIELD("No."),
                                                                            "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                            "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                            "Location Code" = FIELD("Location Filter"),
                                                                            "Drop Shipment" = FIELD("Drop Shipment Filter"),
                                                                            "Shipment Date" = FIELD("Date Filter"),
                                                                            "Unit of Measure Code" = FIELD("Unit of Measure Filter")));
            Caption = 'Qty. on Sales Return';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(8001; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".SystemId;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode();
            end;
        }
        field(8002; "Tax Group Id"; Guid)
        {
            Caption = 'Tax Group Id';
            DataClassification = CustomerContent;
            TableRelation = "Tax Group".SystemId;

            trigger OnValidate()
            begin
                UpdateTaxGroupCode();
            end;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';
            DataClassification = CustomerContent;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';
            DataClassification = CustomerContent;
        }
        field(8005; "Item Category Id"; Guid)
        {
            Caption = 'Item Category Id';
            DataClassification = SystemMetadata;
            TableRelation = "Item Category".SystemId;

            trigger OnValidate()
            begin
                UpdateItemCategoryCode();
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";

            trigger OnValidate()
            begin
                //PlanningAssignment.RoutingReplace(Rec, xRec."Routing No.");

                //if "Routing No." <> xRec."Routing No." then
                //ItemCostMgt.UpdateUnitCost(Rec, '', '', 0, 0, false, false, true, FieldNo("Routing No."));
            end;
        }
        field(70704600; "Default Rental Price"; Decimal)
        {
            Caption = 'Default Rental Price';
            DataClassification = CustomerContent;
        }
        field(50001; "Orginal Item No."; Code[20])
        {
            Caption = 'Original Item No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Inventory Posting Group")
        {
        }
        key(Key4; "Vendor No.")
        {
        }
        key(Key5; "Gen. Prod. Posting Group")
        {
        }
        key(Key6; "Routing No.")
        {
        }
        key(Key7; "Vendor Item No.", "Vendor No.")
        {
        }
        key(Key8; "Service Item Group")
        {
        }
        key(Key9; Description)
        {
        }
        key(Key10; "Base Unit of Measure")
        {
        }
        key(Key17; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Base Unit of Measure", "Unit Price")
        {
        }
        fieldgroup(Brick; "No.", Description, Inventory, "Unit Price", "Base Unit of Measure", "Description 2", Picture)
        {
        }
    }

    trigger OnDelete()
    begin
        //ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);

        CheckJournalsAndWorksheets(0);
        CheckDocuments(0);

        //MoveEntries.MoveItemEntries(Rec);

        DeleteRelatedData();
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            GetRentalSetup();
            RentalSetup.TestField("Main Rental Item Nos.");
            NoSeriesMgt.InitSeries(RentalSetup."Main Rental Item Nos.", xRec."No. Series", 0D, "No.", "No. Series");
            "Costing Method" := RentalSetup."Default Costing Method";
        end;

        DimMgt.UpdateDefaultDim(
          DATABASE::Item, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        UpdateReferencedIds();
        SetLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        UpdateReferencedIds();
        SetLastDateTimeModified();
        //PlanningAssignment.ItemChange(Rec, xRec);
    end;

    trigger OnRename()
    var
        RentalLine: Record "TWE Rental Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        RentalLine.RenameNo(RentalLine.Type::"Rental Item", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::Item, xRec."No.", "No.");
        TransferLine.RenameNo(xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::Item, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Item, xRec."No.", "No.");

        RentalApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);
        ItemAttributeValueMapping.RenameItemAttributeValueMapping(xRec."No.", "No.");
        SetLastDateTimeModified();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        RentalSetup: Record "TWE Rental Setup";
        CommentLine: Record "Comment Line";
        ItemVend: Record "Item Vendor";
        SalesPrepmtPct: Record "Sales Prepayment %";
        PurchPrepmtPct: Record "Purchase Prepayment %";
        ItemTranslation: Record "Item Translation";
        BOMComp: Record "BOM Component";
        VATPostingSetup: Record "VAT Posting Setup";
        ExtTextHeader: Record "Extended Text Header";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        TWERentalItemUnitOfMeasure: Record "TWE Rental Item Unit Of Meas.";
        ItemVariant: Record "Item Variant";
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningAssignment: Record "Planning Assignment";
        SKU: Record "Stockkeeping Unit";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";
        ServInvLine: Record "Service Line";
        ItemSub: Record "Item Substitution";
        TransLine: Record "Transfer Line";
        Vend: Record Vendor;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ItemIdent: Record "Item Identifier";
        RequisitionLine: Record "Requisition Line";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisBudgViewEntry: Record "Item Analysis View Budg. Entry";
        TroubleshSetup: Record "Troubleshooting Setup";
        ServiceContractLine: Record "Service Contract Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
        HasRentalSetup: Boolean;
        GLSetupRead: Boolean;
        Text027Lbl: Label 'must be greater than 0.', Comment = 'starts with "Rounding Precision"';
        CannotChangeFieldErr: Label 'You cannot change the %1 field on %2 %3 because at least one %4 exists for this item.', Comment = '%1 = Field Caption, %2 = Item Table Name, %3 = Item No., %4 = Table Name';
        BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.\\You can change this setup in the Item Units of Measure window.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';
        OpenDocumentTrackingErr: Label 'You cannot change "Item Tracking Code" because there is at least one open document that includes this item with specified tracking. Source Type : %1, Document No. : %2.', Comment = 'Source Type = %1, Document No. = %2.';
        SelectItemErr: Label 'You must select an existing item.';
        UnitOfMeasureNotExistErr: Label 'The Unit of Measure with Code %1 does not exist.', Comment = '%1 = Code of Unit of measure';
        ItemLedgEntryTableCaptionTxt: Label 'Item Ledger Entry';
        ItemTrackingCodeIgnoresExpirationDateErr: Label 'The settings for expiration dates do not match on the item tracking code and the item %1. Both must either use, or not use, expiration dates.', Comment = '%1 is the Item number';
        WhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for this item.', Comment = '%1: Changed field name';
        Text000Lbl: Label 'You cannot delete %1 %2 because there is at least one outstanding Purchase %3 that includes this item.', Comment = '%1 = TableCaption,%2 = "No.",%3 =  PurchaseLine."Document Type"';
        CannotDeleteItemIfRentalDocExistErr: Label 'You cannot delete %1 %2 because there is at least one outstanding Rental %3 that includes this item.', Comment = '%1: Type, %2 Item No. and %3 : Type of document Order,Invoice';
        Text002Lbl: Label 'You cannot delete %1 %2 because there are one or more outstanding production orders that include this item.', Comment = '%1 = TableCaption,%2 = "No."';
        Text004Lbl: Label 'You cannot delete %1 %2 because there are one or more certified Production BOM that include this item.', Comment = '%1 = TableCaption,%2 = "No."';
        CannotDeleteItemIfProdBOMVersionExistsErr: Label 'You cannot delete %1 %2 because there are one or more certified production BOM version that include this item.', Comment = '%1 - Tablecaption, %2 - No.';
        Text006Lbl: Label 'Prices including VAT cannot be calculated when %1 is %2.', Comment = '%1 = FieldCaption "VAT Calculation Type",%2 = "VAT Calculation Type"';
        Text007Lbl: Label 'You cannot change %1 because there are one or more ledger entries for this item.', Comment = '%1 = CurrentFieldName';
        Text008Lbl: Label 'You cannot change %1 because there is at least one outstanding Purchase %2 that include this item.', Comment = '%1 = CurrentFieldName,%2 = PurchaseLine."Document Type"';
        Text014Lbl: Label 'You cannot delete %1 %2 because there are one or more production order component lines that include this item with a remaining quantity that is not 0.', Comment = '%1 = TableCaption,%2 = "No."';
        Text016Lbl: Label 'You cannot delete %1 %2 because there are one or more outstanding transfer orders that include this item.', Comment = '%1 = TableCaption,%2 = "No."';
        Text017Lbl: Label 'You cannot delete %1 %2 because there is at least one outstanding Service %3 that includes this item.', Comment = '%1 = TableCaption,%2 = "No.",%3 = Document Type';
        Text018Lbl: Label '%1 must be %2 in %3 %4 when %5 is %6.', Comment = '%1 = FieldCaption "SN Specific Tracking",%2 = Boolean,%3 = TableCaption,%4 = Code,%5 = FieldCaption "Costing Method",%6 = "Costing Method"';
        Text019Lbl: Label 'You cannot change %1 because there are one or more open ledger entries for this item.', Comment = '%1 = CurrentFieldName';
        Text020Lbl: Label 'There may be orders and open ledger entries for the item. ';
        Text021Lbl: Label 'If you change %1 it may affect new orders and entries.\\', Comment = '%1 = FieldCaption "Standard Cost"';
        Text022Lbl: Label 'Do you want to change %1?', Comment = '%1 = FieldCaption "Standard Cost"';
        Text023Lbl: Label 'You cannot delete %1 %2 because there is at least one %3 that includes this item.', Comment = '%1 = TableCaption,%2 = "No.",%3 = TableCaption';
        Text024Lbl: Label 'If you change %1 it may affect existing production orders.\', Comment = '%1 = Text022Lbl';
        Text025Lbl: Label '%1 must be an integer because %2 %3 is set up to use %4.', Comment = '%1 = FieldName,%2 = TableCaption,%3 = ItemNo,%4 FieldCaption "SN Specific Tracking"';

    local procedure DeleteRelatedData()
    var
        BinContent: Record "Bin Content";
        MyMainRentalItem: Record "TWE My Main Rental Item";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");
        ItemBudgetEntry.SetRange("Item No.", "No.");
        ItemBudgetEntry.DeleteAll(true);

        ItemSub.Reset();
        ItemSub.SetRange(Type, ItemSub.Type::Item);
        ItemSub.SetRange("No.", "No.");
        ItemSub.DeleteAll();

        ItemSub.Reset();
        ItemSub.SetRange("Substitute Type", ItemSub."Substitute Type"::Item);
        ItemSub.SetRange("Substitute No.", "No.");
        ItemSub.DeleteAll();

        SKU.Reset();
        SKU.SetCurrentKey("Item No.");
        SKU.SetRange("Item No.", "No.");
        SKU.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        ItemVend.SetCurrentKey("Item No.");
        ItemVend.SetRange("Item No.", "No.");
        ItemVend.DeleteAll();

        SalesPrepmtPct.SetRange("Item No.", "No.");
        SalesPrepmtPct.DeleteAll();

        PurchPrepmtPct.SetRange("Item No.", "No.");
        PurchPrepmtPct.DeleteAll();

        ItemTranslation.SetRange("Item No.", "No.");
        ItemTranslation.DeleteAll();

        TWERentalItemUnitOfMeasure.SetRange("Item No.", "No.");
        TWERentalItemUnitOfMeasure.DeleteAll();

        ItemVariant.SetRange("Item No.", "No.");
        ItemVariant.DeleteAll();

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.DeleteAll(true);

        ItemAnalysisViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisViewEntry.DeleteAll();

        ItemAnalysisBudgViewEntry.SetRange("Item No.", "No.");
        ItemAnalysisBudgViewEntry.DeleteAll();

        PlanningAssignment.SetRange("Item No.", "No.");
        PlanningAssignment.DeleteAll();

        BOMComp.Reset();
        BOMComp.SetRange("Parent Item No.", "No.");
        BOMComp.DeleteAll();

        TroubleshSetup.Reset();
        TroubleshSetup.SetRange(Type, TroubleshSetup.Type::Item);
        TroubleshSetup.SetRange("No.", "No.");
        TroubleshSetup.DeleteAll();

        ResSkillMgt.DeleteItemResSkills("No.");
        DimMgt.DeleteDefaultDim(DATABASE::Item, "No.");

        ItemIdent.Reset();
        ItemIdent.SetCurrentKey("Item No.");
        ItemIdent.SetRange("Item No.", "No.");
        ItemIdent.DeleteAll();

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "No.");
        BinContent.DeleteAll();

        MyMainRentalItem.SetRange("Main Rental Item No.", "No.");
        MyMainRentalItem.DeleteAll();

        ItemAttributeValueMapping.Reset();
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", "No.");
        ItemAttributeValueMapping.DeleteAll();

        OnAfterDeleteRelatedData(Rec);
    end;

    procedure AssistEdit(): Boolean
    begin
        GetRentalSetup();
        RentalSetup.TestField("Main Rental Item Nos.");
        if NoSeriesMgt.SelectSeries(RentalSetup."Main Rental Item Nos.", xRec."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    procedure FindItemVend(var ItemVend: Record "Item Vendor"; LocationCode: Code[10])
    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
    begin
        TestField("No.");
        ItemVend.Reset();
        ItemVend.SetRange("Item No.", "No.");
        ItemVend.SetRange("Vendor No.", ItemVend."Vendor No.");
        ItemVend.SetRange("Variant Code", ItemVend."Variant Code");
        OnFindItemVendOnAfterSetFilters(ItemVend, Rec);

        if not ItemVend.Find('+') then begin
            ItemVend."Item No." := "No.";
            ItemVend."Vendor Item No." := '';
            GetPlanningParameters.AtSKU(SKU, "No.", ItemVend."Variant Code", LocationCode);
            if ItemVend."Vendor No." = '' then
                ItemVend."Vendor No." := SKU."Vendor No.";
            if ItemVend."Vendor Item No." = '' then
                ItemVend."Vendor Item No." := SKU."Vendor Item No.";
            ItemVend."Lead Time Calculation" := SKU."Lead Time Calculation";
        end;
        if Format(ItemVend."Lead Time Calculation") = '' then begin
            GetPlanningParameters.AtSKU(SKU, "No.", ItemVend."Variant Code", LocationCode);
            ItemVend."Lead Time Calculation" := SKU."Lead Time Calculation";
            if Format(ItemVend."Lead Time Calculation") = '' then
                if Vend.Get(ItemVend."Vendor No.") then
                    ItemVend."Lead Time Calculation" := Vend."Lead Time Calculation";
        end;
        ItemVend.Reset();
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Item, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure TestNoEntriesExist(CurrentFieldName: Text)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        IsHandled := false;
        OnBeforeTestNoItemLedgEntiesExist(Rec, CurrentFieldName, IsHandled);
        if not IsHandled then begin
            ItemLedgEntry.SetCurrentKey("Item No.");
            ItemLedgEntry.SetRange("Item No.", "No.");
            if not ItemLedgEntry.IsEmpty then
                Error(Text007Lbl, CurrentFieldName);
        end;

        IsHandled := false;
        OnBeforeTestNoPurchLinesExist(Rec, CurrentFieldName, IsHandled);
        if not IsHandled then begin
            PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
            PurchaseLine.SetFilter(
              "Document Type", '%1|%2',
              PurchaseLine."Document Type"::Order,
              PurchaseLine."Document Type"::"Return Order");
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", "No.");
            if PurchaseLine.FindFirst() then
                Error(Text008Lbl, CurrentFieldName, PurchaseLine."Document Type");
        end;
    end;

    local procedure TestNoWhseEntriesExist(CurrentFieldName: Text)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", "No.");
        if not WarehouseEntry.IsEmpty() then
            Error(WhseEntriesExistErr, CurrentFieldName);
    end;

    procedure TestNoOpenEntriesExist(CurrentFieldName: Text)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty then
            Error(
              Text019Lbl,
              CurrentFieldName);
    end;

    local procedure TestNoOpenDocumentsWithTrackingExist()
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
        RecRef: RecordRef;
        SourceType: Integer;
        SourceID: Code[20];
    begin
        if ItemTrackingCode2.Code = '' then
            exit;

        TrackingSpecification.SetRange("Item No.", "No.");
        if TrackingSpecification.FindFirst() then begin
            SourceType := TrackingSpecification."Source Type";
            SourceID := TrackingSpecification."Source ID";
        end else begin
            ReservationEntry.SetRange("Item No.", "No.");
            ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
            if ReservationEntry.FindFirst() then begin
                SourceType := ReservationEntry."Source Type";
                SourceID := ReservationEntry."Source ID";
            end;
        end;

        if SourceType = 0 then
            exit;

        RecRef.Open(SourceType);
        Error(OpenDocumentTrackingErr, RecRef.Caption, SourceID);
    end;

    local procedure GetRentalSetup()
    begin
        if not HasRentalSetup then begin
            RentalSetup.GetSetup();
            HasRentalSetup := true;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure ProdOrderExist(): Boolean
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", "No.");
        if not ProdOrderLine.IsEmpty then
            exit(true);

        exit(false);
    end;

    procedure CheckSerialNoQty(ItemNo: Code[20]; FieldName: Text[30]; Quantity: Decimal)
    var
        ItemRec: Record Item;
        ItemTrackingCode3: Record "Item Tracking Code";
    begin
        if Quantity = Round(Quantity, 1) then
            exit;
        if not ItemRec.Get(ItemNo) then
            exit;
        if ItemRec."Item Tracking Code" = '' then
            exit;
        if not ItemTrackingCode3.Get(ItemRec."Item Tracking Code") then
            exit;
        if ItemTrackingCode3."SN Specific Tracking" then
            Error(Text025Lbl,
              FieldName,
              TableCaption,
              ItemNo,
              ItemTrackingCode3.FieldCaption("SN Specific Tracking"));
    end;

    procedure CheckJournalsAndWorksheets(CurrFieldNo: Integer)
    begin
        CheckItemJnlLine(CurrFieldNo);
        CheckStdCostWksh(CurrFieldNo);
        CheckReqLine(CurrFieldNo);
    end;

    local procedure CheckItemJnlLine(CurrFieldNo: Integer)
    begin
        ItemJnlLine.SetRange("Item No.", "No.");
        if not ItemJnlLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", ItemJnlLine.TableCaption);
        end;
    end;

    local procedure CheckStdCostWksh(CurrFieldNo: Integer)
    var
        StdCostWksh: Record "Standard Cost Worksheet";
    begin
        StdCostWksh.Reset();
        StdCostWksh.SetRange(Type, StdCostWksh.Type::Item);
        StdCostWksh.SetRange("No.", "No.");
        if not StdCostWksh.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", StdCostWksh.TableCaption);
    end;

    local procedure CheckReqLine(CurrFieldNo: Integer)
    begin
        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", "No.");
        if not RequisitionLine.IsEmpty then begin
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", RequisitionLine.TableCaption);
        end;
    end;

    procedure CheckDocuments(CurrFieldNo: Integer)
    begin
        if "No." = '' then
            exit;

        CheckBOM(CurrFieldNo);
        CheckPurchLine(CurrFieldNo);
        CheckRentalLine(CurrFieldNo);
        CheckProdOrderLine(CurrFieldNo);
        CheckProdOrderCompLine(CurrFieldNo);
        CheckPlanningCompLine(CurrFieldNo);
        CheckTransLine(CurrFieldNo);
        CheckServLine(CurrFieldNo);
        CheckProdBOMLine(CurrFieldNo);
        CheckServContractLine(CurrFieldNo);
        CheckAsmHeader(CurrFieldNo);
        CheckAsmLine(CurrFieldNo);
        CheckJobPlanningLine(CurrFieldNo);

        OnAfterCheckDocuments(Rec, xRec, CurrFieldNo);
    end;

    local procedure CheckBOM(CurrFieldNo: Integer)
    begin
        BOMComp.Reset();
        BOMComp.SetCurrentKey(Type, "No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", "No.");
        if not BOMComp.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", BOMComp.TableCaption);
    end;

    local procedure CheckPurchLine(CurrFieldNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey(Type, "No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", "No.");
        if PurchaseLine.FindFirst() then
            if CurrFieldNo = 0 then
                Error(Text000Lbl, TableCaption, "No.", PurchaseLine."Document Type");
    end;

    local procedure CheckRentalLine(CurrFieldNo: Integer)
    var
        RentalLine: Record "TWE Rental Line";
    begin
        RentalLine.SetCurrentKey(Type, "No.");
        RentalLine.SetRange(Type, RentalLine.Type::"Rental Item");
        RentalLine.SetRange("No.", "No.");
        if RentalLine.FindFirst() then
            if CurrFieldNo = 0 then
                Error(CannotDeleteItemIfRentalDocExistErr, TableCaption, "No.", RentalLine."Document Type");
    end;

    local procedure CheckProdOrderLine(CurrFieldNo: Integer)
    begin
        if ProdOrderExist() then
            if CurrFieldNo = 0 then
                Error(Text002Lbl, TableCaption, "No.");
    end;

    local procedure CheckProdOrderCompLine(CurrFieldNo: Integer)
    begin
        ProdOrderComp.SetCurrentKey(Status, "Item No.");
        ProdOrderComp.SetFilter(Status, '..%1', ProdOrderComp.Status::Released);
        ProdOrderComp.SetRange("Item No.", "No.");
        if not ProdOrderComp.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text014Lbl, TableCaption, "No.");
    end;

    local procedure CheckPlanningCompLine(CurrFieldNo: Integer)
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date", "Planning Line Origin");
        PlanningComponent.SetRange("Item No.", "No.");
        if not PlanningComponent.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", PlanningComponent.TableCaption);
    end;

    local procedure CheckTransLine(CurrFieldNo: Integer)
    begin
        TransLine.SetCurrentKey("Item No.");
        TransLine.SetRange("Item No.", "No.");
        if not TransLine.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text016Lbl, TableCaption, "No.");
    end;

    local procedure CheckServLine(CurrFieldNo: Integer)
    begin
        ServInvLine.Reset();
        ServInvLine.SetCurrentKey(Type, "No.");
        ServInvLine.SetRange(Type, ServInvLine.Type::Item);
        ServInvLine.SetRange("No.", "No.");
        if not ServInvLine.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text017Lbl, TableCaption, "No.", ServInvLine."Document Type");
    end;

    local procedure CheckProdBOMLine(CurrFieldNo: Integer)
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProdBOMLine.Reset();
        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", "No.");
        if ProdBOMLine.Find('-') then
            if CurrFieldNo = 0 then
                repeat
                    if ProdBOMHeader.Get(ProdBOMLine."Production BOM No.") and
                       (ProdBOMHeader.Status = ProdBOMHeader.Status::Certified)
                    then
                        Error(Text004Lbl, TableCaption, "No.");
                    if ProductionBOMVersion.Get(ProdBOMLine."Production BOM No.", ProdBOMLine."Version Code") and
                       (ProductionBOMVersion.Status = ProductionBOMVersion.Status::Certified)
                    then
                        Error(CannotDeleteItemIfProdBOMVersionExistsErr, TableCaption, "No.");
                until ProdBOMLine.Next() = 0;
    end;

    local procedure CheckServContractLine(CurrFieldNo: Integer)
    begin
        ServiceContractLine.Reset();
        ServiceContractLine.SetRange("Item No.", "No.");
        if not ServiceContractLine.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", ServiceContractLine.TableCaption);
    end;

    local procedure CheckAsmHeader(CurrFieldNo: Integer)
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader.SetCurrentKey("Document Type", "Item No.");
        AsmHeader.SetRange("Item No.", "No.");
        if not AsmHeader.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", AsmHeader.TableCaption);
    end;

    local procedure CheckAsmLine(CurrFieldNo: Integer)
    var
        AsmLine: Record "Assembly Line";
    begin
        AsmLine.SetCurrentKey(Type, "No.");
        AsmLine.SetRange(Type, AsmLine.Type::Item);
        AsmLine.SetRange("No.", "No.");
        if not AsmLine.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", AsmLine.TableCaption);
    end;

    local procedure CheckJobPlanningLine(CurrFieldNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey(Type, "No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetRange("No.", "No.");
        if not JobPlanningLine.IsEmpty then
            if CurrFieldNo = 0 then
                Error(Text023Lbl, TableCaption, "No.", JobPlanningLine.TableCaption);
    end;

    local procedure CalcVAT(): Decimal
    begin
        if "Price Includes VAT" then begin
            VATPostingSetup.Get("VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text006Lbl,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;
        end else
            Clear(VATPostingSetup);

        exit(VATPostingSetup."VAT %" / 100);
    end;

    procedure CalcUnitPriceExclVAT(): Decimal
    begin
        GetGLSetup();
        if 1 + CalcVAT() = 0 then
            exit(0);
        exit(Round("Unit Price" / (1 + CalcVAT()), GLSetup."Unit-Amount Rounding Precision"));
    end;

    /// <summary>
    /// GetItemNo.
    /// </summary>
    /// <param name="ItemText">Text.</param>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetItemNo(ItemText: Text): Code[20]
    var
        ItemNo: Text[50];
    begin
        TryGetItemNo(ItemNo, ItemText, true);
        exit(CopyStr(ItemNo, 1, MaxStrLen("No.")));
    end;

    local procedure AsPriceAsset(var PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset.Init();
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::"Rental Item";
        PriceAsset."Asset No." := "No.";
    end;


    /// <summary>
    /// ShowPriceListLines.
    /// </summary>
    /// <param name="RentalPriceType">Enum "TWE Rental Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceListLines(RentalPriceType: Enum "TWE Rental Price Type"; AmountType: Enum "Price Amount Type")
    var
        TWERentalPriceAsset: Record "TWE Rental Price Asset";
        TWERentalPriceUXManagement: Codeunit "TWE Rental Price UX Management";
    begin
        AsPriceAsset(TWERentalPriceAsset);
        TWERentalPriceUXManagement.ShowPriceListLines(TWERentalPriceAsset, RentalPriceType, AmountType);
    end;

    /// <summary>
    /// TryGetItemNo.
    /// </summary>
    /// <param name="ReturnValue">VAR Text[50].</param>
    /// <param name="ItemText">Text.</param>
    /// <param name="DefaultCreate">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure TryGetItemNo(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean): Boolean
    begin
        RentalSetup.Get();
        exit(TryGetItemNoOpenCard(ReturnValue, ItemText, DefaultCreate, true, false));
    end;

    /// <summary>
    /// TryGetItemNoOpenCard.
    /// </summary>
    /// <param name="ReturnValue">VAR Text.</param>
    /// <param name="ItemText">Text.</param>
    /// <param name="DefaultCreate">Boolean.</param>
    /// <param name="ShowItemCard">Boolean.</param>
    /// <param name="ShowCreateItemOption">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure TryGetItemNoOpenCard(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean): Boolean
    var
        MainRentalItemView: Record "TWE Main Rental Item";
    begin
        MainRentalItemView.SetRange(Blocked, false);
        exit(TryGetItemNoOpenCardWithView(ReturnValue, ItemText, DefaultCreate, ShowItemCard, ShowCreateItemOption, MainRentalItemView.GetView()));
    end;

    procedure TryGetItemNoOpenCardWithView(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean; View: Text): Boolean
    var
        MainRentalItem: Record "TWE Main Rental Item";
        // RentalLine: Record "TWE Rental Line";
        //FindRecordMgt: Codeunit "Find Record Management";
        ItemNo: Code[20];
        ItemWithoutQuote: Text;
        ItemFilterContains: Text;
        FoundRecordCount: Integer;
    begin
        FoundRecordCount := 0;

        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if ItemText = '' then
            exit(DefaultCreate);

        //FoundRecordCount :=
        //FindRecordMgt.FindRecordByDescriptionAndView(ReturnValue, SalesLine.Type::MainRentalItem.AsInteger(), ItemText, View);

        if FoundRecordCount = 1 then
            exit(true);

        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if FoundRecordCount = 0 then begin
            if not DefaultCreate then
                exit(false);

            if not GuiAllowed then
                Error(SelectItemErr);

            //if MainRentalItem.WritePermission then
            //    if ShowCreateItemOption then
            //        case StrMenu(
            //               StrSubstNo('%1,%2', StrSubstNo(CreateNewItemTxt, ConvertStr(ItemText, ',', '.')), SelectItemTxt), 1, ItemNotRegisteredTxt)
            //        of
            //            0:
            //                Error('');
            //             1:
            //                begin
            //                   //ReturnValue := CreateNewItem(CopyStr(ItemText, 1, MaxStrLen(MainRentalItem.Description)), ShowItemCard);
            //                   exit(true);
            //               end;
            //       end
            //   else
            //       exit(false);
        end;

        if not GuiAllowed then
            Error(SelectItemErr);

        if FoundRecordCount > 0 then begin
            ItemWithoutQuote := ConvertStr(ItemText, '''', '?');
            ItemFilterContains := '''@*' + ItemWithoutQuote + '*''';
            MainRentalItem.FilterGroup(-1);
            MainRentalItem.SetFilter("No.", ItemFilterContains);
            MainRentalItem.SetFilter(Description, ItemFilterContains);
            MainRentalItem.SetFilter("Base Unit of Measure", ItemFilterContains);
            OnTryGetItemNoOpenCardOnAfterSetItemFilters(MainRentalItem, ItemFilterContains);
        end;

        if ShowItemCard then
            ItemNo := PickItem(MainRentalItem)
        else begin
            ReturnValue := '';
            exit(true);
        end;

        if ItemNo <> '' then begin
            ReturnValue := ItemNo;
            exit(true);
        end;

        if not DefaultCreate then
            exit(false);
        Error('');
    end;

    /*   local procedure CreateNewItem(ItemName: Text[100]; ShowItemCard: Boolean): Code[20]
      var
          MainRentalItem: Record "TWE Main Rental Item";
          ItemTemplate: Record "Item Templ.";
          ItemCard: Page "Item Card";
      begin
          OnBeforeCreateNewItem(MainRentalItem, ItemName);
          if not ItemTemplate.CopyFromTemplate(MainRentalItem) then
              Error(SelectItemErr);

          MainRentalItem.Description := ItemName;
          MainRentalItem.Modify(true);
          Commit();
          if not ShowItemCard then
              exit(MainRentalItem."No.");
          MainRentalItem.SetRange("No.", MainRentalItem."No.");
          ItemCard.SetTableView(MainRentalItem);
          if not (ItemCard.RunModal = ACTION::OK) then
              Error(SelectItemErr);

          exit(MainRentalItem."No.");
      end; */

    procedure PickItem(var MainRentalItem: Record "TWE Main Rental Item"): Code[20]
    var
        MainRentalItemList: Page "TWE Main Rental Item List";
    begin
        if MainRentalItem.FilterGroup = -1 then
            MainRentalItemList.SetTempFilteredItemRec(MainRentalItem);

        if MainRentalItem.FindFirst() then;
        MainRentalItemList.SetTableView(MainRentalItem);
        MainRentalItemList.SetRecord(MainRentalItem);
        MainRentalItemList.LookupMode := true;
        if MainRentalItemList.RunModal() = ACTION::LookupOK then
            MainRentalItemList.GetRecord(MainRentalItem)
        else
            Clear(MainRentalItem);

        exit(MainRentalItem."No.");
    end;

    local procedure SetLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
        "Last Date Modified" := DT2Date("Last DateTime Modified");
        "Last Time Modified" := DT2Time("Last DateTime Modified");
    end;

    procedure SetLastDateTimeFilter(DateFilter: DateTime)
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        SyncDateTimeUtc: DateTime;
        CurrentFilterGroup: Integer;
    begin
        SyncDateTimeUtc := DotNet_DateTimeOffset.ConvertToUtcDateTime(DateFilter);
        CurrentFilterGroup := FilterGroup;
        SetFilter("Last Date Modified", '>=%1', DT2Date(SyncDateTimeUtc));
        FilterGroup(-1);
        SetFilter("Last Date Modified", '>%1', DT2Date(SyncDateTimeUtc));
        SetFilter("Last Time Modified", '>%1', DT2Time(SyncDateTimeUtc));
        FilterGroup(CurrentFilterGroup);
    end;

    procedure UpdateUnitOfMeasureId()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if "Base Unit of Measure" = '' then begin
            Clear("Unit of Measure Id");
            exit;
        end;

        if not UnitOfMeasure.Get("Base Unit of Measure") then
            exit;

        "Unit of Measure Id" := UnitOfMeasure.SystemId;
    end;

    procedure UpdateItemCategoryId()
    var
        ItemCategory: Record "Item Category";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        if "Item Category Code" = '' then begin
            Clear("Item Category Id");
            exit;
        end;

        if not ItemCategory.Get("Item Category Code") then
            exit;

        "Item Category Id" := ItemCategory.SystemId;
    end;

    procedure UpdateTaxGroupId()
    var
        TaxGroup: Record "Tax Group";
    begin
        if "Tax Group Code" = '' then begin
            Clear("Tax Group Id");
            exit;
        end;

        if not TaxGroup.Get("Tax Group Code") then
            exit;

        "Tax Group Id" := TaxGroup.SystemId;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not IsNullGuid("Unit of Measure Id") then
            UnitOfMeasure.GetBySystemId("Unit of Measure Id");

        "Base Unit of Measure" := UnitOfMeasure.Code;
    end;

    local procedure UpdateTaxGroupCode()
    var
        TaxGroup: Record "Tax Group";
    begin
        if not IsNullGuid("Tax Group Id") then
            TaxGroup.GetBySystemId("Tax Group Id");

        Validate("Tax Group Code", TaxGroup.Code);
    end;

    local procedure UpdateItemCategoryCode()
    var
        ItemCategory: Record "Item Category";
    begin
        if IsNullGuid("Item Category Id") then
            ItemCategory.GetBySystemId("Item Category Id");

        "Item Category Code" := ItemCategory.Code;
    end;

    procedure UpdateReferencedIds()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        UpdateUnitOfMeasureId();
        UpdateTaxGroupId();
        UpdateItemCategoryId();
    end;

    procedure GetReferencedIds(var TempField: Record "Field" temporary)
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Unit of Measure Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Tax Group Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Item, FieldNo("Item Category Id"));
    end;

    procedure IsServiceType(): Boolean
    begin
        exit(false);
    end;

    procedure IsNonInventoriableType(): Boolean
    begin
        exit(true);
    end;

    procedure IsInventoriableType(): Boolean
    begin
        exit(not IsNonInventoriableType());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDocuments(var MainRentalItem: Record "TWE Main Rental Item"; var xMainRentalItem: Record "TWE Main Rental Item"; var CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelatedData(MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var MainRentalItem: Record "TWE Main Rental Item"; xMainRentalItem: Record "TWE Main Rental Item"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var MainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoItemLedgEntiesExist(MainRentalItem: Record "TWE Main Rental Item"; CurrentFieldName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoPurchLinesExist(MainRentalItem: Record "TWE Main Rental Item"; CurrentFieldName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var MainRentalItem: Record "TWE Main Rental Item"; xMainRentalItem: Record "TWE Main Rental Item"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStandardCost(var MainRentalItem: Record "TWE Main Rental Item"; xMainRentalItem: Record "TWE Main Rental Item"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemVendOnAfterSetFilters(var ItemVend: Record "Item Vendor"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryGetItemNoOpenCardOnAfterSetItemFilters(var MainRentalItem: Record "TWE Main Rental Item"; var ItemFilterContains: Text)
    begin
    end;

    procedure ExistsItemLedgerEntry(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", "No.");
        exit(not ItemLedgEntry.IsEmpty);
    end;

    procedure ItemTrackingCodeUseExpirationDates(): Boolean
    begin
        if "Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.Get("Item Tracking Code");
        exit(ItemTrackingCode."Use Expiration Dates");
    end;
}

