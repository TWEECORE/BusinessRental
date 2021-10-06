/// <summary>
/// Table TWE Rental Item Journal Line (ID 50014).
/// </summary>
table 50014 "TWE Rental Item Journal Line"
{
    Caption = 'Item Journal Line';
    DrillDownPageID = "Item Journal Lines";
    LookupPageID = "Item Journal Lines";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item;

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
                ProdOrderComp: Record "Prod. Order Component";
                PriceType: Enum "Price Type";
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Bin Code" := '';
                    /*             if CurrFieldNo <> 0 then
                                    WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Item No.")); */
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                    if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
                        "New Bin Code" := "Bin Code";
                end;

                /*     if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec); */

                if "Item No." = '' then begin
                    CreateDim(
                      DATABASE::Item, "Item No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::"Work Center", "Work Center No.");
                    exit;
                end;

                GetItem();
                OnValidateItemNoOnAfterGetItem(Rec, MainRentalItem);
                DisplayErrorIfItemIsBlocked(MainRentalItem);

                /*  if "Value Entry Type" = "Value Entry Type"::Revaluation then
                     MainRentalItem.TestField("Inventory Value Zero", false); */
                Description := MainRentalItem.Description;
                "Inventory Posting Group" := MainRentalItem."Inventory Posting Group";
                "Item Category Code" := MainRentalItem."Item Category Code";

                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    if "Item No." <> xRec."Item No." then begin
                        TestField("Partial Revaluation", false);
                        RetrieveCosts();
                        "Indirect Cost %" := 0;
                        "Overhead Rate" := 0;
                        "Inventory Value Per" := "Inventory Value Per"::" ";
                        Validate("Applies-to Entry", 0);
                        "Partial Revaluation" := false;
                    end;
                end else begin
                    "Indirect Cost %" := MainRentalItem."Indirect Cost %";
                    //"Overhead Rate" := MainRentalItem."Overhead Rate";
                    if not "Phys. Inventory" or (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) then begin
                        RetrieveCosts();
                        "Unit Cost" := UnitCost;
                    end else
                        UnitCost := "Unit Cost";
                end;

                if (("Entry Type" = "Entry Type"::Output) and (WorkCenter."No." = '') and (MachineCenter."No." = '')) or
                   ("Entry Type" <> "Entry Type"::Output) or
                   ("Value Entry Type" = "Value Entry Type"::Revaluation)
                then
                    "Gen. Prod. Posting Group" := MainRentalItem."Gen. Prod. Posting Group";

                case "Entry Type" of
                    "Entry Type"::Purchase,
                    "Entry Type"::Output,
                    "Entry Type"::"Assembly Output":
                        ApplyPrice(PriceType::Purchase, FieldNo("Item No."));
                    "Entry Type"::"Positive Adjmt.",
                    "Entry Type"::"Negative Adjmt.",
                    "Entry Type"::Consumption,
                    "Entry Type"::"Assembly Consumption":
                        "Unit Amount" := UnitCost;
                    "Entry Type"::Sale:
                        ApplyPrice(PriceType::Sale, FieldNo("Item No."));
                    "Entry Type"::Transfer:
                        begin
                            "Unit Amount" := 0;
                            "Unit Cost" := 0;
                            Amount := 0;
                        end;
                end;

                case "Entry Type" of
                    "Entry Type"::Purchase:
                        "Unit of Measure Code" := MainRentalItem."Purch. Unit of Measure";
                    "Entry Type"::Sale:
                        "Unit of Measure Code" := MainRentalItem."Sales Unit of Measure";
                    "Entry Type"::Output:
                        begin
                            //MainRentalItem.TestField("Inventory Value Zero", false);
                            ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                            ProdOrderLine.SetRange("Item No.", "Item No.");
                            if ProdOrderLine.FindFirst() then begin
                                "Routing No." := ProdOrderLine."Routing No.";
                                "Source Type" := "Source Type"::Item;
                                "Source No." := ProdOrderLine."Item No.";
                            end else
                                if ("Value Entry Type" <> "Value Entry Type"::Revaluation) and
                                   (CurrFieldNo <> 0)
                                then
                                    Error(Text031Lbl, "Item No.", "Order No.");
                            if ProdOrderLine.Count = 1 then
                                CopyFromProdOrderLine(ProdOrderLine)
                            else
                                "Unit of Measure Code" := MainRentalItem."Base Unit of Measure";
                        end;
                    "Entry Type"::Consumption:
                        begin
                            ProdOrderComp.SetFilterByReleasedOrderNo("Order No.");
                            ProdOrderComp.SetRange("Item No.", "Item No.");
                            if ProdOrderComp.Count = 1 then begin
                                ProdOrderComp.FindFirst();
                                CopyFromProdOrderComp(ProdOrderComp);
                            end else begin
                                "Unit of Measure Code" := MainRentalItem."Base Unit of Measure";
                                Validate("Prod. Order Comp. Line No.", 0);
                            end;
                        end;
                end;

                if "Unit of Measure Code" = '' then
                    "Unit of Measure Code" := MainRentalItem."Base Unit of Measure";

                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    "Unit of Measure Code" := MainRentalItem."Base Unit of Measure";
                OnValidateItemNoOnBeforeValidateUnitOfmeasureCode(Rec, MainRentalItem, CurrFieldNo);
                Validate("Unit of Measure Code");
                if "Variant Code" <> '' then
                    Validate("Variant Code");

                OnAfterOnValidateItemNoAssignByEntryType(Rec, MainRentalItem);

                CheckItemAvailable(FieldNo("Item No."));

                if ((not ("Order Type" in ["Order Type"::Production, "Order Type"::Assembly])) or ("Order No." = '')) and not "Phys. Inventory"
                then
                    CreateDim(
                      DATABASE::Item, "Item No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::"Work Center", "Work Center No.");

                OnBeforeVerifyReservedQty(Rec, xRec, FieldNo("Item No."));
                //ReserveItemJnlLine.VerifyChange(Rec, xRec);
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
            // CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
            begin
                TestField("Posting Date");
                Validate("Document Date", "Posting Date");
                //CheckDateConflict.ItemJnlLineCheck(Rec, CurrFieldNo <> 0);
            end;
        }
        field(5; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."]) then
                    TestField("Phys. Inventory", false);


                case "Entry Type" of
                    "Entry Type"::Purchase:
                        if UserMgt.GetRespCenter(1, '') <> '' then
                            "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
                    "Entry Type"::Sale:
                        begin
                            if UserMgt.GetRespCenter(0, '') <> '' then
                                "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
                            CheckItemAvailable(FieldNo("Entry Type"));
                        end;
                    "Entry Type"::Consumption, "Entry Type"::Output:
                        Validate("Order Type", "Order Type"::Production);
                    "Entry Type"::"Assembly Consumption", "Entry Type"::"Assembly Output":
                        Validate("Order Type", "Order Type"::Assembly);
                end;

                if xRec."Location Code" = '' then
                    if Location.Get("Location Code") then
                        if Location."Directed Put-away and Pick" then
                            "Location Code" := '';

                if "Item No." <> '' then
                    Validate("Location Code");

                Validate("Item No.");
                if "Entry Type" <> "Entry Type"::Transfer then begin
                    "New Location Code" := '';
                    "New Bin Code" := '';
                end;

                if "Entry Type" <> "Entry Type"::Output then
                    Type := Type::" ";

                SetDefaultPriceCalculationMethod();
            end;
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLocationCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger() then
                    TestField("Item No.");

                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '') and
                   ("No." = '')
                then begin
                    GetUnitAmount(FieldNo("Location Code"));
                    "Unit Cost" := UnitCost;
                    Validate("Unit Amount");
                    CheckItemAvailable(FieldNo("Location Code"));
                end;

                if "Location Code" <> xRec."Location Code" then begin
                    "Bin Code" := '';
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
                    end;
                    if "Entry Type" = "Entry Type"::Transfer then begin
                        "New Location Code" := "Location Code";
                        "New Bin Code" := "Bin Code";
                    end;
                end;

                Validate("Unit of Measure Code");
            end;
        }
        field(10; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Inventory Posting Group";
        }
        field(11; "Source Posting Group"; Code[20])
        {
            Caption = 'Source Posting Group';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = IF ("Source Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Source Type" = CONST(Vendor)) "Vendor Posting Group"
            ELSE
            IF ("Source Type" = CONST(Item)) "Inventory Posting Group";
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
            //   CallWhseCheck: Boolean;
            begin
                if ("Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger()) and (Quantity <> 0) then
                    TestField("Item No.");

                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                /*        CallWhseCheck :=
                         ("Entry Type" = "Entry Type"::"Assembly Consumption") or
                         ("Entry Type" = "Entry Type"::Consumption) or
                         ("Entry Type" = "Entry Type"::Output) and */
                /*    LastOutputOperation(Rec);
                 if CallWhseCheck then
                     WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec); */

                /* if CurrFieldNo <> 0 then
                    WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption(Quantity)); */

                "Quantity (Base)" := UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                if ("Entry Type" = "Entry Type"::Output) and
                   ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                then
                    "Invoiced Quantity" := 0
                else
                    "Invoiced Quantity" := Quantity;
                "Invoiced Qty. (Base)" :=
                  UOMMgt.CalcBaseQty(
                    "Item No.", "Variant Code", "Unit of Measure Code", "Invoiced Quantity", "Qty. per Unit of Measure");

                OnValidateQuantityOnBeforeGetUnitAmount(Rec, xRec, CurrFieldNo);

                GetUnitAmount(FieldNo(Quantity));
                UpdateAmount();

                CheckItemAvailable(FieldNo(Quantity));

                if "Entry Type" = "Entry Type"::Transfer then begin
                    "Qty. (Calculated)" := 0;
                    "Qty. (Phys. Inventory)" := 0;
                    "Last Item Ledger Entry No." := 0;
                end;

                CalcFields("Reserved Qty. (Base)");
                if Abs("Quantity (Base)") < Abs("Reserved Qty. (Base)") then
                    Error(Text001Lbl, FieldCaption("Reserved Qty. (Base)"));

                /*    if MainRentalItem."Item Tracking Code" <> '' then
                       ReserveItemJnlLine.VerifyQuantity(Rec, xRec); */
            end;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateAmount();
                if "Item No." <> '' then
                    if "Value Entry Type" = "Value Entry Type"::Revaluation then
                        "Unit Cost" := "Unit Amount"
                    else
                        case "Entry Type" of
                            "Entry Type"::Purchase,
                            "Entry Type"::"Positive Adjmt.",
                            "Entry Type"::"Assembly Output":
                                begin
                                    if "Entry Type" = "Entry Type"::"Positive Adjmt." then begin
                                        GetItem();
                                        if (CurrFieldNo = FieldNo("Unit Amount")) and
                                           (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard)
                                        then
                                            Error(
                                              Text002Lbl,
                                              FieldCaption("Unit Amount"), MainRentalItem.FieldCaption("Costing Method"), MainRentalItem."Costing Method");
                                    end;

                                    ReadGLSetup();
                                    if "Entry Type" = "Entry Type"::Purchase then
                                        "Unit Cost" := "Unit Amount";
                                    if "Entry Type" = "Entry Type"::"Positive Adjmt." then
                                        "Unit Cost" :=
                                          Round(
                                            "Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                                          "Overhead Rate" * "Qty. per Unit of Measure";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                            "Entry Type"::"Negative Adjmt.",
                            "Entry Type"::Consumption,
                            "Entry Type"::"Assembly Consumption":
                                begin
                                    GetItem();
                                    if (CurrFieldNo = FieldNo("Unit Amount")) and
                                       (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard)
                                    then
                                        Error(
                                          Text002Lbl,
                                          FieldCaption("Unit Amount"), MainRentalItem.FieldCaption("Costing Method"), MainRentalItem."Costing Method");
                                    "Unit Cost" := "Unit Amount";
                                    if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                                       ("Item Charge No." = '')
                                    then
                                        Validate("Unit Cost");
                                end;
                        end;
            end;
        }
        field(17; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("Item No.");
                RetrieveCosts();
                if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.", "Entry Type"::Consumption] then
                    if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then begin
                        if CurrFieldNo = FieldNo("Unit Cost") then
                            Error(
                              Text002Lbl,
                              FieldCaption("Unit Cost"), MainRentalItem.FieldCaption("Costing Method"), MainRentalItem."Costing Method");
                        "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                    end;

                if ("Item Charge No." = '') and
                   ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   (CurrFieldNo = FieldNo("Unit Cost"))
                then begin
                    case "Entry Type" of
                        "Entry Type"::Purchase:
                            "Unit Amount" := "Unit Cost";
                        "Entry Type"::"Positive Adjmt.",
                        "Entry Type"::"Assembly Output":
                            begin
                                ReadGLSetup();
                                "Unit Amount" :=
                                  Round(
                                    ("Unit Cost" - "Overhead Rate" * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                                    GLSetup."Unit-Amount Rounding Precision")
                            end;
                        "Entry Type"::"Negative Adjmt.",
                        "Entry Type"::Consumption,
                        "Entry Type"::"Assembly Consumption":
                            begin
                                if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then
                                    Error(
                                      Text002Lbl,
                                      FieldCaption("Unit Cost"), MainRentalItem.FieldCaption("Costing Method"), MainRentalItem."Costing Method");
                                "Unit Amount" := "Unit Cost";
                            end;
                    end;
                    UpdateAmount();
                end;
            end;
        }
        field(18; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField(Quantity);
                "Unit Amount" := Amount / Quantity;
                Validate("Unit Amount");
                ReadGLSetup();
                "Unit Amount" := Round("Unit Amount", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(22; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                if ("Order Type" <> "Order Type"::Production) or ("Order No." = '') then
                    CreateDim(
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Item, "Item No.",
                      DATABASE::"Work Center", "Work Center No.");
            end;
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Source Code";
        }
        field(29; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-to Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
            begin
                if "Applies-to Entry" <> 0 then begin
                    ItemLedgEntry.Get("Applies-to Entry");

                    if "Value Entry Type" = "Value Entry Type"::Revaluation then begin
                        if "Inventory Value Per" <> "Inventory Value Per"::" " then
                            Error(Text006Lbl, FieldCaption("Applies-to Entry"));

                        if "Inventory Value Per" = "Inventory Value Per"::" " then
                            if not RevaluationPerEntryAllowed("Item No.") then
                                Error(RevaluationPerEntryNotAllowedErr);

                        InitRevalJnlLine(ItemLedgEntry);
                        ItemLedgEntry.TestField(Positive, true);
                    end else begin
                        TestField(Quantity);
                        if Signed(Quantity) * ItemLedgEntry.Quantity > 0 then begin
                            if Quantity > 0 then
                                FieldError(Quantity, Text030Lbl);
                            if Quantity < 0 then
                                FieldError(Quantity, Text029Lbl);
                        end;
                        if ItemLedgEntry.TrackingExists() then
                            Error(Text033Lbl, FieldCaption("Applies-to Entry"), ItemTrackingLines.Caption);

                        if not ItemLedgEntry.Open then
                            Message(Text032Lbl, "Applies-to Entry");

                        if "Entry Type" = "Entry Type"::Output then begin
                            ItemLedgEntry.TestField("Order Type", "Order Type"::Production);
                            ItemLedgEntry.TestField("Order No.", "Order No.");
                            ItemLedgEntry.TestField("Order Line No.", "Order Line No.");
                            ItemLedgEntry.TestField("Entry Type", "Entry Type");
                        end;
                    end;

                    "Location Code" := ItemLedgEntry."Location Code";
                    "Variant Code" := ItemLedgEntry."Variant Code";
                end else
                    if "Value Entry Type" = "Value Entry Type"::Revaluation then begin
                        Validate("Unit Amount", 0);
                        Validate(Quantity, 0);
                        "Inventory Value (Calculated)" := 0;
                        "Inventory Value (Revalued)" := 0;
                        "Location Code" := '';
                        "Variant Code" := '';
                        "Bin Code" := '';
                    end;
            end;
        }
        field(32; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(34; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(35; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(37; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Item No.");
                TestField("Value Entry Type", "Value Entry Type"::"Direct Cost");
                TestField("Item Charge No.", '');
                if "Entry Type" in ["Entry Type"::Sale, "Entry Type"::"Negative Adjmt."] then
                    Error(
                      Text002Lbl,
                      FieldCaption("Indirect Cost %"), FieldCaption("Entry Type"), "Entry Type");

                GetItem();
                if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then
                    Error(
                      Text002Lbl,
                      FieldCaption("Indirect Cost %"), MainRentalItem.FieldCaption("Costing Method"), MainRentalItem."Costing Method");

                if "Entry Type" <> "Entry Type"::Purchase then
                    "Unit Cost" :=
                      Round(
                        "Unit Amount" * (1 + "Indirect Cost %" / 100) +
                        "Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(39; "Source Type"; Enum "TWE Rent. Item-Jnl.-Line S. Type")
        {
            Caption = 'Source Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipment Method";
        }
        field(41; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = CustomerContent;
            TableRelation = "Item Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(43; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            DataClassification = CustomerContent;
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(44; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            DataClassification = CustomerContent;
        }
        field(45; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
            DataClassification = CustomerContent;
        }
        field(46; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            DataClassification = CustomerContent;
            TableRelation = "Transport Method";
        }
        field(49; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(50; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Location Code" <> xRec."New Location Code" then begin
                    "New Bin Code" := '';
                    if ("New Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("New Location Code");
                        if IsDefaultBin() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "New Location Code", "New Bin Code")
                    end;
                end;

                //‚ReserveItemJnlLine.VerifyChange(Rec, xRec);
            end;
        }
        field(51; "New Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1,' + Text007Lbl;
            Caption = 'New Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
            end;
        }
        field(52; "New Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2,' + Text007Lbl;
            Caption = 'New Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");
            end;
        }
        field(53; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Qty. (Phys. Inventory)");
            end;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Phys. Inventory", true);

                /*   if CurrFieldNo <> 0 then
                      WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Qty. (Phys. Inventory)")); */

                PhysInvtEntered := true;
                Quantity := 0;
                if "Qty. (Phys. Inventory)" >= "Qty. (Calculated)" then begin
                    Validate("Entry Type", "Entry Type"::"Positive Adjmt.");
                    Validate(Quantity, "Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                end else begin
                    Validate("Entry Type", "Entry Type"::"Negative Adjmt.");
                    Validate(Quantity, "Qty. (Calculated)" - "Qty. (Phys. Inventory)");
                end;
                PhysInvtEntered := false;
            end;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Item Ledger Entry";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Product Posting Group";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            DataClassification = CustomerContent;
            TableRelation = "Entry/Exit Point";
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }
        field(62; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            DataClassification = CustomerContent;
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Specification";
        }
        field(65; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(68; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Journal Template Name"),
                                                                  "Source Ref. No." = FIELD("Line No."),
                                                                  "Source Type" = CONST(83),
                                                                  "Source Subtype" = FIELD("Entry Type"),
                                                                  "Source Batch Name" = FIELD("Journal Batch Name"),
                                                                  "Source Prod. Order Line" = CONST(0),
                                                                  "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Cost (ACY)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(73; "Source Currency Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Source Currency Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Currency;
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(80; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            DataClassification = CustomerContent;
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                if "Order Type" = xRec."Order Type" then
                    exit;
                Validate("Order No.", '');
                "Order Line No." := 0;
            end;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Order Type" = CONST(Production)) "Production Order"."No." WHERE(Status = CONST(Released));

            trigger OnValidate()
            var
                AssemblyHeader: Record "Assembly Header";
                ProdOrder: Record "Production Order";
                ProdOrderLine: Record "Prod. Order Line";
            begin
                case "Order Type" of
                    "Order Type"::Production,
                    "Order Type"::Assembly:
                        begin
                            if "Order No." = '' then begin
                                case "Order Type" of
                                    "Order Type"::Production:
                                        CreateProdDim();
                                    "Order Type"::Assembly:
                                        CreateAssemblyDim();
                                end;
                                exit;
                            end;

                            case "Order Type" of
                                "Order Type"::Production:
                                    begin
                                        GetMfgSetup();
                                        if MfgSetup."Doc. No. Is Prod. Order No." then
                                            "Document No." := "Order No.";
                                        ProdOrder.Get(ProdOrder.Status::Released, "Order No.");
                                        ProdOrder.TestField(Blocked, false);
                                        Description := ProdOrder.Description;
                                        OnValidateOrderNoOrderTypeProduction(Rec, ProdOrder);
                                    end;
                                "Order Type"::Assembly:
                                    begin
                                        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Order No.");
                                        Description := AssemblyHeader.Description;
                                    end;
                            end;

                            "Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
                            case true of
                                "Entry Type" = "Entry Type"::Output:
                                    begin
                                        "Inventory Posting Group" := ProdOrder."Inventory Posting Group";
                                        "Gen. Prod. Posting Group" := ProdOrder."Gen. Prod. Posting Group";
                                    end;
                                "Entry Type" = "Entry Type"::"Assembly Output":
                                    begin
                                        "Inventory Posting Group" := AssemblyHeader."Inventory Posting Group";
                                        "Gen. Prod. Posting Group" := AssemblyHeader."Gen. Prod. Posting Group";
                                    end;
                                "Entry Type" = "Entry Type"::Consumption:
                                    begin
                                        ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                                        if ProdOrderLine.Count = 1 then begin
                                            ProdOrderLine.FindFirst();
                                            Validate("Order Line No.", ProdOrderLine."Line No.");
                                        end;
                                    end;
                            end;

                            if ("Order No." <> xRec."Order No.") or ("Order Type" <> xRec."Order Type") then
                                case "Order Type" of
                                    "Order Type"::Production:
                                        CreateProdDim();
                                    "Order Type"::Assembly:
                                        CreateAssemblyDim();
                                end;
                        end;
                    "Order Type"::Transfer, "Order Type"::Service, "Order Type"::" ":
                        Error(Text002Lbl, FieldCaption("Order No."), FieldCaption("Order Type"), "Order Type");
                    else
                        OnValidateOrderNoOnCaseOrderTypeElse(Rec);
                end;
            end;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Order Type" = CONST(Production)) "Prod. Order Line"."Line No." WHERE(Status = CONST(Released),
                                                                                                     "Prod. Order No." = FIELD("Order No."));

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                TestField("Order No.");
                case "Order Type" of
                    "Order Type"::Production,
                    "Order Type"::Assembly:
                        begin
                            if "Order Type" = "Order Type"::Production then begin
                                ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                                ProdOrderLine.SetRange("Line No.", "Order Line No.");
                                if ProdOrderLine.FindFirst() then begin
                                    "Source Type" := "Source Type"::Item;
                                    "Source No." := ProdOrderLine."Item No.";
                                    "Order Line No." := ProdOrderLine."Line No.";
                                    "Routing No." := ProdOrderLine."Routing No.";
                                    "Routing Reference No." := ProdOrderLine."Routing Reference No.";
                                    if "Entry Type" = "Entry Type"::Output then begin
                                        "Location Code" := ProdOrderLine."Location Code";
                                        "Bin Code" := ProdOrderLine."Bin Code";
                                    end;
                                end;
                            end;

                            if "Order Line No." <> xRec."Order Line No." then
                                case "Order Type" of
                                    "Order Type"::Production:
                                        CreateProdDim();
                                    "Order Type"::Assembly:
                                        CreateAssemblyDim();
                                end;
                        end;
                    else
                        OnValidateOrderLineNoOnCaseOrderTypeElse(Rec);
                end;
            end;
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(481; "New Dimension Set ID"; Integer)
        {
            Caption = 'New Dimension Set ID';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(904; "Assemble to Order"; Boolean)
        {
            Caption = 'Assemble to Order';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(1000; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            DataClassification = CustomerContent;
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            DataClassification = CustomerContent;
        }
        field(1002; "Job Purchase"; Boolean)
        {
            Caption = 'Job Purchase';
            DataClassification = CustomerContent;
        }
        field(1030; "Job Contract Entry No."; Integer)
        {
            Caption = 'Job Contract Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                /*     if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then
                        WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec); */

                if "Variant Code" <> xRec."Variant Code" then begin
                    "Bin Code" := '';
                    /* if CurrFieldNo <> 0 then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Variant Code")); */
                    if ("Location Code" <> '') and ("Item No." <> '') then begin
                        GetLocation("Location Code");
                        if IsDefaultBin() then
                            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code")
                    end;
                    if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
                        "New Bin Code" := "Bin Code";
                end;
                if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   ("Item Charge No." = '')
                then begin
                    GetUnitAmount(FieldNo("Variant Code"));
                    "Unit Cost" := UnitCost;
                    Validate("Unit Amount");
                    Validate("Unit of Measure Code");
                    //  ReserveItemJnlLine.VerifyChange(Rec, xRec);
                end;

                if "Variant Code" <> '' then begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                end else begin
                    GetItem();
                    Description := MainRentalItem.Description;
                end;
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Entry Type" = FILTER(Purchase | "Positive Adjmt." | Output),
                                Quantity = FILTER(>= 0)) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                      "Item Filter" = FIELD("Item No."),
                                                                      "Variant Filter" = FIELD("Variant Code"))
            ELSE
            IF ("Entry Type" = FILTER(Purchase | "Positive Adjmt." | Output),
                                                                               Quantity = FILTER(< 0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                    "Item No." = FIELD("Item No."),
                                                                                                                                    "Variant Code" = FIELD("Variant Code"))
            ELSE
            IF ("Entry Type" = FILTER(Sale | "Negative Adjmt." | Transfer | Consumption),
                                                                                                                                             Quantity = FILTER(> 0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                  "Item No." = FIELD("Item No."),
                                                                                                                                                                                                  "Variant Code" = FIELD("Variant Code"))
            ELSE
            IF ("Entry Type" = FILTER(Sale | "Negative Adjmt." | Transfer | Consumption),
                                                                                                                                                                                                           Quantity = FILTER(<= 0)) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                                                                 "Item Filter" = FIELD("Item No."),
                                                                                                                                                                                                                                                 "Variant Filter" = FIELD("Variant Code"));

            trigger OnValidate()
            var
                ProdOrderComp: Record "Prod. Order Component";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                if "Bin Code" <> xRec."Bin Code" then begin
                    TestField("Location Code");
                    if "Bin Code" <> '' then begin
                        GetBin("Location Code", "Bin Code");
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        /*  if CurrFieldNo <> 0 then
                             WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Bin Code")); */
                        TestField("Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Item Journal Line",
                          CopyStr(FieldCaption("Bin Code"), 0, 30),
                          "Location Code",
                          "Bin Code",
                          "Entry Type".AsInteger());
                    end;
                    if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
                        "New Bin Code" := "Bin Code";

                    if ("Entry Type" = "Entry Type"::Consumption) and
                       ("Bin Code" <> '') and ("Prod. Order Comp. Line No." <> 0)
                    then begin
                        TestField("Order Type", "Order Type"::Production);
                        TestField("Order No.");
                        ProdOrderComp.Get(ProdOrderComp.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
                        if (ProdOrderComp."Bin Code" <> '') and (ProdOrderComp."Bin Code" <> "Bin Code") then
                            if not Confirm(
                                 Text021Lbl,
                                 false,
                                 "Bin Code",
                                 ProdOrderComp."Bin Code",
                                 "Order No.")
                            then
                                Error(UpdateInterruptedErr);
                    end;
                end;

                //ReserveItemJnlLine.VerifyChange(Rec, xRec);
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5406; "New Bin Code"; Code[20])
        {
            Caption = 'New Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("New Location Code"),
                                            "Item Filter" = FIELD("Item No."),
                                            "Variant Filter" = FIELD("Variant Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Bin Code" <> xRec."New Bin Code" then begin
                    TestField("New Location Code");
                    if "New Bin Code" <> '' then begin
                        GetBin("New Location Code", "New Bin Code");
                        GetLocation("New Location Code");
                        Location.TestField("Bin Mandatory");
                        /*   if CurrFieldNo <> 0 then
                              WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("New Bin Code")); */
                        TestField("New Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Item Journal Line",
                          CopyStr(FieldCaption("New Bin Code"), 0, 30),
                          "New Location Code",
                          "New Bin Code",
                          "Entry Type".AsInteger());
                    end;
                end;

                //ReserveItemJnlLine.VerifyChange(Rec, xRec);
            end;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateUnitOfMeasureCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                GetItem();
                //"Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(MainRentalItem, "Unit of Measure Code");

                /*        if "Entry Type" in ["Entry Type"::Consumption, "Entry Type"::Output] then
                           WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec); */

                /*      if CurrFieldNo <> 0 then
                         WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Unit of Measure Code")); */

                GetUnitAmount(FieldNo("Unit of Measure Code"));
                if "Value Entry Type" = "Value Entry Type"::Revaluation then
                    TestField("Qty. per Unit of Measure", 1);

                ReadGLSetup();
                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeCalcUnitCost(Rec, UnitCost, IsHandled);
                if not IsHandled then
                    "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");

                if "Entry Type" = "Entry Type"::Consumption then
                    "Indirect Cost %" := Round(MainRentalItem."Indirect Cost %" * "Qty. per Unit of Measure", 1);
                /*    "Overhead Rate" :=
                     Round(MainRentalItem."Overhead Rate" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                   "Unit Amount" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision"); */


                if "No." <> '' then
                    Validate("Cap. Unit of Measure Code");

                Validate("Unit Amount");

                if "Entry Type" = "Entry Type"::Output then begin
                    Validate("Output Quantity");
                    Validate("Scrap Quantity");
                end else
                    Validate(Quantity);

                CheckItemAvailable(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5413; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5415; "Invoiced Qty. (Base)"; Decimal)
        {
            Caption = 'Invoiced Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Journal Template Name"),
                                                                           "Source Ref. No." = FIELD("Line No."),
                                                                           "Source Type" = CONST(83),
                                                                           "Source Subtype" = FIELD("Entry Type"),
                                                                           "Source Batch Name" = FIELD("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = CONST(0),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5560; Level; Integer)
        {
            Caption = 'Level';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5561; "Flushing Method"; Enum "Flushing Method")
        {
            Caption = 'Flushing Method';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5562; "Changed by User"; Boolean)
        {
            Caption = 'Changed by User';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered No.';
            DataClassification = CustomerContent;
            TableRelation = Item;
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered Var. Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Originally Ordered No."));
        }
        field(5703; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
            DataClassification = CustomerContent;
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Category";
        }
        field(5705; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            DataClassification = CustomerContent;
        }
        field(5706; "Purchasing Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Purchasing Code';
            DataClassification = CustomerContent;
            TableRelation = Purchasing;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            Caption = 'Item Reference No.';
            DataClassification = CustomerContent;
        }
        field(5791; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
            DataClassification = CustomerContent;
        }
        field(5793; "Order Date"; Date)
        {
            Caption = 'Order Date';
            DataClassification = CustomerContent;
        }
        field(5800; "Value Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Value Entry Type';
            DataClassification = CustomerContent;
        }
        field(5801; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            DataClassification = CustomerContent;
            TableRelation = "Item Charge";
        }
        field(5802; "Inventory Value (Calculated)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Calculated)';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                ReadGLSetup();
                "Unit Cost (Calculated)" :=
                  Round("Inventory Value (Calculated)" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(5803; "Inventory Value (Revalued)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Revalued)';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
                Validate(Amount, "Inventory Value (Revalued)" - "Inventory Value (Calculated)");
                ReadGLSetup();
                if ("Unit Cost (Revalued)" <> xRec."Unit Cost (Revalued)") or
                   ("Inventory Value (Revalued)" <> xRec."Inventory Value (Revalued)")
                then begin
                    if CurrFieldNo <> FieldNo("Unit Cost (Revalued)") then
                        "Unit Cost (Revalued)" :=
                          Round("Inventory Value (Revalued)" / Quantity, GLSetup."Unit-Amount Rounding Precision");

                    if CurrFieldNo <> 0 then
                        ClearSingleAndRolledUpCosts();
                end
            end;
        }
        field(5804; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
            DataClassification = CustomerContent;
        }
        field(5805; "Inventory Value Per"; Option)
        {
            Caption = 'Inventory Value Per';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = ' ,Item,Location,Variant,Location and Variant';
            OptionMembers = " ",Item,Location,Variant,"Location and Variant";
        }
        field(5806; "Partial Revaluation"; Boolean)
        {
            Caption = 'Partial Revaluation';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5807; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-from Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
                IsHandled: Boolean;
            begin
                if "Applies-from Entry" <> 0 then begin
                    TestField(Quantity);
                    if Signed(Quantity) < 0 then begin
                        if Quantity > 0 then
                            FieldError(Quantity, Text030Lbl);
                        if Quantity < 0 then
                            FieldError(Quantity, Text029Lbl);
                    end;
                    ItemLedgEntry.Get("Applies-from Entry");
                    ItemLedgEntry.TestField(Positive, false);

                    OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(Rec, ItemLedgEntry, IsHandled);
                    if not IsHandled then
                        if ItemLedgEntry.TrackingExists() then
                            Error(Text033Lbl, FieldCaption("Applies-from Entry"), ItemTrackingLines.Caption);
                    "Unit Cost" := CalcUnitCost(ItemLedgEntry);
                end;
            end;
        }
        field(5808; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
            DataClassification = CustomerContent;
        }
        field(5809; "Unit Cost (Calculated)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Calculated)';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
            end;
        }
        field(5810; "Unit Cost (Revalued)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Revalued)';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                ReadGLSetup();
                TestField("Value Entry Type", "Value Entry Type"::Revaluation);
                if "Unit Cost (Revalued)" <> xRec."Unit Cost (Revalued)" then
                    Validate(
                      "Inventory Value (Revalued)",
                      Round(
                        "Unit Cost (Revalued)" * Quantity, GLSetup."Amount Rounding Precision"));
            end;
        }
        field(5811; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5812; "Update Standard Cost"; Boolean)
        {
            Caption = 'Update Standard Cost';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("Inventory Value Per");
                GetItem();
                MainRentalItem.TestField("Costing Method", MainRentalItem."Costing Method"::Standard);
            end;
        }
        field(5813; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = CustomerContent;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            DataClassification = CustomerContent;
        }
        field(5818; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
            DataClassification = CustomerContent;
        }
        field(5819; "Applies-to Value Entry"; Integer)
        {
            Caption = 'Applies-to Value Entry';
            DataClassification = CustomerContent;
        }
        field(5820; "Invoice-to Source No."; Code[20])
        {
            Caption = 'Invoice-to Source No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor;
        }
        field(5830; Type; Enum "Capacity Type Journal")
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Type = Type::Resource then
                    TestField("Entry Type", "Entry Type"::"Assembly Output")
                else
                    TestField("Entry Type", "Entry Type"::Output);
                Validate("No.", '');
            end;
        }
        field(5831; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Machine Center")) "Machine Center"
            ELSE
            IF (Type = CONST("Work Center")) "Work Center"
            ELSE
            IF (Type = CONST(Resource)) Resource;

            trigger OnValidate()
            var
                Resource: Record Resource;
            begin
                if Type = Type::Resource then
                    TestField("Entry Type", "Entry Type"::"Assembly Output")
                else
                    TestField("Entry Type", "Entry Type"::Output);
                if "No." = '' then begin
                    "Work Center No." := '';
                    "Work Center Group Code" := '';
                    Validate("Item No.");
                    if Type in [Type::"Work Center", Type::"Machine Center"] then
                        CreateDimWithProdOrderLine()
                    else
                        CreateDim(
                          DATABASE::"Work Center", "Work Center No.",
                          DATABASE::Item, "Item No.",
                          DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code");
                    exit;
                end;

                case Type of
                    Type::"Work Center":
                        begin
                            WorkCenter.Get("No.");
                            WorkCenter.TestField(Blocked, false);
                            CopyFromWorkCenter(WorkCenter);
                        end;
                    Type::"Machine Center":
                        begin
                            MachineCenter.Get("No.");
                            MachineCenter.TestField(Blocked, false);
                            WorkCenter.Get(MachineCenter."Work Center No.");
                            WorkCenter.TestField(Blocked, false);
                            CopyFromMachineCenter(MachineCenter);
                        end;
                    Type::Resource:
                        begin
                            Resource.Get("No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;

                if Type in [Type::"Work Center", Type::"Machine Center"] then begin
                    "Work Center No." := WorkCenter."No.";
                    "Work Center Group Code" := WorkCenter."Work Center Group Code";
                    Validate("Cap. Unit of Measure Code", WorkCenter."Unit of Measure Code");
                end;

                if "Work Center No." <> '' then
                    CreateDimWithProdOrderLine();
            end;
        }
        field(5838; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Order Type" = CONST(Production)) "Prod. Order Routing Line"."Operation No." WHERE(Status = CONST(Released),
                                                                                                                  "Prod. Order No." = FIELD("Order No."),
                                                                                                                  "Routing No." = FIELD("Routing No."),
                                                                                                                  "Routing Reference No." = FIELD("Routing Reference No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if "Operation No." = '' then
                    exit;

                TestField("Order Type", "Order Type"::Production);
                TestField("Order No.");
                TestField("Item No.");

                ConfirmOutputOnFinishedOperation();
                GetProdOrderRtngLine(ProdOrderRtngLine);

                case ProdOrderRtngLine.Type of
                    ProdOrderRtngLine.Type::"Work Center":
                        Type := Type::"Work Center";
                    ProdOrderRtngLine.Type::"Machine Center":
                        Type := Type::"Machine Center";
                end;
                Validate("No.", ProdOrderRtngLine."No.");
                Description := ProdOrderRtngLine.Description;
            end;
        }
        field(5839; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";
        }
        field(5841; "Setup Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Setup Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if SubcontractingWorkCenterUsed() and ("Setup Time" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Setup Time"), "Line No.");
                "Setup Time (Base)" := CalcBaseTime("Setup Time");
            end;
        }
        field(5842; "Run Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Run Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if SubcontractingWorkCenterUsed() and ("Run Time" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Run Time"), "Line No.");

                "Run Time (Base)" := CalcBaseTime("Run Time");
            end;
        }
        field(5843; "Stop Time"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Stop Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Stop Time (Base)" := CalcBaseTime("Stop Time");
            end;
        }
        field(5846; "Output Quantity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Output Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if SubcontractingWorkCenterUsed() and ("Output Quantity" <> 0) then
                    Error(SubcontractedErr, FieldCaption("Output Quantity"), "Line No.");

                ConfirmOutputOnFinishedOperation();

                /* if LastOutputOperation(Rec) then
                    WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec); */

                "Output Quantity (Base)" :=
                  UOMMgt.CalcBaseQty(
                    "Item No.", "Variant Code", "Unit of Measure Code", "Output Quantity", "Qty. per Unit of Measure");

                Validate(Quantity, "Output Quantity");
            end;
        }
        field(5847; "Scrap Quantity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Scrap Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Output);
                "Scrap Quantity (Base)" :=
                  UOMMgt.CalcBaseQty(
                    "Item No.", "Variant Code", "Unit of Measure Code", "Scrap Quantity", "Qty. per Unit of Measure");
            end;
        }
        field(5849; "Concurrent Capacity"; Decimal)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Concurrent Capacity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                TotalTime: Integer;
            begin
                TestField("Entry Type", "Entry Type"::Output);
                if "Concurrent Capacity" = 0 then
                    exit;

                TestField("Starting Time");
                TestField("Ending Time");
                TotalTime := CalendarMgt.CalcTimeDelta("Ending Time", "Starting Time");
                if "Ending Time" < "Starting Time" then
                    TotalTime := TotalTime + 86400000;
                TestField("Work Center No.");
                WorkCenter.Get("Work Center No.");
                Validate("Setup Time", 0);
                Validate(
                  "Run Time",
                  Round(
                    TotalTime / CalendarMgt.TimeFactor("Cap. Unit of Measure Code") *
                    "Concurrent Capacity", WorkCenter."Calendar Rounding Precision"));
            end;
        }
        field(5851; "Setup Time (Base)"; Decimal)
        {
            Caption = 'Setup Time (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Setup Time", "Setup Time (Base)");
            end;
        }
        field(5852; "Run Time (Base)"; Decimal)
        {
            Caption = 'Run Time (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Run Time", "Run Time (Base)");
            end;
        }
        field(5853; "Stop Time (Base)"; Decimal)
        {
            Caption = 'Stop Time (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Cap. Unit of Measure", 1);
                Validate("Stop Time", "Stop Time (Base)");
            end;
        }
        field(5856; "Output Quantity (Base)"; Decimal)
        {
            Caption = 'Output Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Output Quantity", "Output Quantity (Base)");
            end;
        }
        field(5857; "Scrap Quantity (Base)"; Decimal)
        {
            Caption = 'Scrap Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Scrap Quantity", "Scrap Quantity (Base)");
            end;
        }
        field(5858; "Cap. Unit of Measure Code"; Code[10])
        {
            Caption = 'Cap. Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(Resource)) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
            "Capacity Unit of Measure";

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                if Type <> Type::Resource then begin
                    "Qty. per Cap. Unit of Measure" :=
                      Round(
                        CalendarMgt.QtyperTimeUnitofMeasure(
                          "Work Center No.", "Cap. Unit of Measure Code"),
                        UOMMgt.QtyRndPrecision());

                    Validate("Setup Time");
                    Validate("Run Time");
                    Validate("Stop Time");
                end;

                if "Order No." <> '' then
                    case "Order Type" of
                        "Order Type"::Production:
                            begin
                                GetProdOrderRtngLine(ProdOrderRtngLine);
                                "Unit Cost" := ProdOrderRtngLine."Unit Cost per";

                                CostCalcMgt.RoutingCostPerUnit(
                                  Type, "No.", "Unit Amount", "Indirect Cost %", "Overhead Rate", "Unit Cost", "Unit Cost Calculation");
                            end;
                        "Order Type"::Assembly:
                            CostCalcMgt.ResourceCostPerUnit("No.", "Unit Amount", "Indirect Cost %", "Overhead Rate", "Unit Cost");
                        else
                            OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(Rec);
                    end;

                ReadGLSetup();
                "Unit Cost" :=
                  Round("Unit Cost" * "Qty. per Cap. Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                "Unit Amount" :=
                  Round("Unit Amount" * "Qty. per Cap. Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                Validate("Unit Amount");
            end;
        }
        field(5859; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Cap. Unit of Measure';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(5873; "Starting Time"; Time)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Starting Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Ending Time" < "Starting Time" then
                    "Ending Time" := "Starting Time";

                Validate("Concurrent Capacity");
            end;
        }
        field(5874; "Ending Time"; Time)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Ending Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                Validate("Concurrent Capacity");
            end;
        }
        field(5882; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Routing Header";
        }
        field(5883; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
        }
        field(5884; "Prod. Order Comp. Line No."; Integer)
        {
            Caption = 'Prod. Order Comp. Line No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Order Type" = CONST(Production)) "Prod. Order Component"."Line No." WHERE(Status = CONST(Released),
                                                                                                          "Prod. Order No." = FIELD("Order No."),
                                                                                                          "Prod. Order Line No." = FIELD("Order Line No."));

            trigger OnValidate()
            begin
                if "Prod. Order Comp. Line No." <> xRec."Prod. Order Comp. Line No." then
                    CreateProdDim();
            end;
        }
        field(5885; Finished; Boolean)
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Finished';
            DataClassification = CustomerContent;
        }
        field(5887; "Unit Cost Calculation"; Option)
        {
            Caption = 'Unit Cost Calculation';
            DataClassification = CustomerContent;
            OptionCaption = 'Time,Units';
            OptionMembers = Time,Units;
        }
        field(5888; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
            DataClassification = CustomerContent;
        }
        field(5895; "Stop Code"; Code[10])
        {
            Caption = 'Stop Code';
            DataClassification = CustomerContent;
            TableRelation = Stop;
        }
        field(5896; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
            DataClassification = CustomerContent;
            TableRelation = Scrap;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateScrapCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::"Machine Center");
            end;
        }
        field(5898; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(5899; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Shift";
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6503; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6504; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6505; "New Item Expiration Date"; Date)
        {
            Caption = 'New Item Expiration Date';
            DataClassification = CustomerContent;
        }
        field(6506; "Item Expiration Date"; Date)
        {
            Caption = 'Item Expiration Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6600; "Return Reason Code"; Code[10])
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
        field(7315; "Warehouse Adjustment"; Boolean)
        {
            Caption = 'Warehouse Adjustment';
            DataClassification = CustomerContent;
        }
        field(7316; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
            DataClassification = SystemMetadata;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
                   ("Item Charge No." <> '')
                then begin
                    "Overhead Rate" := 0;
                    Validate("Indirect Cost %", 0);
                end else
                    Validate("Indirect Cost %");
            end;
        }
        field(99000756; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Material Cost';
            DataClassification = CustomerContent;
        }
        field(99000757; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Capacity Cost';
            DataClassification = CustomerContent;
        }
        field(99000758; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Subcontrd. Cost';
            DataClassification = CustomerContent;
        }
        field(99000759; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Cap. Ovhd Cost';
            DataClassification = CustomerContent;
        }
        field(99000760; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
        }
        field(99000761; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Material Cost';
            DataClassification = CustomerContent;
        }
        field(99000762; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Capacity Cost';
            DataClassification = CustomerContent;
        }
        field(99000763; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Subcontracted Cost';
            DataClassification = CustomerContent;
        }
        field(99000764; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
        }
        field(99000765; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Cap. Overhead Cost';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
        }
        key(Key2; "Entry Type", "Item No.", "Variant Code", "Location Code", "Bin Code", "Posting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key3; "Entry Type", "Item No.", "Variant Code", "New Location Code", "New Bin Code", "Posting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Quantity (Base)";
        }
        key(Key4; "Item No.", "Posting Date")
        {
        }
        key(Key5; "Journal Template Name", "Journal Batch Name", "Item No.", "Location Code", "Variant Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        //ReserveItemJnlLine.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnInsert()
    begin
        LockTable();
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
        ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
        ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");

        CheckPlanningAssignment();
    end;

    trigger OnModify()
    begin
        OnBeforeVerifyReservedQty(Rec, xRec, 0);
        //ReserveItemJnlLine.VerifyChange(Rec, xRec);
        CheckPlanningAssignment();
    end;

    trigger OnRename()
    begin
        //ReserveItemJnlLine.RenameLine(Rec, xRec);
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        RentalItemJnlLine: Record "TWE Rental Item Journal Line";
        MainRentalItem: Record "TWE Main Rental Item";
        ItemVariant: Record "Item Variant";
        GLSetup: Record "General Ledger Setup";
        MfgSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        Location: Record Location;
        Bin: Record Bin;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        UserMgt: Codeunit "User Setup Management";
        CalendarMgt: Codeunit "Shop Calendar Management";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        WMSManagement: Codeunit "WMS Management";
        PhysInvtEntered: Boolean;
        GLSetupRead: Boolean;
        MfgSetupRead: Boolean;
        UnitCost: Decimal;
        Text007Lbl: Label 'New ';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
        Text021Lbl: Label 'The entered bin code %1 is different from the bin code %2 in production order component %3.\\Are you sure that you want to post the consumption from bin code %1?', Comment = '%1 = "Bin Code", %2 = ProdOrderComp."Bin Code",%3 = "Order No."';
        Text029Lbl: Label 'must be positive';
        Text030Lbl: Label 'must be negative';
        Text031Lbl: Label 'You can not insert item number %1 because it is not produced on released production order %2.', Comment = '%1 = "Item No.",%2 = "Order No."';
        Text032Lbl: Label 'When posting, the entry %1 will be opened first.', Comment = '%1 = "Applies-to Entry"';
        Text033Lbl: Label 'If the item carries serial or lot numbers, then you must use the %1 field in the %2 window.', Comment = '%1 = FieldCaption "Applies-to Entry",%2 = ItemTrackingLines Caption';
        RevaluationPerEntryNotAllowedErr: Label 'This item has already been revalued with the Calculate Inventory Value function, so you cannot use the Applies-to Entry field as that may change the valuation.';
        SubcontractedErr: Label '%1 must be zero in line number %2 because it is linked to the subcontracted work center.', Comment = '%1 - Field Caption, %2 - Line No.';
        FinishedOutputQst: Label 'The operation has been finished. Do you want to post output for the finished operation?';
        SalesBlockedErr: Label 'You cannot sell this item because the Sales Blocked check box is selected on the item card.';
        PurchasingBlockedErr: Label 'You cannot purchase this item because the Purchasing Blocked check box is selected on the item card.';
        BlockedErr: Label 'You cannot purchase this item because the Blocked check box is selected on the item card.';
        Text001Lbl: Label '%1 must be reduced.', Comment = '%1 = FieldCaption "Reserved Qty. (Base)"';
        Text002Lbl: Label 'You cannot change %1 when %2 is %3.', Comment = '%1 = FieldCaption "Unit Amount",%2 = FieldCaption "Costing Method",%3 = "Costing Method"';
        Text006Lbl: Label 'You must not enter %1 in a revaluation sum line.', Comment = '%1 = FieldCaption "Applies-to Entry"';

    procedure EmptyLine(): Boolean
    begin
        exit(
          (Quantity = 0) and
          ((TimeIsEmpty() and ("Item No." = '')) or
           ("Value Entry Type" = "Value Entry Type"::Revaluation)));
    end;

    procedure IsValueEntryForDeletedItem(): Boolean
    begin
        exit(
          (("Entry Type" = "Entry Type"::Output) or ("Value Entry Type" = "Value Entry Type"::Rounding)) and
          ("Item No." = '') and ("Item Charge No." = '') and ("Invoiced Qty. (Base)" <> 0));
    end;

    local procedure CalcBaseTime(Qty: Decimal): Decimal
    begin
        if "Run Time" <> 0 then
            TestField("Qty. per Cap. Unit of Measure");
        exit(Round(Qty * "Qty. per Cap. Unit of Measure", UOMMgt.TimeRndPrecision()));
    end;

    procedure UpdateAmount()
    begin
        Amount := Round(Quantity * "Unit Amount");

        OnAfterUpdateAmount(Rec);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        RentalItemJnlLine2: Record "TWE Rental Item Journal Line";
        PositiveFilterValue: Boolean;
    begin
        OnBeforeSelectItemEntry(Rec, xRec, CurrentFieldNo);

        if ("Entry Type" = "Entry Type"::Output) and
           ("Value Entry Type" <> "Value Entry Type"::Revaluation) and
           (CurrentFieldNo = FieldNo("Applies-to Entry"))
        then begin
            ItemLedgEntry.SetCurrentKey(
              "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            ItemLedgEntry.SetRange("Order Type", "Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "Order No.");
            ItemLedgEntry.SetRange("Order Line No.", "Order Line No.");
            ItemLedgEntry.SetRange("Entry Type", "Entry Type");
            ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", 0);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange("Item No.", "Item No.");
        end;

        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");

        if CurrentFieldNo = FieldNo("Applies-to Entry") then begin
            if Quantity <> 0 then begin
                PositiveFilterValue := (Signed(Quantity) < 0) or ("Value Entry Type" = "Value Entry Type"::Revaluation);
                ItemLedgEntry.SetRange(Positive, PositiveFilterValue);
            end;

            if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open);
                ItemLedgEntry.SetRange(Open, true);
            end;
        end else
            ItemLedgEntry.SetRange(Positive, false);

        OnSelectItemEntryOnBeforeOpenPage(ItemLedgEntry, Rec);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            RentalItemJnlLine2 := Rec;
            if CurrentFieldNo = FieldNo("Applies-to Entry") then
                RentalItemJnlLine2.Validate("Applies-to Entry", ItemLedgEntry."Entry No.")
            else
                RentalItemJnlLine2.Validate("Applies-from Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := RentalItemJnlLine2;
        end;
    end;

    local procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        if (CurrFieldNo = 0) or (CurrFieldNo <> CalledByFieldNo) then // Prevent two checks on quantity
            exit;

        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;
    end;

    local procedure GetItem()
    begin
        if MainRentalItem."No." <> "Item No." then
            MainRentalItem.Get("Item No.");

        OnAfterGetItemChange(MainRentalItem, Rec);
    end;

    /// <summary>
    /// SetUpNewLine.
    /// </summary>
    /// <param name="LastRentalItemJnlLine">Record "TWE Rental Item Journal Line".</param>
    procedure SetUpNewLine(LastRentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
        MfgSetup.Get();
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        RentalItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        RentalItemJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if RentalItemJnlLine.FindFirst() then begin
            "Posting Date" := LastRentalItemJnlLine."Posting Date";
            "Document Date" := LastRentalItemJnlLine."Posting Date";
            if (ItemJnlTemplate.Type in
                [ItemJnlTemplate.Type::Consumption, ItemJnlTemplate.Type::Output])
            then begin
                if not MfgSetup."Doc. No. Is Prod. Order No." then
                    "Document No." := LastRentalItemJnlLine."Document No."
            end else
                "Document No." := LastRentalItemJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            if ItemJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.TryGetNextNo(ItemJnlBatch."No. Series", "Posting Date");
            end;
            if (ItemJnlTemplate.Type in
                [ItemJnlTemplate.Type::Consumption, ItemJnlTemplate.Type::Output]) and
               not MfgSetup."Doc. No. Is Prod. Order No."
            then
                if ItemJnlBatch."No. Series" <> '' then begin
                    Clear(NoSeriesMgt);
                    "Document No." := NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", "Posting Date", false);
                end;
        end;
        "Recurring Method" := LastRentalItemJnlLine."Recurring Method";
        "Entry Type" := LastRentalItemJnlLine."Entry Type";
        "Source Code" := ItemJnlTemplate."Source Code";
        "Reason Code" := ItemJnlBatch."Reason Code";
        "Posting No. Series" := ItemJnlBatch."Posting No. Series";
        if ItemJnlTemplate.Type = ItemJnlTemplate.Type::Revaluation then begin
            "Value Entry Type" := "Value Entry Type"::Revaluation;
            "Entry Type" := "Entry Type"::"Positive Adjmt.";
        end;
        SetDefaultPriceCalculationMethod();

        case "Entry Type" of
            "Entry Type"::Purchase:
                "Location Code" := UserMgt.GetLocation(1, '', UserMgt.GetPurchasesFilter());
            "Entry Type"::Sale:
                "Location Code" := UserMgt.GetLocation(0, '', UserMgt.GetSalesFilter());
            "Entry Type"::Output:
                Clear(DimMgt);
        end;

        if Location.Get("Location Code") then
            if Location."Directed Put-away and Pick" then
                "Location Code" := '';

        OnAfterSetupNewLine(Rec, LastRentalItemJnlLine, ItemJnlTemplate);
    end;

    local procedure SetDefaultPriceCalculationMethod()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case "Entry Type" of
            "Entry Type"::Purchase,
            "Entry Type"::Output,
            "Entry Type"::"Assembly Output":
                begin
                    PurchasesPayablesSetup.Get();
                    "Price Calculation Method" := PurchasesPayablesSetup."Price Calculation Method";
                end;
            "Entry Type"::Sale:
                begin
                    SalesReceivablesSetup.Get();
                    "Price Calculation Method" := SalesReceivablesSetup."Price Calculation Method";
                end;
            else
                "Price Calculation Method" := "Price Calculation Method"::" ";
        end;
    end;

    /// <summary>
    /// SetDocNos.
    /// </summary>
    /// <param name="DocType">Enum "Item Ledger Document Type".</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="ExtDocNo">Text[35].</param>
    /// <param name="PostingNos">Code[20].</param>
    procedure SetDocNos(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; PostingNos: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Posting No. Series" := PostingNos;
    end;

    local procedure GetUnitAmount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        UnitCostValue: Decimal;
        IsHandled: Boolean;
    begin
        RetrieveCosts();
        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        OnBeforeGetUnitAmount(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        UnitCostValue := UnitCost;
        /*   if (CalledByFieldNo = FieldNo(Quantity)) and
             (MainRentalItem."No." <> '') and (MainRentalItem."Costing Method" <> MainRentalItem."Costing Method"::Standard)
          then
              UnitCostValue := "Unit Cost" / UOMMgt.GetQtyPerUnitOfMeasure(LastRentalItemJnlLine, "Unit of Measure Code"); */

        case "Entry Type" of
            "Entry Type"::Purchase:
                ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            "Entry Type"::Sale:
                ApplyPrice(PriceType::Sale, CalledByFieldNo);
            "Entry Type"::"Positive Adjmt.":
                "Unit Amount" :=
                  Round(
                    ((UnitCostValue - "Overhead Rate") * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Negative Adjmt.":
                "Unit Amount" := UnitCostValue * "Qty. per Unit of Measure";
            "Entry Type"::Transfer:
                "Unit Amount" := 0;
        end;
        OnAfterGetUnitAmount(Rec);
    end;

    /// <summary>
    /// ApplyPrice.
    /// </summary>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="CalledByFieldNo">Integer.</param>
    procedure ApplyPrice(PriceType: Enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    /// <summary>
    /// GetLineWithPrice.
    /// </summary>
    /// <param name="LineWithPrice">VAR Interface "Line With Price".</param>
    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
    begin
        LineWithPrice := ItemJournalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    procedure Signed(Value: Decimal): Decimal
    begin
        case "Entry Type" of
            "Entry Type"::Purchase,
          "Entry Type"::"Positive Adjmt.",
          "Entry Type"::Output,
          "Entry Type"::"Assembly Output":
                exit(Value);
            "Entry Type"::Sale,
          "Entry Type"::"Negative Adjmt.",
          "Entry Type"::Consumption,
          "Entry Type"::Transfer,
          "Entry Type"::"Assembly Consumption":
                exit(-Value);
        end;
    end;

    procedure IsInbound(): Boolean
    begin
        exit((Signed(Quantity) > 0) or (Signed("Invoiced Quantity") > 0));
    end;

    procedure OpenItemTrackingLines(IsReclass: Boolean)
    begin
        //ReserveItemJnlLine.CallItemTracking(Rec, IsReclass);
    end;

    local procedure PickDimension(TableArray: array[10] of Integer; CodeArray: array[10] of Code[20]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        SourceCode: Code[10];
    begin
        SourceCode := "Source Code";
        if SourceCode = '' then
            if ItemJournalTemplate.Get("Journal Template Name") then
                SourceCode := ItemJournalTemplate."Source Code";

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableArray, CodeArray, SourceCode,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", InheritFromDimSetID, InheritFromTableNo);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if "Entry Type" = "Entry Type"::Transfer then begin
            "New Dimension Set ID" := "Dimension Set ID";
            "New Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            "New Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
        end;
    end;

    local procedure CreateCodeArray(var CodeArray: array[10] of Code[20]; No1: Code[20]; No2: Code[20]; No3: Code[20])
    begin
        Clear(CodeArray);
        CodeArray[1] := No1;
        CodeArray[2] := No2;
        CodeArray[3] := No3;
    end;

    local procedure CreateTableArray(var TableID: array[10] of Integer; Type1: Integer; Type2: Integer; Type3: Integer)
    begin
        Clear(TableID);
        TableID[1] := Type1;
        TableID[2] := Type2;
        TableID[3] := Type3;
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        CreateTableArray(TableID, Type1, Type2, Type3);
        CreateCodeArray(No, No1, No2, No3);
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);
        PickDimension(TableID, No, 0, 0);
    end;

    procedure CopyDim(DimesionSetID: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        ReadGLSetup();
        "Dimension Set ID" := DimesionSetID;
        DimSetEntry.SetRange("Dimension Set ID", DimesionSetID);
        DimSetEntry.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
        if DimSetEntry.FindFirst() then
            "Shortcut Dimension 1 Code" := DimSetEntry."Dimension Value Code"
        else
            "Shortcut Dimension 1 Code" := '';
        DimSetEntry.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
        if DimSetEntry.FindFirst() then
            "Shortcut Dimension 2 Code" := DimSetEntry."Dimension Value Code"
        else
            "Shortcut Dimension 2 Code" := '';
    end;

    procedure CreateProdDim()
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := 0;
        if ("Order Type" <> "Order Type"::Production) or ("Order No." = '') then
            exit;
        ProdOrder.Get(ProdOrder.Status::Released, "Order No.");
        i := 1;
        DimSetIDArr[i] := ProdOrder."Dimension Set ID";
        if "Order Line No." <> 0 then begin
            i := i + 1;
            ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.");
            DimSetIDArr[i] := ProdOrderLine."Dimension Set ID";
        end;
        if "Prod. Order Comp. Line No." <> 0 then begin
            i := i + 1;
            ProdOrderComp.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.", "Prod. Order Comp. Line No.");
            DimSetIDArr[i] := ProdOrderComp."Dimension Set ID";
        end;

        OnCreateProdDimOnAfterCreateDimSetIDArr(Rec, DimSetIDArr, i);
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure CreateAssemblyDim()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        DimSetIDArr: array[10] of Integer;
        i: Integer;
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := 0;
        if ("Order Type" <> "Order Type"::Assembly) or ("Order No." = '') then
            exit;
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Order No.");
        i := 1;
        DimSetIDArr[i] := AssemblyHeader."Dimension Set ID";
        if "Order Line No." <> 0 then begin
            i := i + 1;
            AssemblyLine.Get(AssemblyLine."Document Type"::Order, "Order No.", "Order Line No.");
            DimSetIDArr[i] := AssemblyLine."Dimension Set ID";
        end;

        OnCreateAssemblyDimOnAfterCreateDimSetIDArr(Rec, DimSetIDArr, i);
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure CreateDimWithProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        InheritFromDimSetID: Integer;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if "Order Type" = "Order Type"::Production then
            if ProdOrderLine.Get(ProdOrderLine.Status::Released, "Order No.", "Order Line No.") then
                InheritFromDimSetID := ProdOrderLine."Dimension Set ID";

        CreateTableArray(TableID, DATABASE::"Work Center", DATABASE::"Salesperson/Purchaser", 0);
        CreateCodeArray(No, "Work Center No.", "Salespers./Purch. Code", '');
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);
        PickDimension(TableID, No, InheritFromDimSetID, DATABASE::Item);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ValidateNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    procedure LookupNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, NewShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    procedure ShowNewShortcutDimCode(var NewShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("New Dimension Set ID", NewShortcutDimCode);
    end;

    local procedure InitRevalJnlLine(ItemLedgEntry2: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        CostAmtActual: Decimal;
    begin
        if "Value Entry Type" <> "Value Entry Type"::Revaluation then
            exit;

        ItemLedgEntry2.TestField("Item No.", "Item No.");
        ItemLedgEntry2.TestField("Completely Invoiced", true);
        ItemLedgEntry2.TestField(Positive, true);
        ItemApplnEntry.CheckAppliedFromEntryToAdjust(ItemLedgEntry2."Entry No.");

        Validate("Entry Type", ItemLedgEntry2."Entry Type");
        "Posting Date" := ItemLedgEntry2."Posting Date";
        Validate("Unit Amount", 0);
        Validate(Quantity, ItemLedgEntry2."Invoiced Quantity");

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Rounding);
        ValueEntry.Find('-');
        repeat
            if not (ValueEntry."Expected Cost" or ValueEntry."Partial Revaluation") then
                CostAmtActual := CostAmtActual + ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;

        Validate("Inventory Value (Calculated)", CostAmtActual);
        Validate("Inventory Value (Revalued)", CostAmtActual);

        "Location Code" := ItemLedgEntry2."Location Code";
        "Variant Code" := ItemLedgEntry2."Variant Code";
        "Applies-to Entry" := ItemLedgEntry2."Entry No.";
        CopyDim(ItemLedgEntry2."Dimension Set ID");
    end;

    procedure CopyDocumentFields(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SourceCode: Code[10]; NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    procedure CopyFromRentalHeader(RentalHeader: Record "TWE Rental Header")
    begin
        "Posting Date" := RentalHeader."Posting Date";
        "Document Date" := RentalHeader."Document Date";
        "Order Date" := RentalHeader."Order Date";
        "Source Posting Group" := RentalHeader."Customer Posting Group";
        "Salespers./Purch. Code" := RentalHeader."Salesperson Code";
        "Reason Code" := RentalHeader."Reason Code";
        "Source Currency Code" := RentalHeader."Currency Code";
        "Shpt. Method Code" := RentalHeader."Shipment Method Code";
        "Price Calculation Method" := RentalHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromSalesHeader(Rec, RentalHeader);
    end;

    procedure CopyFromRentalLine(RentalLine: Record "TWE Rental Line")
    begin
        "Item No." := RentalLine."No.";
        Description := RentalLine.Description;
        "Shortcut Dimension 1 Code" := RentalLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := RentalLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := RentalLine."Dimension Set ID";
        "Location Code" := RentalLine."Location Code";
        "Bin Code" := RentalLine."Bin Code";
        "Variant Code" := RentalLine."Variant Code";
        "Inventory Posting Group" := RentalLine."Posting Group";
        "Gen. Bus. Posting Group" := RentalLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := RentalLine."Gen. Prod. Posting Group";
        "Entry/Exit Point" := RentalLine."Exit Point";
        Area := RentalLine.Area;
        "Drop Shipment" := RentalLine."Drop Shipment";
        "Entry Type" := "Entry Type"::Sale;
        "Unit of Measure Code" := RentalLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := RentalLine."Qty. per Unit of Measure";
        //"Item Reference No." := RentalLine."Item Reference No.";
        //"Item Category Code" := RentalLine."Item Category Code";
        Nonstock := RentalLine.Nonstock;
        "Purchasing Code" := RentalLine."Purchasing Code";
        "Return Reason Code" := RentalLine."Return Reason Code";
        "Planned Delivery Date" := RentalLine."Planned Delivery Date";
        "Document Line No." := RentalLine."Line No.";
        "Unit Cost" := RentalLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := RentalLine."Unit Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Source Type" := "Source Type"::Customer;
        "Source No." := RentalLine."Rented-to Customer No.";
        "Price Calculation Method" := RentalLine."Price Calculation Method";
        "Invoice-to Source No." := RentalLine."Bill-to Customer No.";

        OnAfterCopyItemJnlLineFromSalesLine(Rec, RentalLine);
    end;

    procedure CopyFromPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        "Posting Date" := PurchHeader."Posting Date";
        "Document Date" := PurchHeader."Document Date";
        "Source Posting Group" := PurchHeader."Vendor Posting Group";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "Country/Region Code" := PurchHeader."Buy-from Country/Region Code";
        "Reason Code" := PurchHeader."Reason Code";
        "Source Currency Code" := PurchHeader."Currency Code";
        "Shpt. Method Code" := PurchHeader."Shipment Method Code";
        "Price Calculation Method" := PurchHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromPurchHeader(Rec, PurchHeader);
    end;

    procedure CopyFromPurchLine(PurchLine: Record "Purchase Line")
    begin
        "Item No." := PurchLine."No.";
        Description := PurchLine.Description;
        "Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchLine."Dimension Set ID";
        "Location Code" := PurchLine."Location Code";
        "Bin Code" := PurchLine."Bin Code";
        "Variant Code" := PurchLine."Variant Code";
        "Item Category Code" := PurchLine."Item Category Code";
        "Inventory Posting Group" := PurchLine."Posting Group";
        "Gen. Bus. Posting Group" := PurchLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        "Job No." := PurchLine."Job No.";
        "Job Task No." := PurchLine."Job Task No.";
        if "Job No." <> '' then
            "Job Purchase" := true;
        "Applies-to Entry" := PurchLine."Appl.-to Item Entry";
        "Transaction Type" := PurchLine."Transaction Type";
        "Transport Method" := PurchLine."Transport Method";
        "Entry/Exit Point" := PurchLine."Entry Point";
        Area := PurchLine.Area;
        "Transaction Specification" := PurchLine."Transaction Specification";
        "Drop Shipment" := PurchLine."Drop Shipment";
        "Entry Type" := "Entry Type"::Purchase;
        if PurchLine."Prod. Order No." <> '' then begin
            "Order Type" := "Order Type"::Production;
            "Order No." := PurchLine."Prod. Order No.";
            "Order Line No." := PurchLine."Prod. Order Line No.";
        end;
        "Unit of Measure Code" := PurchLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := PurchLine."Qty. per Unit of Measure";
        "Item Reference No." := PurchLine."Item Reference No.";
        "Document Line No." := PurchLine."Line No.";
        "Unit Cost" := PurchLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := PurchLine."Unit Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchLine."Buy-from Vendor No.";
        "Price Calculation Method" := PurchLine."Price Calculation Method";
        "Invoice-to Source No." := PurchLine."Pay-to Vendor No.";
        "Purchasing Code" := PurchLine."Purchasing Code";
        "Indirect Cost %" := PurchLine."Indirect Cost %";
        "Overhead Rate" := PurchLine."Overhead Rate";
        "Return Reason Code" := PurchLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromPurchLine(Rec, PurchLine);
    end;

    procedure CopyFromServHeader(ServiceHeader: Record "Service Header")
    begin
        "Document Date" := ServiceHeader."Document Date";
        "Order Date" := ServiceHeader."Order Date";
        "Source Posting Group" := ServiceHeader."Customer Posting Group";
        "Salespers./Purch. Code" := ServiceHeader."Salesperson Code";
        "Country/Region Code" := ServiceHeader."VAT Country/Region Code";
        "Reason Code" := ServiceHeader."Reason Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := ServiceHeader."Customer No.";
        "Shpt. Method Code" := ServiceHeader."Shipment Method Code";
        "Price Calculation Method" := ServiceHeader."Price Calculation Method";

        OnAfterCopyItemJnlLineFromServHeader(Rec, ServiceHeader);
    end;

    procedure CopyFromServLine(ServiceLine: Record "Service Line")
    begin
        "Item No." := ServiceLine."No.";
        "Posting Date" := ServiceLine."Posting Date";
        Description := ServiceLine.Description;
        "Shortcut Dimension 1 Code" := ServiceLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServiceLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServiceLine."Dimension Set ID";
        "Location Code" := ServiceLine."Location Code";
        "Bin Code" := ServiceLine."Bin Code";
        "Variant Code" := ServiceLine."Variant Code";
        "Inventory Posting Group" := ServiceLine."Posting Group";
        "Gen. Bus. Posting Group" := ServiceLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServiceLine."Gen. Prod. Posting Group";
        "Applies-to Entry" := ServiceLine."Appl.-to Item Entry";
        "Transaction Type" := ServiceLine."Transaction Type";
        "Transport Method" := ServiceLine."Transport Method";
        "Entry/Exit Point" := ServiceLine."Exit Point";
        Area := ServiceLine.Area;
        "Transaction Specification" := ServiceLine."Transaction Specification";
        "Entry Type" := "Entry Type"::Sale;
        "Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        "Derived from Blanket Order" := false;
        "Item Category Code" := ServiceLine."Item Category Code";
        Nonstock := ServiceLine.Nonstock;
        "Return Reason Code" := ServiceLine."Return Reason Code";
        "Order Type" := "Order Type"::Service;
        "Order No." := ServiceLine."Document No.";
        "Order Line No." := ServiceLine."Line No.";
        "Job No." := ServiceLine."Job No.";
        "Job Task No." := ServiceLine."Job Task No.";
        "Price Calculation Method" := ServiceLine."Price Calculation Method";

        OnAfterCopyItemJnlLineFromServLine(Rec, ServiceLine);
    end;

    procedure CopyFromServShptHeader(ServShptHeader: Record "Service Shipment Header")
    begin
        "Document Date" := ServShptHeader."Document Date";
        "Order Date" := ServShptHeader."Order Date";
        "Country/Region Code" := ServShptHeader."VAT Country/Region Code";
        "Source Posting Group" := ServShptHeader."Customer Posting Group";
        "Salespers./Purch. Code" := ServShptHeader."Salesperson Code";
        "Reason Code" := ServShptHeader."Reason Code";

        OnAfterCopyItemJnlLineFromServShptHeader(Rec, ServShptHeader);
    end;

    procedure CopyFromServShptLine(ServShptLine: Record "Service Shipment Line")
    begin
        "Item No." := ServShptLine."No.";
        Description := ServShptLine.Description;
        "Gen. Bus. Posting Group" := ServShptLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServShptLine."Gen. Prod. Posting Group";
        "Inventory Posting Group" := ServShptLine."Posting Group";
        "Location Code" := ServShptLine."Location Code";
        "Unit of Measure Code" := ServShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Variant Code" := ServShptLine."Variant Code";
        "Bin Code" := ServShptLine."Bin Code";
        "Shortcut Dimension 1 Code" := ServShptLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServShptLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServShptLine."Dimension Set ID";
        "Entry/Exit Point" := ServShptLine."Exit Point";
        "Value Entry Type" := RentalItemJnlLine."Value Entry Type"::"Direct Cost";
        "Transaction Type" := ServShptLine."Transaction Type";
        "Transport Method" := ServShptLine."Transport Method";
        Area := ServShptLine.Area;
        "Transaction Specification" := ServShptLine."Transaction Specification";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Item Category Code" := ServShptLine."Item Category Code";
        Nonstock := ServShptLine.Nonstock;
        "Return Reason Code" := ServShptLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromServShptLine(Rec, ServShptLine);
    end;

    procedure CopyFromServShptLineUndo(ServShptLine: Record "Service Shipment Line")
    begin
        "Item No." := ServShptLine."No.";
        "Posting Date" := ServShptLine."Posting Date";
        "Order Date" := ServShptLine."Order Date";
        "Inventory Posting Group" := ServShptLine."Posting Group";
        "Gen. Bus. Posting Group" := ServShptLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServShptLine."Gen. Prod. Posting Group";
        "Location Code" := ServShptLine."Location Code";
        "Variant Code" := ServShptLine."Variant Code";
        "Bin Code" := ServShptLine."Bin Code";
        "Entry/Exit Point" := ServShptLine."Exit Point";
        "Shortcut Dimension 1 Code" := ServShptLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServShptLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServShptLine."Dimension Set ID";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Item No." := ServShptLine."No.";
        Description := ServShptLine.Description;
        "Location Code" := ServShptLine."Location Code";
        "Variant Code" := ServShptLine."Variant Code";
        "Transaction Type" := ServShptLine."Transaction Type";
        "Transport Method" := ServShptLine."Transport Method";
        Area := ServShptLine.Area;
        "Transaction Specification" := ServShptLine."Transaction Specification";
        "Unit of Measure Code" := ServShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Derived from Blanket Order" := false;
        "Item Category Code" := ServShptLine."Item Category Code";
        Nonstock := ServShptLine.Nonstock;
        "Return Reason Code" := ServShptLine."Return Reason Code";

        OnAfterCopyItemJnlLineFromServShptLineUndo(Rec, ServShptLine);
    end;

    procedure CopyFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Line No." := JobJnlLine."Line No.";
        "Item No." := JobJnlLine."No.";
        "Posting Date" := JobJnlLine."Posting Date";
        "Document Date" := JobJnlLine."Document Date";
        "Document No." := JobJnlLine."Document No.";
        "External Document No." := JobJnlLine."External Document No.";
        Description := JobJnlLine.Description;
        "Location Code" := JobJnlLine."Location Code";
        "Applies-to Entry" := JobJnlLine."Applies-to Entry";
        "Applies-from Entry" := JobJnlLine."Applies-from Entry";
        "Shortcut Dimension 1 Code" := JobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := JobJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := JobJnlLine."Dimension Set ID";
        "Country/Region Code" := JobJnlLine."Country/Region Code";
        "Entry Type" := "Entry Type"::"Negative Adjmt.";
        "Source Code" := JobJnlLine."Source Code";
        "Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        "Posting No. Series" := JobJnlLine."Posting No. Series";
        "Variant Code" := JobJnlLine."Variant Code";
        "Bin Code" := JobJnlLine."Bin Code";
        "Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        "Reason Code" := JobJnlLine."Reason Code";
        "Transaction Type" := JobJnlLine."Transaction Type";
        "Transport Method" := JobJnlLine."Transport Method";
        "Entry/Exit Point" := JobJnlLine."Entry/Exit Point";
        Area := JobJnlLine.Area;
        "Transaction Specification" := JobJnlLine."Transaction Specification";
        "Invoiced Quantity" := JobJnlLine.Quantity;
        "Invoiced Qty. (Base)" := JobJnlLine."Quantity (Base)";
        "Source Currency Code" := JobJnlLine."Source Currency Code";
        Quantity := JobJnlLine.Quantity;
        "Quantity (Base)" := JobJnlLine."Quantity (Base)";
        "Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";
        "Unit Cost" := JobJnlLine."Unit Cost (LCY)";
        "Unit Cost (ACY)" := JobJnlLine."Unit Cost";
        Amount := JobJnlLine."Total Cost (LCY)";
        "Amount (ACY)" := JobJnlLine."Total Cost";
        "Value Entry Type" := "Value Entry Type"::"Direct Cost";
        "Job No." := JobJnlLine."Job No.";
        "Job Task No." := JobJnlLine."Job Task No.";
        "Shpt. Method Code" := JobJnlLine."Shpt. Method Code";

        OnAfterCopyItemJnlLineFromJobJnlLine(Rec, JobJnlLine);
    end;

    local procedure CopyFromProdOrderComp(ProdOrderComp: Record "Prod. Order Component")
    begin
        Validate("Order Line No.", ProdOrderComp."Prod. Order Line No.");
        Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Location Code" := ProdOrderComp."Location Code";
        Validate("Variant Code", ProdOrderComp."Variant Code");
        Validate("Bin Code", ProdOrderComp."Bin Code");

        OnAfterCopyFromProdOrderComp(Rec, ProdOrderComp);
    end;

    local procedure CopyFromProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    begin
        Validate("Order Line No.", ProdOrderLine."Line No.");
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Location Code" := ProdOrderLine."Location Code";
        Validate("Variant Code", ProdOrderLine."Variant Code");
        Validate("Bin Code", ProdOrderLine."Bin Code");

        OnAfterCopyFromProdOrderLine(Rec, ProdOrderLine);
    end;

    local procedure CopyFromWorkCenter(WorkCenter: Record "Work Center")
    begin
        "Work Center No." := WorkCenter."No.";
        Description := WorkCenter.Name;
        "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
        "Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";

        OnAfterCopyFromWorkCenter(Rec, WorkCenter);
    end;

    local procedure CopyFromMachineCenter(MachineCenter: Record "Machine Center")
    begin
        "Work Center No." := MachineCenter."Work Center No.";
        Description := MachineCenter.Name;
        "Gen. Prod. Posting Group" := MachineCenter."Gen. Prod. Posting Group";
        "Unit Cost Calculation" := "Unit Cost Calculation"::Time;

        OnAfterCopyFromMachineCenter(Rec, MachineCenter);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;

        OnAfterReadGLSetup(GLSetup);
    end;

    protected procedure RetrieveCosts()
    var
        SKU: Record "Stockkeeping Unit";
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveCosts(Rec, UnitCost, IsHandled);
        if IsHandled then
            exit;

        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then
            exit;

        ReadGLSetup();
        GetItem();

        InventorySetup.Get();
        if InventorySetup."Average Cost Calc. Type" = InventorySetup."Average Cost Calc. Type"::Item then
            UnitCost := MainRentalItem."Unit Cost"
        else
            if SKU.Get("Location Code", "Item No.", "Variant Code") then
                UnitCost := SKU."Unit Cost"
            else
                UnitCost := MainRentalItem."Unit Cost";

        OnRetrieveCostsOnAfterSetUnitCost(Rec, UnitCost, MainRentalItem);

        if "Entry Type" = "Entry Type"::Transfer then
            UnitCost := 0
        else
            if MainRentalItem."Costing Method" <> MainRentalItem."Costing Method"::Standard then
                UnitCost := Round(UnitCost, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        LocalUnitCost: Decimal;
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
        LocalUnitCost :=
          (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgEntry.Quantity;

        exit(Abs(LocalUnitCost * "Qty. per Unit of Measure"));
    end;

    local procedure ClearSingleAndRolledUpCosts()
    begin
        "Single-Level Material Cost" := "Unit Cost (Revalued)";
        "Single-Level Capacity Cost" := 0;
        "Single-Level Subcontrd. Cost" := 0;
        "Single-Level Cap. Ovhd Cost" := 0;
        "Single-Level Mfg. Ovhd Cost" := 0;
        "Rolled-up Material Cost" := "Unit Cost (Revalued)";
        "Rolled-up Capacity Cost" := 0;
        "Rolled-up Subcontracted Cost" := 0;
        "Rolled-up Mfg. Ovhd Cost" := 0;
        "Rolled-up Cap. Overhead Cost" := 0;
    end;

    local procedure GetMfgSetup()
    begin
        if not MfgSetupRead then
            MfgSetup.Get();
        MfgSetupRead := true;
    end;

    local procedure GetProdOrderRtngLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
        TestField("Order Type", "Order Type"::Production);
        TestField("Order No.");
        TestField("Operation No.");

        ProdOrderRtngLine.Get(
          ProdOrderRtngLine.Status::Released,
          "Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
    end;

    procedure OnlyStopTime(): Boolean
    begin
        exit(("Setup Time" = 0) and ("Run Time" = 0) and ("Stop Time" <> 0));
    end;

    procedure OutputValuePosting(): Boolean
    begin
        exit(TimeIsEmpty() and ("Invoiced Quantity" <> 0) and not Subcontracting);
    end;

    procedure TimeIsEmpty(): Boolean
    begin
        exit(("Setup Time" = 0) and ("Run Time" = 0) and ("Stop Time" = 0));
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(DATABASE::"Item Journal Line", "Entry Type".AsInteger(),
            "Journal Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if (Bin.Code <> BinCode) or (Bin."Location Code" <> LocationCode) then
                Bin.Get(LocationCode, BinCode);
    end;

    procedure GetSourceCaption(): Text
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1 = Jnl. Template Name, %2 = Journal Batch Name,%3 = Item No.';
    begin
        exit(StrSubstNo(Placeholder001Lbl, "Journal Template Name", "Journal Batch Name", "Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Posting Date";
        ReservEntry."Shipment Date" := "Posting Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(
          DATABASE::"Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", false);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);
        //ReservEntry.SetTrackingFilterFromItemJnlLine(Rec);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        ReservEntry.ClearTrackingFilter();
        exit(not ReservEntry.IsEmpty);
    end;

    procedure ItemPosting(): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NextOperationNoIsEmpty: Boolean;
        IsHandled: Boolean;
    begin
        if ("Entry Type" = "Entry Type"::Output) and ("Output Quantity" <> 0) and ("Operation No." <> '') then begin
            ProdOrderRoutingLine.Get(
              ProdOrderRoutingLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
            IsHandled := false;
            OnAfterItemPosting(ProdOrderRoutingLine, NextOperationNoIsEmpty, IsHandled);
            if IsHandled then
                exit(NextOperationNoIsEmpty);
            exit(ProdOrderRoutingLine."Next Operation No." = '');
        end;

        exit(true);
    end;

    local procedure CheckPlanningAssignment()
    begin
        if ("Quantity (Base)" <> 0) and ("Item No." <> '') and ("Posting Date" <> 0D) and
           ("Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::"Positive Adjmt.", "Entry Type"::Transfer])
        then
            if ("Entry Type" = "Entry Type"::Transfer) and ("Location Code" = "New Location Code") then
                exit;
    end;

    procedure LastOutputOperation(RentalItemJnlLine: Record "TWE Rental Item Journal Line"): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Operation: Boolean;
        IsHandled: Boolean;
    begin
        if RentalItemJnlLine."Operation No." <> '' then begin
            IsHandled := false;
            OnLastOutputOperationOnBeforeTestRoutingNo(RentalItemJnlLine, IsHandled);
            if not IsHandled then
                RentalItemJnlLine.TestField("Routing No.");
            if not ProdOrderRtngLine.Get(
                 ProdOrderRtngLine.Status::Released, RentalItemJnlLine."Order No.",
                 RentalItemJnlLine."Routing Reference No.", RentalItemJnlLine."Routing No.", RentalItemJnlLine."Operation No.")
            then
                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Finished, RentalItemJnlLine."Order No.",
                  RentalItemJnlLine."Routing Reference No.", RentalItemJnlLine."Routing No.", RentalItemJnlLine."Operation No.");
            if RentalItemJnlLine.Finished then
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished
            else
                ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::"In Progress";
            Operation := not ItemJnlPostLine.NextOperationExist(ProdOrderRtngLine);
        end else
            Operation := true;

        exit(Operation);
    end;

    procedure LookupItemNo()
    var
        MainRentalItemList: Page "TWE Main Rental Item List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupItemNo(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Entry Type" of
            "Entry Type"::Consumption:
                LookupProdOrderComp();
            "Entry Type"::Output:
                LookupProdOrderLine();
            else begin
                    MainRentalItemList.LookupMode := true;
                    if MainRentalItemList.RunModal() = ACTION::LookupOK then begin
                        MainRentalItemList.GetRecord(MainRentalItem);
                        Validate("Item No.", MainRentalItem."No.");
                    end;
                end;
        end;
    end;

    local procedure LookupProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLineList: Page "Prod. Order Line List";
    begin
        ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := "Order No.";
        ProdOrderLine."Line No." := "Order Line No.";
        ProdOrderLine."Item No." := "Item No.";

        ProdOrderLineList.LookupMode(true);
        ProdOrderLineList.SetTableView(ProdOrderLine);
        ProdOrderLineList.SetRecord(ProdOrderLine);

        if ProdOrderLineList.RunModal() = ACTION::LookupOK then begin
            ProdOrderLineList.GetRecord(ProdOrderLine);
            Validate("Item No.", ProdOrderLine."Item No.");
            if "Order Line No." <> ProdOrderLine."Line No." then
                Validate("Order Line No.", ProdOrderLine."Line No.");
        end;
    end;

    local procedure LookupProdOrderComp()
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderCompLineList: Page "Prod. Order Comp. Line List";
    begin
        ProdOrderComp.SetFilterByReleasedOrderNo("Order No.");
        if "Order Line No." <> 0 then
            ProdOrderComp.SetRange("Prod. Order Line No.", "Order Line No.");
        ProdOrderComp.Status := ProdOrderComp.Status::Released;
        ProdOrderComp."Prod. Order No." := "Order No.";
        ProdOrderComp."Prod. Order Line No." := "Order Line No.";
        ProdOrderComp."Line No." := "Prod. Order Comp. Line No.";
        ProdOrderComp."Item No." := "Item No.";

        ProdOrderCompLineList.LookupMode(true);
        ProdOrderCompLineList.SetTableView(ProdOrderComp);
        ProdOrderCompLineList.SetRecord(ProdOrderComp);

        if ProdOrderCompLineList.RunModal() = ACTION::LookupOK then begin
            ProdOrderCompLineList.GetRecord(ProdOrderComp);
            if "Prod. Order Comp. Line No." <> ProdOrderComp."Line No." then begin
                Validate("Item No.", ProdOrderComp."Item No.");
                Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            end;
        end;
    end;

    procedure RecalculateUnitAmount()
    var
        ItemJnlLine1: Record "Item Journal Line";
        PriceType: Enum "Price Type";
    begin
        GetItem();

        if ("Value Entry Type" <> "Value Entry Type"::"Direct Cost") or
           ("Item Charge No." <> '')
        then begin
            "Indirect Cost %" := 0;
            "Overhead Rate" := 0;
        end else
            "Indirect Cost %" := MainRentalItem."Indirect Cost %";
        //"Overhead Rate" := MainRentalItem."Overhead Rate";

        //"Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(MainRentalItem, "Unit of Measure Code");
        GetUnitAmount(FieldNo("Unit of Measure Code"));

        ReadGLSetup();

        UpdateAmount();

        case "Entry Type" of
            "Entry Type"::Purchase:
                begin
                    ItemJnlLine1.Copy(Rec);
                    ItemJnlLine1.ApplyPrice(PriceType::Purchase, FieldNo("Unit of Measure Code"));
                    "Unit Cost" := Round(ItemJnlLine1."Unit Amount" * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
                end;
            "Entry Type"::Sale:
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
            "Entry Type"::"Positive Adjmt.":
                "Unit Cost" :=
                  Round(
                    "Unit Amount" * (1 + "Indirect Cost %" / 100), GLSetup."Unit-Amount Rounding Precision") +
                  "Overhead Rate" * "Qty. per Unit of Measure";
            "Entry Type"::"Negative Adjmt.":
                if not "Phys. Inventory" then
                    "Unit Cost" := UnitCost * "Qty. per Unit of Measure";
        end;

        if "Entry Type" in ["Entry Type"::Purchase, "Entry Type"::"Positive Adjmt."] then
            if MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard then
                "Unit Cost" := Round(UnitCost * "Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");

        OnAfterRecalculateUnitAmount(Rec, xRec, CurrFieldNo);
    end;

    procedure IsReclass(RentalItemJnlLine: Record "TWE Rental Item Journal Line"): Boolean
    begin
        if (RentalItemJnlLine."Entry Type" = RentalItemJnlLine."Entry Type"::Transfer) and
           ((RentalItemJnlLine."Order Type" <> RentalItemJnlLine."Order Type"::Transfer) or (RentalItemJnlLine."Order No." = ''))
        then
            exit(true);
        exit(false);
    end;

    procedure CheckWhse(LocationCode: Code[20]; var QtyToPost: Decimal)
    var
        LocalLocation: Record Location;
    begin
        LocalLocation.Get(LocationCode);
        if LocalLocation."Require Put-away" and
           (not LocalLocation."Directed Put-away and Pick") and
           (not LocalLocation."Require Receive")
        then
            QtyToPost := 0;
    end;

    procedure ShowDimensions()
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1 = "Journal Template Name",%2 = "Journal Batch Name",%3 = "Line No."';
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo(Placeholder001Lbl, "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ShowReclasDimensions()
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1 = "Journal Template Name",%2 = "Journal Batch Name",%3 = "Line No."';
    begin
        DimMgt.EditReclasDimensionSet(
          "Dimension Set ID", "New Dimension Set ID", StrSubstNo(Placeholder001Lbl, "Journal Template Name", "Journal Batch Name", "Line No."),
          "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code");
    end;

    procedure PostingItemJnlFromProduction(Print: Boolean)
    var
        ProductionOrder: Record "Production Order";
        IsHandled: Boolean;
    begin
        if ("Order Type" = "Order Type"::Production) and ("Order No." <> '') then
            ProductionOrder.Get(ProductionOrder.Status::Released, "Order No.");

        IsHandled := false;
        OnBeforePostingItemJnlFromProduction(Rec, Print, IsHandled);
        if IsHandled then
            exit;

        if Print then
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post+Print", Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post", Rec);
    end;

    procedure IsAssemblyResourceConsumpLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Assembly Output") and (Type = Type::Resource));
    end;

    procedure IsAssemblyOutputLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Assembly Output") and (Type = Type::" "));
    end;

    procedure IsATOCorrection(): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        if not Correction then
            exit(false);
        if "Entry Type" <> "Entry Type"::Sale then
            exit(false);
        if not ItemLedgEntry.Get("Applies-to Entry") then
            exit(false);
        if ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Sale then
            exit(false);
        PostedATOLink.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        PostedATOLink.SetRange("Document Type", PostedATOLink."Document Type"::"Sales Shipment");
        PostedATOLink.SetRange("Document No.", ItemLedgEntry."Document No.");
        PostedATOLink.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
        exit(not PostedATOLink.IsEmpty);
    end;

    local procedure RevaluationPerEntryAllowed(ItemNo: Code[20]): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        GetItem();
        if MainRentalItem."Costing Method" <> MainRentalItem."Costing Method"::Average then
            exit(true);

        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.SetRange("Partial Revaluation", true);
        exit(ValueEntry.IsEmpty);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        OnAfterClearTracking(Rec);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromNewSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."New Serial No.";
        "New Lot No." := TrackingSpecification."New Lot No.";

        OnAfterCopyNewTrackingFromNewSpec(Rec, TrackingSpecification);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure HasSameNewTracking() IsSameTracking: Boolean
    begin
        IsSameTracking := ("Serial No." = "New Serial No.") and ("Lot No." = "New Lot No.");

        OnAfterHasSameNewTracking(Rec, IsSameTracking);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestItemFields(Rec, ItemNo, VariantCode, LocationCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure DisplayErrorIfItemIsBlocked(MainRentalItem: Record "TWE Main Rental Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDisplayErrorIfItemIsBlocked(MainRentalItem, Rec, IsHandled);
        if IsHandled then
            exit;

        if MainRentalItem.Blocked then
            Error(BlockedErr);

        if "Item Charge No." <> '' then
            exit;

        case "Entry Type" of
            "Entry Type"::Purchase:
                if MainRentalItem."Purchasing Blocked" and
                   not ("Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Credit Memo"])
                then
                    Error(PurchasingBlockedErr);
            "Entry Type"::Sale:
                if MainRentalItem."Sales Blocked" and
                   not ("Document Type" in ["Document Type"::"Sales Return Receipt", "Document Type"::"Sales Credit Memo"])
                then
                    Error(SalesBlockedErr);
        end;

        OnAfterDisplayErrorIfItemIsBlocked(MainRentalItem, Rec);
    end;

    procedure IsPurchaseReturn(): Boolean
    begin
        exit(
          ("Document Type" in ["Document Type"::"Purchase Credit Memo",
                               "Document Type"::"Purchase Return Shipment",
                               "Document Type"::"Purchase Invoice",
                               "Document Type"::"Purchase Receipt"]) and
          (Quantity < 0));
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        ItemJournalBatch: Record "Item Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                ItemJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            ItemJournalBatch.SetFilter(Name, BatchFilter);
            if not ItemJournalBatch.IsEmpty() then;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure SubcontractingWorkCenterUsed(): Boolean
    var
        localWorkCenter: Record "Work Center";
    begin
        if Type = Type::"Work Center" then
            if localWorkCenter.Get("Work Center No.") then
                exit(localWorkCenter."Subcontractor No." <> '');

        exit(false);
    end;

    procedure CheckItemJournalLineRestriction()
    begin
        OnCheckItemJournalLinePostRestrictions();
    end;

    procedure CheckTrackingIsEmpty()
    begin
        RentalItemJnlLine.TestField("Serial No.", '');
        RentalItemJnlLine.TestField("Lot No.", '');

        OnAfterCheckTrackingisEmpty(Rec);
    end;

    procedure CheckNewTrackingIsEmpty()
    begin
        RentalItemJnlLine.TestField("New Serial No.", '');
        RentalItemJnlLine.TestField("New Lot No.", '');

        OnAfterCheckNewTrackingisEmpty(Rec);
    end;

    procedure CheckTrackingEqualItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TestField("Lot No.", ItemLedgerEntry."Lot No.");
        TestField("Serial No.", ItemLedgerEntry."Serial No.");

        OnAfterCheckTrackingEqualItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    /// <summary>
    /// CheckTrackingEqualTrackingSpecification.
    /// </summary>
    /// <param name="TrackingSpecification">Record "Tracking Specification".</param>
    procedure CheckTrackingEqualTrackingSpecification(TrackingSpecification: Record "Tracking Specification")
    begin
        TestField("Lot No.", TrackingSpecification."Lot No.");
        TestField("Serial No.", TrackingSpecification."Serial No.");

        OnAfterCheckTrackingEqualTrackingSpecification(Rec, TrackingSpecification);
    end;

    local procedure IsDefaultBin() Result: Boolean
    begin
        Result := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";

        OnAfterIsDefaultBin(Location, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var LastRentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemJournalTemplate: Record "Item Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingisEmpty(RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNewTrackingisEmpty(RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingEqualItemLedgEntry(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingEqualTrackingSpecification(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesHeader(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchHeader(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromPurchLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServHeader(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; ServHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptHeader(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; ServShptHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; ServShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShptLineUndo(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; ServShptLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromJobJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromNewSpec(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromProdOrderComp(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromProdOrderLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromWorkCenter(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromMachineCenter(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDisplayErrorIfItemIsBlocked(var MainRentalItem: Record "TWE Main Rental Item"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemChange(var MainRentalItem: Record "TWE Main Rental Item"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitAmount(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameNewTracking(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsSameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemPosting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var NextOperationNoIsEmpty: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnValidateItemNoAssignByEntryType(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateUnitAmount(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmount(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDisplayErrorIfItemIsBlocked(var MainRentalItem: Record "TWE Main Rental Item"; var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnitAmount(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItemNo(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostingItemJnlFromProduction(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; Print: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCosts(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectItemEntry(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitOfMeasureCode(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; CalledByFieldNo: Integer)
    begin
    end;

    local procedure ConfirmOutputOnFinishedOperation()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if ("Entry Type" <> "Entry Type"::Output) or ("Output Quantity" = 0) then
            exit;

        if not ProdOrderRtngLine.Get(
             ProdOrderRtngLine.Status::Released, "Order No.", "Routing Reference No.", "Routing No.", "Operation No.")
        then
            exit;

        if ProdOrderRtngLine."Routing Status" <> ProdOrderRtngLine."Routing Status"::Finished then
            exit;

        if not Confirm(FinishedOutputQst) then
            Error(UpdateInterruptedErr);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCheckItemJournalLinePostRestrictions()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAssemblyDimOnAfterCreateDimSetIDArr(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var DimSetIDArr: array[10] of Integer; var i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdDimOnAfterCreateDimSetIDArr(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var DimSetIDArr: array[10] of Integer; var i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLastOutputOperationOnBeforeTestRoutingNo(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnBeforeOpenPage(var ItemLedgerEntry: Record "Item Ledger Entry"; RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCapUnitOfMeasureCodeOnCaseOrderTypeElse(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterGetItem(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOrderTypeProduction(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderNoOnCaseOrderTypeElse(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderLineNoOnCaseOrderTypeElse(var RentalItemJournalLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetUnitAmount(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestItemFields(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeCalcUnitCost(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateScrapCode(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveCostsOnAfterSetUnitCost(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var UnitCost: Decimal; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeValidateUnitOfmeasureCode(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var MainRentalItem: Record "TWE Main Rental Item"; CurrFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLocationCode(RentalItemJournalLine: Record "TWE Rental Item Journal Line"; xRentalItemJournalLine: Record "TWE Rental Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsDefaultBin(Location: Record Location; var Result: Boolean)
    begin
    end;
}

