/// <summary>
/// Table TWE Rental Line (ID 707064611).
/// </summary>
table 50016 "TWE Rental Line"
{
    Caption = 'Rental Line';
    //DrillDownPageID = "Sales Lines";
    //LookupPageID = "Sales Lines";

    fields
    {
        field(1; "Document Type"; Enum "TWE Rental Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
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
            TableRelation = "TWE Rental Header"."No." WHERE("Document Type" = FIELD("Document Type"));
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

            trigger OnValidate()
            var
                TempTWERentalLine: Record "TWE Rental Line" temporary;
            begin
                TestStatusOpen();
                GetRentalHeader();

                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');

                TestField("Return Receipt No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                CheckAssocPurchOrder(CopyStr(FieldCaption(Type), 1, 250));

                if Type <> xRec.Type then
                    case xRec.Type of
                        Type::"Rental Item":
                            if Quantity <> 0 then begin
                                RentalHeader.TestField(Status, RentalHeader.Status::Open);
                                CalcFields("Reserved Qty. (Base)");
                                TestField("Reserved Qty. (Base)", 0);
                                VerifyChangeForTWERentalLineReserve(FieldNo(Type));
                                OnValidateTypeOnAfterCheckMainRentalItem(Rec, xRec);
                            end;
                    end;

                TempTWERentalLine := Rec;
                Init();
                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := true;

                Type := TempTWERentalLine.Type;
                "System-Created Entry" := TempTWERentalLine."System-Created Entry";
                "Currency Code" := RentalHeader."Currency Code";

                OnValidateTypeOnCopyFromTempTWERentalLine(Rec, TempTWERentalLine);

                if Type = Type::"Rental Item" then begin
                    if RentalHeader.InventoryPickConflict("Document Type", "Document No.", RentalHeader."Shipping Advice") then
                        Error(Text056Lbl, RentalHeader."Shipping Advice");
                    if RentalHeader.WhseShipmentConflict("Document Type", "Document No.", RentalHeader."Shipping Advice") then
                        Error(Text052Lbl, RentalHeader."Shipping Advice");
                end;
            end;
        }
        field(6; "No."; Code[20])
        {
            //CaptionClass = GetCaptionClass(FieldNo("No."));
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account"),
                                     "System-Created Entry" = CONST(false)) "G/L Account" WHERE("Direct Posting" = CONST(true),
                                                                                               "Account Type" = CONST(Posting),
                                                                                               Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account"), "System-Created Entry" = CONST(true)) "G/L Account"
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST("Rental Item"), "Document Type" = FILTER(<> "Credit Memo" & <> "Return Shipment")) "TWE Main Rental Item" WHERE(Blocked = CONST(false), "Sales Blocked" = CONST(false))
            ELSE
            IF (Type = CONST("Rental Item"), "Document Type" = FILTER("Credit Memo" | "Return Shipment")) "TWE Main Rental Item" WHERE(Blocked = CONST(false));

            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempTWERentalLine: Record "TWE Rental Line" temporary;
                IsHandled: Boolean;
            begin
                GetRentalSetup();

                //"No." := FindOrCreateRecordByNo("No.");

                TestStatusOpen();
                CheckMainRentalItemAvailable(FieldNo("No."));

                if (xRec."No." <> "No.") and (Quantity <> 0) then begin
                    TestField("Qty. to Asm. to Order (Base)", 0);
                    CalcFields("Reserved Qty. (Base)");
                    TestField("Reserved Qty. (Base)", 0);

                    OnValidateNoOnAfterVerifyChange(Rec, xRec);
                end;

                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                TestField("Return Receipt No.", '');

                CheckAssocPurchOrder(Copystr(FieldCaption("No."), 1, 250));

                OnValidateNoOnBeforeInitRec(Rec, xRec, CurrFieldNo);
                TempTWERentalLine := Rec;
                Init();
                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := true;
                Type := TempTWERentalLine.Type;
                "No." := TempTWERentalLine."No.";
                OnValidateNoOnCopyFromTempTWERentalLine(Rec, TempTWERentalLine, xRec);
                if "No." = '' then
                    exit;

                if HasTypeToFillMandatoryFields() then
                    Quantity := TempTWERentalLine.Quantity;

                "System-Created Entry" := TempTWERentalLine."System-Created Entry";
                GetRentalHeader();
                InitHeaderDefaults(RentalHeader);
                OnValidateNoOnAfterInitHeaderDefaults(RentalHeader, TempTWERentalLine);

                "Promised Delivery Date" := RentalHeader."Promised Delivery Date";
                "Requested Delivery Date" := RentalHeader."Requested Delivery Date";

                IsHandled := false;
                OnValidateNoOnBeforeCalcShipmentDateForLocation(IsHandled);
                if not IsHandled then
                    CalcShipmentDateForLocation();

                IsHandled := false;
                OnValidateNoOnBeforeUpdateDates(Rec, xRec, RentalHeader, CurrFieldNo, IsHandled, TempTWERentalLine);
                if not IsHandled then
                    UpdateDates();

                OnAfterAssignHeaderValues(Rec, RentalHeader);

                case Type of
                    Type::" ":
                        CopyFromStandardText();
                    Type::"G/L Account":
                        CopyFromGLAccount();
                    Type::"Rental Item":
                        CopyFromMainRentalItem();
                    Type::Resource:
                        CopyFromResource();
                end;

                OnAfterAssignFieldsForNo(Rec, xRec, RentalHeader);

                if Type <> Type::" " then begin
                    PostingSetupMgt.CheckGenPostingSetupSalesAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    PostingSetupMgt.CheckGenPostingSetupCOGSAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    PostingSetupMgt.CheckVATPostingSetupSalesAccount("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                end;

                if HasTypeToFillMandatoryFields() then
                    ValidateVATProdPostingGroup();

                UpdatePrepmtSetupFields();

                if HasTypeToFillMandatoryFields() then begin
                    PlanPriceCalcByField(FieldNo("No."));
                    Validate("Unit of Measure Code");
                    if Quantity <> 0 then begin
                        InitOutstanding();
                        if not IsCreditDocType() then
                            InitQtyToShip();
                        InitQtyToAsm();
                        UpdateWithWarehouseShip();
                    end;
                end;

                if "No." <> xRec."No." then begin
                    if Type = Type::"Rental Item" then
                        if (Quantity <> 0) and MainRentalItemExists(xRec."No.") then
                            VerifyChangeForTWERentalLineReserve(FieldNo("No."));

                    GetDefaultBin();
                    AutoAsmToOrder();
                    DeleteMainRentalItemChargeAssignment("Document Type", "Document No.", "Line No.");
                end;

                UpdateUnitPriceByField(FieldNo("No."));

                OnValidateNoOnAfterUpdateUnitPrice(Rec, xRec);
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();
                CheckAssocPurchOrder(Copystr(FieldCaption("Location Code"), 1, 250));

                if xRec."Location Code" <> "Location Code" then begin
                    if not FullQtyIsForAsmToOrder() then begin
                        CalcFields("Reserved Qty. (Base)");
                        TestField("Reserved Qty. (Base)", "Qty. to Asm. to Order (Base)");
                    end;
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');
                    TestField("Return Receipt No.", '');
                end;

                GetRentalHeader();
                IsHandled := false;
                OnValidateLocationCodeOnBeforeSetShipmentDate(Rec, IsHandled);
                if not IsHandled then
                    CalcShipmentDateForLocation();

                CheckMainRentalItemAvailable(FieldNo("Location Code"));

                if not "Drop Shipment" then begin
                    if "Location Code" = '' then begin
                        if InvtSetup.Get() then
                            "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                    end else
                        if Location.Get("Location Code") then
                            "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                end else
                    Evaluate("Outbound Whse. Handling Time", '<0D>');

                OnValidateLocationCodeOnAfterSetOutboundWhseHandlingTime(Rec);

                if "Location Code" <> xRec."Location Code" then begin
                    GetDefaultBin();
                    InitQtyToAsm();
                    AutoAsmToOrder();
                    if Quantity <> 0 then begin
                        if not "Drop Shipment" then
                            UpdateWithWarehouseShip();
                        if not FullReservedQtyIsForAsmToOrder() then
                            VerifyChangeForTWERentalLineReserve(FieldNo("Location Code"));
                    end;
                    if IsInventoriableMainRentalItem() then
                        PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");
                end;

                UpdateDates();

                if (Type = Type::"Rental Item") and ("No." <> '') then
                    GetUnitCost();

                CheckWMS();
            end;
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
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipment Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                IsHandled: boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentDate(IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();

                if "Shipment Date" <> 0D then begin
                    if CurrFieldNo in [
                                       FieldNo("Planned Shipment Date"),
                                       FieldNo("Planned Delivery Date"),
                                       FieldNo("Shipment Date"),
                                       FieldNo("Shipping Time"),
                                       FieldNo("Outbound Whse. Handling Time"),
                                       FieldNo("Requested Delivery Date")]
                    then
                        CheckMainRentalItemAvailable(FieldNo("Shipment Date"));

                    if ("Shipment Date" < WorkDate()) and HasTypeToFillMandatoryFields() then
                        if not (GetHideValidationDialog() or HasBeenShown) and GuiAllowed then begin
                            Message(
                              Text014Lbl,
                              FieldCaption("Shipment Date"), "Shipment Date", WorkDate());
                            HasBeenShown := true;
                        end;
                end;

                AutoAsmToOrder();

                if not PlannedShipmentDateCalculated then
                    "Planned Shipment Date" := CalcPlannedShptDate(FieldNo("Shipment Date"));
                if not PlannedDeliveryDateCalculated then
                    "Planned Delivery Date" := CalcPlannedDeliveryDate(FieldNo("Shipment Date"));
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("G/L Account"), "No." = CONST(''),
                                "System-Created Entry" = CONST(false)) "G/L Account".Name WHERE("Direct Posting" = CONST(true),
                                "Account Type" = CONST(Posting),
                                Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account"), "No." = CONST(''),
                "System-Created Entry" = CONST(true)) "G/L Account".Name
            ELSE
            IF (Type = CONST("Rental Item"), "No." = CONST(''),
                "Document Type" = FILTER(<> "Credit Memo" & <> "Return Shipment")) "TWE Main Rental Item".Description WHERE(Blocked = CONST(false),
                                                    "Sales Blocked" = CONST(false))
            ELSE
            IF (Type = CONST("Rental Item"), "No." = CONST(''), "Document Type" = FILTER("Credit Memo" | "Return Shipment")) "TWE Main Rental Item".Description WHERE(Blocked = CONST(false))
            ELSE
            IF (Type = CONST(Resource), "No." = CONST('')) Resource.Name;

            ValidateTableRelation = false;


            trigger OnValidate()
            var
                MainRentalItem: Record "TWE Main Rental Item";
                ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                ReturnValue: Text[100];
                DescriptionIsNo: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDescription(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if Type = Type::" " then
                    exit;

                if "No." <> '' then
                    exit;

                case Type of
                    Type::"Rental Item":
                        begin
                            if StrLen(Description) <= MaxStrLen(MainRentalItem."No.") then
                                DescriptionIsNo := MainRentalItem.Get(Description)
                            else
                                DescriptionIsNo := false;

                            if not DescriptionIsNo then begin
                                MainRentalItem.SetRange(Blocked, false);
                                if not IsCreditDocType() then
                                    MainRentalItem.SetRange("Sales Blocked", false);

                                MainRentalItem.SetRange(Description, Description);
                                if MainRentalItem.FindFirst() then begin
                                    Validate("No.", MainRentalItem."No.");
                                    exit;
                                end;
                                MainRentalItem.SetFilter(Description, '''@' + ConvertStr(Description, '''', '?') + '''');
                                if MainRentalItem.FindFirst() then begin
                                    Validate("No.", MainRentalItem."No.");
                                    exit;
                                end;
                            end;

                            GetRentalSetup();
                            case ReturnValue of
                                '':
                                    begin
                                        LookupRequested := true;
                                        Description := xRec.Description;
                                    end;
                                "No.":
                                    Description := xRec.Description;
                                else begin
                                        CurrFieldNo := FieldNo("No.");
                                        Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen(MainRentalItem."No.")));
                                    end;
                            end;
                        end;
                    else begin
                            IsHandled := false;
                            OnBeforeFindNoByDescription(Rec, xRec, CurrFieldNo, IsHandled);
                            if not IsHandled then
                                if ReturnValue <> '' then begin
                                    CurrFieldNo := FieldNo("No.");
                                    Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen("No.")));
                                end;
                        end;
                end;

                IsHandled := false;
                OnValidateDescriptionOnBeforeCannotFindDescrError(Rec, xRec, IsHandled);
                if not IsHandled then
                    if ("No." = '') and GuiAllowed then
                        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                            if "Document Type" in
                            ["Document Type"::Contract, "Document Type"::Invoice, "Document Type"::Quote, "Document Type"::"Credit Memo"]
                            then
                                Error(CannotFindDescErr, Type, Description);
            end;
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
            TableRelation = IF (Type = FILTER(<> " ")) "Unit of Measure".Description;
            ValidateTableRelation = false;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                MainRentalItem: Record "TWE Main Rental Item";
                MainRentalItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                CheckAssocPurchOrder(CopyStr(FieldCaption(Quantity), 1, 250));

                if "Shipment No." <> '' then
                    CheckShipmentRelation()
                else
                    if "Return Receipt No." <> '' then
                        CheckRetRcptRelation();

                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec);

                if IsCreditDocType() then begin
                    if (Quantity * "Quantity Returned" < 0) or
                       ((Abs(Quantity) < Abs("Quantity Returned")) and ("Return Receipt No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text003Lbl, FieldCaption("Quantity Returned")));
                end else begin
                    if (Quantity * "Quantity Shipped" < 0) or
                       ((Abs(Quantity) < Abs("Quantity Shipped")) and ("Shipment No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text003Lbl, FieldCaption("Quantity Shipped")));
                    if ("Quantity (Base)" * "Qty. Shipped (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Qty. Shipped (Base)")) and ("Shipment No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text003Lbl, FieldCaption("Qty. Shipped (Base)")));
                end;

                IsHandled := false;
                OnValidateQuantityOnBeforeCheckReceiptOrderStatus(Rec, StatusCheckSuspended, IsHandled);

                InitQty();

                CheckMainRentalItemAvailable(FieldNo(Quantity));

                if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then
                    PlanPriceCalcByField(FieldNo(Quantity));

                if Type = Type::"Rental Item" then begin
                    if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then begin
                        OnBeforeVerifyReservedQty(Rec, xRec, FieldNo(Quantity));
                        //ReserveTWERentalLine.VerifyQuantity(Rec, xRec);
                        if not "Drop Shipment" then
                            UpdateWithWarehouseShip();

                        IsHandled := false;
                        OnValidateQuantityOnBeforeTWERentalLineVerifyChange(Rec, StatusCheckSuspended, IsHandled);
                        // if not IsHandled then
                        //    WhseValidateSourceLine.TWERentalLineVerifyChange(Rec, xRec);
                        if ("Quantity (Base)" * xRec."Quantity (Base)" <= 0) and ("No." <> '') then begin
                            GetMainRentalItem(MainRentalItem);
                            OnValidateQuantityOnBeforeGetUnitCost(Rec, MainRentalItem);
                            if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and not IsShipment() then
                                GetUnitCost();
                        end;
                    end;
                    IsHandled := false;
                    OnValidateQuantityOnBeforeValidateQtyToAssembleToOrder(Rec, StatusCheckSuspended, IsHandled);
                    if not IsHandled then
                        Validate("Qty. to Assemble to Order");
                    if (Quantity = "Quantity Invoiced") and (CurrFieldNo <> 0) then
                        CheckMainRentalItemChargeAssgnt();
                    CheckApplFromMainRentalItemLedgEntry(MainRentalItemLedgEntry);
                end else
                    Validate("Line Discount %");

                IsHandled := false;
                OnValidateQuantityOnBeforeResetAmounts(Rec, xRec, IsHandled);
                if not IsHandled then
                    if (xRec.Quantity <> Quantity) and (Quantity = 0) and
                       ((Amount <> 0) or ("Amount Including VAT" <> 0) or ("VAT Base Amount" <> 0))
                    then begin
                        Amount := 0;
                        "Amount Including VAT" := 0;
                        "VAT Base Amount" := 0;
                    end;

                UpdateUnitPriceByField(FieldNo(Quantity));
                UpdatePrePaymentAmounts();

                CheckWMS();

            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Invoice" = MaxQtyToInvoice() then
                    InitQtyToInvoice()
                else
                    "Qty. to Invoice (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Invoice", "Qty. per Unit of Measure");

                if ("Qty. to Invoice" * Quantity < 0) or
                   (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice()))
                then
                    Error(Text005Lbl, MaxQtyToInvoice());

                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase()))
                then
                    Error(Text006Lbl, MaxQtyToInvoiceBase());

                "VAT Difference" := 0;
                CalcInvDiscToInvoice();
                CalcPrepaymentToDeduct();
            end;
        }
        field(18; "Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Qty. to Ship';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                MainRentalItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
            begin
                GetLocation("Location Code");
                if (CurrFieldNo <> 0) and (Type = Type::"Rental Item") and (not "Drop Shipment") then
                    if Location."Require Shipment" and ("Qty. to Ship" <> 0) then
                        CheckWarehouse();

                OnValidateQtyToShipOnAfterCheck(Rec, CurrFieldNo);

                if "Qty. to Ship" = "Outstanding Quantity" then
                    InitQtyToShip()
                else begin
                    "Qty. to Ship (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Ship", "Qty. per Unit of Measure");
                    CheckServMainRentalItemCreation();
                    InitQtyToInvoice();
                end;

                IsHandled := false;
                OnValidateQtyToShipAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if ((("Qty. to Ship" < 0) xor (Quantity < 0)) and (Quantity <> 0) and ("Qty. to Ship" <> 0)) or
                       (Abs("Qty. to Ship") > Abs("Outstanding Quantity")) or
                       (((Quantity < 0) xor ("Outstanding Quantity" < 0)) and (Quantity <> 0) and ("Outstanding Quantity" <> 0))
                    then
                        Error(Text007Lbl, "Outstanding Quantity");
                    if ((("Qty. to Ship (Base)" < 0) xor ("Quantity (Base)" < 0)) and ("Qty. to Ship (Base)" <> 0) and ("Quantity (Base)" <> 0)) or
                       (Abs("Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)")) or
                       ((("Quantity (Base)" < 0) xor ("Outstanding Qty. (Base)" < 0)) and ("Quantity (Base)" <> 0) and ("Outstanding Qty. (Base)" <> 0))
                    then
                        Error(Text008Lbl, "Outstanding Qty. (Base)");
                end;

                if (CurrFieldNo <> 0) and (Type = Type::"Rental Item") and ("Qty. to Ship" < 0) then
                    CheckApplFromMainRentalItemLedgEntry(MainRentalItemLedgEntry);

                // ATOLink.UpdateQtyToAsmFromTWERentalLine(Rec);
            end;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            //CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MainRentalItem: Record "TWE Main Rental Item";
            begin
                if (CurrFieldNo = FieldNo("Unit Cost (LCY)")) and
                   ("Unit Cost (LCY)" <> xRec."Unit Cost (LCY)")
                then
                    CheckAssocPurchOrder(Copystr(FieldCaption("Unit Cost (LCY)"), 1, 250));

                if (CurrFieldNo = FieldNo("Unit Cost (LCY)")) and
                   (Type = Type::"Rental Item") and ("No." <> '') and ("Quantity (Base)" <> 0)
                then begin
                    GetMainRentalItem(MainRentalItem);
                    if (MainRentalItem."Costing Method" = MainRentalItem."Costing Method"::Standard) and not IsShipment() then begin
                        if IsCreditDocType() then
                            Error(
                              Text037Lbl,
                              FieldCaption("Unit Cost (LCY)"), MainRentalItem.FieldCaption("Costing Method"),
                              MainRentalItem."Costing Method", FieldCaption(Quantity));
                        Error(
                          Text038Lbl,
                          FieldCaption("Unit Cost (LCY)"), MainRentalItem.FieldCaption("Costing Method"),
                          MainRentalItem."Costing Method", FieldCaption(Quantity));
                    end;
                end;

                GetRentalHeader();
                if RentalHeader."Currency Code" <> '' then begin
                    Currency.TestField("Unit-Amount Rounding Precision");
                    "Unit Cost" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          GetDate(), RentalHeader."Currency Code",
                          "Unit Cost (LCY)", RentalHeader."Currency Factor"),
                        Currency."Unit-Amount Rounding Precision")
                end else
                    "Unit Cost" := "Unit Cost (LCY)";
            end;
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

            trigger OnValidate()
            begin
                ValidateLineDiscountPercent(true);
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                GetRentalHeader();
                "Line Discount Amount" := Round("Line Discount Amount", Currency."Amount Rounding Precision");
                TestStatusOpen();
                TestQtyFromLindDiscountAmount();
                if xRec."Line Discount Amount" <> "Line Discount Amount" then
                    UpdateLineDiscPct();
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts();
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - RentalHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * "VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text009Lbl, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            RentalHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Round(Amount, Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Amount +
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", RentalHeader."Posting Date",
                                "VAT Base Amount", "Quantity (Base)", RentalHeader."Currency Factor");
                            OnAfterRentalTaxCalculate(Rec, RentalHeader, Currency);
                            UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                            "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                        end;
                end;

                InitOutstandingAmount();
            end;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - RentalHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - RentalHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            RentalHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", RentalHeader."Posting Date",
                                "Amount Including VAT", "Quantity (Base)", RentalHeader."Currency Factor");
                            OnAfterRentalTaxCalculateReverse(Rec, RentalHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end;
                OnValidateAmountIncludingVATOnAfterAssignAmounts(Rec, Currency);

                InitOutstandingAmount();
            end;
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = CustomerContent;
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if ("VAT Calculation Type" = "VAT Calculation Type"::"Full VAT") and "Allow Invoice Disc." then
                    Error(CannotAllowInvDiscountErr, FieldCaption("Allow Invoice Disc."));

                if "Allow Invoice Disc." <> xRec."Allow Invoice Disc." then begin
                    if not "Allow Invoice Disc." then begin
                        "Inv. Discount Amount" := 0;
                        "Inv. Disc. Amount to Invoice" := 0;
                    end;
                    UpdateAmounts();
                end;
            end;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData "TWE Main Rental Item" = R;
            Caption = 'Appl.-to MainRentalItem Entry';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                SelectMainRentalItemEntry(FieldNo("Appl.-to Item Entry"));
            end;

            trigger OnValidate()
            var
                MainRentalItemLedgEntry: Record "Item Ledger Entry";
                MainRentalItemTrackingLines: Page "Item Tracking Lines";
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    TestField(Type, Type::"Rental Item");
                    TestField(Quantity);
                    CheckQuantitySign();
                    MainRentalItemLedgEntry.Get("Appl.-to Item Entry");
                    MainRentalItemLedgEntry.TestField(Positive, true);
                    if MainRentalItemLedgEntry.TrackingExists() then
                        Error(Text040Lbl, MainRentalItemTrackingLines.Caption, FieldCaption("Appl.-to Item Entry"));
                    if Abs("Qty. to Ship (Base)") > MainRentalItemLedgEntry.Quantity then
                        Error(ShippingMoreUnitsThanReceivedErr, MainRentalItemLedgEntry.Quantity, MainRentalItemLedgEntry."Document No.");

                    Validate("Unit Cost (LCY)", CalcUnitCost(MainRentalItemLedgEntry));

                    "Location Code" := MainRentalItemLedgEntry."Location Code";
                    if not MainRentalItemLedgEntry.Open then
                        Message(Text042Lbl, "Appl.-to Item Entry");
                end;
            end;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                //ATOLink.UpdateAsmDimFromTWERentalLine(Rec);
            end;
        }
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if Type = Type::"Rental Item" then begin
                    if "Customer Price Group" <> xRec."Customer Price Group" then
                        PlanPriceCalcByField(FieldNo("Customer Price Group"));
                    UpdateUnitPriceByField(FieldNo("Customer Price Group"));
                end;
            end;
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                WorkType: Record "Work Type";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWorkTypeCode(xRec, IsHandled);
                if IsHandled then
                    exit;

                if Type = Type::Resource then begin
                    TestStatusOpen();
                    if WorkType.Get("Work Type Code") then
                        Validate("Unit of Measure Code", WorkType."Unit of Measure Code");
                    if "Work Type Code" <> xRec."Work Type Code" then
                        PlanPriceCalcByField(FieldNo("Work Type Code"));
                    UpdateUnitPriceByField(FieldNo("Work Type Code"));
                    ApplyResUnitCost(FieldNo("Work Type Code"));
                end;
            end;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            Caption = 'Recalculate Invoice Disc.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetRentalHeader();
                Currency2.InitRoundingPrecision();
                if RentalHeader."Currency Code" <> '' then
                    "Outstanding Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Outstanding Amount", RentalHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Outstanding Amount (LCY)" :=
                      Round("Outstanding Amount", Currency2."Amount Rounding Precision");
            end;
        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "Shipped Not Invoiced"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetRentalHeader();
                Currency2.InitRoundingPrecision();
                if RentalHeader."Currency Code" <> '' then
                    "Shipped Not Invoiced (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Shipped Not Invoiced", RentalHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Shipped Not Invoiced (LCY)" :=
                      Round("Shipped Not Invoiced", Currency2."Amount Rounding Precision");

                CalculateNotShippedInvExlcVatLCY();
            end;
        }
        field(60; "Quantity Shipped"; Decimal)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Quantity Shipped';
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
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(67; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            //CaptionClass = GetCaptionClass(FieldNo("Inv. Discount Amount"));
            Caption = 'Inv. Discount Amount';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                CalcInvDiscToInvoice();
                UpdateAmounts();
            end;
        }
        field(71; "Purchase Order No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = IF ("Drop Shipment" = CONST(true)) "Purchase Header"."No." WHERE("Document Type" = CONST(Order));

            trigger OnValidate()
            begin
                if (xRec."Purchase Order No." <> "Purchase Order No.") and (Quantity <> 0) then
                    VerifyChangeForTWERentalLineReserve(FieldNo("Purchase Order No."));
            end;
        }
        field(72; "Purch. Order Line No."; Integer)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Purch. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = IF ("Drop Shipment" = CONST(true)) "Purchase Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                               "Document No." = FIELD("Purchase Order No."));

            trigger OnValidate()
            begin
                if (xRec."Purch. Order Line No." <> "Purch. Order Line No.") and (Quantity <> 0) then
                    VerifyChangeForTWERentalLineReserve(FieldNo("Purch. Order Line No."));

            end;
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            DataClassification = CustomerContent;
            Editable = true;

            trigger OnValidate()
            begin
                TestField("Document Type", "Document Type"::Contract);
                TestField(Type, Type::"Rental Item");
                TestField("Quantity Shipped", 0);
                TestField("Qty. to Asm. to Order (Base)", 0);

                if "Drop Shipment" then
                    TestField("Special Order", false);

                CheckAssocPurchOrder(Copystr(FieldCaption("Drop Shipment"), 1, 250));

                if "Special Order" then
                    Reserve := Reserve::Never
                else
                    if "Drop Shipment" then begin
                        Reserve := Reserve::Never;
                        Evaluate("Outbound Whse. Handling Time", '<0D>');
                        Evaluate("Shipping Time", '<0D>');
                        UpdateDates();
                        "Bin Code" := '';
                    end else
                        SetReserveWithoutPurchasingCode();

                CheckMainRentalItemAvailable(FieldNo("Drop Shipment"));

                if (xRec."Drop Shipment" <> "Drop Shipment") and (Quantity <> 0) then begin
                    if not "Drop Shipment" then begin
                        InitQtyToAsm();
                        AutoAsmToOrder();
                        UpdateWithWarehouseShip();
                    end else
                        InitQtyToShip();
                    if not FullReservedQtyIsForAsmToOrder() then
                        VerifyChangeForTWERentalLineReserve(FieldNo("Drop Shipment"));
                end;
            end;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "TWE Rental Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                           "Document No." = FIELD("Document No."));
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

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                ValidateTaxGroupCode();
                UpdateAmounts();
            end;
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

            trigger OnValidate()
            begin
                ValidateVATProdPostingGroup();
            end;
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();
                if "Prepmt. Amt. Inv." <> 0 then
                    Error(CannotChangeVATGroupWithPrepmInvErr);
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                "VAT Difference" := 0;

                GetRentalHeader();
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                    Validate("Allow Invoice Disc.", false);
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                "VAT Clause Code" := VATPostingSetup."VAT Clause Code";

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Reverse Charge VAT",
                        "VAT Calculation Type"::"Sales Tax":
                            "VAT %" := 0;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                TestField(Type, Type::"G/L Account");
                                TestField("No.", VATPostingSetup.GetSalesAccount(false));
                            end;
                    end;

                IsHandled := FALSE;
                OnValidateVATProdPostingGroupOnBeforeUpdateUnitPrice(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if RentalHeader."Prices Including VAT" and (Type in [Type::"Rental Item", Type::Resource]) then
                        Validate("Unit Price",
                            Round(
                                "Unit Price" * (100 + "VAT %") / (100 + xRec."VAT %"),
                        Currency."Unit-Amount Rounding Precision"));

                OnValidateVATProdPostingGroupOnBeforeUpdateAmounts(Rec, xRec, RentalHeader, Currency);
                UpdateAmounts();
            end;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(93; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced (LCY) Incl. VAT';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(94; "Shipped Not Inv. (LCY) No VAT"; Decimal)
        {
            Caption = 'Shipped Not Invoiced (LCY)';
            DataClassification = CustomerContent;
            Editable = false;
            FieldClass = Normal;
        }
        field(95; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - Sum("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                   "Source Ref. No." = FIELD("Line No."),
                                                                   "Source Type" = CONST(37),
                                                                   "Source Subtype" = FIELD("Document Type"),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "TWE Main Rental Item" = R;
            Caption = 'Reserve';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MainRentalItem: Record "TWE Main Rental Item";
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::"Rental Item");
                    TestField("No.");
                end;
                CalcFields("Reserved Qty. (Base)");
                if (Reserve = Reserve::Never) and ("Reserved Qty. (Base)" > 0) then
                    TestField("Reserved Qty. (Base)", 0);

                if "Drop Shipment" or "Special Order" then
                    TestField(Reserve, Reserve::Never);
                if xRec.Reserve = Reserve::Always then begin
                    GetMainRentalItem(MainRentalItem);
                    if MainRentalItem.Reserve = MainRentalItem.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
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
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            //CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MaxLineAmount: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLineAmount(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type);
                TestField(Quantity);
                IsHandled := false;
                OnValidateLineAmountOnbeforeTestUnitPrice(Rec, IsHandled);
                if not IsHandled then
                    TestField("Unit Price");

                GetRentalHeader();

                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                MaxLineAmount := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision");

                if "Line Amount" < 0 then
                    if "Line Amount" < MaxLineAmount then
                        Error(LineAmountInvalidErr);

                if "Line Amount" > 0 then
                    if "Line Amount" > MaxLineAmount then
                        Error(LineAmountInvalidErr);

                Validate("Line Discount Amount", MaxLineAmount - "Line Amount");
            end;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(109; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnValidatePrepaymentPercentageOnBeforeUpdatePrepmtSetupFields(Rec, IsHandled);
                if IsHandled then
                    exit;

                UpdatePrepmtSetupFields();

                if HasTypeToFillMandatoryFields() then
                    UpdateAmounts();

                UpdateBaseAmounts(Amount, "Amount Including VAT", "VAT Base Amount");
            end;
        }
        field(110; "Prepmt. Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            // CaptionClass = GetCaptionClass(FieldNo("Prepmt. Line Amount"));
            Caption = 'Prepmt. Line Amount';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen();
                PrePaymentLineAmountEntered := true;
                TestField("Line Amount");
                if "Prepmt. Line Amount" < "Prepmt. Amt. Inv." then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text044Lbl, "Prepmt. Amt. Inv."));
                if "Prepmt. Line Amount" > "Line Amount" then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045Lbl, "Line Amount"));
                if "System-Created Entry" and not IsServiceChargeLine() then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045Lbl, 0));
                Validate("Prepayment %", Round("Prepmt. Line Amount" * 100 / "Line Amount", 0.00001));
            end;
        }
        field(111; "Prepmt. Amt. Inv."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            //CaptionClass = GetCaptionClass(FieldNo("Prepmt. Amt. Inv."));
            Caption = 'Prepmt. Amt. Inv.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(112; "Prepmt. Amt. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amt. Incl. VAT';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(113; "Prepayment Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(114; "Prepmt. VAT Base Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. VAT Base Amt.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(115; "Prepayment VAT %"; Decimal)
        {
            Caption = 'Prepayment VAT %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(116; "Prepmt. VAT Calc. Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Prepmt. VAT Calc. Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(117; "Prepayment VAT Identifier"; Code[20])
        {
            Caption = 'Prepayment VAT Identifier';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(118; "Prepayment Tax Area Code"; Code[20])
        {
            Caption = 'Prepayment Tax Area Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(119; "Prepayment Tax Liable"; Boolean)
        {
            Caption = 'Prepayment Tax Liable';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(120; "Prepayment Tax Group Code"; Code[20])
        {
            Caption = 'Prepayment Tax Group Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmounts();
            end;
        }
        field(121; "Prepmt Amt to Deduct"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            // CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt to Deduct"));
            Caption = 'Prepmt Amt to Deduct';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Prepmt Amt to Deduct" > "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text045Lbl, "Prepmt. Amt. Inv." - "Prepmt Amt Deducted"));

                if "Prepmt Amt to Deduct" > "Qty. to Invoice" * "Unit Price" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text045Lbl, "Qty. to Invoice" * "Unit Price"));

                if ("Prepmt. Amt. Inv." - "Prepmt Amt to Deduct" - "Prepmt Amt Deducted") >
                   (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Unit Price"
                then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text044Lbl,
                        "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" - (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Unit Price"));
            end;
        }
        field(122; "Prepmt Amt Deducted"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            //  CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt Deducted"));
            Caption = 'Prepmt Amt Deducted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(124; "Prepmt. Amount Inv. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. Incl. VAT';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(129; "Prepmt. Amount Inv. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. (LCY)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(132; "Prepmt. VAT Amount Inv. (LCY)"; Decimal)
        {
            Caption = 'Prepmt. VAT Amount Inv. (LCY)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(135; "Prepayment VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment VAT Difference';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(136; "Prepmt VAT Diff. to Deduct"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. to Deduct';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(137; "Prepmt VAT Diff. Deducted"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. Deducted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField(Quantity);
                UpdateAmounts();
            end;
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(900; "Qty. to Assemble to Order"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Qty. to Assemble to Order';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. to Asm. to Order (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Assemble to Order", "Qty. per Unit of Measure");

                if "Qty. to Asm. to Order (Base)" <> 0 then begin
                    TestField("Drop Shipment", false);
                    TestField("Special Order", false);
                    if "Qty. to Asm. to Order (Base)" < 0 then
                        FieldError("Qty. to Assemble to Order", StrSubstNo(Text009Lbl, FieldCaption("Quantity (Base)"), "Quantity (Base)"));
                    TestField("Appl.-to Item Entry", 0);
                end;

                CheckMainRentalItemAvailable(FieldNo("Qty. to Assemble to Order"));
                if not (CurrFieldNo in [FieldNo(Quantity), FieldNo("Qty. to Assemble to Order")]) then
                    GetDefaultBin();
                AutoAsmToOrder();
            end;
        }
        field(901; "Qty. to Asm. to Order (Base)"; Decimal)
        {
            Caption = 'Qty. to Asm. to Order (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Assemble to Order", "Qty. to Asm. to Order (Base)");
            end;
        }
        field(902; "ATO Whse. Outstanding Qty."; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            BlankZero = true;
            CalcFormula = Sum("Warehouse Shipment Line"."Qty. Outstanding" WHERE("Source Type" = CONST(37),
                                                                                  "Source Subtype" = FIELD("Document Type"),
                                                                                  "Source No." = FIELD("Document No."),
                                                                                  "Source Line No." = FIELD("Line No."),
                                                                                  "Assemble to Order" = FILTER(true)));
            Caption = 'ATO Whse. Outstanding Qty.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(903; "ATO Whse. Outstd. Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            BlankZero = true;
            CalcFormula = Sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" WHERE("Source Type" = CONST(37),
                                                                                         "Source Subtype" = FIELD("Document Type"),
                                                                                         "Source No." = FIELD("Document No."),
                                                                                         "Source Line No." = FIELD("Line No."),
                                                                                         "Assemble to Order" = FILTER(true)));
            Caption = 'ATO Whse. Outstd. Qty. (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1300; "Posting Date"; Date)
        {
            CalcFormula = Lookup("TWE Rental Header"."Posting Date" WHERE("Document Type" = FIELD("Document Type"),
                                                                      "No." = FIELD("Document No.")));
            Caption = 'Posting Date';
            FieldClass = FlowField;
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = CustomerContent;
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                DeferralPostDate: Date;
            begin
                GetRentalHeader();
                OnGetDeferralPostDate(RentalHeader, DeferralPostDate, Rec);
                if DeferralPostDate = 0D then
                    DeferralPostDate := RentalHeader."Posting Date";
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Rental Item")) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            begin
                if "Variant Code" <> '' then
                    TestField(Type, Type::"Rental Item");
                TestStatusOpen();
                CheckAssocPurchOrder(Copystr(FieldCaption("Variant Code"), 1, 250));

                if xRec."Variant Code" <> "Variant Code" then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');

                    TestField("Return Receipt No.", '');
                end;

                OnValidateVariantCodeOnAfterChecks(Rec, xRec, CurrFieldNo);

                CheckMainRentalItemAvailable(FieldNo("Variant Code"));

                if Type = Type::"Rental Item" then begin
                    GetUnitCost();
                    if "Variant Code" <> xRec."Variant Code" then
                        PlanPriceCalcByField(FieldNo("Variant Code"));
                end;

                GetDefaultBin();
                InitQtyToAsm();
                AutoAsmToOrder();

                UpdateUnitPriceByField(FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Document Type" = FILTER(Contract | Invoice),
                                Quantity = FILTER(>= 0),
                                "Qty. to Asm. to Order (Base)" = CONST(0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                         "Item No." = FIELD("No."),
                                                                                                         "Variant Code" = FIELD("Variant Code"))
            ELSE
            IF ("Document Type" = FILTER("Return Shipment" | "Credit Memo"),
                                                                                                                  Quantity = FILTER(< 0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                                       "Item No." = FIELD("No."),
                                                                                                                                                                       "Variant Code" = FIELD("Variant Code"))
            ELSE
            Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                if not IsInbound() and ("Quantity (Base)" <> 0) then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            begin
                if "Bin Code" <> '' then
                    CheckBinCodeRelation();

                if "Drop Shipment" then
                    CheckAssocPurchOrder(Copystr(FieldCaption("Bin Code"), 1, 250));

                TestField(Type, Type::"Rental Item");
                TestField("Location Code");

                if (Type = Type::"Rental Item") and ("Bin Code" <> '') then begin
                    TestField("Drop Shipment", false);
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                    CheckWarehouse();
                end;
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
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = IF (Type = CONST("Rental Item"),
                                "No." = FILTER(<> '')) "TWE Rental Item Unit Of Meas.".Code WHERE("Item No." = FIELD("No."))
            ELSE
            IF (Type = CONST(Resource),
                                         "No." = FILTER(<> '')) "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("No."))
            ELSE
            "Unit of Measure";

            trigger OnValidate()
            var
                MainRentalItem: Record "TWE Main Rental Item";
                UnitOfMeasureTranslation: Record "Unit of Measure Translation";
            begin
                TestStatusOpen();
                TestField("Quantity Shipped", 0);
                TestField("Qty. Shipped (Base)", 0);
                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then begin
                    TestField("Shipment No.", '');
                    TestField("Return Receipt No.", '');
                end;

                CheckAssocPurchOrder(Copystr(FieldCaption("Unit of Measure Code"), 1, 250));

                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    if not UnitOfMeasure.Get("Unit of Measure Code") then
                        UnitOfMeasure.Init();
                    "Unit of Measure" := UnitOfMeasure.Description;
                    GetRentalHeader();
                    if RentalHeader."Language Code" <> '' then begin
                        UnitOfMeasureTranslation.SetRange(Code, "Unit of Measure Code");
                        UnitOfMeasureTranslation.SetRange("Language Code", RentalHeader."Language Code");
                        if UnitOfMeasureTranslation.FindFirst() then
                            "Unit of Measure" := UnitOfMeasureTranslation.Description;
                    end;
                end;

                case Type of
                    Type::"Rental Item":
                        begin
                            GetMainRentalItem(MainRentalItem);
                            GetUnitCost();
                            if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            CheckMainRentalItemAvailable(FieldNo("Unit of Measure Code"));
                        end;
                    Type::Resource:
                        begin
                            if "Unit of Measure Code" = '' then begin
                                GetResource();
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                            end;
                            AssignResourceUoM();
                            if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            ApplyResUnitCost(FieldNo("Unit of Measure Code"));
                        end;
                end;
                UpdateQuantityFromUOMCode();
                UpdateUnitPriceByField(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                if "Quantity (Base)" <> xRec."Quantity (Base)" then
                    PlanPriceCalcByField(FieldNo("Quantity (Base)"));
                Validate(Quantity, "Quantity (Base)");
                UpdateUnitPriceByField(FieldNo("Quantity (Base)"));
            end;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5418; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;
        }
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5460; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5495; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - Sum("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Document No."),
                                                                            "Source Ref. No." = FIELD("Line No."),
                                                                            "Source Type" = CONST(37),
                                                                            "Source Subtype" = FIELD("Document Type"),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5600; "FA Posting Date"; Date)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Date';
            DataClassification = CustomerContent;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(5709; "MainRentalItem Category Code"; Code[20])
        {
            Caption = 'MainRentalItem Category Code';
            DataClassification = CustomerContent;
            TableRelation = "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Catalog';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Purchasing Code';
            DataClassification = CustomerContent;
            TableRelation = Purchasing;

            trigger OnValidate()
            var
                PurchasingCode: Record Purchasing;
                ShippingAgentServices: Record "Shipping Agent Services";
                IsHandled: Boolean;
            begin
                TestStatusOpen();
                TestField(Type, Type::"Rental Item");
                CheckAssocPurchOrder(Copystr(FieldCaption(Type), 1, 250));

                if PurchasingCode.Get("Purchasing Code") then begin
                    "Drop Shipment" := PurchasingCode."Drop Shipment";
                    "Special Order" := PurchasingCode."Special Order";
                    IsHandled := false;
                    OnValidatePurchasingCodeOnAfterAssignPurchasingFields(Rec, PurchasingCode, IsHandled);
                    if not IsHandled then
                        if "Drop Shipment" or "Special Order" then begin
                            TestField("Qty. to Asm. to Order (Base)", 0);
                            CalcFields("Reserved Qty. (Base)");
                            TestField("Reserved Qty. (Base)", 0);
                            VerifyChangeForTWERentalLineReserve(FieldNo("Purchasing Code"));

                            //if (Quantity <> 0) and (Quantity = "Quantity Shipped") then
                            //Error(TWERentalLineCompletelyShippedErr);
                            Reserve := Reserve::Never;
                            if "Drop Shipment" then begin
                                Evaluate("Outbound Whse. Handling Time", '<0D>');
                                Evaluate("Shipping Time", '<0D>');
                                UpdateDates();
                                "Bin Code" := '';
                            end;
                        end else
                            SetReserveWithoutPurchasingCode();
                end else begin
                    "Drop Shipment" := false;
                    "Special Order" := false;
                    SetReserveWithoutPurchasingCode();
                end;

                if ("Purchasing Code" <> xRec."Purchasing Code") and
                   (not "Drop Shipment") and
                   ("Drop Shipment" <> xRec."Drop Shipment")
                then begin
                    if "Location Code" = '' then begin
                        if InvtSetup.Get() then
                            "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                    end else
                        if Location.Get("Location Code") then
                            "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                    if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
                        "Shipping Time" := ShippingAgentServices."Shipping Time"
                    else begin
                        GetRentalHeader();
                        "Shipping Time" := RentalHeader."Shipping Time";
                    end;
                    UpdateDates();
                end;
            end;
        }
        field(5713; "Special Order"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5714; "Special Order Purchase No."; Code[20])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Purchase No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Special Order" = CONST(true)) "Purchase Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(5715; "Special Order Purch. Line No."; Integer)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Purch. Line No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Special Order" = CONST(true)) "Purchase Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                               "Document No." = FIELD("Special Order Purchase No."));
        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Location = R;
            BlankZero = true;
            CalcFormula = Sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" WHERE("Source Type" = CONST(37),
                                                                                         "Source Subtype" = FIELD("Document Type"),
                                                                                         "Source No." = FIELD("Document No."),
                                                                                         "Source Line No." = FIELD("Line No.")));
            Caption = 'Whse. Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
                CheckPromisedDeliveryDate();

                if "Requested Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Requested Delivery Date")
                else begin
                    GetRentalHeader();
                    Validate("Shipment Date", RentalHeader."Shipment Date");
                end;
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Promised Delivery Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Promised Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Promised Delivery Date")
                else
                    Validate("Requested Delivery Date");
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Shipping Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Drop Shipment" then
                    DateFormularZero("Shipping Time", FieldNo("Shipping Time"), Copystr(FieldCaption("Shipping Time"), 1, 250));
                UpdateDates();
            end;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Drop Shipment" then
                    DateFormularZero("Outbound Whse. Handling Time",
                      FieldNo("Outbound Whse. Handling Time"), Copystr(FieldCaption("Outbound Whse. Handling Time"), 1, 250));
                UpdateDates();
            end;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Planned Delivery Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                IsHandled: boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePlannedDeliveryDate(IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Planned Delivery Date" <> 0D then begin
                    PlannedDeliveryDateCalculated := true;

                    Validate("Planned Shipment Date", CalcPlannedDate());

                    if "Planned Shipment Date" > "Planned Delivery Date" then
                        "Planned Delivery Date" := "Planned Shipment Date";
                end;
            end;
        }
        field(5795; "Planned Shipment Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Planned Shipment Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                IsHandled: boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePlannedShipmentDate(IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Planned Shipment Date" <> 0D then begin
                    PlannedShipmentDateCalculated := true;

                    Validate("Shipment Date", CalcShipmentDate());
                end;
            end;
        }
        field(5796; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(5797; "Shipping Agent Service Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Service Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            var
                ShippingAgentServices: Record "Shipping Agent Services";
            begin
                TestStatusOpen();
                if "Shipping Agent Service Code" <> xRec."Shipping Agent Service Code" then
                    Evaluate("Shipping Time", '<>');

                if "Drop Shipment" then begin
                    Evaluate("Shipping Time", '<0D>');
                    UpdateDates();
                end else
                    if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
                        "Shipping Time" := ShippingAgentServices."Shipping Time"
                    else begin
                        GetRentalHeader();
                        "Shipping Time" := RentalHeader."Shipping Time";
                    end;

                if ShippingAgentServices."Shipping Time" <> xRec."Shipping Time" then
                    Validate("Shipping Time", "Shipping Time");
            end;
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData "TWE Main Rental Item" = R;
            Caption = 'Appl.-from Item Entry';
            DataClassification = CustomerContent;
            MinValue = 0;

            trigger OnLookup()
            begin
                // SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;

            trigger OnValidate()
            var
                MainRentalItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-from Item Entry" <> 0 then begin
                    CheckApplFromMainrentalItemLedgEntry(MainRentalItemLedgEntry);
                    Validate("Unit Cost (LCY)", CalcUnitCost(MainRentalItemLedgEntry));
                end;
            end;
        }
        field(5909; "BOM Item No."; Code[20])
        {
            Caption = 'BOM Item No.';
            DataClassification = CustomerContent;
            TableRelation = "TWE Main Rental Item";
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

            trigger OnValidate()
            begin
                ValidateReturnReasonCode(FieldNo("Return Reason Code"));
            end;
        }
        field(6610; "Copied From Posted Doc."; Boolean)
        {
            Caption = 'Copied From Posted Doc.';
            DataClassification = SystemMetadata;
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

            trigger OnValidate()
            begin
                if Type = Type::"Rental Item" then begin
                    if "Customer Disc. Group" <> xRec."Customer Disc. Group" then
                        PlanPriceCalcByField(FieldNo("Customer Disc. Group"));
                    UpdateUnitPriceByField(FieldNo("Customer Disc. Group"));
                end;
            end;
        }
        field(7004; "Price description"; Text[80])
        {
            Caption = 'Price description';
            DataClassification = CustomerContent;
        }
        field(7010; "Attached Doc Count"; Integer)
        {
            BlankNumbers = DontBlank;
            CalcFormula = Count("Document Attachment" WHERE("Table ID" = CONST(37),
                                                             "No." = FIELD("Document No."),
                                                             "Document Type" = FIELD("Document Type"),
                                                             "Line No." = FIELD("Line No.")));
            Caption = 'Attached Doc Count';
            FieldClass = FlowField;
            InitValue = 0;
        }
        field(70704600; "Rental Item"; Code[20])
        {
            Caption = 'Rental Item';
            DataClassification = CustomerContent;
            TableRelation =
            IF ("Document Type" = CONST("Credit Memo"))
                "Service Item"."No." WHERE("TWE Main Rental Item" = FIELD("No."))
            ELSE
            IF ("Document Type" = CONST("Return Shipment"))
                "Service Item"."No." WHERE("TWE Main Rental Item" = FIELD("No."))
            ELSE
            "Service Item"."No." WHERE("TWE Main Rental Item" = FIELD("No."), "TWE Rented" = CONST(false));

            trigger OnValidate()
            begin
                SetDataFromRentalHeader();

                Validate(Quantity, 1);
            end;
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
        }
        field(70704608; "Quantity Returned"; Decimal)
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
            Editable = false;
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
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Document Type")
        {
            Enabled = false;
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date")
        {
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key4; "Document Type", "Bill-to Customer No.", "Currency Code", "Document No.")
        {
            SumIndexFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key5; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Location Code", "Shipment Date")
        {
            Enabled = false;
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key6; "Document Type", "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Currency Code", "Document No.")
        {
            Enabled = false;
            SumIndexFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key8; "Document Type", "Document No.", "Location Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount Including VAT", "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key9; "Document Type", "Shipment No.", "Shipment Line No.")
        {
        }
        key(Key10; Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Shipment Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Document Type", "Rented-to Customer No.", "Shipment No.", "Document No.")
        {
            SumIndexFields = "Outstanding Amount (LCY)";
        }
        key(Key13; "Document Type", "Document No.", "Qty. Shipped Not Invoiced")
        {
            Enabled = false;
        }
        key(Key14; "Document Type", "Document No.", Type, "No.")
        {
            Enabled = false;
        }
        key(Key15; "Recalculate Invoice Disc.")
        {
        }
        key(Key16; "Qty. Shipped Not Invoiced")
        {
        }
        key(Key17; "Qty. Shipped (Base)")
        {
        }
        key(Key18; "Shipment Date", "Outstanding Quantity")
        {
        }
        key(Key19; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code", "Price description")
        {
        }
        fieldgroup(Brick; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code", "Price description")
        {
        }
    }

    trigger OnDelete()
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        CapableToPromise: Codeunit "Capable to Promise";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnDeleteOnBeforeTestStatusOpen(Rec, IsHandled);
        if not IsHandled then
            TestStatusOpen();

        if (Quantity <> 0) and MainRentalItemExists("No.") then
            if "Shipment No." = '' then
                TestField("Qty. Shipped Not Invoiced", 0);

        if ("Document Type" = "Document Type"::Contract) and (Quantity <> "Quantity Invoiced") then
            TestField("Prepmt. Amt. Inv.", "Prepmt Amt Deducted");

        CleanDropShipmentFields();
        CleanSpecialOrderFieldsAndCheckAssocPurchOrder();

        if Type = Type::"Rental Item" then
            DeleteMainRentalItemChargeAssignment("Document Type", "Document No.", "Line No.");

        if ("Document Type" = "Document Type"::Contract) then
            CapableToPromise.RemoveReqLines("Document No.", "Line No.", 0, false);

        if "Line No." <> 0 then begin
            TWERentalLine2.Reset();
            TWERentalLine2.SetRange("Document Type", "Document Type");
            TWERentalLine2.SetRange("Document No.", "Document No.");
            TWERentalLine2.SetRange("Attached to Line No.", "Line No.");
            TWERentalLine2.SetFilter("Line No.", '<>%1', "Line No.");
            OnDeleteOnAfterSetTWERentalLineFilters(TWERentalLine2);
            TWERentalLine2.DeleteAll(true);
        end;

        RentalCommentLine.SetRange("Document Type", "Document Type");
        RentalCommentLine.SetRange("No.", "Document No.");
        RentalCommentLine.SetRange("Document Line No.", "Line No.");
        if not RentalCommentLine.IsEmpty then
            RentalCommentLine.DeleteAll();

        // In case we have roundings on VAT or Sales Tax, we should update some other line
        if (Type <> Type::" ") and ("Line No." <> 0) and ("Attached to Line No." = 0) and
           (Quantity <> 0) and (Amount <> 0) and (Amount <> "Amount Including VAT") and not StatusCheckSuspended
        then begin
            Quantity := 0;
            "Quantity (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
            "Line Discount Amount" := 0;
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
            UpdateAmounts();
        end;

        if "Deferral Code" <> '' then
            DeferralUtilities.DeferralCodeOnDelete(
                "Deferral Document Type"::Sales.AsInteger(), '', '',
                "Document Type".AsInteger(), "Document No.", "Line No.");
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();
        if Quantity <> 0 then
            OnBeforeVerifyReservedQty(Rec, xRec, 0);

        LockTable();
        RentalHeader."No." := '';
        if Type = Type::"Rental Item" then
            CheckInventoryPickConflict();
    end;

    trigger OnModify()
    begin
        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and MainRentalItemExists(xRec."No.") and not FullReservedQtyIsForAsmToOrder() then
            VerifyChangeForTWERentalLineReserve(0);
    end;

    trigger OnRename()
    begin
        Error(Text001Lbl, TableCaption);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        RentalHeader: Record "TWE Rental Header";
        TWERentalLine2: Record "TWE Rental Line";
        GLAcc: Record "G/L Account";
        Resource: Record Resource;
        Currency: Record Currency;
        Res: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        NonstockMainRentalItem: Record "Nonstock Item";
        SKU: Record "Stockkeeping Unit";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        RentalSetup: Record "TWE Rental Setup";
        CalChange: Record "Customized Calendar Change";
        ConfigTemplateHeader: Record "Config. Template Header";
        TempErrorMessage: Record "Error Message" temporary;
        RentalCustCheckCreditLimit: Codeunit "TWE Rent. Cust-Check Cr. Limit";
        //MainRentalItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        UOMMgt: Codeunit "TWE Rental Unit of Measure Mgt";
        //AddOnIntegrMgt: Codeunit AddOnIntegrManagement;
        DimMgt: Codeunit DimensionManagement;
        //DistIntegration: Codeunit "Dist. Integration";
        //CatalogMainRentalItemMgt: Codeunit "Catalog Item Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        RentalTransferExtendedText: Codeunit "TWE Rental Trans. Ext. Text";
        DeferralUtilities: Codeunit "Deferral Utilities";
        CalendarMgmt: Codeunit "Calendar Management";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        //ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        PriceType: Enum "TWE Rental Price Type";
        FieldCausedPriceCalculation: Integer;
        FullAutoReservation: Boolean;
        HasBeenShown: Boolean;
        PlannedShipmentDateCalculated: Boolean;
        PlannedDeliveryDateCalculated: Boolean;
        RentalSetupRead: Boolean;
        LookupRequested: Boolean;
        Text028Lbl: Label 'You cannot change the %1 when the %2 has been filled in.', Comment = '%1 = FieldCaption "Requested Delivery Date",%2 = FieldCaption "Promised Delivery Date"';
        Text029Lbl: Label 'must be positive';
        Text030Lbl: Label 'must be negative';
        Text031Lbl: Label 'You must either specify %1 or %2.', Comment = '%1 = FieldCaption "Rented-to Customer No.",%2 = FieldCaption "Rented-to Cust. Templ Code"';
        Text034Lbl: Label 'The value of %1 field must be a whole number for the MainRentalItem included in the service MainRentalItem group if the %2 field in the Service MainRentalItem Groups window contains a check mark.', Comment = '%1 = FieldCaption "Qty. to Ship (Base)",%2 = FieldCaption "Create Service Item"';
        Text035Lbl: Label 'Warehouse ';
        Text036Lbl: Label 'Inventory ';
        Text037Lbl: Label 'You cannot change %1 when %2 is %3 and %4 is positive.', Comment = '%1 = FieldCaption "Unit Cost (LCY)",%2 = FieldCaption "Costing Method",%3 = "Costing Method",%4 = FieldCaption Quantity';
        Text038Lbl: Label 'You cannot change %1 when %2 is %3 and %4 is negative.', Comment = '%1= FieldCaption "Unit Cost (LCY)",%2 = FieldCaption "Costing Method",%3 = "Costing Method",%4= FieldCaption Quantity';
        Text039Lbl: Label '%1 units for %2 %3 have already been returned. Therefore, only %4 units can be returned.', Comment = '%1= QtyReturned,%2= FieldCaption "Document No.",%3= "Document No.",%4= QtyNotReturned';
        Text040Lbl: Label 'You must use form %1 to enter %2, if MainRentalItem tracking is used.', Comment = '%1= Caption,%2= FieldCaption "Appl.-from Item Entry"';
        Text042Lbl: Label 'When posting the Applied to Ledger Entry %1 will be opened first', Comment = '%1= "Appl.-to Item Entry"';
        ShippingMoreUnitsThanReceivedErr: Label 'You cannot ship more than the %1 units that you have received for document no. %2.', Comment = '%1= Quantity,%2= "Document No."';
        Text044Lbl: Label 'cannot be less than %1', Comment = '%1= xRec."Line Amount"';
        Text045Lbl: Label 'cannot be more than %1', Comment = '%1= Amounts/Quantities';
        Text046Lbl: Label 'You cannot return more than the %1 units that you have shipped for %2 %3.', Comment = '%1= Quantity,%2= FieldCaption "Document No.",%3= "Document No."';
        Text047Lbl: Label 'must be positive when %1 is not 0.', Comment = '%1= FieldCaption "Prepayment %"';
        Text049Lbl: Label 'cannot be %1.', Comment = '%1= "Prepmt. Amt. Inv."';
        Text051Lbl: Label 'You cannot use %1 in a %2.', Comment = '%1= CalledByFieldCaption,%2= FieldCaption "Drop Shipment"';
        Text052Lbl: Label 'You cannot add an MainRentalItem line because an open warehouse shipment exists for the sales header and Shipping Advice is %1.\\You must add MainRentalItems as new lines to the existing warehouse shipment or change Shipping Advice to Partial.', Comment = '%1= "Shipping Advice"';
        Text053Lbl: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?', Comment = '%1= TableCaption';
        Text054Lbl: Label 'Cancelled.';
        Text056Lbl: Label 'You cannot add an MainRentalItem line because an open inventory pick exists for the Rental Header and because Shipping Advice is %1.\\You must first post or delete the inventory pick or change Shipping Advice to Partial.', Comment = '%1= "Shipping Advice"';
        Text057Lbl: Label 'must have the same sign as the shipment';
        Text058Lbl: Label 'The quantity that you are trying to invoice is greater than the quantity in shipment %1.', Comment = '%1= "Document No."';
        Text059Lbl: Label 'must have the same sign as the return receipt';
        Text060Lbl: Label 'The quantity that you are trying to invoice is greater than the quantity in return receipt %1.', Comment = '%1= "Document No."';
        FreightLineDescriptionTxt: Label 'Freight Amount';
        CannotFindDescErr: Label 'Cannot find %1 with Description %2.\\Make sure to use the correct type.', Comment = '%1 = Type caption %2 = Description';
        PriceDescriptionTxt: Label 'x%1 (%2%3/%4)', Locked = true;
        PriceDescriptionWithLineDiscountTxt: Label 'x%1 (%2%3/%4) - %5%', Locked = true;
        SelectNonstockMainRentalItemErr: Label 'You can only select a catalog MainRentalItem for an empty line.';
        CommentLbl: Label 'Comment';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        SalesBlockedErr: Label 'You cannot sell this MainRentalItem because the Sales Blocked check box is selected on the MainRentalItem card.';
        CannotChangePrepaidServiceChargeErr: Label 'You cannot change the line because it will affect service charges that are already invoiced as part of a prepayment.';
        LineAmountInvalidErr: Label 'You have set the line amount to a value that results in a discount that is not valid. Consider increasing the unit price instead.';
        LineInvoiceDiscountAmountResetTok: Label 'The value in the Inv. Discount Amount field in %1 has been cleared.', Comment = '%1 - Record ID';
        UnitPriceChangedMsg: Label 'The unit price for %1 %2 that was copied from the posted document has been changed.', Comment = '%1 = Type caption %2 = No.';
        BlockedMainRentalItemNotificationMsg: Label 'MainRentalItem %1 is blocked, but it is allowed on this type of document.', Comment = '%1 is MainRentalItem No.';
        InvDiscForPrepmtExceededErr: Label 'You cannot enter an invoice discount for sales document %1.\\You must cancel the prepayment invoice first and then you will be able to update the invoice discount.', Comment = '%1 - document number';
        CannotAllowInvDiscountErr: Label 'The value of the %1 field is not valid when the VAT Calculation Type field is set to "Full VAT".', Comment = '%1 is the name of not valid field';
        CannotChangeVATGroupWithPrepmInvErr: Label 'You cannot change the VAT product posting group because prepayment invoices have been posted.\\You need to post the prepayment credit memo to be able to change the VAT product posting group.';
        CannotChangePrepmtAmtDiffVAtPctErr: Label 'You cannot change the prepayment amount because the prepayment invoice has been posted with a different VAT percentage. Please check the settings on the prepayment G/L account.';

        Text000Lbl: Label 'You cannot delete the order line because it is associated with purchase order %1 line %2.', Comment = '%1 = "Purchase Order No.",%2 = "Purch. Order Line No."';
        Text001Lbl: Label 'You cannot rename a %1.', Comment = '%1 = TableCaption';
        Text002Lbl: Label 'You cannot change %1 because the order line is associated with purchase order %2 line %3.', Comment = '%1 = TheFieldCaption,%2 = "Purchase Order No.",%3 = "Purch. Order Line No."';
        Text003Lbl: Label 'must not be less than %1', Comment = '%1 = FieldCaption "Quantity Returned"';
        Text005Lbl: Label 'You cannot invoice more than %1 units.', Comment = '%1 = MaxQtyToInvoice';
        Text006Lbl: Label 'You cannot invoice more than %1 base units.', Comment = '%1 = MaxQtyToInvoiceBase';
        Text007Lbl: Label 'You cannot ship more than %1 units.', Comment = '%1 = "Outstanding Quantity"';
        Text008Lbl: Label 'You cannot ship more than %1 base units.', Comment = '%1 = "Outstanding Qty. (Base)"';
        Text009Lbl: Label ' must be 0 when %1 is %2', Comment = '%1 = FieldCaption("VAT Calculation Type"),%2 = "VAT Calculation Type")';
        ManualReserveQst: Label 'Automatic reservation is not possible.\Do you want to reserve MainRentalItems manually?';
        Text014Lbl: Label '%1 %2 is before work date %3', Comment = '%1 = FieldCaption "Shipment Date",%2 = "Shipment Date",%3 = WorkDate()';
        Text016Lbl: Label '%1 is required for %2 = %3.', Comment = '%1 = DialogText,%2 = FieldCaption "Line No.",%3 = "Line No."';
        WhseRequirementMsg: Label '%1 is required for this line. The entered information may be disregarded by warehouse activities.', Comment = '%1 = Document';
        // Text020Lbl: Label 'You cannot return more than %1 units.';
        //Text021Lbl: Label 'You cannot return more than %1 base units.';
        Text026Lbl: Label 'You cannot change %1 if the MainRentalItem charge has already been posted.', Comment = '%1 = FieldCaption Amount';

    protected var
        HideValidationDialog: Boolean;
        StatusCheckSuspended: Boolean;
        PrePaymentLineAmountEntered: Boolean;

    /// <summary>
    /// InitOutstanding.
    /// </summary>
    procedure InitOutstanding()
    begin
        if IsCreditDocType() then
            "Outstanding Quantity" := Quantity - "Quantity Returned"
        else begin
            "Outstanding Quantity" := Quantity - "Quantity Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
            "Qty. Shipped Not Invoiced" := "Quantity Shipped" - "Quantity Invoiced";
            "Qty. Shipped Not Invd. (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        end;

        OnAfterInitOutstandingQty(Rec);
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        InitOutstandingAmount();

        OnAfterInitOutstanding(Rec);
    end;

    /// <summary>
    /// InitOutstandingAmount.
    /// </summary>
    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingAmount(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Quantity = 0 then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Shipped Not Invoiced" := 0;
            "Shipped Not Invoiced (LCY)" := 0;
        end else begin
            GetRentalHeader();
            AmountInclVAT := "Amount Including VAT";
            if Type <> Type::"Rental Item" then begin
                Validate(
                  "Outstanding Amount",
                  Round(
                    AmountInclVAT * "Outstanding Quantity" / Quantity,
                    Currency."Amount Rounding Precision"));
                if not IsCreditDocType() then
                    Validate(
                      "Shipped Not Invoiced",
                      Round(
                        AmountInclVAT * "Qty. Shipped Not Invoiced" / Quantity,
                        Currency."Amount Rounding Precision"));
            end else begin
                Validate(
                  "Outstanding Amount",
                  Round(
                    AmountInclVAT / "Total Days to Invoice" * ("Total Days to Invoice" - "Invoiced Duration"),
                    Currency."Amount Rounding Precision"));
                if not IsCreditDocType() then
                    Validate(
                      "Shipped Not Invoiced",
                      Round(
                        AmountInclVAT / "Total Days to Invoice" * ("Total Days to Invoice" - "Invoiced Duration"),
                        Currency."Amount Rounding Precision"));

            end;
        end;

        OnAfterInitOutstandingAmount(Rec, RentalHeader, Currency);
    end;

    /// <summary>
    /// InitQtyToShip.
    /// </summary>
    procedure InitQtyToShip()
    begin
        GetRentalSetup();
        if (RentalSetup."Default Quantity to Ship" = RentalSetup."Default Quantity to Ship"::Remainder) or
           ("Document Type" = "Document Type"::Invoice)
        then begin
            "Qty. to Ship" := "Outstanding Quantity";
            "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Qty. to Ship" <> 0 then
                "Qty. to Ship (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Ship", "Qty. per Unit of Measure");

        OnInitQtyToShipOnBeforeCheckServMainRentalItemCreation(Rec);
        CheckServMainRentalItemCreation();

        OnAfterInitQtyToShip(Rec, CurrFieldNo);

        InitQtyToInvoice();
    end;

    /// <summary>
    /// InitQtyToInvoice.
    /// </summary>
    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();
        "VAT Difference" := 0;

        OnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
        CalcInvDiscToInvoice();
        if RentalHeader."Document Type" <> RentalHeader."Document Type"::Invoice then
            CalcPrepaymentToDeduct();

        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    /// <summary>
    /// MaxQtyToInvoice.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure MaxQtyToInvoice(): Decimal
    var
        MaxQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoice(Rec, MaxQty, IsHandled);
        if IsHandled then
            exit(MaxQty);

        if "Prepayment Line" then
            exit(1);

        exit("Quantity Shipped" + "Qty. to Ship" - "Quantity Invoiced");
    end;

    /// <summary>
    /// MaxQtyToInvoiceBase.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure MaxQtyToInvoiceBase(): Decimal
    var
        MaxQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoiceBase(Rec, MaxQtyBase, IsHandled);
        if IsHandled then
            exit(MaxQtyBase);

        exit("Qty. Shipped (Base)" + "Qty. to Ship (Base)" - "Qty. Invoiced (Base)");
    end;

    /// <summary>
    /// CalcLineAmount.
    /// </summary>
    /// <returns>Return variable LineAmount of type Decimal.</returns>
    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Inv. Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    procedure CalcLineAmountToInvoice() LineAmount: Decimal
    begin
        if Type = Type::"Rental Item" then
            LineAmount := ("Line Amount" - "Inv. Discount Amount") / "Total Days to Invoice" * "Duration to be billed"
        else
            LineAmount := CalcLineAmount();

        OnAfterCalcLineAmountToInvoice(Rec, LineAmount);
    end;

    local procedure CopyFromStandardText()
    var
        StandardText: Record "Standard Text";
    begin
        "Tax Area Code" := '';
        "Tax Liable" := false;
        StandardText.Get("No.");
        Description := StandardText.Description;
        OnAfterAssignStdTxtValues(Rec, StandardText);
    end;

    local procedure CalcShipmentDateForLocation()
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
    begin
        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
        "Shipment Date" := CalendarMgmt.CalcDateBOC('', RentalHeader."Shipment Date", CustomCalendarChange, false);
    end;

    local procedure CopyFromGLAccount()
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc();
        if not "System-Created Entry" then
            GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Group Code" := GLAcc."Tax Group Code";
        "Allow Invoice Disc." := false;
        //"Allow Item Charge Assignment" := false;
        //InitDeferralCode();
        OnAfterAssignGLAccountValues(Rec, GLAcc);
    end;

    local procedure CopyFromMainRentalItem()
    var
        MainRentalItem: Record "TWE Main Rental Item";
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        GetMainRentalItem(MainRentalItem);
        IsHandled := false;
        OnBeforeCopyFromMainRentalItem(Rec, MainRentalItem, IsHandled);
        if not IsHandled then begin
            MainRentalItem.TestField(Blocked, false);
            MainRentalItem.TestField("Gen. Prod. Posting Group");
            if MainRentalItem."Sales Blocked" then
                if IsCreditDocType() then
                    SendBlockedMainRentalItemNotification()
                else
                    Error(SalesBlockedErr);
        end;

        OnCopyFromMainRentalItemOnAfterCheck(Rec, MainRentalItem);

        Description := MainRentalItem.Description;
        "Description 2" := MainRentalItem."Description 2";
        GetUnitCost();
        "Allow Invoice Disc." := MainRentalItem."Allow Invoice Disc.";
        "Gen. Prod. Posting Group" := MainRentalItem."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := MainRentalItem."VAT Prod. Posting Group";
        "Tax Group Code" := MainRentalItem."Tax Group Code";
        "MainRentalItem Category Code" := MainRentalItem."Item Category Code";
        "Profit %" := MainRentalItem."Profit %";
        RentalPrepaymentMgt.SetRentalPrepaymentPct(Rec, RentalHeader."Posting Date");
        if IsInventoriableMainRentalItem() then
            PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");

        if RentalHeader."Language Code" <> '' then
            GetMainRentalItemTranslation();

        if MainRentalItem.Reserve = MainRentalItem.Reserve::Optional then
            Reserve := RentalHeader.Reserve
        else
            Reserve := MainRentalItem.Reserve;

        if MainRentalItem."Sales Unit of Measure" <> '' then
            "Unit of Measure Code" := MainRentalItem."Sales Unit of Measure"
        else
            "Unit of Measure Code" := MainRentalItem."Base Unit of Measure";

        Validate("Purchasing Code", MainRentalItem."Purchasing Code");
        OnAfterCopyFromMainRentalItem(Rec, MainRentalItem, CurrFieldNo);

        //InitDeferralCode();
        SetDefaultMainRentalItemQuantity();
        OnAfterAssignMainRentalItemValues(Rec, MainRentalItem);
    end;

    local procedure CopyFromResource()
    var
        IsHandled: Boolean;
    begin
        Res.Get("No.");
        Res.CheckResourcePrivacyBlocked(false);
        IsHandled := false;
        OnCopyFromResourceOnBeforeTestBlocked(Res, IsHandled);
        if not IsHandled then
            Res.TestField(Blocked, false);
        Res.TestField("Gen. Prod. Posting Group");
        Description := Res.Name;
        "Description 2" := Res."Name 2";
        "Unit of Measure Code" := Res."Base Unit of Measure";
        "Unit Cost (LCY)" := Res."Unit Cost";
        "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Res."VAT Prod. Posting Group";
        "Tax Group Code" := Res."Tax Group Code";
        ApplyResUnitCost(FieldNo("No."));
        //InitDeferralCode();
        OnAfterAssignResourceValues(Rec, Res);
    end;

    /// <summary>
    /// CopyFromTWERentalLine.
    /// </summary>
    /// <param name="FromTWERentalLine">Record "TWE Rental Line".</param>
    procedure CopyFromTWERentalLine(FromTWERentalLine: Record "TWE Rental Line")
    begin
        "No." := FromTWERentalLine."No.";
        "Variant Code" := FromTWERentalLine."Variant Code";
        "Location Code" := FromTWERentalLine."Location Code";
        "Bin Code" := FromTWERentalLine."Bin Code";
        "Unit of Measure Code" := FromTWERentalLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromTWERentalLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromTWERentalLine.Quantity;
        "Qty. to Assemble to Order" := 0;
        "Drop Shipment" := FromTWERentalLine."Drop Shipment";
        OnAfterCopyFromTWERentalLine(Rec, FromTWERentalLine);
    end;

    /// <summary>
    /// CopyFromRentalShptLine.
    /// </summary>
    /// <param name="FromRentalShptLine">Record "TWE Rental Shipment Line".</param>
    procedure CopyFromRentalShptLine(FromRentalShptLine: Record "TWE Rental Shipment Line")
    begin
        "No." := FromRentalShptLine."No.";
        "Variant Code" := FromRentalShptLine."Variant Code";
        "Location Code" := FromRentalShptLine."Location Code";
        "Bin Code" := FromRentalShptLine."Bin Code";
        "Unit of Measure Code" := FromRentalShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromRentalShptLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromRentalShptLine.Quantity;
        "Qty. to Assemble to Order" := 0;
        "Drop Shipment" := FromRentalShptLine."Drop Shipment";
    end;


    /// <summary>
    /// CopyFromRentalInvLine.
    /// </summary>
    /// <param name="FromRentalInvLine">Record "TWE Rental Invoice Line".</param>
    procedure CopyFromRentalInvLine(FromRentalInvLine: Record "TWE Rental Invoice Line")
    begin
        "No." := FromRentalInvLine."No.";
        "Variant Code" := FromRentalInvLine."Variant Code";
        "Location Code" := FromRentalInvLine."Location Code";
        "Bin Code" := FromRentalInvLine."Bin Code";
        "Unit of Measure Code" := FromRentalInvLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromRentalInvLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromRentalInvLine.Quantity;
        "Drop Shipment" := FromRentalInvLine."Drop Shipment";
    end;

    /// <summary>
    /// CopyFromReturnRcptLine.
    /// </summary>
    /// <param name="FromReturnRcptLine">Record "Return Receipt Line".</param>
    procedure CopyFromReturnRcptLine(FromReturnRcptLine: Record "Return Receipt Line")
    begin
        "No." := FromReturnRcptLine."No.";
        "Variant Code" := FromReturnRcptLine."Variant Code";
        "Location Code" := FromReturnRcptLine."Location Code";
        "Bin Code" := FromReturnRcptLine."Bin Code";
        "Unit of Measure Code" := FromReturnRcptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromReturnRcptLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromReturnRcptLine.Quantity;
        "Drop Shipment" := false;
    end;

    /// <summary>
    /// CopyFromRentalCrMemoLine.
    /// </summary>
    /// <param name="FromRentalCrMemoLine">Record "TWE Rental Cr.Memo Line".</param>
    procedure CopyFromRentalCrMemoLine(FromRentalCrMemoLine: Record "TWE Rental Cr.Memo Line")
    begin
        "No." := FromRentalCrMemoLine."No.";
        "Variant Code" := FromRentalCrMemoLine."Variant Code";
        "Location Code" := FromRentalCrMemoLine."Location Code";
        "Bin Code" := FromRentalCrMemoLine."Bin Code";
        "Unit of Measure Code" := FromRentalCrMemoLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromRentalCrMemoLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromRentalCrMemoLine.Quantity;
        "Drop Shipment" := false;
    end;

    local procedure SelectMainRentalItemEntry(CurrentFieldNo: Integer)
    var
        MainRentalItemLedgEntry: Record "Item Ledger Entry";
        TWERentalLine3: Record "TWE Rental Line";
    begin
        MainRentalItemLedgEntry.SetRange("Item No.", "No.");
        if "Location Code" <> '' then
            MainRentalItemLedgEntry.SetRange("Location Code", "Location Code");
        MainRentalItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            MainRentalItemLedgEntry.SetCurrentKey("Item No.", Open);
            MainRentalItemLedgEntry.SetRange(Positive, true);
            MainRentalItemLedgEntry.SetRange(Open, true);
        end else begin
            MainRentalItemLedgEntry.SetCurrentKey("Item No.", Positive);
            MainRentalItemLedgEntry.SetRange(Positive, false);
            MainRentalItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
        end;
        OnSelectMainRentalItemEntryOnAfterSetFilters(MainRentalItemLedgEntry, Rec, CurrFieldNo);
        if PAGE.RunModal(PAGE::"Item Ledger Entries", MainRentalItemLedgEntry) = ACTION::LookupOK then begin
            TWERentalLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                TWERentalLine3.Validate("Appl.-to Item Entry", MainRentalItemLedgEntry."Entry No.")
            else
                TWERentalLine3.Validate("Appl.-from Item Entry", MainRentalItemLedgEntry."Entry No.");
            CheckMainRentalItemAvailable(CurrentFieldNo);
            Rec := TWERentalLine3;
        end;
    end;

    /// <summary>
    /// SetRentalHeader.
    /// </summary>
    /// <param name="NewRentalHeader">VAR Record "TWE Rental Header".</param>
    procedure SetRentalHeader(NewRentalHeader: Record "TWE Rental Header")
    begin
        RentalHeader := NewRentalHeader;
        OnBeforeSetRentalHeader(RentalHeader);

        if RentalHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            RentalHeader.TestField("Currency Factor");
            Currency.Get(RentalHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    /// <summary>
    /// GetRentalHeader.
    /// </summary>
    procedure GetRentalHeader()
    begin
        GetRentalHeader(RentalHeader, Currency);
    end;

    /// <summary>
    /// GetRentalHeader.
    /// </summary>
    /// <param name="OutRentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="OutCurrency">VAR Record Currency.</param>
    procedure GetRentalHeader(var OutRentalHeader: Record "TWE Rental Header"; var OutCurrency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetRentalHeader(Rec, RentalHeader, IsHandled, Currency);
        if IsHandled then
            exit;

        TestField("Document No.");
        if ("Document Type" <> RentalHeader."Document Type") or ("Document No." <> RentalHeader."No.") then begin
            RentalHeader.Get("Document Type", "Document No.");
            if RentalHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision()
            else begin
                RentalHeader.TestField("Currency Factor");
                Currency.Get(RentalHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;

        OnAfterGetRentalHeader(Rec, RentalHeader, Currency);
        OutRentalHeader := RentalHeader;
        OutCurrency := Currency;
    end;

    /// <summary>
    /// GetMainRentalItem.
    /// </summary>
    /// <param name="MainRentalItem">VAR Record TWE Main Rental MainRentalItem.</param>
    procedure GetMainRentalItem(var MainRentalItem: Record "TWE Main Rental Item")
    begin
        TestField("No.");
        MainRentalItem.Get("No.");
    end;

    /// <summary>
    /// GetResource.
    /// </summary>
    procedure GetResource()
    begin
        TestField("No.");
        if "No." <> Resource."No." then
            Resource.Get("No.");
    end;

    /// <summary>
    /// GetRemainingQty.
    /// </summary>
    /// <param name="RemainingQty">VAR Decimal.</param>
    /// <param name="RemainingQtyBase">VAR Decimal.</param>
    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    /// <summary>
    /// GetReservationQty.
    /// </summary>
    /// <param name="QtyReserved">VAR Decimal.</param>
    /// <param name="QtyReservedBase">VAR Decimal.</param>
    /// <param name="QtyToReserve">VAR Decimal.</param>
    /// <param name="QtyToReserveBase">VAR Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if "Document Type" = "Document Type"::"Return Shipment" then begin
            "Reserved Quantity" := -"Reserved Quantity";
            "Reserved Qty. (Base)" := -"Reserved Qty. (Base)";
        end;
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Outstanding Quantity";
        QtyToReserveBase := "Outstanding Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    /// <summary>
    /// GetSourceCaption.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetSourceCaption(): Text
    var
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1= "Document Type",%2= "Document No.",%3= "No."';
    begin
        exit(StrSubstNo(Placeholder001Lbl, "Document Type", "Document No.", "No."));
    end;


    /// <summary>
    /// SetReservationEntry.
    /// </summary>
    /// <param name="ReservEntry">VAR Record "Reservation Entry".</param>
    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::"Rental Item" then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Shipment Date";
        ReservEntry."Shipment Date" := "Shipment Date";
    end;

    /// <summary>
    /// SetReservationFilters.
    /// </summary>
    /// <param name="ReservEntry">VAR Record "Reservation Entry".</param>
    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    /// <summary>
    /// ReservEntryExist.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    /// <summary>
    /// IsPriceCalcCalledByField.
    /// </summary>
    /// <param name="CurrPriceFieldNo">Integer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsPriceCalcCalledByField(CurrPriceFieldNo: Integer): Boolean;
    begin
        exit(FieldCausedPriceCalculation = CurrPriceFieldNo);
    end;

    /// <summary>
    /// PlanPriceCalcByField.
    /// </summary>
    /// <param name="CurrPriceFieldNo">Integer.</param>
    procedure PlanPriceCalcByField(CurrPriceFieldNo: Integer)
    begin
        if FieldCausedPriceCalculation = 0 then
            FieldCausedPriceCalculation := CurrPriceFieldNo;
    end;

    /// <summary>
    /// ClearFieldCausedPriceCalculation.
    /// </summary>
    procedure ClearFieldCausedPriceCalculation()
    begin
        FieldCausedPriceCalculation := 0;
    end;

    local procedure UpdateQuantityFromUOMCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQuantityFromUOMCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate(Quantity);
    end;

    /// <summary>
    /// UpdateUnitPrice.
    /// </summary>
    /// <param name="CalledByFieldNo">Integer.</param>
    procedure UpdateUnitPrice(CalledByFieldNo: Integer)
    begin
        ClearFieldCausedPriceCalculation();
        PlanPriceCalcByField(CalledByFieldNo);
        UpdateUnitPriceByField(CalledByFieldNo);
    end;

    local procedure UpdateUnitPriceByField(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        if not IsPriceCalcCalledByField(CalledByFieldNo) then
            exit;

        IsHandled := false;
        OnBeforeUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetRentalHeader();
        TestField("Qty. per Unit of Measure");

        case Type of
            Type::"Rental Item",
            Type::Resource:
                begin
                    IsHandled := false;
                    OnUpdateUnitPriceOnBeforeFindPrice(RentalHeader, Rec, CalledByFieldNo, CurrFieldNo, IsHandled);
                    if not IsHandled then begin
                        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
                        if not ("Copied From Posted Doc." and IsCreditDocType()) then begin
                            PriceCalculation.ApplyDiscount();
                            ApplyPrice(CalledByFieldNo, PriceCalculation);
                        end;
                    end;
                    OnUpdateUnitPriceByFieldOnAfterFindPrice(RentalHeader, Rec, CalledByFieldNo, CurrFieldNo);
                end;
        end;

        if "Copied From Posted Doc." and IsCreditDocType() and ("Appl.-from Item Entry" <> 0) then
            if xRec."Unit Price" <> "Unit Price" then
                if GuiAllowed then
                    ShowMessageOnce(StrSubstNo(UnitPriceChangedMsg, Type, "No."));

        Validate("Unit Price");

        ClearFieldCausedPriceCalculation();
        OnAfterUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    local procedure GetLineWithCalculatedPrice(var PriceCalculation: Interface "TWE Rent Price Calculation")
    var
        Line: Variant;
    begin
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    local procedure GetPriceCalculationHandler(PriceType: Enum "TWE Rental Price Type"; RentalHeader: Record "TWE Rental Header"; var PriceCalculation: Interface "TWE Rent Price Calculation")
    var
        PriceCalculationMgt: codeunit "TWE Rental Price Calc Mgt.";
        LineWithPrice: Interface "TWE Rent Line With Price";
    begin
        if (RentalHeader."No." = '') and ("Document No." <> '') then
            RentalHeader.Get("Document Type", "Document No.");
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, RentalHeader, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;

    /// <summary>
    /// GetLineWithPrice.
    /// </summary>
    /// <param name="LineWithPrice">VAR Interface "Line With Price".</param>
    procedure GetLineWithPrice(var LineWithPrice: Interface "TWE Rent Line With Price")
    var
        RentalLinePrice: Codeunit "TWE Rental Line - Price";
    begin
        LineWithPrice := RentalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    /// <summary>
    /// ApplyDiscount.
    /// </summary>
    /// <param name="PriceCalculation">VAR Interface "Price Calculation".</param>
    procedure ApplyDiscount(var PriceCalculation: Interface "TWE Rent Price Calculation")
    begin
        PriceCalculation.ApplyDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// ApplyPrice.
    /// </summary>
    /// <param name="CalledByFieldNo">Integer.</param>
    /// <param name="PriceCalculation">VAR Interface "Price Calculation".</param>
    procedure ApplyPrice(CalledByFieldNo: Integer; var PriceCalculation: Interface "TWE Rent Price Calculation")
    begin
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        GetLineWithCalculatedPrice(PriceCalculation);
        OnAfterApplyPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    local procedure ApplyResUnitCost(CalledByFieldNo: Integer)
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Purchase, RentalHeader, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        GetLineWithCalculatedPrice(PriceCalculation);
        Validate("Unit Cost (LCY)");
    end;

    /// <summary>
    /// CountDiscount.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return value of type Integer.</returns>
    procedure CountDiscount(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
        exit(PriceCalculation.CountDiscount(ShowAll));
    end;


    /// <summary>
    /// CountPrice.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return value of type Integer.</returns>
    procedure CountPrice(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
        exit(PriceCalculation.CountPrice(ShowAll));
    end;

    /// <summary>
    /// DiscountExists.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure DiscountExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
        exit(PriceCalculation.IsDiscountExists(ShowAll));
    end;

    /// <summary>
    /// PriceExists.
    /// </summary>
    /// <param name="ShowAll">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure PriceExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Sale, RentalHeader, PriceCalculation);
        exit(PriceCalculation.IsPriceExists(ShowAll));
    end;
    /// <summary>
    /// PickDiscount.
    /// </summary>
    procedure PickDiscount()
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
        PriceCalculation.PickDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// PickPrice.
    /// </summary>
    procedure PickPrice()
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
        PriceCalculation.PickPrice();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// UpdateReferencePriceAndDiscount.
    /// </summary>
    procedure UpdateReferencePriceAndDiscount();
    var
        PriceCalculation: Interface "TWE Rent Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Rental, RentalHeader, PriceCalculation);
    end;

    local procedure ShowMessageOnce(MessageText: Text)
    begin
        TempErrorMessage.SetContext(Rec);
        if TempErrorMessage.FindRecord(RecordId, 0, TempErrorMessage."Message Type"::Warning, MessageText) = 0 then begin
            TempErrorMessage.LogMessage(Rec, 0, TempErrorMessage."Message Type"::Warning, MessageText);
            Message(MessageText);
        end;
    end;

    /// <summary>
    /// UpdatePrepmtSetupFields.
    /// </summary>
    procedure UpdatePrepmtSetupFields()
    var
        GenPostingSetup: Record "General Posting Setup";
        LocalGLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtSetupFields(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if ("Prepayment %" <> 0) and (Type <> Type::" ") then begin
            TestField("Document Type", "Document Type"::Contract);
            TestField("No.");
            if CurrFieldNo = FieldNo("Prepayment %") then
                if "System-Created Entry" and not IsServiceChargeLine() then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045Lbl, 0));
            if "System-Created Entry" and not IsServiceChargeLine() then
                "Prepayment %" := 0;
            GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
            if GenPostingSetup."Sales Prepayments Account" <> '' then begin
                LocalGLAcc.Get(GenPostingSetup."Sales Prepayments Account");
                VATPostingSetup.Get("VAT Bus. Posting Group", LocalGLAcc."VAT Prod. Posting Group");
                VATPostingSetup.TestField("VAT Calculation Type", "VAT Calculation Type");
            end else
                Clear(VATPostingSetup);
            if ("Prepayment VAT %" <> 0) and ("Prepayment VAT %" <> VATPostingSetup."VAT %") and ("Prepmt. Amt. Inv." <> 0) then
                Error(CannotChangePrepmtAmtDiffVAtPctErr);
            "Prepayment VAT %" := VATPostingSetup."VAT %";
            "Prepmt. VAT Calc. Type" := VATPostingSetup."VAT Calculation Type";
            "Prepayment VAT Identifier" := VATPostingSetup."VAT Identifier";
            if "Prepmt. VAT Calc. Type" in
               ["Prepmt. VAT Calc. Type"::"Reverse Charge VAT", "Prepmt. VAT Calc. Type"::"Sales Tax"]
            then
                "Prepayment VAT %" := 0;
            "Prepayment Tax Group Code" := LocalGLAcc."Tax Group Code";
        end;
    end;

    local procedure UpdatePrepmtAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtAmounts(Rec, RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader."Document Type" <> RentalHeader."Document Type"::Invoice then begin
            "Prepayment VAT Difference" := 0;
            if not PrePaymentLineAmountEntered then
                "Prepmt. Line Amount" := Round("Line Amount" * "Prepayment %" / 100, Currency."Amount Rounding Precision");
            PrePaymentLineAmountEntered := false;
        end;

        if not IsTemporary() then
            CheckPrepmtAmounts();
    end;

    local procedure CheckPrepmtAmounts()
    var
        RemLineAmountToInvoice: Decimal;
    begin
        if "Prepayment %" <> 0 then begin
            if Quantity < 0 then
                FieldError(Quantity, StrSubstNo(Text047Lbl, FieldCaption("Prepayment %")));
            if "Unit Price" < 0 then
                FieldError("Unit Price", StrSubstNo(Text047Lbl, FieldCaption("Prepayment %")));
        end;
        if RentalHeader."Document Type" <> RentalHeader."Document Type"::Invoice then begin
            if "Prepmt. Line Amount" < "Prepmt. Amt. Inv." then begin
                if IsServiceChargeLine() then
                    Error(CannotChangePrepaidServiceChargeErr);
                FieldError("Prepmt. Line Amount", StrSubstNo(Text049Lbl, "Prepmt. Amt. Inv."));
            end;
            if "Prepmt. Line Amount" <> 0 then begin
                RemLineAmountToInvoice :=
                  Round("Line Amount" * (Quantity - "Quantity Invoiced") / Quantity, Currency."Amount Rounding Precision");
                if RemLineAmountToInvoice < ("Prepmt. Line Amount" - "Prepmt Amt Deducted") then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045Lbl, RemLineAmountToInvoice + "Prepmt Amt Deducted"));
            end;
        end else
            if (CurrFieldNo <> 0) and ("Line Amount" <> xRec."Line Amount") and
               ("Prepmt. Amt. Inv." <> 0) and ("Prepayment %" = 100)
            then begin
                if "Line Amount" < xRec."Line Amount" then
                    FieldError("Line Amount", StrSubstNo(Text044Lbl, xRec."Line Amount"));
                FieldError("Line Amount", StrSubstNo(Text045Lbl, xRec."Line Amount"));
            end;
    end;

    /// <summary>
    /// UpdateAmounts.
    /// </summary>
    procedure UpdateAmounts()
    var
        VATBaseAmount: Decimal;
        LineAmountChanged: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::" " then
            exit;

        GetRentalHeader();
        VATBaseAmount := "VAT Base Amount";
        "Recalculate Invoice Disc." := true;

        IsHandled := false;
        OnUpdateAmountsOnBeforeCheckLineAmount(IsHandled);
        if not IsHandled then
            if "Line Amount" <> xRec."Line Amount" then begin
                "VAT Difference" := 0;
                LineAmountChanged := true;
            end;
        if Type <> "TWE Rental Line Type"::"Rental Item" then begin
            if "Line Amount" <> Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") - "Line Discount Amount" then begin
                "Line Amount" := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") - "Line Discount Amount";
                "VAT Difference" := 0;
                LineAmountChanged := true;
            end;
        end else
            if "Line Amount" <> Round(Quantity * "Unit Price" * "Total Days to Invoice", Currency."Amount Rounding Precision") - "Line Discount Amount" then begin
                "Line Amount" := Round(Quantity * "Unit Price" * "Total Days to Invoice", Currency."Amount Rounding Precision") - "Line Discount Amount";
                "VAT Difference" := 0;
                LineAmountChanged := true;
            end;

        if not "Prepayment Line" then
            UpdatePrepmtAmounts();

        OnAfterUpdateAmounts(Rec, xRec, CurrFieldNo);

        UpdateVATAmounts();
        InitOutstandingAmount();
        CheckCreditLimit();

        CalcPrepaymentToDeduct();
        if VATBaseAmount <> "VAT Base Amount" then
            LineAmountChanged := true;

        if LineAmountChanged then
            LineAmountChanged := false;

        OnAfterUpdateAmountsDone(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// UpdateVATAmounts.
    /// </summary>
    procedure UpdateVATAmounts()
    var
        localTWERentalLine2: Record "TWE Rental Line";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalQuantityBase: Decimal;
        TotalVATBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateVATAmounts(Rec);

        GetRentalHeader();
        localTWERentalLine2.SetRange("Document Type", "Document Type");
        localTWERentalLine2.SetRange("Document No.", "Document No.");
        localTWERentalLine2.SetFilter("Line No.", '<>%1', "Line No.");
        localTWERentalLine2.SetRange("VAT Identifier", "VAT Identifier");
        localTWERentalLine2.SetRange("Tax Group Code", "Tax Group Code");
        localTWERentalLine2.SetRange("Tax Area Code", "Tax Area Code");

        IsHandled := false;
        OnUpdateVATAmountsOnAfterSetTWERentalLineFilters(Rec, localTWERentalLine2, IsHandled);
        if IsHandled then
            exit;

        if "Line Amount" = "Inv. Discount Amount" then begin
            Amount := 0;
            "VAT Base Amount" := 0;
            "Amount Including VAT" := 0;
            if (Quantity = 0) and (xRec.Quantity <> 0) and (xRec.Amount <> 0) then
                if "Line No." <> 0 then
                    Modify();
        end else begin
            TotalLineAmount := 0;
            TotalInvDiscAmount := 0;
            TotalAmount := 0;
            TotalAmountInclVAT := 0;
            TotalQuantityBase := 0;
            TotalVATBaseAmount := 0;
            if ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") or
               (("VAT Calculation Type" in
                 ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"]) and ("VAT %" <> 0))
            then begin
                localTWERentalLine2.SetFilter("VAT %", '<>0');
                if not localTWERentalLine2.IsEmpty then begin
                    localTWERentalLine2.CalcSums("Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)", "VAT Base Amount");
                    TotalLineAmount := localTWERentalLine2."Line Amount";
                    TotalInvDiscAmount := localTWERentalLine2."Inv. Discount Amount";
                    TotalAmount := localTWERentalLine2.Amount;
                    TotalAmountInclVAT := localTWERentalLine2."Amount Including VAT";
                    TotalQuantityBase := localTWERentalLine2."Quantity (Base)";
                    TotalVATBaseAmount := localTWERentalLine2."VAT Base Amount";
                    OnAfterUpdateTotalAmounts(Rec, localTWERentalLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount);
                end;
            end;

            OnUpdateVATAmountsOnBeforeCalcAmounts(
               Rec, localTWERentalLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount, TotalVATBaseAmount, TotalQuantityBase, IsHandled);
            if IsHandled then
                exit;

            if RentalHeader."Prices Including VAT" then
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                (TotalLineAmount - TotalInvDiscAmount + CalcLineAmount()) / (1 + "VAT %" / 100),
                                Currency."Amount Rounding Precision") -
                              TotalAmount;
                            "VAT Base Amount" :=
                              Round(
                                Amount * (1 - RentalHeader."VAT Base Discount %" / 100),
                                Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalLineAmount + "Line Amount" -
                              Round(
                                (TotalAmount + Amount) * (RentalHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                              TotalAmountInclVAT - TotalInvDiscAmount - "Inv. Discount Amount";
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := ROUND(CalcLineAmount(), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            RentalHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", RentalHeader."Posting Date",
                                TotalAmountInclVAT + "Amount Including VAT", TotalQuantityBase + "Quantity (Base)",
                                RentalHeader."Currency Factor") -
                              TotalAmount;
                            OnAfterRentalTaxCalculateReverse(Rec, RentalHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end
            else
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - RentalHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                (TotalAmount + Amount) * (1 - RentalHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                              TotalAmountInclVAT;
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := CalcLineAmount();
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                SalesTaxCalculate.CalculateTax(
                                  "Tax Area Code", "Tax Group Code", "Tax Liable", RentalHeader."Posting Date",
                                  TotalAmount + Amount, TotalQuantityBase + "Quantity (Base)",
                                  RentalHeader."Currency Factor"), Currency."Amount Rounding Precision") -
                              TotalAmountInclVAT;
                            OnAfterRentalTaxCalculate(Rec, RentalHeader, Currency);
                            UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                        end;
                end;
        end;

        OnAfterUpdateVATAmounts(Rec);
    end;

    local procedure InitQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQty(Rec, xRec, IsAsmToOrderAllowed(), IsAsmToOrderRequired(), IsHandled);
        if IsHandled then
            exit;

        if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then begin
            InitOutstanding();
            if IsCreditDocType() then begin
                "Qty. to Invoice" := Quantity - "Quantity Invoiced";
                "Qty. to Invoice (Base)" := "Quantity (Base)" - "Quantity Invoiced";
            end else
                InitQtyToShip();

            InitQtyToAsm();
            SetDefaultQuantity();
        end;
    end;

    /// <summary>
    /// CheckMainRentalItemAvailable.
    /// </summary>
    /// <param name="CalledByFieldNo">Integer.</param>
    procedure CheckMainRentalItemAvailable(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMainRentalItemAvailable(Rec, CalledByFieldNo, IsHandled, CurrFieldNo, xRec);
        if IsHandled then
            exit;

        if Reserve = Reserve::Always then
            exit;

        if "Shipment Date" = 0D then begin
            GetRentalHeader();
            if RentalHeader."Shipment Date" <> 0D then
                Validate("Shipment Date", RentalHeader."Shipment Date")
            else
                Validate("Shipment Date", WorkDate());
        end;

        OnAfterCheckMainRentalItemAvailable(Rec, CalledByFieldNo, HideValidationDialog);
    end;

    local procedure CheckCreditLimit()
    var
        IsHandled: Boolean;
    begin
        if (CurrFieldNo <> 0) and
           not ((Type = Type::"Rental Item") and (CurrFieldNo = FieldNo("No.")) and (Quantity <> 0) and
                ("Qty. per Unit of Measure" <> xRec."Qty. per Unit of Measure")) and
           CheckCreditLimitCondition() and
           (("Outstanding Amount" + "Shipped Not Invoiced") > 0)
        then begin
            IsHandled := false;
            OnUpdateAmountOnBeforeCheckCreditLimit(Rec, IsHandled, CurrFieldNo);
            if not IsHandled then
                RentalCustCheckCreditLimit.RentalLineCheck(Rec);
        end;
    end;

    local procedure CheckBinCodeRelation()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinCodeRelation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not IsInbound() and ("Quantity (Base)" <> 0) and ("Qty. to Asm. to Order (Base)" = 0) then
            WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
        else
            WMSManagement.FindBin("Location Code", "Bin Code", '');
    end;

    local procedure CheckCreditLimitCondition(): Boolean
    var
        RunCheck: Boolean;
    begin
        RunCheck := "Document Type".AsInteger() <= "Document Type"::Invoice.AsInteger();
        OnAfterCheckCreditLimitCondition(Rec, RunCheck);
        exit(RunCheck);
    end;

    /// <summary>
    /// ShowReservation.
    /// </summary>
    procedure ShowReservation()
    var
        Reservation: Page Reservation;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::"Rental Item");
        TestField("No.");
        TestField(Reserve);
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    /// <summary>
    /// ShowReservationEntries.
    /// </summary>
    /// <param name="Modal">Boolean.</param>
    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservationEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::"Rental Item");
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    /// <summary>
    /// AutoReserve.
    /// </summary>
    procedure AutoReserve()
    var
        localRentalSetup: Record "TWE Rental Setup";
        ReservMgt: Codeunit "Reservation Management";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        QtyToReserveBase := 0;
        QtyToReserve := 0;
        // OnBeforeAutoReserve(Rec, IsHandled, xRec, FullAutoReservation, ReserveTWERentalLine);
        if IsHandled then
            exit;

        TestField(Type, Type::"Rental Item");
        TestField("No.");

        if QtyToReserveBase <> 0 then begin
            TestField("Shipment Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Shipment Date", QtyToReserve, QtyToReserveBase);
            Find();
            localRentalSetup.Get();
            if (not FullAutoReservation) then begin // and (not RentalSetup."Skip Manual Reservation")
                Commit();
                if ConfirmManagement.GetResponse(ManualReserveQst, true) then begin
                    ShowReservation();
                    Find();
                end;
            end;
        end;

        OnAfterAutoReserve(Rec);
    end;

    /// <summary>
    /// AutoAsmToOrder.
    /// </summary>
    procedure AutoAsmToOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoAsmToOrder(Rec, IsHandled);
        if IsHandled then
            exit;

        //ATOLink.UpdateAsmFromTWERentalLine(Rec);

        OnAfterAutoAsmToOrder(Rec);
    end;

    /// <summary>
    /// GetDate.
    /// </summary>
    /// <returns>Return value of type Date.</returns>
    procedure GetDate(): Date
    begin
        GetRentalHeader();
        if RentalHeader."Posting Date" <> 0D then
            exit(RentalHeader."Posting Date");
        exit(WorkDate());
    end;

    /// <summary>
    /// CalcPlannedDeliveryDate.
    /// </summary>
    /// <param name="CurrFieldNo">Integer.</param>
    /// <returns>Return variable PlannedDeliveryDate of type Date.</returns>
    procedure CalcPlannedDeliveryDate(CurrFieldNo: Integer) PlannedDeliveryDate: Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PlannedDeliveryDate := "Planned Delivery Date";
        OnBeforeCalcPlannedDeliveryDate(Rec, PlannedDeliveryDate, CurrFieldNo, IsHandled);
        if IsHandled then
            exit(PlannedDeliveryDate);

        if "Shipment Date" = 0D then
            exit("Planned Delivery Date");

        CustomCalendarChange[1].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
        case CurrFieldNo of
            FieldNo("Shipment Date"):
                begin
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Customer, "Rented-to Customer No.", '', '');
                    exit(CalendarMgmt.CalcDateBOC(Format("Shipping Time"), "Planned Shipment Date", CustomCalendarChange, true));
                end;
            FieldNo("Planned Delivery Date"):
                begin
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    exit(CalendarMgmt.CalcDateBOC2(Format("Shipping Time"), "Planned Delivery Date", CustomCalendarChange, true));
                end;
        end;
    end;

    /// <summary>
    /// CalcPlannedShptDate.
    /// </summary>
    /// <param name="CurrFieldNo">Integer.</param>
    /// <returns>Return variable PlannedShipmentDate of type Date.</returns>
    procedure CalcPlannedShptDate(CurrFieldNo: Integer) PlannedShipmentDate: Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        IsHandled: Boolean;
    begin
        OnBeforeCalcPlannedShptDate(Rec, PlannedShipmentDate, CurrFieldNo, IsHandled);
        if IsHandled then
            exit(PlannedShipmentDate);

        if "Shipment Date" = 0D then
            exit("Planned Shipment Date");

        CustomCalendarChange[2].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
        case CurrFieldNo of
            FieldNo("Shipment Date"):
                begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    exit(CalendarMgmt.CalcDateBOC(Format("Outbound Whse. Handling Time"), "Shipment Date", CustomCalendarChange, true));
                end;
            FieldNo("Planned Delivery Date"):
                begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Customer, "Rented-to Customer No.", '', '');
                    exit(CalendarMgmt.CalcDateBOC(Format(''), "Planned Delivery Date", CustomCalendarChange, true));
                end;
        end;
    end;

    /// <summary>
    /// CalcShipmentDate.
    /// </summary>
    /// <returns>Return value of type Date.</returns>
    procedure CalcShipmentDate(): Date
    var
        CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if "Planned Shipment Date" = 0D then
            exit("Shipment Date");

        IsHandled := false;
        OnCalcShipmentDateOnPlannedShipmentDate(Rec, ShipmentDate, IsHandled);
        if IsHandled then
            exit(ShipmentDate);

        if Format("Outbound Whse. Handling Time") <> '' then begin
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
            exit(CalendarMgmt.CalcDateBOC2(Format("Outbound Whse. Handling Time"), "Planned Shipment Date", CustomCalendarChange, false));
        end;

        CustomCalendarChange[1].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
        CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
        exit(CalendarMgmt.CalcDateBOC(Format(Format('')), "Planned Shipment Date", CustomCalendarChange, false));
    end;

    /// <summary>
    /// SignedXX.
    /// </summary>
    /// <param name="Value">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure SignedXX(Value: Decimal): Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSignedXX(Rec, Value, IsHandled);
        if IsHandled then
            exit(Value);

        case "Document Type" of
            "Document Type"::Quote,
          "Document Type"::Contract,
          "Document Type"::Invoice,
            "Document Type"::"Return Shipment",
          "Document Type"::"Credit Memo":
                exit(Value);
        end;
    end;

    /// <summary>
    /// ShowDimensions.
    /// </summary>
    /// <returns>Return variable IsChanged of type Boolean.</returns>
    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
        Placeholder001Lbl: Label '%1 %2 %3', Comment = '%1= "Document Type",%2= "Document No.",%3= "Line No."';
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo(Placeholder001Lbl, "Document Type", "Document No.", "Line No."));
        VerifyMainRentalItemLineDim();
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        IsChanged := OldDimSetID <> "Dimension Set ID";

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// OpenMainRentalItemTrackingLines.
    /// </summary>
    procedure OpenMainRentalItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenMainRentalItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::"Rental Item");
        TestField("No.");
        TestField("Quantity (Base)");

        IsHandled := false;
        OnBeforeCallMainRentalItemTracking(Rec, IsHandled);
        // if not IsHandled then
        //     ReserveTWERentalLine.CallMainRentalItemTracking(Rec);
    end;

    /// <summary>
    /// CreateDim.
    /// </summary>
    /// <param name="Type1">Integer.</param>
    /// <param name="No1">Code[20].</param>
    /// <param name="Type2">Integer.</param>
    /// <param name="No2">Code[20].</param>
    /// <param name="Type3">Integer.</param>
    /// <param name="No3">Code[20].</param>
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetRentalHeader();
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Sales,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", RentalHeader."Dimension Set ID", DATABASE::Customer);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        // ATOLink.UpdateAsmDimFromTWERentalLine(Rec);

        OnAfterCreateDim(Rec, CurrFieldNo);
    end;

    /// <summary>
    /// ValidateShortcutDimCode.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <param name="ShortcutDimCode">VAR Code[20].</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        VerifyMainRentalItemLineDim();

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// LookupShortcutDimCode.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <param name="ShortcutDimCode">VAR Code[20].</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
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
    /// SelectMultipleMainRentalItems.
    /// </summary>
    /*     procedure SelectMultipleMainRentalItems()
        var
            MainRentalItemListPage: Page "TWE Rental List";
            SelectionFilter: Text;
        begin
            if IsCreditDocType() then
                SelectionFilter := MainRentalItemListPage.SelectActiveItems
            else
                SelectionFilter := MainRentalItemListPage.SelectActiveItemsForRent;
            if SelectionFilter <> '' then
                AddMainRentalItems(SelectionFilter);
        end; */

    /*     local procedure AddMainRentalItems(SelectionFilter: Text)
        var
            MainRentalItem: Record "TWE Main Rental Item";
            TWERentalLine: Record "TWE Rental Line";
            LastTWERentalLine: Record "TWE Rental Line";
        begin
            OnBeforeAddMainRentalItems(Rec);

            InitNewLine(TWERentalLine);
            MainRentalItem.SetFilter("No.", SelectionFilter);
            if MainRentalItem.FindSet() then
                repeat
                    TWERentalLine.Init();
                    TWERentalLine."Line No." += 10000;
                    TWERentalLine.Validate(Type, Type::"Rental Item");
                    TWERentalLine.Validate("No.", MainRentalItem."No.");
                    TWERentalLine.Insert(true);

                    if TWERentalLine.IsAsmToOrderRequired() then
                        TWERentalLine.AutoAsmToOrder();

                    //  if TransferExtendedText.SalesCheckIfAnyExtText(TWERentalLine, false) then begin
                    //      TransferExtendedText.InsertSalesExtTextRetLast(TWERentalLine, LastTWERentalLine);
                    //     TWERentalLine."Line No." := LastTWERentalLine."Line No."
                    //   end;
                    OnAfterAddMainRentalItem(TWERentalLine, LastTWERentalLine);
                until MainRentalItem.Next() = 0;
        end; */

    /*     local procedure InitNewLine(var NewTWERentalLine: Record "TWE Rental Line")
        var
            TWERentalLine: Record "TWE Rental Line";
        begin
            NewTWERentalLine.Copy(Rec);
            TWERentalLine.SetRange("Document Type", NewTWERentalLine."Document Type");
            TWERentalLine.SetRange("Document No.", NewTWERentalLine."Document No.");
            if TWERentalLine.FindLast() then
                NewTWERentalLine."Line No." := TWERentalLine."Line No."
            else
                NewTWERentalLine."Line No." := 0;
        end; */

    /// <summary>
    /// ShowNonstock.
    /// </summary>
    procedure ShowNonstock()
    var
        TempMainRentalItemTemplate: Record "Item Templ." temporary;
    begin
        TestField(Type, Type::"Rental Item");
        if "No." <> '' then
            Error(SelectNonstockMainRentalItemErr);
        if PAGE.RunModal(PAGE::"Catalog Item List", NonstockMainRentalItem) = ACTION::LookupOK then begin
            NonstockMainRentalItem.TestField("Item Templ. Code");
            ConfigTemplateHeader.SetRange(Code, NonstockMainRentalItem."Item Templ. Code");
            ConfigTemplateHeader.FindFirst();
            //TempMainRentalItemTemplate.InitializeTempRecordFromConfigTemplate(TempMainRentalItemTemplate, ConfigTemplateHeader);
            TempMainRentalItemTemplate.TestField("Gen. Prod. Posting Group");
            TempMainRentalItemTemplate.TestField("Inventory Posting Group");

            "No." := NonstockMainRentalItem."Entry No.";
            //  CatalogMainRentalItemMgt.NonStockSales(Rec);
            Validate("No.", "No.");
            Validate("Unit Price", NonstockMainRentalItem."Unit Price");

            OnAfterShowNonStock(Rec, NonstockMainRentalItem);
        end;
    end;

    local procedure GetRentalSetup()
    begin
        if not RentalSetupRead then
            RentalSetup.GetSetup();
        RentalSetupRead := true;

        OnAfterGetRentalSetup(Rec, RentalSetup);
    end;

    /// <summary>
    /// GetCaptionClass.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <returns>Return value of type Text[80].</returns>
/*     procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        SalesLineCaptionClassMgmt: Codeunit "Sales Line CaptionClass Mgmt";
    begin
        //  exit(SalesLineCaptionClassMgmt.GetSalesLineCaptionClass(Rec, FieldNumber));
    end; */

    local procedure GetSKU() Result: Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result);
    end;

    /// <summary>
    /// GetUnitCost.
    /// </summary>
    procedure GetUnitCost()
    var
        MainRentalItem: Record "TWE Main Rental Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUnitCost(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::"Rental Item");
        TestField("No.");
        GetMainRentalItem(MainRentalItem);
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(MainRentalItem, "Unit of Measure Code");
        ValidateUnitCostLCYOnGetUnitCost(MainRentalItem);

        OnAfterGetUnitCost(Rec, MainRentalItem);
    end;

    local procedure CalcUnitCost(MainRentalItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", MainRentalItemLedgEntry."Entry No.");
        if IsNonInventoriableMainRentalItem() then begin
            ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
            UnitCost := ValueEntry."Cost Amount (Non-Invtbl.)" / MainRentalItemLedgEntry.Quantity;
        end else begin
            ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
            UnitCost :=
              (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / MainRentalItemLedgEntry.Quantity;
        end;

        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    /// <summary>
    /// ShowMainRentalItemChargeAssgnt.
    /// </summary>
    procedure ShowMainRentalItemChargeAssgnt()
    var
        MainRentalItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        AssignMainRentalItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
        MainRentalItemChargeAssgnts: Page "Item Charge Assignment (Sales)";
        MainRentalItemChargeAssgntLineAmt: Decimal;
        IsHandled: Boolean;
    begin
        Get("Document Type", "Document No.", "Line No.");
        TestField("No.");
        TestField(Quantity);

        GetRentalHeader();
        Currency.Initialize(RentalHeader."Currency Code");
        if ("Inv. Discount Amount" = 0) and ("Line Discount Amount" = 0) and
           (not RentalHeader."Prices Including VAT")
        then
            MainRentalItemChargeAssgntLineAmt := "Line Amount"
        else
            if RentalHeader."Prices Including VAT" then
                MainRentalItemChargeAssgntLineAmt :=
                  Round(CalcLineAmount() / (1 + "VAT %" / 100), Currency."Amount Rounding Precision")
            else
                MainRentalItemChargeAssgntLineAmt := CalcLineAmount();

        MainRentalItemChargeAssgntSales.Reset();
        MainRentalItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        MainRentalItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        MainRentalItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
        MainRentalItemChargeAssgntSales.SetRange("Item Charge No.", "No.");
        if not MainRentalItemChargeAssgntSales.FindLast() then begin
            MainRentalItemChargeAssgntSales."Document Type" := "Document Type";
            MainRentalItemChargeAssgntSales."Document No." := "Document No.";
            MainRentalItemChargeAssgntSales."Document Line No." := "Line No.";
            MainRentalItemChargeAssgntSales."Item Charge No." := "No.";
            MainRentalItemChargeAssgntSales."Unit Cost" :=
              Round(MainRentalItemChargeAssgntLineAmt / Quantity, Currency."Unit-Amount Rounding Precision");
        end;

        IsHandled := false;
        OnShowMainRentalItemChargeAssgntOnBeforeCalcMainRentalItemCharge(Rec, MainRentalItemChargeAssgntLineAmt, Currency, IsHandled, MainRentalItemChargeAssgntSales);
        if not IsHandled then
            MainRentalItemChargeAssgntLineAmt :=
              Round(MainRentalItemChargeAssgntLineAmt * ("Qty. to Invoice" / Quantity), Currency."Amount Rounding Precision");

        if IsCreditDocType() then
            AssignMainRentalItemChargeSales.CreateDocChargeAssgn(MainRentalItemChargeAssgntSales, "Return Receipt No.")
        else
            AssignMainRentalItemChargeSales.CreateDocChargeAssgn(MainRentalItemChargeAssgntSales, "Shipment No.");
        Clear(AssignMainRentalItemChargeSales);
        Commit();

        //   MainRentalItemChargeAssgnts.Initialize(Rec, MainRentalItemChargeAssgntLineAmt);
        MainRentalItemChargeAssgnts.RunModal();
    end;

    /// <summary>
    /// UpdateMainRentalItemChargeAssgnt.
    /// </summary>
    procedure UpdateMainRentalItemChargeAssgnt()
    var
        MainRentalItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ShareOfVAT: Decimal;
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateMainRentalItemChargeAssgnt(Rec, IsHandled);
        if IsHandled then
            exit;

        MainRentalItemChargeAssgntSales.Reset();
        MainRentalItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        MainRentalItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        MainRentalItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
        MainRentalItemChargeAssgntSales.CalcSums("Qty. to Assign");
        TotalQtyToAssign := MainRentalItemChargeAssgntSales."Qty. to Assign";
        if (CurrFieldNo <> 0) and (Amount <> xRec.Amount) and
           not ((Quantity <> xRec.Quantity) and (TotalQtyToAssign = 0))
        then begin
            MainRentalItemChargeAssgntSales.SetFilter("Qty. Assigned", '<>0');
            if not MainRentalItemChargeAssgntSales.IsEmpty then
                Error(Text026Lbl,
                  FieldCaption(Amount));
            MainRentalItemChargeAssgntSales.SetRange("Qty. Assigned");
        end;

        if MainRentalItemChargeAssgntSales.FindSet(true) and (Quantity <> 0) then begin
            GetRentalHeader();
            TotalAmtToAssign := CalcTotalAmtToAssign(TotalQtyToAssign);
            repeat
                ShareOfVAT := 1;
                if RentalHeader."Prices Including VAT" then
                    ShareOfVAT := 1 + "VAT %" / 100;
                if Quantity <> 0 then
                    if MainRentalItemChargeAssgntSales."Unit Cost" <>
                       Round(CalcLineAmount() / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision")
                    then
                        MainRentalItemChargeAssgntSales."Unit Cost" :=
                          Round(CalcLineAmount() / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision");
                if TotalQtyToAssign <> 0 then begin
                    MainRentalItemChargeAssgntSales."Amount to Assign" :=
                      Round(MainRentalItemChargeAssgntSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    TotalQtyToAssign -= MainRentalItemChargeAssgntSales."Qty. to Assign";
                    TotalAmtToAssign -= MainRentalItemChargeAssgntSales."Amount to Assign";
                end;
                MainRentalItemChargeAssgntSales.Modify();
            until MainRentalItemChargeAssgntSales.Next() = 0;
        end;
    end;

    /// <summary>
    /// DeleteMainRentalItemChargeAssignment.
    /// </summary>
    /// <param name="DocType">Enum "Sales Document Type".</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="DocLineNo">Integer.</param>
    procedure DeleteMainRentalItemChargeAssignment(DocType: Enum "TWE Rental Document Type"; DocNo: Code[20];
                                                                DocLineNo: Integer)
    var
        MainRentalItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        MainRentalItemChargeAssgntSales.SetRange("Applies-to Doc. Type", DocType);
        MainRentalItemChargeAssgntSales.SetRange("Applies-to Doc. No.", DocNo);
        MainRentalItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", DocLineNo);
        if not MainRentalItemChargeAssgntSales.IsEmpty then
            MainRentalItemChargeAssgntSales.DeleteAll(true);
    end;

    local procedure CheckMainRentalItemChargeAssgnt()
    var
        MainRentalItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        MainRentalItemChargeAssgntSales.SetRange("Applies-to Doc. Type", "Document Type");
        MainRentalItemChargeAssgntSales.SetRange("Applies-to Doc. No.", "Document No.");
        MainRentalItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", "Line No.");
        MainRentalItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        MainRentalItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        if MainRentalItemChargeAssgntSales.FindSet() then
            repeat
                MainRentalItemChargeAssgntSales.TestField("Qty. to Assign", 0);
            until MainRentalItemChargeAssgntSales.Next() = 0;

    end;

    /// <summary>
    /// TestStatusOpen.
    /// </summary>
    procedure TestStatusOpen()
    var
        IsHandled: Boolean;
    begin
        GetRentalHeader();
        IsHandled := false;
        OnBeforeTestStatusOpen(Rec, RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if StatusCheckSuspended then
            exit;

        if not "System-Created Entry" then
            if (xRec.Type <> Type) or HasTypeToFillMandatoryFields() then
                RentalHeader.TestField(Status, RentalHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, RentalHeader);
    end;

    local procedure TestQtyFromLindDiscountAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQtyFromLindDiscountAmount(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TestField(Quantity);
    end;

    /// <summary>
    /// GetSuspendedStatusCheck.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetSuspendedStatusCheck(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    /// <summary>
    /// SuspendStatusCheck.
    /// </summary>
    /// <param name="Suspend">Boolean.</param>
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    /// <summary>
    /// UpdateVATOnLines.
    /// </summary>
    /// <param name="QtyType">Option General,Invoicing,Shipping.</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TWERentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmountLine">VAR Record "VAT Amount Line".</param>
    /// <returns>Return variable LineWasModified of type Boolean.</returns>
    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping; var RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line") LineWasModified: Boolean
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        localCurrency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
        LineAmountToInvoiceDiscounted: Decimal;
    begin
        if IsUpdateVATOnLinesHandled(RentalHeader, TWERentalLine, VATAmountLine, QtyType) then
            exit;

        LineWasModified := false;
        if QtyType = QtyType::Shipping then
            exit;

        localCurrency.Initialize(RentalHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll();
        TWERentalLine.SetRange("Document Type", RentalHeader."Document Type");
        TWERentalLine.SetRange("Document No.", RentalHeader."No.");
        TWERentalLine.LockTable();
        if TWERentalLine.FindSet() then
            repeat
                if not TWERentalLine.ZeroAmountLine(QtyType) then begin
                    VATAmountLine.Get(TWERentalLine."VAT Identifier", TWERentalLine."VAT Calculation Type", TWERentalLine."Tax Group Code", false, TWERentalLine."Line Amount" >= 0);
                    if VATAmountLine.Modified then begin
                        if not TempVATAmountLineRemainder.Get(
                             TWERentalLine."VAT Identifier", TWERentalLine."VAT Calculation Type", TWERentalLine."Tax Group Code", false, TWERentalLine."Line Amount" >= 0)
                        then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        if QtyType = QtyType::General then
                            LineAmountToInvoice := TWERentalLine."Line Amount"
                        else
                            LineAmountToInvoice :=
                              Round(TWERentalLine."Line Amount" * TWERentalLine."Qty. to Invoice" / TWERentalLine.Quantity, localCurrency."Amount Rounding Precision");

                        if TWERentalLine."Allow Invoice Disc." then begin
                            if (VATAmountLine."Inv. Disc. Base Amount" = 0) or (LineAmountToInvoice = 0) then
                                InvDiscAmount := 0
                            else begin
                                LineAmountToInvoiceDiscounted :=
                                  VATAmountLine."Invoice Discount Amount" * LineAmountToInvoice /
                                  VATAmountLine."Inv. Disc. Base Amount";
                                TempVATAmountLineRemainder."Invoice Discount Amount" :=
                                  TempVATAmountLineRemainder."Invoice Discount Amount" + LineAmountToInvoiceDiscounted;
                                InvDiscAmount :=
                                  Round(
                                    TempVATAmountLineRemainder."Invoice Discount Amount", localCurrency."Amount Rounding Precision");
                                TempVATAmountLineRemainder."Invoice Discount Amount" :=
                                  TempVATAmountLineRemainder."Invoice Discount Amount" - InvDiscAmount;
                            end;
                            if QtyType = QtyType::General then begin
                                TWERentalLine."Inv. Discount Amount" := InvDiscAmount;
                                TWERentalLine.CalcInvDiscToInvoice();
                            end else
                                TWERentalLine."Inv. Disc. Amount to Invoice" := InvDiscAmount;
                        end else
                            InvDiscAmount := 0;

                        OnUpdateVATOnLinesOnBeforeCalculateAmounts(TWERentalLine, RentalHeader);
                        if QtyType = QtyType::General then begin
                            if RentalHeader."Prices Including VAT" then begin
                                if (VATAmountLine.CalcLineAmount() = 0) or (TWERentalLine."Line Amount" = 0) then begin
                                    VATAmount := 0;
                                    NewAmountIncludingVAT := 0;
                                end else begin
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * TWERentalLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      VATAmountLine."Amount Including VAT" * TWERentalLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                                end;
                                OnUpdateVATOnLinesOnBeforeCalculateNewAmount(
                                 Rec, RentalHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmountIncludingVAT, VATAmount);
                                NewAmount :=
                                  Round(NewAmountIncludingVAT, localCurrency."Amount Rounding Precision") -
                                  Round(VATAmount, localCurrency."Amount Rounding Precision");
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - RentalHeader."VAT Base Discount %" / 100), localCurrency."Amount Rounding Precision");
                            end else begin
                                if TWERentalLine."VAT Calculation Type" = TWERentalLine."VAT Calculation Type"::"Full VAT" then begin
                                    VATAmount := TWERentalLine.CalcLineAmount();
                                    NewAmount := 0;
                                    NewVATBaseAmount := 0;
                                end else begin
                                    NewAmount := TWERentalLine.CalcLineAmount();
                                    NewVATBaseAmount :=
                                      Round(
                                        NewAmount * (1 - RentalHeader."VAT Base Discount %" / 100), localCurrency."Amount Rounding Precision");
                                    if VATAmountLine."VAT Base" = 0 then
                                        VATAmount := 0
                                    else
                                        VATAmount :=
                                          TempVATAmountLineRemainder."VAT Amount" +
                                          VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                                end;
                                OnUpdateVATOnLinesOnBeforeCalculateNewAmount(
                                  Rec, RentalHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmount, VATAmount);
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, localCurrency."Amount Rounding Precision");
                            end;
                            OnUpdateVATOnLinesOnAfterCalculateNewAmount(
                              Rec, RentalHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmountIncludingVAT, VATAmount,
                               NewAmount, NewVATBaseAmount);
                        end else begin
                            if VATAmountLine.CalcLineAmount() = 0 then
                                VATDifference := 0
                            else
                                VATDifference :=
                                  TempVATAmountLineRemainder."VAT Difference" +
                                  VATAmountLine."VAT Difference" * (LineAmountToInvoice - InvDiscAmount) / VATAmountLine.CalcLineAmount();
                            if LineAmountToInvoice = 0 then
                                TWERentalLine."VAT Difference" := 0
                            else
                                TWERentalLine."VAT Difference" := Round(VATDifference, localCurrency."Amount Rounding Precision");
                        end;
                        OnUpdateVATOnLinesOnAfterCalculateAmounts(TWERentalLine, RentalHeader);

                        if QtyType = QtyType::General then begin
                            if not TWERentalLine."Prepayment Line" then
                                UpdatePrepmtAmounts();
                            UpdateBaseAmounts(NewAmount, Round(NewAmountIncludingVAT, localCurrency."Amount Rounding Precision"), NewVATBaseAmount);
                        end;
                        TWERentalLine.InitOutstanding();
                        TWERentalLine.Modify();
                        LineWasModified := true;

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, localCurrency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - TWERentalLine."VAT Difference";
                        OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(Rec, TempVATAmountLineRemainder, VATAmount, NewVATBaseAmount);
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until TWERentalLine.Next() = 0;

        OnAfterUpdateVATOnLines(RentalHeader, TWERentalLine, VATAmountLine, QtyType);
    end;

    local procedure IsUpdateVATOnLinesHandled(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Integer) IsHandled: Boolean
    begin
        IsHandled := FALSE;
        OnBeforeUpdateVATOnLines(RentalHeader, TWERentalLine, VATAmountLine, IsHandled, QtyType);
        exit(IsHandled);
    end;

    /// <summary>
    /// CalcVATAmountLines.
    /// </summary>
    /// <param name="QtyType">Option General,Invoicing,Shipping.</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TWERentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmountLine">VAR Record "VAT Amount Line".</param>
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping; var RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        CalcVATAmountLines(QtyType, RentalHeader, TWERentalLine, VATAmountLine, true);
    end;

    /// <summary>
    /// CalcVATAmountLines.
    /// </summary>
    /// <param name="QtyType">Option General,Invoicing,Shipping.</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="TWERentalLine">VAR Record "TWE Rental Line".</param>
    /// <param name="VATAmountLine">VAR Record "VAT Amount Line".</param>
    /// <param name="IncludePrepayments">Boolean.</param>
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping; var RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; IncludePrepayments: Boolean)
    var
        TotalVATAmount: Decimal;
        QtyToHandle: Decimal;
        AmtToHandle: Decimal;
        RoundingLineInserted: Boolean;
    begin
        if IsCalcVATAmountLinesHandled(RentalHeader, TWERentalLine, VATAmountLine, QtyType) then
            exit;

        Currency.Initialize(RentalHeader."Currency Code");

        VATAmountLine.DeleteAll();

        TWERentalLine.SetRange("Document Type", RentalHeader."Document Type");
        TWERentalLine.SetRange("Document No.", RentalHeader."No.");
        OnCalcVATAmountLinesOnAfterSetFilters(TWERentalLine, RentalHeader);
        if TWERentalLine.FindSet() then
            repeat
                if not ZeroAmountLine(QtyType) then begin
                    if (Type = Type::"G/L Account") and not "Prepayment Line" then
                        RoundingLineInserted := (("No." = GetCPGInvRoundAcc(RentalHeader)) and "System-Created Entry") or RoundingLineInserted;
                    if "VAT Calculation Type" in
                       ["VAT Calculation Type"::"Reverse Charge VAT", "VAT Calculation Type"::"Sales Tax"]
                    then
                        "VAT %" := 0;
                    if not VATAmountLine.Get(
                         "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Line Amount" >= 0)
                    then
                        VATAmountLine.InsertNewLine(
                          "VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "VAT %", "Line Amount" >= 0, false);

                    case QtyType of
                        QtyType::General:
                            begin
                                VATAmountLine.Quantity += "Quantity (Base)";
                                VATAmountLine.SumLine(
                                  "Line Amount", "Inv. Discount Amount", "VAT Difference", "Allow Invoice Disc.", "Prepayment Line");
                            end;
                        QtyType::Invoicing:
                            begin
                                case true of
                                    ("Document Type" in ["Document Type"::Contract, "Document Type"::Invoice]) and
                                  (not RentalHeader.Ship) and RentalHeader.Invoice and (not "Prepayment Line"):
                                        if "Shipment No." = '' then begin
                                            if Type <> Type::"Rental Item" then begin
                                                QtyToHandle := GetAbsMin("Qty. to Invoice", "Qty. Shipped Not Invoiced");
                                                VATAmountLine.Quantity += GetAbsMin("Qty. to Invoice (Base)", "Qty. Shipped Not Invd. (Base)");
                                            end else begin
                                                QtyToHandle := Quantity;
                                                VATAmountLine.Quantity += "Quantity (Base)";
                                            end;
                                        end else
                                            if Type <> Type::"Rental Item" then begin
                                                QtyToHandle := "Qty. to Invoice";
                                                VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                            end else begin
                                                QtyToHandle := Quantity;
                                                VATAmountLine.Quantity += "Quantity (Base)";
                                            end;

                                    IsCreditDocType() and (not RentalHeader.Receive) and RentalHeader.Invoice:
                                        if "Return Receipt No." <> '' then begin
                                            QtyToHandle := "Qty. to Invoice";
                                            VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                        end;
                                    else
                                        if Type <> Type::"Rental Item" then begin
                                            QtyToHandle := "Qty. to Invoice";
                                            VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                        end else begin
                                            QtyToHandle := Quantity;
                                            VATAmountLine.Quantity += "Quantity (Base)";
                                        end;
                                end;

                                if IncludePrepayments then
                                    AmtToHandle := GetLineAmountToHandleInclPrepmt(QtyToHandle)
                                else
                                    AmtToHandle := GetLineAmountToHandle(QtyToHandle);
                                if RentalHeader."Invoice Discount Calculation" <> RentalHeader."Invoice Discount Calculation"::Amount then
                                    VATAmountLine.SumLine(
                                      AmtToHandle, Round("Inv. Discount Amount" * QtyToHandle / Quantity, Currency."Amount Rounding Precision"),
                                      "VAT Difference", "Allow Invoice Disc.", "Prepayment Line")
                                else
                                    VATAmountLine.SumLine(
                                      AmtToHandle, "Inv. Disc. Amount to Invoice", "VAT Difference", "Allow Invoice Disc.", "Prepayment Line");
                            end;
                        QtyType::Shipping:
                            begin
                                if IncludePrepayments then
                                    AmtToHandle := GetLineAmountToHandleInclPrepmt(QtyToHandle)
                                else
                                    AmtToHandle := GetLineAmountToHandle(QtyToHandle);
                                VATAmountLine.SumLine(
                                  AmtToHandle, Round("Inv. Discount Amount" * QtyToHandle / Quantity, Currency."Amount Rounding Precision"),
                                  "VAT Difference", "Allow Invoice Disc.", "Prepayment Line");
                            end;
                    end;
                    TotalVATAmount += "Amount Including VAT" - Amount;
                    OnCalcVATAmountLinesOnAfterCalcLineTotals(VATAmountLine, RentalHeader, TWERentalLine, Currency, QtyType, TotalVATAmount);
                end;
            until Next() = 0;

        VATAmountLine.UpdateLines(
          TotalVATAmount, Currency, RentalHeader."Currency Factor", RentalHeader."Prices Including VAT",
          RentalHeader."VAT Base Discount %", RentalHeader."Tax Area Code", RentalHeader."Tax Liable", RentalHeader."Posting Date");

        if RoundingLineInserted and (TotalVATAmount <> 0) then
            if GetVATAmountLineOfMaxAmt(VATAmountLine, TWERentalLine) then begin
                VATAmountLine."VAT Amount" += TotalVATAmount;
                VATAmountLine."Amount Including VAT" += TotalVATAmount;
                VATAmountLine."Calculated VAT Amount" += TotalVATAmount;
                VATAmountLine.Modify();
            end;

        OnAfterCalcVATAmountLines(RentalHeader, TWERentalLine, VATAmountLine, QtyType);
    end;

    /// <summary>
    /// GetCPGInvRoundAcc.
    /// </summary>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetCPGInvRoundAcc(var RentalHeader: Record "TWE Rental Header"): Code[20]
    var
        Cust: Record Customer;
        CustTemplate: Record "Customer Templ.";
        CustPostingGroup: Record "Customer Posting Group";
    begin
        GetRentalSetup();
        if RentalSetup."Invoice Rounding" then
            if Cust.Get(RentalHeader."Bill-to Customer No.") then
                CustPostingGroup.Get(Cust."Customer Posting Group")
            else
                if CustTemplate.Get(RentalHeader."Rented-to Cust. Templ Code") then
                    CustPostingGroup.Get(CustTemplate."Customer Posting Group");

        exit(CustPostingGroup."Invoice Rounding Account");
    end;

    local procedure GetVATAmountLineOfMaxAmt(var VATAmountLine: Record "VAT Amount Line"; TWERentalLine: Record "TWE Rental Line"): Boolean
    var
        VATAmount1: Decimal;
        VATAmount2: Decimal;
        IsPositive1: Boolean;
        IsPositive2: Boolean;
    begin
        if VATAmountLine.Get(TWERentalLine."VAT Identifier", TWERentalLine."VAT Calculation Type", TWERentalLine."Tax Group Code", false, false) then begin
            VATAmount1 := VATAmountLine."VAT Amount";
            IsPositive1 := VATAmountLine.Positive;
        end;
        if VATAmountLine.Get(TWERentalLine."VAT Identifier", TWERentalLine."VAT Calculation Type", TWERentalLine."Tax Group Code", false, true) then begin
            VATAmount2 := VATAmountLine."VAT Amount";
            IsPositive2 := VATAmountLine.Positive;
        end;
        if Abs(VATAmount1) >= Abs(VATAmount2) then
            exit(
              VATAmountLine.Get(TWERentalLine."VAT Identifier", TWERentalLine."VAT Calculation Type", TWERentalLine."Tax Group Code", false, IsPositive1));
        exit(
          VATAmountLine.Get(TWERentalLine."VAT Identifier", TWERentalLine."VAT Calculation Type", TWERentalLine."Tax Group Code", false, IsPositive2));
    end;

    /// <summary>
    /// CalcInvDiscToInvoice.
    /// </summary>
    procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetRentalHeader();
        OldInvDiscAmtToInv := "Inv. Disc. Amount to Invoice";
        if Quantity = 0 then
            Validate("Inv. Disc. Amount to Invoice", 0)
        else
            Validate(
              "Inv. Disc. Amount to Invoice",
              Round(
                "Inv. Discount Amount" * "Qty. to Invoice" / Quantity,
                Currency."Amount Rounding Precision"));

        if OldInvDiscAmtToInv <> "Inv. Disc. Amount to Invoice" then begin
            "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
            "VAT Difference" := 0;
        end;
        NotifyOnMissingSetup(FieldNo("Inv. Discount Amount"));
    end;

    /// <summary>
    /// UpdateWithWarehouseShip.
    /// </summary>
    procedure UpdateWithWarehouseShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWithWarehouseShip(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsInventoriableMainRentalItem() then
            case true of
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Contract]) and (Quantity >= 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Qty. to Ship", 0)
                    else
                        Validate("Qty. to Ship", "Outstanding Quantity");
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Contract]) and (Quantity < 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Qty. to Ship", 0)
                    else
                        Validate("Qty. to Ship", "Outstanding Quantity");
            end;

        SetDefaultQuantity();

        OnAfterUpdateWithWarehouseShip(RentalHeader, Rec);
    end;

    local procedure CheckWarehouse()
    var
        Location2: Record Location;
        WhseSetup: Record "Warehouse Setup";
        ShowDialog: Option " ",Message,Error;
        DialogText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(Rec, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if "Location Code" = '' then begin
            WhseSetup.Get();
            Location2."Require Shipment" := WhseSetup."Require Shipment";
            Location2."Require Pick" := WhseSetup."Require Pick";
            Location2."Require Receive" := WhseSetup."Require Receive";
            Location2."Require Put-away" := WhseSetup."Require Put-away";
        end else
            Location2 := Location;

        DialogText := Text035Lbl;
        if ("Document Type" in ["Document Type"::Contract, "Document Type"::"Return Shipment"]) and
           Location2."Directed Put-away and Pick"
        then begin
            ShowDialog := ShowDialog::Error;
            if (("Document Type" = "Document Type"::Contract) and (Quantity >= 0)) or
               (("Document Type" = "Document Type"::"Return Shipment") and (Quantity < 0))
            then
                DialogText :=
                  DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
            else
                DialogText :=
                  DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"));
        end else begin
            if (("Document Type" = "Document Type"::Contract) and (Quantity >= 0) and
                (Location2."Require Shipment" or Location2."Require Pick")) or
               (("Document Type" = "Document Type"::"Return Shipment") and (Quantity < 0) and
                (Location2."Require Shipment" or Location2."Require Pick"))
            then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location2."Require Shipment" then
                        ShowDialog := ShowDialog::Message;
                if Location2."Require Shipment" then
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
                else begin
                    DialogText := Text036Lbl;
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Pick"));
                end;
            end;

            if (("Document Type" = "Document Type"::Contract) and (Quantity < 0) and
                (Location2."Require Receive" or Location2."Require Put-away")) or
               (("Document Type" = "Document Type"::"Return Shipment") and (Quantity >= 0) and
                (Location2."Require Receive" or Location2."Require Put-away"))
            then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location2."Require Receive" then
                        ShowDialog := ShowDialog::Message;
                if Location2."Require Receive" then
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"))
                else begin
                    DialogText := Text036Lbl;
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Put-away"));
                end;
            end;
        end;

        OnCheckWarehouseOnBeforeShowDialog(Rec, Location2, ShowDialog, DialogText);

        case ShowDialog of
            ShowDialog::Message:
                Message(WhseRequirementMsg, DialogText);
            ShowDialog::Error:
                Error(Text016Lbl, DialogText, FieldCaption("Line No."), "Line No.");
        end;

        HandleDedicatedBin(true);
    end;

    /// <summary>
    /// UpdateDates.
    /// </summary>
    procedure UpdateDates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDates(Rec, IsHandled);
        if IsHandled then
            exit;

        if CurrFieldNo = 0 then begin
            PlannedShipmentDateCalculated := false;
            PlannedDeliveryDateCalculated := false;
        end;
        if "Promised Delivery Date" <> 0D then
            Validate("Promised Delivery Date")
        else
            if "Requested Delivery Date" <> 0D then
                Validate("Requested Delivery Date")
            else
                Validate("Shipment Date");

        OnAfterUpdateDates(Rec);
    end;

    /// <summary>
    /// GetMainRentalItemTranslation.
    /// </summary>
    procedure GetMainRentalItemTranslation()
    var
        MainRentalItemTranslation: Record "Item Translation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetMainRentalItemTranslation(Rec, IsHandled);
        if IsHandled then
            exit;

        GetRentalHeader();
        if MainRentalItemTranslation.Get("No.", "Variant Code", RentalHeader."Language Code") then begin
            Description := MainRentalItemTranslation.Description;
            "Description 2" := MainRentalItemTranslation."Description 2";
            OnAfterGetMainRentalItemTranslation(Rec, RentalHeader, MainRentalItemTranslation);
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    /// <summary>
    /// PriceExists.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure PriceExists(): Boolean
    begin
        if "Document No." <> '' then
            exit(PriceExists(true));
        exit(false);
    end;

    /// <summary>
    /// LineDiscExists.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure LineDiscExists(): Boolean
    begin
        if "Document No." <> '' then
            exit(DiscountExists(true));
        exit(false);
    end;

    /// <summary>
    /// RowID1.
    /// </summary>
    /// <returns>Return value of type Text[250].</returns>
    procedure RowID1(): Text[250]
    var
        MainRentalItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(MainRentalItemTrackingMgt.ComposeRowID(DATABASE::"Sales Line", "Document Type".AsInteger(),
            "Document No.", '', 0, "Line No."));
    end;

    local procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::"Rental Item" then
            exit;

        "Bin Code" := '';
        if "Drop Shipment" then
            exit;

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then begin
                if ("Qty. to Assemble to Order" > 0) or IsAsmToOrderRequired() then
                    if GetATOBin(Location, "Bin Code") then
                        exit;

                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                HandleDedicatedBin(false);
            end;
        end;
    end;

    /// <summary>
    /// GetATOBin.
    /// </summary>
    /// <param name="Location">Record Location.</param>
    /// <param name="BinCode">VAR Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetATOBin(Location: Record Location; var BinCode: Code[20]): Boolean
    var
        AsmHeader: Record "Assembly Header";
    begin
        if not Location."Require Shipment" then
            BinCode := Location."Asm.-to-Order Shpt. Bin Code";
        if BinCode <> '' then
            exit(true);

        if AsmHeader.GetFromAssemblyBin(Location, BinCode) then
            exit(true);

        exit(false);
    end;

    /// <summary>
    /// IsInbound.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsInbound(): Boolean
    begin
        case "Document Type" of
            "Document Type"::Contract, "Document Type"::Invoice, "Document Type"::Quote:
                exit("Quantity (Base)" < 0);
            "Document Type"::"Return Shipment", "Document Type"::"Credit Memo":
                exit("Quantity (Base)" > 0);
        end;

        exit(false);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if not IsInbound() and ("Quantity (Base)" <> 0) then
            WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Location Code", "Bin Code", IssueWarning);
    end;

    /// <summary>
    /// CheckAssocPurchOrder.
    /// </summary>
    /// <param name="TheFieldCaption">Text[250].</param>
    procedure CheckAssocPurchOrder(TheFieldCaption: Text[250])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAssocPurchOrder(Rec, TheFieldCaption, IsHandled, xRec);
        if IsHandled then
            exit;

        if TheFieldCaption = '' then begin // If sales line is being deleted
            if "Purch. Order Line No." <> 0 then
                Error(Text000Lbl, "Purchase Order No.", "Purch. Order Line No.");
            if "Special Order Purch. Line No." <> 0 then
                CheckPurchOrderLineDeleted("Special Order Purchase No.", "Special Order Purch. Line No.");
        end else begin
            if "Purch. Order Line No." <> 0 then
                Error(Text002Lbl, TheFieldCaption, "Purchase Order No.", "Purch. Order Line No.");

            if "Special Order Purch. Line No." <> 0 then
                Error(Text002Lbl, TheFieldCaption, "Special Order Purchase No.", "Special Order Purch. Line No.");
        end;
    end;

    local procedure CheckPurchOrderLineDeleted(PurchaseOrderNo: Code[20]; PurchaseLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseOrderNo, PurchaseLineNo) then
            Error(Text000Lbl, PurchaseOrderNo, PurchaseLineNo);
    end;

    /// <summary>
    /// CheckServMainRentalItemCreation.
    /// </summary>
    procedure CheckServMainRentalItemCreation()
    var
        MainRentalItem: Record "TWE Main Rental Item";
        ServMainRentalItemGroup: Record "Service Item Group";
    begin
        if CurrFieldNo = 0 then
            exit;
        if Type <> Type::"Rental Item" then
            exit;
        GetMainRentalItem(MainRentalItem);
        if MainRentalItem."Service Item Group" = '' then
            exit;
        if ServMainRentalItemGroup.Get(MainRentalItem."Service Item Group") then
            if ServMainRentalItemGroup."Create Service Item" then
                if "Qty. to Ship (Base)" <> Round("Qty. to Ship (Base)", 1) then
                    Error(
                      Text034Lbl,
                      FieldCaption("Qty. to Ship (Base)"),
                      ServMainRentalItemGroup.FieldCaption("Create Service Item"));
    end;

    /// <summary>
    /// MainRentalItemExists.
    /// </summary>
    /// <param name="MainRentalItemNo">Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure MainRentalItemExists(MainRentalItemNo: Code[20]): Boolean
    var
        MainRentalItem2: Record "TWE Main Rental Item";
    begin
        if Type = Type::"Rental Item" then
            if not MainRentalItem2.Get(MainRentalItemNo) then
                exit(false);
        exit(true);
    end;

    /*     local procedure FindOrCreateRecordByNo(SourceNo: Code[20]): Code[20]
        var
            MainRentalItem: Record "TWE Main Rental Item";
            FindRecordManagement: Codeunit "Find Record Management";
            FoundNo: Text;
            IsHandled: Boolean;
        begin
            IsHandled := false;
            OnBeforeFindOrCreateRecordByNo(Rec, xRec, CurrFieldNo, IsHandled);
            if IsHandled then
                exit("No.");

            GetRentalSetup;

            if Type = Type::"Rental Item" then begin
                if MainRentalItem.TryGetMainRentalItemNoOpenCardWithView(
                    FoundNo, SourceNo, RentalSetup."Create MainRentalItem from MainRentalItem No.", true, RentalSetup."Create MainRentalItem from MainRentalItem No.", '')
                 then
                    exit(CopyStr(FoundNo, 1, MaxStrLen("No.")))
            end else
                exit(FindRecordManagement.FindNoFromTypedValue(Type.AsInteger(), "No.", not "System-Created Entry"));

            exit(SourceNo);
        end; */

    /// <summary>
    /// IsShipment.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsShipment(): Boolean
    begin
        exit(SignedXX("Quantity (Base)") < 0);
    end;

    local procedure GetAbsMin(QtyToHandle: Decimal; QtyHandled: Decimal): Decimal
    begin
        if Abs(QtyHandled) < Abs(QtyToHandle) then
            exit(QtyHandled);

        exit(QtyToHandle);
    end;

    /// <summary>
    /// SetHideValidationDialog.
    /// </summary>
    /// <param name="NewHideValidationDialog">Boolean.</param>
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    /// <summary>
    /// GetHideValidationDialog.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    local procedure CheckApplFromMainRentalItemLedgEntry(var MainRentalItemLedgEntry: Record "Item Ledger Entry")
    var
        MainRentalItemTrackingLines: Page "Item Tracking Lines";
        QtyNotReturned: Decimal;
        QtyReturned: Decimal;
    begin
        if "Appl.-from Item Entry" = 0 then
            exit;

        if "Shipment No." <> '' then
            exit;

        OnCheckApplFromMainRentalItemLedgEntryOnBeforeTestFieldType(Rec);
        TestField(Type, Type::"Rental Item");
        TestField(Quantity);
        if IsCreditDocType() then begin
            if Quantity < 0 then
                FieldError(Quantity, Text029Lbl);
        end else
            if Quantity > 0 then
                FieldError(Quantity, Text030Lbl);


        MainRentalItemLedgEntry.Get("Appl.-from Item Entry");
        MainRentalItemLedgEntry.TestField(Positive, false);
        MainRentalItemLedgEntry.TestField("Item No.", "No.");
        MainRentalItemLedgEntry.TestField("Variant Code", "Variant Code");
        if MainRentalItemLedgEntry.TrackingExists() then
            Error(Text040Lbl, MainRentalItemTrackingLines.Caption, FieldCaption("Appl.-from Item Entry"));

        if Abs("Quantity (Base)") > -MainRentalItemLedgEntry.Quantity then
            Error(
              Text046Lbl,
              -MainRentalItemLedgEntry.Quantity, MainRentalItemLedgEntry.FieldCaption("Document No."),
              MainRentalItemLedgEntry."Document No.");

        if IsCreditDocType() then
            if Abs("Outstanding Qty. (Base)") > -MainRentalItemLedgEntry."Shipped Qty. Not Returned" then begin
                QtyNotReturned := MainRentalItemLedgEntry."Shipped Qty. Not Returned";
                QtyReturned := MainRentalItemLedgEntry.Quantity - MainRentalItemLedgEntry."Shipped Qty. Not Returned";
                if "Qty. per Unit of Measure" <> 0 then begin
                    QtyNotReturned :=
                      Round(MainRentalItemLedgEntry."Shipped Qty. Not Returned" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    QtyReturned :=
                      Round(
                        (MainRentalItemLedgEntry.Quantity - MainRentalItemLedgEntry."Shipped Qty. Not Returned") /
                        "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                end;
                ShowReturnedUnitsError(MainRentalItemLedgEntry, QtyReturned, QtyNotReturned);
            end;
    end;

    /// <summary>
    /// CalcPrepaymentToDeduct.
    /// </summary>
    procedure CalcPrepaymentToDeduct()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPrepmtToDeduct(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Qty. to Invoice" <> 0) and ("Prepmt. Amt. Inv." <> 0) then begin
            GetRentalHeader();
            if ("Prepayment %" = 100) and not IsFinalInvoice() then
                "Prepmt Amt to Deduct" := GetLineAmountToHandle("Qty. to Invoice") - "Inv. Disc. Amount to Invoice"
            else
                "Prepmt Amt to Deduct" :=
                  Round(
                    ("Prepmt. Amt. Inv." - "Prepmt Amt Deducted") *
                    "Qty. to Invoice" / (Quantity - "Quantity Invoiced"), Currency."Amount Rounding Precision")
        end else
            "Prepmt Amt to Deduct" := 0
    end;

    /// <summary>
    /// IsFinalInvoice.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsFinalInvoice(): Boolean
    begin
        exit("Qty. to Invoice" = Quantity - "Quantity Invoiced");
    end;

    /// <summary>
    /// GetLineAmountToHandle.
    /// </summary>
    /// <param name="QtyToHandle">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetLineAmountToHandle(QtyToHandle: Decimal): Decimal
    var
        LineAmount: Decimal;
        LineDiscAmount: Decimal;
    begin
        if "Line Discount %" = 100 then
            exit(0);

        GetRentalHeader();

        if "Prepmt Amt to Deduct" = 0 then
            if Type <> "TWE Rental Line Type"::"Rental Item" then
                LineAmount := Round(QtyToHandle * "Unit Price", Currency."Amount Rounding Precision")
            else
                LineAmount := Round(QtyToHandle * "Unit Price" * "Total Days to Invoice", Currency."Amount Rounding Precision")
        else
            if Quantity <> 0 then begin
                if Type <> "TWE Rental Line Type"::"Rental Item" then begin
                    LineAmount := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision");
                    LineAmount := Round(QtyToHandle * LineAmount / Quantity, Currency."Amount Rounding Precision");
                end else begin
                    LineAmount := Round(Quantity * "Unit Price" * "Total Days to Invoice", Currency."Amount Rounding Precision");
                    LineAmount := Round(QtyToHandle * LineAmount / Quantity, Currency."Amount Rounding Precision");
                end;
            end else
                LineAmount := 0;

        if QtyToHandle <> Quantity then
            LineDiscAmount := Round(LineAmount * "Line Discount %" / 100, Currency."Amount Rounding Precision")
        else
            LineDiscAmount := "Line Discount Amount";

        OnAfterGetLineAmountToHandle(Rec, QtyToHandle, LineAmount, LineDiscAmount);
        exit(LineAmount - LineDiscAmount);
    end;

    /// <summary>
    /// GetLineAmountToHandleInclPrepmt.
    /// </summary>
    /// <param name="QtyToHandle">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetLineAmountToHandleInclPrepmt(QtyToHandle: Decimal): Decimal
    var
        RentalPostPrepayments: Codeunit "TWE Rental-Post Prepayments";
        DocType: Option Invoice,"Credit Memo",Statistic;
    begin
        if "Line Discount %" = 100 then
            exit(0);

        if IsCreditDocType() then
            DocType := DocType::"Credit Memo"
        else
            DocType := DocType::Invoice;

        if ("Prepayment %" = 100) and not "Prepayment Line" and ("Prepmt Amt to Deduct" <> 0) then
            if RentalPostPrepayments.PrepmtAmount(Rec, DocType) <= 0 then
                exit("Prepmt Amt to Deduct" + "Inv. Disc. Amount to Invoice");

        exit(GetLineAmountToHandle(QtyToHandle));
    end;

    /// <summary>
    /// GetLineAmountToInvoice.
    /// </summary>
    /// <returns>Return the Line Amout which will be invoiced</returns>
    procedure GetLineAmountToInvoice(): Decimal
    begin
        if (Type = Type::"Rental Item") then
            exit("Line Amount" / "Total Days to Invoice" * "Duration to be billed")
        else
            exit("Line Amount" / "Qty. to Invoice");
    end;

    /// <summary>
    /// GetVATAmountToInvoice.
    /// </summary>
    /// <returns>Return the VAT Amount which will be invoiced</returns>
    procedure GetVATAmountToInvoice(): Decimal
    begin

        if (Type = Type::"Rental Item") then
            exit(("Amount Including VAT" - Amount) / "Total Days to Invoice" * "Duration to be billed")
        else
            exit(("Amount Including VAT" - Amount) / "Qty. to Invoice");
    end;

    /// <summary>
    /// GetLineAmountExclVAT.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetLineAmountExclVAT(): Decimal
    begin
        if "Document No." = '' then
            exit(0);
        GetRentalHeader();
        if not RentalHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// GetLineAmountInclVAT.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetLineAmountInclVAT(): Decimal
    begin
        if "Document No." = '' then
            exit(0);
        GetRentalHeader();
        if RentalHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// SetHasBeenShown.
    /// </summary>
    procedure SetHasBeenShown()
    begin
        HasBeenShown := true;
    end;

    /// <summary>
    /// BlockDynamicTracking.
    /// </summary>
    /// <param name="SetBlock">Boolean.</param>
    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        ReserveSalesLine.Block(SetBlock);
    end;

    /// <summary>
    /// InitQtyToShip2.
    /// </summary>
    procedure InitQtyToShip2()
    begin
        "Qty. to Ship" := "Outstanding Quantity";
        "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        OnAfterInitQtyToShip2(Rec, CurrFieldNo);

        //ATOLink.UpdateQtyToAsmFromTWERentalLine(Rec);

        CheckServMainRentalItemCreation();

        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();
        "VAT Difference" := 0;

        OnInitQtyToShip2OnBeforeCalcInvDiscToInvoice(Rec, xRec);

        CalcInvDiscToInvoice();

        CalcPrepaymentToDeduct();
    end;

    /// <summary>
    /// ShowLineComments.
    /// </summary>
    procedure ShowLineComments()
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
        RentalCommentSheet: Page "TWE Rental Comment Sheet";
    begin
        TestField("Document No.");
        TestField("Line No.");
        RentalCommentLine.SetRange("Document Type", "Document Type");
        RentalCommentLine.SetRange("No.", "Document No.");
        RentalCommentLine.SetRange("Document Line No.", "Line No.");
        RentalCommentSheet.SetTableView(RentalCommentLine);
        RentalCommentSheet.RunModal();
    end;

    /// <summary>
    /// SetDefaultQuantity.
    /// </summary>
    procedure SetDefaultQuantity()
    begin
        GetRentalSetup();
        if RentalSetup."Default Quantity to Ship" = RentalSetup."Default Quantity to Ship"::Blank then begin
            if ("Document Type" = "Document Type"::Contract) or ("Document Type" = "Document Type"::Quote) then begin
                "Qty. to Ship" := 0;
                "Qty. to Ship (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
            if "Document Type" = "Document Type"::"Return Shipment" then begin
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
                "Return Quantity" := 0;
            end;
        end;

        OnAfterSetDefaultQuantity(Rec, xRec);
    end;

    local procedure SetReserveWithoutPurchasingCode()
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        GetMainRentalItem(MainRentalItem);
        if MainRentalItem.Reserve = MainRentalItem.Reserve::Optional then begin
            GetRentalHeader();
            Reserve := RentalHeader.Reserve;
        end else
            Reserve := MainRentalItem.Reserve;

        OnAfterSetReserveWithoutPurchasingCode(Rec, RentalHeader, MainRentalItem);
    end;

    local procedure SetDefaultMainRentalItemQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultMainRentalItemQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        GetRentalSetup();
    end;

    /// <summary>
    /// UpdatePrePaymentAmounts.
    /// </summary>
    procedure UpdatePrePaymentAmounts()
    var
        ShipmentLine: Record "Sales Shipment Line";
        RentalContractLine: Record "TWE Rental Line";
        RentalContractHeader: Record "TWE Rental Header";
    begin
        if ("Document Type" <> "Document Type"::Invoice) or ("Prepayment %" = 0) then
            exit;

        if not ShipmentLine.Get("Shipment No.", "Shipment Line No.") then begin
            "Prepmt Amt to Deduct" := 0;
            "Prepmt VAT Diff. to Deduct" := 0;
        end else
            if RentalContractLine.Get(RentalContractLine."Document Type"::Contract, ShipmentLine."Order No.", ShipmentLine."Order Line No.") then begin
                if ("Prepayment %" = 100) and (Quantity <> RentalContractLine.Quantity - RentalContractLine."Quantity Invoiced") then
                    "Prepmt Amt to Deduct" := "Line Amount"
                else
                    "Prepmt Amt to Deduct" :=
                      Round((RentalContractLine."Prepmt. Amt. Inv." - RentalContractLine."Prepmt Amt Deducted") *
                        Quantity / (RentalContractLine.Quantity - RentalContractLine."Quantity Invoiced"), Currency."Amount Rounding Precision");
                "Prepmt VAT Diff. to Deduct" := "Prepayment VAT Difference" - "Prepmt VAT Diff. Deducted";
                RentalContractHeader.Get(RentalContractHeader."Document Type"::Contract, RentalContractLine."Document No.");
            end else begin
                "Prepmt Amt to Deduct" := 0;
                "Prepmt VAT Diff. to Deduct" := 0;
            end;

        GetRentalHeader();
        RentalHeader.TestField("Prices Including VAT", RentalContractHeader."Prices Including VAT");
        if RentalHeader."Prices Including VAT" then begin
            "Prepmt. Amt. Incl. VAT" := "Prepmt Amt to Deduct";
            "Prepayment Amount" :=
              Round(
                "Prepmt Amt to Deduct" / (1 + ("Prepayment VAT %" / 100)),
                Currency."Amount Rounding Precision");
        end else begin
            "Prepmt. Amt. Incl. VAT" :=
              Round(
                "Prepmt Amt to Deduct" * (1 + ("Prepayment VAT %" / 100)),
                Currency."Amount Rounding Precision");
            "Prepayment Amount" := "Prepmt Amt to Deduct";
        end;
        "Prepmt. Line Amount" := "Prepmt Amt to Deduct";
        "Prepmt. Amt. Inv." := "Prepmt. Line Amount";
        "Prepmt. VAT Base Amt." := "Prepayment Amount";
        "Prepmt. Amount Inv. Incl. VAT" := "Prepmt. Amt. Incl. VAT";
        "Prepmt Amt Deducted" := 0;

        OnAfterUpdatePrePaymentAmounts(Rec);
    end;

    /// <summary>
    /// ZeroAmountLine.
    /// </summary>
    /// <param name="QtyType">Option General,Invoicing,Shipping.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure ZeroAmountLine(QtyType: Option General,Invoicing,Shipping) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeZeroAmountLine(Rec, QtyType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not HasTypeToFillMandatoryFields() then
            exit(true);
        if Quantity = 0 then
            exit(true);
        if "Unit Price" = 0 then
            exit(true);
        if QtyType = QtyType::Invoicing then
            if Type <> Type::"Rental Item" then
                if "Qty. to Invoice" = 0 then
                    exit(true);
        exit(false);
    end;

    /// <summary>
    /// FilterLinesWithMainRentalItemToPlan.
    /// </summary>
    /// <param name="MainRentalItem">VAR Record MainRentalItem.</param>
    /// <param name="DocumentType">Enum "Sales Document Type".</param>
    procedure FilterLinesWithMainRentalItemToPlan(var MainRentalItem: Record "TWE Main Rental Item"; DocumentType: Enum "Sales Document Type")
    begin
        Reset();
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::"Rental Item");
        SetRange("No.", MainRentalItem."No.");
        // SetFilter("Variant Code", MainRentalItem.GetFilter("Variant Filter"));
        SetFilter("Location Code", MainRentalItem.GetFilter("Location Filter"));
        SetFilter("Drop Shipment", MainRentalItem.GetFilter("Drop Shipment Filter"));
        SetFilter("Shortcut Dimension 1 Code", MainRentalItem.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", MainRentalItem.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Shipment Date", MainRentalItem.GetFilter("Date Filter"));
        SetFilter("Outstanding Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", MainRentalItem.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithMainRentalItemToPlan(Rec, MainRentalItem, DocumentType.AsInteger());
    end;

    /// <summary>
    /// FindLinesWithMainRentalItemToPlan.
    /// </summary>
    /// <param name="MainRentalItem">VAR Record MainRentalItem.</param>
    /// <param name="DocumentType">Enum "Sales Document Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure FindLinesWithMainRentalItemToPlan(var MainRentalItem: Record "TWE Main Rental Item"; DocumentType: Enum "Sales Document Type"): Boolean
    begin
        FilterLinesWithMainRentalItemToPlan(MainRentalItem, DocumentType);
        exit(Find('-'));
    end;

    /// <summary>
    /// LinesWithMainRentalItemToPlanExist.
    /// </summary>
    /// <param name="MainRentalItem">VAR Record MainRentalItem.</param>
    /// <param name="DocumentType">Enum "Sales Document Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure LinesWithMainRentalItemToPlanExist(var MainRentalItem: Record "TWE Main Rental Item"; DocumentType: Enum "Sales Document Type"): Boolean
    begin
        FilterLinesWithMainRentalItemToPlan(MainRentalItem, DocumentType);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// FilterLinesForReservation.
    /// </summary>
    /// <param name="ReservationEntry">Record "Reservation Entry".</param>
    /// <param name="DocumentType">Enum "Sales Document Type".</param>
    /// <param name="AvailabilityFilter">Text.</param>
    /// <param name="Positive">Boolean.</param>
    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Enum "Sales Document Type"; AvailabilityFilter: Text;
                                                                                                        Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(
"Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::"Rental Item");
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Drop Shipment", false);
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Shipment Date", AvailabilityFilter);

        if DocumentType = "Document Type"::"Return Shipment" then
            if Positive then
                SetFilter("Quantity (Base)", '>0')
            else
                SetFilter("Quantity (Base)", '<0')
        else
            if Positive then
                SetFilter("Quantity (Base)", '<0')
            else
                SetFilter("Quantity (Base)", '>0');
    end;

    local procedure DateFormularZero(var DateFormularValue: DateFormula; CalledByFieldNo: Integer; CalledByFieldCaption: Text[250])
    var
        localDateFormularZero: DateFormula;
    begin
        Evaluate(localDateFormularZero, '<0D>');
        if (DateFormularValue <> localDateFormularZero) and (CalledByFieldNo = CurrFieldNo) then
            Error(Text051Lbl, CalledByFieldCaption, FieldCaption("Drop Shipment"));
        Evaluate(DateFormularValue, '<0D>');
    end;

    local procedure InitQtyToAsm()
    begin
        OnBeforeInitQtyToAsm(Rec, CurrFieldNo);

        if not IsAsmToOrderAllowed() then begin
            "Qty. to Assemble to Order" := 0;
            "Qty. to Asm. to Order (Base)" := 0;
            exit;
        end;

        if ((xRec."Qty. to Asm. to Order (Base)" = 0) and IsAsmToOrderRequired() and ("Qty. Shipped (Base)" = 0)) or
           ((xRec."Qty. to Asm. to Order (Base)" <> 0) and
            (xRec."Qty. to Asm. to Order (Base)" = xRec."Quantity (Base)")) or
           ("Qty. to Asm. to Order (Base)" > "Quantity (Base)")
        then begin
            "Qty. to Assemble to Order" := Quantity;
            "Qty. to Asm. to Order (Base)" := "Quantity (Base)";
        end;

        OnAfterInitQtyToAsm(Rec, CurrFieldNo)
    end;

    /// <summary>
    /// AsmToOrderExists.
    /// </summary>
    /// <param name="AsmHeader">VAR Record "Assembly Header".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure AsmToOrderExists(var AsmHeader: Record "Assembly Header"): Boolean
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        //  if not ATOLink.AsmExistsForTWERentalLine(Rec) then
        //      exit(false);
        exit(AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No."));
    end;

    /// <summary>
    /// FullQtyIsForAsmToOrder.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure FullQtyIsForAsmToOrder(): Boolean
    begin
        if "Qty. to Asm. to Order (Base)" = 0 then
            exit(false);
        exit("Quantity (Base)" = "Qty. to Asm. to Order (Base)");
    end;

    local procedure FullReservedQtyIsForAsmToOrder(): Boolean
    begin
        if "Qty. to Asm. to Order (Base)" = 0 then
            exit(false);
        CalcFields("Reserved Qty. (Base)");
        exit("Reserved Qty. (Base)" = "Qty. to Asm. to Order (Base)");
    end;

    /// <summary>
    /// QtyBaseOnATO.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure QtyBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Quantity (Base)");
        exit(0);
    end;

    /// <summary>
    /// QtyAsmRemainingBaseOnATO.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure QtyAsmRemainingBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Remaining Quantity (Base)");
        exit(0);
    end;

    /// <summary>
    /// QtyToAsmBaseOnATO.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure QtyToAsmBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Quantity to Assemble (Base)");
        exit(0);
    end;

    /// <summary>
    /// IsAsmToOrderAllowed.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAsmToOrderAllowed(): Boolean
    begin
        if Quantity < 0 then
            exit(false);
        if Type <> Type::"Rental Item" then
            exit(false);
        if "No." = '' then
            exit(false);
        if "Drop Shipment" or "Special Order" then
            exit(false);
        exit(true)
    end;

    /// <summary>
    /// IsAsmToOrderRequired.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsAsmToOrderRequired(): Boolean
    var
        MainRentalItem: Record "TWE Main Rental Item";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeIsAsmToOrderRequired(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (Type <> Type::"Rental Item") or ("No." = '') then
            exit(false);
        GetMainRentalItem(MainRentalItem);
        if GetSKU() then
            exit(SKU."Assembly Policy" = SKU."Assembly Policy"::"Assemble-to-Order");
        exit(MainRentalItem."Assembly Policy" = MainRentalItem."Assembly Policy"::"Assemble-to-Order");
    end;

    /// <summary>
    /// CheckAsmToOrder.
    /// </summary>
    /// <param name="AsmHeader">Record "Assembly Header".</param>
    procedure CheckAsmToOrder(AsmHeader: Record "Assembly Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAsmToOrder(Rec, AsmHeader, IsHandled);
        if IsHandled then
            exit;

        TestField("Qty. to Assemble to Order", AsmHeader.Quantity);
        TestField("Document Type", AsmHeader."Document Type");
        TestField(Type, Type::"Rental Item");
        TestField("No.", AsmHeader."Item No.");
        TestField("Location Code", AsmHeader."Location Code");
        TestField("Unit of Measure Code", AsmHeader."Unit of Measure Code");
        TestField("Variant Code", AsmHeader."Variant Code");
        TestField("Shipment Date", AsmHeader."Due Date");
        if "Document Type" = "Document Type"::Contract then begin
            AsmHeader.CalcFields("Reserved Qty. (Base)");
            AsmHeader.TestField("Reserved Qty. (Base)", AsmHeader."Remaining Quantity (Base)");
        end;
        TestField("Qty. to Asm. to Order (Base)", AsmHeader."Quantity (Base)");
        if "Outstanding Qty. (Base)" < AsmHeader."Remaining Quantity (Base)" then
            AsmHeader.FieldError("Remaining Quantity (Base)", StrSubstNo(Text045Lbl, AsmHeader."Remaining Quantity (Base)"));
    end;

    /// <summary>
    /// RollUpAsmCost.
    /// </summary>
    procedure RollUpAsmCost()
    begin
        // ATOLink.RollUpCost(Rec);
    end;

    /// <summary>
    /// RollupAsmPrice.
    /// </summary>
    procedure RollupAsmPrice()
    begin
        GetRentalHeader();
        // ATOLink.RollUpPrice(RentalHeader, Rec);
    end;

    /// <summary>
    /// OutstandingInvoiceAmountFromShipment.
    /// </summary>
    /// <param name="SellToCustomerNo">Code[20].</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure OutstandingInvoiceAmountFromShipment(SellToCustomerNo: Code[20]): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        TWERentalLine: Record "TWE Rental Line";
    begin
        TWERentalLine.SetCurrentKey("Document Type", "Rented-to Customer No.", "Shipment No.");
        TWERentalLine.SetRange("Document Type", TWERentalLine."Document Type"::Invoice);
        TWERentalLine.SetRange("Rented-to Customer No.", SellToCustomerNo);
        TWERentalLine.SetFilter("Shipment No.", '<>%1', '');
        TWERentalLine.CalcSums("Outstanding Amount (LCY)");
        exit(TWERentalLine."Outstanding Amount (LCY)");
    end;

    local procedure CheckShipmentRelation()
    var
        SalesShptLine: Record "Sales Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipmentRelation(IsHandled);
        if IsHandled then
            exit;

        SalesShptLine.Get("Shipment No.", "Shipment Line No.");
        if (Quantity * SalesShptLine."Qty. Shipped Not Invoiced") < 0 then
            FieldError("Qty. to Invoice", Text057Lbl);
        if Abs(Quantity) > Abs(SalesShptLine."Qty. Shipped Not Invoiced") then
            Error(Text058Lbl, SalesShptLine."Document No.");

        OnAfterCheckShipmentRelation(Rec, SalesShptLine);
    end;

    local procedure CheckRetRcptRelation()
    var
        ReturnRcptLine: Record "Return Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRetRcptRelation(IsHandled);
        if IsHandled then
            exit;

        ReturnRcptLine.Get("Return Receipt No.", "Return Receipt Line No.");
        if (Quantity * (ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced")) < 0 then
            FieldError("Qty. to Invoice", Text059Lbl);
        if Abs(Quantity) > Abs(ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced") then
            Error(Text060Lbl, ReturnRcptLine."Document No.");

        OnAfterCheckRetRcptRelation(Rec, ReturnRcptLine);
    end;

    local procedure VerifyMainRentalItemLineDim()
    begin
        if IsShippedReceivedMainRentalItemDimChanged() then
            ConfirmShippedReceivedMainRentalItemDimChange();
    end;

    /// <summary>
    /// IsShippedReceivedMainRentalItemDimChanged.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsShippedReceivedMainRentalItemDimChanged(): Boolean
    begin
        exit(("Dimension Set ID" <> xRec."Dimension Set ID") and (Type = Type::"Rental Item") and
          (("Qty. Shipped Not Invoiced" <> 0)));
    end;

    /// <summary>
    /// IsServiceChargeLine.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsServiceChargeLine(): Boolean
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if Type <> Type::"G/L Account" then
            exit(false);

        GetRentalHeader();
        CustomerPostingGroup.Get(RentalHeader."Customer Posting Group");
        exit(CustomerPostingGroup."Service Charge Acc." = "No.");
    end;

    /// <summary>
    /// ConfirmShippedReceivedMainRentalItemDimChange.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ConfirmShippedReceivedMainRentalItemDimChange(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text053Lbl, TableCaption), true) then
            Error(Text054Lbl);

        exit(true);
    end;

    /// <summary>
    /// InitType.
    /// </summary>
    procedure InitType()
    begin
        if "Document No." <> '' then begin
            if not RentalHeader.Get("Document Type", "Document No.") then
                exit;
            if (RentalHeader.Status = RentalHeader.Status::Released) and
               (xRec.Type in [xRec.Type::"Rental Item"])
            then
                Type := Type::" "
            else
                Type := xRec.Type;
        end;

        OnAfterInitType(Rec, xRec);
    end;

    local procedure CheckWMS()
    begin
        if CurrFieldNo <> 0 then
            CheckLocationOnWMS();
    end;

    /// <summary>
    /// CheckLocationOnWMS.
    /// </summary>
    procedure CheckLocationOnWMS()
    var
        DialogText: Text;
    begin
        if Type = Type::"Rental Item" then begin
            DialogText := Text035Lbl;
            if "Quantity (Base)" <> 0 then
                case "Document Type" of
                    "Document Type"::Invoice:
                        if "Shipment No." = '' then
                            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                DialogText += Location.GetRequirementText(Location.FieldNo("Require Shipment"));
                                Error(Text016Lbl, DialogText, FieldCaption("Line No."), "Line No.");
                            end;
                    "Document Type"::"Credit Memo":
                        if "Return Receipt No." = '' then
                            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                DialogText += Location.GetRequirementText(Location.FieldNo("Require Receive"));
                                Error(Text016Lbl, DialogText, FieldCaption("Line No."), "Line No.");
                            end;
                end;
        end;
    end;

    /// <summary>
    /// IsNonInventoriableMainRentalItem.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsNonInventoriableMainRentalItem(): Boolean
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        if Type <> Type::"Rental Item" then
            exit(false);
        if "No." = '' then
            exit(false);
        GetMainRentalItem(MainRentalItem);
        exit(MainRentalItem.IsNonInventoriableType());
    end;

    /// <summary>
    /// IsInventoriableMainRentalItem.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsInventoriableMainRentalItem(): Boolean
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        if Type <> Type::"Rental Item" then
            exit(false);
        if "No." = '' then
            exit(false);
        GetMainRentalItem(MainRentalItem);
        exit(MainRentalItem.IsInventoriableType());
    end;

    /// <summary>
    /// ValidateReturnReasonCode.
    /// </summary>
    /// <param name="CallingFieldNo">Integer.</param>
    procedure ValidateReturnReasonCode(CallingFieldNo: Integer)
    var
        ReturnReason: Record "Return Reason";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateReturnReasonCode(Rec, CallingFieldNo, IsHandled);
        if IsHandled then
            exit;

        if CallingFieldNo = 0 then
            exit;
        if "Return Reason Code" = '' then begin
            if (Type = Type::"Rental Item") and ("No." <> '') then
                GetUnitCost();
            PlanPriceCalcByField(CallingFieldNo);
        end;

        if ReturnReason.Get("Return Reason Code") then begin
            if (CallingFieldNo <> FieldNo("Location Code")) and (ReturnReason."Default Location Code" <> '') then
                Validate("Location Code", ReturnReason."Default Location Code");
            if ReturnReason."Inventory Value Zero" then
                Validate("Unit Cost (LCY)", 0)
            else
                if "Unit Price" = 0 then
                    PlanPriceCalcByField(CallingFieldNo);
        end;
        UpdateUnitPriceByField(CallingFieldNo);

        OnAfterValidateReturnReasonCode(Rec, CallingFieldNo);
    end;

    /// <summary>
    /// ValidateLineDiscountPercent.
    /// </summary>
    /// <param name="DropInvoiceDiscountAmount">Boolean.</param>
    procedure ValidateLineDiscountPercent(DropInvoiceDiscountAmount: Boolean)
    begin
        TestStatusOpen();

        if Type <> "TWE Rental Line Type"::"Rental Item" then
            "Line Discount Amount" :=
            Round(
                Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") *
                "Line Discount %" / 100, Currency."Amount Rounding Precision")
        else
            "Line Discount Amount" :=
            Round(
                Round(Quantity * "Unit Price" * "Total Days to Invoice", Currency."Amount Rounding Precision") *
                "Line Discount %" / 100, Currency."Amount Rounding Precision");

        if DropInvoiceDiscountAmount then begin
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
        end;
        OnValidateLineDiscountPercentOnBeforeUpdateAmounts(Rec, CurrFieldNo);
        UpdateAmounts();

        OnAfterValidateLineDiscountPercent(Rec, CurrFieldNo);
    end;

    local procedure ValidateVATProdPostingGroup()
    var
        IsHandled: boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVATProdPostingGroup(IsHandled);
        if IsHandled then
            exit;

        Validate("VAT Prod. Posting Group");
    end;

    local procedure NotifyOnMissingSetup(FieldNumber: Integer)
    var
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        if CurrFieldNo = 0 then
            exit;
        GetRentalSetup();
        DiscountNotificationMgt.RecallNotification(RentalSetup.RecordId);
        if (FieldNumber = FieldNo("Line Discount Amount")) and ("Line Discount Amount" = 0) then
            exit;
        DiscountNotificationMgt.NotifyAboutMissingSetup(
          RentalSetup.RecordId, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
          RentalSetup."Discount Posting", RentalSetup."Discount Posting"::"Invoice Discounts");
    end;

    /// <summary>
    /// HasTypeToFillMandatoryFields.
    /// </summary>
    /// <returns>Return variable ReturnValue of type Boolean.</returns>
    procedure HasTypeToFillMandatoryFields() ReturnValue: Boolean
    begin
        ReturnValue := Type <> Type::" ";

        OnAfterHasTypeToFillMandatoryFields(Rec, ReturnValue);
    end;


    /// <summary>
    /// UpdatePriceDescription.
    /// </summary>
    procedure UpdatePriceDescription()
    var
        localCurrency: Record Currency;
    begin
        "Price description" := '';
        if Type in [Type::"Rental Item", Type::Resource] then
            if "Line Discount %" = 0 then
                "Price description" := StrSubstNo(
                    PriceDescriptionTxt, Quantity, localCurrency.ResolveGLCurrencySymbol("Currency Code"),
                    "Unit Price", "Unit of Measure")
            else
                "Price description" := StrSubstNo(
                    PriceDescriptionWithLineDiscountTxt, Quantity, localCurrency.ResolveGLCurrencySymbol("Currency Code"),
                    "Unit Price", "Unit of Measure", "Line Discount %")

    end;

    local procedure UpdateVATPercent(BaseAmount: Decimal; VATAmount: Decimal)
    begin
        if BaseAmount <> 0 then
            "VAT %" := Round(100 * VATAmount / BaseAmount, 0.00001)
        else
            "VAT %" := 0;
    end;

    local procedure InitHeaderDefaults(RentalHeader: Record "TWE Rental Header")
    begin
        if RentalHeader."Document Type" = RentalHeader."Document Type"::Quote then begin
            if (RentalHeader."Rented-to Customer No." = '') and
               (RentalHeader."Rented-to Cust. Templ Code" = '')
            then
                Error(
                  Text031Lbl,
                  RentalHeader.FieldCaption("Rented-to Customer No."),
                  RentalHeader.FieldCaption("Rented-to Cust. Templ Code"));
            if (RentalHeader."Bill-to Customer No." = '') and
               (RentalHeader."Bill-to Customer Template Code" = '')
            then
                Error(
                  Text031Lbl,
                  RentalHeader.FieldCaption("Bill-to Customer No."),
                  RentalHeader.FieldCaption("Bill-to Customer Template Code"));
        end else
            RentalHeader.TestField("Rented-to Customer No.");

        "Rented-to Customer No." := RentalHeader."Rented-to Customer No.";
        "Currency Code" := RentalHeader."Currency Code";
        if not IsNonInventoriableMainRentalItem() then
            "Location Code" := RentalHeader."Location Code";
        "Customer Price Group" := RentalHeader."Customer Price Group";
        "Customer Disc. Group" := RentalHeader."Customer Disc. Group";
        "Allow Line Disc." := RentalHeader."Allow Line Disc.";
        "Bill-to Customer No." := RentalHeader."Bill-to Customer No.";
        "Price Calculation Method" := RentalHeader."Price Calculation Method";
        "Gen. Bus. Posting Group" := RentalHeader."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := RentalHeader."VAT Bus. Posting Group";
        "Exit Point" := RentalHeader."Exit Point";
        Area := RentalHeader.Area;
        "Tax Area Code" := RentalHeader."Tax Area Code";
        "Tax Liable" := RentalHeader."Tax Liable";
        if not "System-Created Entry" and ("Document Type" = "Document Type"::Contract) and HasTypeToFillMandatoryFields() or
           IsServiceChargeLine()
        then
            "Prepayment %" := RentalHeader."Prepayment %";
        "Prepayment Tax Area Code" := RentalHeader."Tax Area Code";
        "Prepayment Tax Liable" := RentalHeader."Tax Liable";
        "Responsibility Center" := RentalHeader."Responsibility Center";

        "Shipping Agent Code" := RentalHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := RentalHeader."Shipping Agent Service Code";
        "Outbound Whse. Handling Time" := RentalHeader."Outbound Whse. Handling Time";
        "Shipping Time" := RentalHeader."Shipping Time";

        OnAfterInitHeaderDefaults(Rec, RentalHeader, xRec);
    end;

    /* local procedure InitDeferralCode()
    var
    //  MainRentalItem: Record "TWE Main Rental Item";
    begin
        if "Document Type" in
           ["Document Type"::Contract, "Document Type"::Invoice, "Document Type"::"Credit Memo", "Document Type"::"Return Shipment"]
        then
            case Type of
                Type::"G/L Account":
                    Validate("Deferral Code", GLAcc."Default Deferral Template Code");
                Type::"Rental Item":
                    begin
                        //GetMainRentalItem(MainRentalItem);
                        // Validate("Deferral Code", MainRentalItem."Default Deferral Template Code");
                    end;
                Type::Resource:
                    Validate("Deferral Code", Res."Default Deferral Template Code");
            end;
    end; */

    /// <summary>
    /// DefaultDeferralCode.
    /// </summary>
    procedure DefaultDeferralCode()
    var
        MainRentalItem: Record "TWE Main Rental Item";
    begin
        case Type of
            Type::"G/L Account":
                // begin
                GLAcc.Get("No.");
            //InitDeferralCode();
            //end;
            Type::"Rental Item":
                // begin
                GetMainRentalItem(MainRentalItem);
            // InitDeferralCode();
            //  end;
            Type::Resource:
                //  begin
                Res.Get("No.");
        //  InitDeferralCode();
        // end;
        end;
    end;

    /// <summary>
    /// IsCreditDocType.
    /// </summary>
    /// <returns>Return variable CreditDocType of type Boolean.</returns>
    procedure IsCreditDocType() CreditDocType: Boolean
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Shipment", "Document Type"::"Credit Memo"];
        OnAfterIsCreditDocType(Rec, CreditDocType);
    end;

    local procedure IsFullyInvoiced(): Boolean
    begin
        exit(("Qty. Shipped Not Invd. (Base)" = 0) and ("Qty. Shipped (Base)" = "Quantity (Base)"))
    end;

    local procedure CleanDropShipmentFields()
    begin
        if ("Purch. Order Line No." <> 0) and IsFullyInvoiced() then
            if CleanPurchaseLineDropShipmentFields() then begin
                "Purchase Order No." := '';
                "Purch. Order Line No." := 0;
            end;
    end;

    local procedure CleanSpecialOrderFieldsAndCheckAssocPurchOrder()
    begin
        OnBeforeCleanSpecialOrderFieldsAndCheckAssocPurchOrder(Rec);

        if ("Special Order Purch. Line No." <> 0) and IsFullyInvoiced() then
            if CleanPurchaseLineSpecialOrderFields() then begin
                "Special Order Purchase No." := '';
                "Special Order Purch. Line No." := 0;
            end;

        CheckAssocPurchOrder('');
    end;

    local procedure CleanPurchaseLineDropShipmentFields(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, "Purchase Order No.", "Purch. Order Line No.") then begin
            if PurchaseLine."Qty. Received (Base)" < "Qty. Shipped (Base)" then
                exit(false);

            PurchaseLine."Sales Order No." := '';
            PurchaseLine."Sales Order Line No." := 0;
            PurchaseLine.Modify();
        end;

        exit(true);
    end;

    local procedure CleanPurchaseLineSpecialOrderFields() Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCleanPurchaseLineSpecialOrderFields(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, "Special Order Purchase No.", "Special Order Purch. Line No.") then begin
            if PurchaseLine."Qty. Received (Base)" < "Qty. Shipped (Base)" then
                exit(false);

            PurchaseLine."Special Order" := false;
            PurchaseLine."Special Order Sales No." := '';
            PurchaseLine."Special Order Sales Line No." := 0;
            PurchaseLine.Modify();
        end;

        exit(true);
    end;

    /// <summary>
    /// CanEditUnitOfMeasureCode.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure CanEditUnitOfMeasureCode(): Boolean
    var
        RentalItemUnitOfMeasure: Record "TWE Rental Item Unit Of Meas.";
    begin
        if (Type = Type::"Rental Item") and ("No." <> '') then begin
            RentalItemUnitOfMeasure.SetRange("Item No.", "No.");
            exit(RentalItemUnitOfMeasure.Count > 1);
        end;
        exit(true);
    end;

    local procedure ValidateTaxGroupCode()
    var
        TaxDetail: Record "Tax Detail";
    begin
        if ("Tax Area Code" <> '') and ("Tax Group Code" <> '') then
            TaxDetail.ValidateTaxSetup("Tax Area Code", "Tax Group Code", "Posting Date");
    end;

    /// <summary>
    /// InsertFreightLine.
    /// </summary>
    /// <param name="FreightAmount">VAR Decimal.</param>
    procedure InsertFreightLine(var FreightAmount: Decimal)
    var
        TWERentalLine: Record "TWE Rental Line";
        FreightAmountQuantity: Integer;
    begin
        if FreightAmount <= 0 then begin
            FreightAmount := 0;
            exit;
        end;

        FreightAmountQuantity := 1;

        RentalSetup.Get();

        TestField("Document No.");

        TWERentalLine.SetRange("Document Type", "Document Type");
        TWERentalLine.SetRange("Document No.", "Document No.");
        TWERentalLine.SetRange(Type, TWERentalLine.Type::"G/L Account");
        // "Quantity Shipped" will be equal to 0 until FreightAmount line successfully shipped
        TWERentalLine.SetRange("Quantity Shipped", 0);
        if TWERentalLine.FindFirst() then begin
            TWERentalLine.Validate(Quantity, FreightAmountQuantity);
            TWERentalLine.Validate("Unit Price", FreightAmount);
            TWERentalLine.Modify();
        end else begin
            TWERentalLine.SetRange(Type);
            TWERentalLine.SetRange("No.");
            TWERentalLine.SetRange("Quantity Shipped");
            TWERentalLine.FindLast();
            TWERentalLine."Line No." += 10000;
            TWERentalLine.Init();
            TWERentalLine.Validate(Type, TWERentalLine.Type::"G/L Account");
            TWERentalLine.Validate(Description, FreightLineDescriptionTxt);
            TWERentalLine.Validate(Quantity, FreightAmountQuantity);
            TWERentalLine.Validate("Unit Price", FreightAmount);
            TWERentalLine.Insert();
        end;
    end;

    local procedure CalcTotalAmtToAssign(TotalQtyToAssign: Decimal) TotalAmtToAssign: Decimal
    begin
        TotalAmtToAssign := CalcLineAmount() * TotalQtyToAssign / Quantity;
        if RentalHeader."Prices Including VAT" then
            TotalAmtToAssign := TotalAmtToAssign / (1 + "VAT %" / 100) - "VAT Difference";

        TotalAmtToAssign := Round(TotalAmtToAssign, Currency."Amount Rounding Precision");
    end;

    /// <summary>
    /// IsLookupRequested.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsLookupRequested() Result: Boolean
    begin
        Result := LookupRequested;
        LookupRequested := false;
    end;

    /// <summary>
    /// TestMainRentalItemFields.
    /// </summary>
    /// <param name="MainRentalItemNo">Code[20].</param>
    /// <param name="VariantCode">Code[10].</param>
    /// <param name="LocationCode">Code[10].</param>
    procedure TestMainRentalItemFields(MainRentalItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::"Rental Item");
        TestField("No.", MainRentalItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    /// <summary>
    /// CalculateNotShippedInvExlcVatLCY.
    /// </summary>
    procedure CalculateNotShippedInvExlcVatLCY()
    var
        Currency2: Record Currency;
    begin
        Currency2.InitRoundingPrecision();
        "Shipped Not Inv. (LCY) No VAT" :=
          Round("Shipped Not Invoiced (LCY)" / (1 + "VAT %" / 100), Currency2."Amount Rounding Precision");
    end;

    /// <summary>
    /// ClearRentalHeader.
    /// </summary>
    procedure ClearRentalHeader()
    begin
        Clear(RentalHeader);
    end;

    local procedure GetBlockedMainRentalItemNotificationID(): Guid
    begin
        exit('963A9FD3-11E8-4CAA-BE3A-7F8CEC9EF8EC');
    end;

    local procedure SendBlockedMainRentalItemNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetBlockedMainRentalItemNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message := StrSubstNo(BlockedMainRentalItemNotificationMsg, "No.");
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
    end;

    /// <summary>
    /// SendLineInvoiceDiscountResetNotification.
    /// </summary>
    procedure SendLineInvoiceDiscountResetNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        if ("Inv. Discount Amount" = 0) and (xRec."Inv. Discount Amount" <> 0) and ("Line Amount" <> 0) then begin
            NotificationToSend.Id := RentalHeader.GetLineInvoiceDiscountResetNotificationId();
            NotificationToSend.Message := StrSubstNo(LineInvoiceDiscountAmountResetTok, RecordId);

            NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
        end;
    end;

    /// <summary>
    /// GetDocumentTypeDescription.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetDocumentTypeDescription(): Text
    begin
        exit(Format("Document Type"));
    end;

    /// <summary>
    /// FormatType.
    /// </summary>
    /// <returns>Return variable FormattedType of type Text[20].</returns>
    procedure FormatType() FormattedType: Text[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatType(Rec, FormattedType, IsHandled);
        if IsHandled then
            EXIT(FormattedType);

        if Type = Type::" " then
            exit(CommentLbl);

        exit(Format(Type));
    end;

    /// <summary>
    /// RenameNo.
    /// </summary>
    /// <param name="LineType">Enum "Sales Line Type".</param>
    /// <param name="OldNo">Code[20].</param>
    /// <param name="NewNo">Code[20].</param>
    procedure RenameNo(LineType: Enum "Sales Line Type"; OldNo: Code[20];
                                     NewNo: Code[20])
    begin
        Reset();
        SetRange(Type, LineType);
        SetRange("No.", OldNo);
        ModifyAll("No.", NewNo, true);
    end;

    local procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineDiscPct(Rec, IsHandled, Currency);
        if IsHandled then
            exit;

        if Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") <> 0 then begin
            if Type <> "TWE Rental Line Type"::"Rental Item" then begin
                LineDiscountPct := Round(
                    "Line Discount Amount" / Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") * 100,
                    0.00001);
                if not (LineDiscountPct in [0 .. 100]) then
                    Error(LineDiscountPctErr);
            end else begin
                LineDiscountPct := Round(
                    "Line Discount Amount" / Round(Quantity * "Unit Price" * "Total Days to Invoice", Currency."Amount Rounding Precision") * 100,
                    0.00001);
                if not (LineDiscountPct in [0 .. 100]) then
                    Error(LineDiscountPctErr);
            end;
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;

        OnAfterUpdateLineDiscPct(Rec);
    end;

    local procedure UpdateBaseAmounts(NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
        Amount := NewAmount;
        "Amount Including VAT" := NewAmountIncludingVAT;
        "VAT Base Amount" := NewVATBaseAmount;
        if not RentalHeader."Prices Including VAT" and (Amount > 0) and (Amount < "Prepmt. Line Amount") then
            "Prepmt. Line Amount" := Amount;
        if RentalHeader."Prices Including VAT" and ("Amount Including VAT" > 0) and ("Amount Including VAT" < "Prepmt. Line Amount") then
            "Prepmt. Line Amount" := "Amount Including VAT";
        if ("Prepmt. Line Amount" < "Prepmt. Amt. Inv.") and ("Inv. Discount Amount" <> 0) then
            Error(InvDiscForPrepmtExceededErr, "Document No.");

        OnAfterUpdateBaseAmounts(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// CalcPlannedDate.
    /// </summary>
    /// <returns>Return value of type Date.</returns>
    procedure CalcPlannedDate(): Date
    begin
        if Format("Shipping Time") <> '' then
            exit(CalcPlannedDeliveryDate(FieldNo("Planned Delivery Date")));

        exit(CalcPlannedShptDate(FieldNo("Planned Delivery Date")));
    end;

    local procedure IsCalcVATAmountLinesHandled(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping) IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(RentalHeader, TWERentalLine, VATAmountLine, IsHandled, QtyType);
        exit(IsHandled);
    end;

    local procedure ValidateUnitCostLCYOnGetUnitCost(MainRentalItem: Record "TWE Main Rental Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateUnitCostLCYOnGetUnitCost(IsHandled);
        if IsHandled then
            exit;

        if GetSKU() then
            Validate("Unit Cost (LCY)", SKU."Unit Cost" * "Qty. per Unit of Measure")
        else
            Validate("Unit Cost (LCY)", MainRentalItem."Unit Cost" * "Qty. per Unit of Measure");
    end;

    local procedure AssignResourceUoM()
    var
        ResUnitofMeasure: Record "Resource Unit of Measure";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignResourceUoM(ResUnitofMeasure, IsHandled);
        if IsHandled then
            exit;

        ResUnitofMeasure.Get("No.", "Unit of Measure Code");
        "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";

        OnAfterAssignResourceUOM(Rec, Resource, ResUnitofMeasure);
    end;

    local procedure CheckPromisedDeliveryDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPromisedDeliveryDate(RentalHeader, IsHandled);
        if IsHandled then
            exit;

        if ("Requested Delivery Date" <> xRec."Requested Delivery Date") and ("Promised Delivery Date" <> 0D) then
            Error(Text028Lbl, FieldCaption("Requested Delivery Date"), FieldCaption("Promised Delivery Date"));
    end;

    local procedure VerifyChangeForTWERentalLineReserve(CallingFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChangeForTWERentalLineReserve(Rec, xRec, CallingFieldNo, IsHandled);
        if IsHandled then
            exit;
    end;

    local procedure CheckInventoryPickConflict()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInventoryPickConflict(Rec, IsHandled);
        if IsHandled then
            exit;

        if RentalHeader.InventoryPickConflict("Document Type", "Document No.", RentalHeader."Shipping Advice") then
            Error(Text056Lbl, RentalHeader."Shipping Advice");
    end;

    local procedure CheckQuantitySign()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQuantitySign(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType() then begin
            if Quantity > 0 then
                FieldError(Quantity, Text030Lbl);
        end else
            if Quantity < 0 then
                FieldError(Quantity, Text029Lbl);
    end;

    local procedure GetRentalHeader(var tweRentalHeader: Record "TWE Rental Header")
    var
        localTWERentalHeader: Record "TWE Rental Header";
    begin
        localTWERentalHeader.SetRange("Document Type", Rec."Document Type");
        localTWERentalHeader.SetRange("No.", Rec."Document No.");
        if localTWERentalHeader.FindFirst() then
            tweRentalHeader := localTWERentalHeader;
    end;

    local procedure SetDataFromRentalHeader()
    var
        localTWERentalHeader: Record "TWE Rental Header";
        BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
        localTotalQtyDays: Decimal;
        localQtyDaysInvoice: Decimal;
        ErrorTextRentalHeaderCheck: Text;
    begin
        ErrorTextRentalHeaderCheck := BusinessRentalMgt.CheckRentalHeaderBeforeLineIsInserted(Rec);
        if ErrorTextRentalHeaderCheck <> '' then
            Error(ErrorTextRentalHeaderCheck);

        if (Rec."Rental Item" = xRec."Rental Item") or (Rec."Rental Item" = '') then
            exit;
        GetRentalHeader(localTWERentalHeader);
        if (Rec."Rental Rate Code" = '') or (Rec."Rental Rate Code" <> xRec."Rental Rate Code") then
            if localTWERentalHeader."Rental Rate Code" <> Rec."Rental Rate Code" then
                Rec."Rental Rate Code" := localTWERentalHeader."Rental Rate Code";

        if (Rec."Invoicing Period" = '') or (Rec."Invoicing Period" <> xRec."Invoicing Period") then
            if localTWERentalHeader."Invoicing Period" <> Rec."Invoicing Period" then
                Rec."Invoicing Period" := localTWERentalHeader."Invoicing Period";

        BusinessRentalMgt.CalculateNextInvoiceDates(Rec);

        localTotalQtyDays := BusinessRentalMgt.CalculateTotalDaysToInvoice(Rec."Rental Rate Code", localTWERentalHeader."Rental Start", localTWERentalHeader."Rental End");
        Rec."Total Days to Invoice" := localTotalQtyDays;


        localQtyDaysInvoice := BusinessRentalMgt.CalculateDaysToInvoice(Rec."Rental Rate Code", Rec."Invoicing Period", Rec."Billing Start Date", Rec."Billing End Date");
        Rec."Duration to be billed" := localQtyDaysInvoice;
    end;

    local procedure ShowReturnedUnitsError(var MainRentalItemLedgEntry: Record "Item Ledger Entry"; QtyReturned: Decimal; QtyNotReturned: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReturnedUnitsError(Rec, MainRentalItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        Error(Text039Lbl, -QtyReturned, MainRentalItemLedgEntry.FieldCaption("Document No."), MainRentalItemLedgEntry."Document No.", -QtyNotReturned);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFieldsForNo(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPrice(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line"; CallFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignHeaderValues(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignStdTxtValues(var TWERentalLine: Record "TWE Rental Line"; StandardText: Record "Standard Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var TWERentalLine: Record "TWE Rental Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignMainRentalItemValues(var TWERentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var TWERentalLine: Record "TWE Rental Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceUOM(var TWERentalLine: Record "TWE Rental Line"; Resource: Record Resource; ResourceUOM: Record "Resource Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserve(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMainRentalItemAvailable(var TWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckShipmentRelation(TWERentalLine: Record "TWE Rental Line"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckRetRcptRelation(TWERentalLine: Record "TWE Rental Line"; ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromMainRentalItem(var TWERentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTWERentalLine(var TWERentalLine: Record "TWE Rental Line"; FromTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithMainRentalItemToPlan(var TWERentalLine: Record "TWE Rental Line"; var MainRentalItem: Record "TWE Main Rental Item"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetMainRentalItemTranslation(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; MainRentalItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRentalHeader(var TWERentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var TWERentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasTypeToFillMandatoryFields(var TWERentalLine: Record "TWE Rental Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToAsm(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRentalSetup(var TWERentalLine: Record "TWE Rental Line"; var RentalSetup: Record "TWE Rental Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCreditDocType(TWERentalLine: Record "TWE Rental Line"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowNonStock(var TWERentalLine: Record "TWE Rental Line"; NonstockMainRentalItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLineDiscPct(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePrePaymentAmounts(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscToInvoice(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPlannedShptDate(var TWERentalLine: Record "TWE Rental Line"; var PlannedShipmentDate: Date; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPrepmtToDeduct(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallMainRentalItemTracking(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssocPurchOrder(var TWERentalLine: Record "TWE Rental Line"; TheFieldCaption: Text[250]; var IsHandled: Boolean; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAsmToOrder(var TWERentalLine: Record "TWE Rental Line"; AsmHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeRelation(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMainRentalItemAvailable(var TWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCleanSpecialOrderFieldsAndCheckAssocPurchOrder(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCleanPurchaseLineSpecialOrderFields(TWERentalLine: Record "TWE Rental Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromMainRentalItem(var TWERentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNoByDescription(TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; var CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatType(TWERentalLine: Record "TWE Rental Line"; var FormattedType: Text[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMainRentalItemTranslation(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRentalHeader(var TWERentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header"; var IsHanded: Boolean; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnitCost(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingAmount(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQty(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; IsAsmToOrderAlwd: Boolean; IsAsmToOrderRqd: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToAsm(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsAsmToOrderRequired(TWERentalLine: Record "TWE Rental Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoice(TWERentalLine: Record "TWE Rental Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoiceBase(TWERentalLine: Record "TWE Rental Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultMainRentalItemQuantity(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRentalHeader(RentalHeader: record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSignedXX(var TWERentalLine: Record "TWE Rental Line"; var Value: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMainRentalItemSub(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservationEntries(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var TWERentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQtyFromLindDiscountAmount(var TWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDates(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmounts(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtSetupFields(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLineDiscPct(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPrice(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATAmounts(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATOnLines(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean; QtyType: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseShip(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQuantityFromUOMCode(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReasonCode(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeZeroAmountLine(var TWERentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitHeaderDefaults(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstanding(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var TWERentalLine: Record "TWE Rental Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var TWERentalLine: Record "TWE Rental Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip2(var TWERentalLine: Record "TWE Rental Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitType(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var TWERentalLine: Record "TWE Rental Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmountToInvoice(var TWERentalLine: Record "TWE Rental Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(var RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineAmountToHandle(TWERentalLine: Record "TWE Rental Line"; QtyToHandle: Decimal; var LineAmount: Decimal; var LineDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "TWE Rent Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(TWERentalLine: Record "TWE Rental Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalTaxCalculate(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRentalTaxCalculateReverse(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReserveWithoutPurchasingCode(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmounts(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsDone(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBaseAmounts(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDates(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATAmounts(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(var RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWithWarehouseShip(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowMainRentalItemSub(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateReturnReasonCode(var TWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToShip2OnBeforeCalcInvDiscToInvoice(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowMainRentalItemChargeAssgntOnBeforeCalcMainRentalItemCharge(var TWERentalLine: Record "TWE Rental Line"; var MainRentalItemChargeAssgntLineAmt: Decimal; Currency: Record Currency; var IsHandled: Boolean; var MainRentalItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceByFieldOnAfterFindPrice(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceOnBeforeFindPrice(RentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeSetShipmentDate(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnAfterCheckMainRentalItem(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnCopyFromTempTWERentalLine(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterInitHeaderDefaults(var RentalHeader: Record "TWE Rental Header"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterUpdateUnitPrice(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterVerifyChange(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnCopyFromTempTWERentalLine(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitRec(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateNoOnBeforeCalcShipmentDateForLocation(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeUpdateDates(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; CallingFieldNo: Integer; var IsHandled: Boolean; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcBaseQty(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetUnitCost(var TWERentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeResetAmounts(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipAfterInitQty(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipOnAfterCheck(var TWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterChecks(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(var TWERentalLine: Record "TWE Rental Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeUpdateUnitPrice(var TWERentalLine: Record "TWE Rental Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var TWERentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultQuantity(var TWERentalLine: Record "TWE Rental Line"; var xTWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalAmounts(var TWERentalLine: Record "TWE Rental Line"; TWERentalLine2: Record "TWE Rental Line"; var TotalAmount: Decimal; var TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnBeforeShowDialog(var TWERentalLine: Record "TWE Rental Line"; Location: Record Location; ShowDialog: Option " ",Message,Error; var DialogText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcShipmentDateOnPlannedShipmentDate(TWERentalLine: Record "TWE Rental Line"; var ShipmentDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromMainRentalItemOnAfterCheck(var TWERentalLine: Record "TWE Rental Line"; MainRentalItem: Record "TWE Main Rental Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourceOnBeforeTestBlocked(var Resoiurce: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDeferralPostDate(RentalHeader: Record "TWE Rental Header"; var DeferralPostingDate: Date; TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoAsmToOrder(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoAsmToOrder(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPlannedDeliveryDate(var TWERentalLine: Record "TWE Rental Line"; var PlannedDeliveryDate: Date; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenMainRentalItemTrackingLines(TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditLimitCondition(TWERentalLine: Record "TWE Rental Line"; var RunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMainRentalItemChargeAssgnt(var TWERentalLine: Record "TWE Rental Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDescription(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePlannedDeliveryDate(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePlannedShipmentDate(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmountOnBeforeCheckCreditLimit(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateAmountsOnBeforeCheckLineAmount(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalculateNewAmount(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; VATAmountLine: Record "VAT Amount Line"; VATAmountLineReminder: Record "VAT Amount Line"; var NewAmount: Decimal; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateAmounts(var TWERentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateNewAmount(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; VATAmountLine: Record "VAT Amount Line"; VATAmountLineReminder: Record "VAT Amount Line"; var NewAmountIncludingVAT: Decimal; VATAmount: Decimal; var NewAmount: Decimal; var NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalculateAmounts(var TWERentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(TWERentalLine: Record "TWE Rental Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; VATAmount: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDescriptionOnBeforeCannotFindDescrError(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnAfterSetOutboundWhseHandlingTime(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcLineTotals(var VATAmountLine: Record "VAT Amount Line"; RentalHeader: Record "TWE Rental Header"; TWERentalLine: Record "TWE Rental Line"; Currency: Record Currency; QtyType: Option General,Invoicing,Shipping; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterSetFilters(var TWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSetTWERentalLineFilters(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeTestStatusOpen(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterSetTWERentalLineFilters(var TWERentalLine: Record "TWE Rental Line"; var TWERentalLine2: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeCalcAmounts(var TWERentalLine: Record "TWE Rental Line"; var TWERentalLine2: Record "TWE Rental Line"; var TotalAmount: Decimal; TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal; var TotalVATBaseAmount: Decimal; var TotalQuantityBase: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectMainRentalItemEntryOnAfterSetFilters(var MainRentalItemLedgEntry: Record "Item Ledger Entry"; TWERentalLine: Record "TWE Rental Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountIncludingVATOnAfterAssignAmounts(var TWERentalLine: Record "TWE Rental Line"; Currency: Record Currency);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineAmountOnbeforeTestUnitPrice(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePrepaymentPercentageOnBeforeUpdatePrepmtSetupFields(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckReceiptOrderStatus(var TWERentalLine: Record "TWE Rental Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeTWERentalLineVerifyChange(var TWERentalLine: Record "TWE Rental Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeValidateQtyToAssembleToOrder(var TWERentalLine: Record "TWE Rental Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterAssignPurchasingFields(var TWERentalLine: Record "TWE Rental Line"; PurchasingCode: Record Purchasing; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeUpdateAmounts(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateDim(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateUnitCostLCYOnGetUnitCost(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateWorkTypeCode(xTWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateShipmentDate(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAssignResourceUoM(var ResUnitofMeasure: Record "Resource Unit of Measure"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPromisedDeliveryDate(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckShipmentRelation(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRetRcptRelation(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToShipOnBeforeCheckServMainRentalItemCreation(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChangeForTWERentalLineReserve(var TWERentalLine: Record "TWE Rental Line"; xTWERentalLine: Record "TWE Rental Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInventoryPickConflict(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckApplFromMainRentalItemLedgEntryOnBeforeTestFieldType(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQuantitySign(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReturnedUnitsError(var TWERentalLine: Record "TWE Rental Line"; var MainRentalItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateLineDiscountPercent(var TWERentalLine: Record "TWE Rental Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineDiscountPercentOnBeforeUpdateAmounts(var TWERentalLine: Record "TWE Rental Line"; CurrFieldNo: Integer)
    begin
    end;
}
