/// <summary>
/// Table TWE Rental Header (ID 707064610).
/// </summary>
table 50008 "TWE Rental Header"
{
    Caption = 'TWE Rental Header';
    DataCaptionFields = "No.", "Rented-to Customer Name";
    LookupPageID = "TWE Rental List";
    Permissions = tabledata "Assemble-to-Order Link" = rmid;

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
            TableRelation = Customer;

            trigger OnValidate()
            var
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
                IsHandled: Boolean;
            begin
                CheckCreditLimitIfLineNotInsertedYet;
                if "No." = '' then
                    InitRecord;
                TestStatusOpen;
                if ("Rented-to Customer No." <> xRec."Rented-to Customer No.") and
                   (xRec."Rented-to Customer No." <> '')
                then begin
                    if ("Opportunity No." <> '') and ("Document Type" in ["Document Type"::Quote, "Document Type"::Contract]) then
                        Error(
                          Text062Lbl,
                          FieldCaption("Rented-to Customer No."),
                          FieldCaption("Opportunity No."),
                          "Opportunity No.",
                          "Document Type");
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, SellToCustomerTxt);
                    if Confirmed then begin
                        RentalLine.SetRange("Document Type", "Document Type");
                        RentalLine.SetRange("Document No.", "No.");
                        if "Rented-to Customer No." = '' then begin
                            if RentalLine.FindFirst() then
                                Error(
                                  Text005Lbl,
                                  FieldCaption("Rented-to Customer No."));
                            Init;
                            OnValidateSellToCustomerNoAfterInit(Rec, xRec);
                            GetRentalSetup;
                            "No. Series" := xRec."No. Series";
                            InitRecord;
                            InitNoSeries;
                            exit;
                        end;

                        CheckShipmentInfo(RentalLine, false);
                        //CheckPrepmtInfo(RentalLine);
                        CheckReturnInfo(RentalLine, false);

                        RentalLine.Reset();
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Document Type" = "Document Type"::Contract) and
                   (xRec."Rented-to Customer No." <> "Rented-to Customer No.")
                then begin
                    RentalLine.SetRange("Document Type", RentalLine."Document Type"::Contract);
                    RentalLine.SetRange("Document No.", "No.");
                    RentalLine.SetFilter("Purch. Order Line No.", '<>0');
                    if not RentalLine.IsEmpty then
                        Error(
                          Text006Lbl,
                          FieldCaption("Rented-to Customer No."));
                    RentalLine.Reset();
                end;

                GetCust("Rented-to Customer No.");
                IsHandled := false;
                OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, Cust, IsHandled);
                if not IsHandled then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                if not ApplicationAreaMgmt.IsSalesTaxEnabled then
                    Cust.TestField("Gen. Bus. Posting Group");
                //OnAfterCheckSellToCust(Rec, xRec, Cust, CurrFieldNo);

                CopySellToCustomerAddressFieldsFromCustomer(Cust);

                if "Rented-to Customer No." = xRec."Rented-to Customer No." then
                    if ShippedTWERentalLinesExist or ReturnReceiptExist then begin
                        TestField("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                        TestField("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                    end;

                "Rented-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Rented-to IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                Validate("Ship-to Code", Cust."Ship-to Code");
                SetBillToCustomerNo(Cust);

                GetShippingTime(FieldNo("Rented-to Customer No."));

                if (xRec."Rented-to Customer No." <> "Rented-to Customer No.") or
                   (xRec."Currency Code" <> "Currency Code") or
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") or
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                then
                    RecreateTWERentalLines(SellToCustomerTxt);

                if not SkipSellToContact then
                    UpdateSellToCont("Rented-to Customer No.");

                OnValidateSellToCustomerNoOnBeforeRecallModifyAddressNotification(Rec);
                if (xRec."Rented-to Customer No." <> '') and (xRec."Rented-to Customer No." <> "Rented-to Customer No.") then
                    RecallModifyAddressNotification(GetModifyCustomerAddressNotificationId);
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetRentalSetup;
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen;
                BilltoCustomerNoChanged := xRec."Bill-to Customer No." <> "Bill-to Customer No.";
                if BilltoCustomerNoChanged then
                    if xRec."Bill-to Customer No." = '' then
                        InitRecord
                    else begin
                        if GetHideValidationDialog or not GuiAllowed then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, BillToCustomerTxt);
                        if Confirmed then begin
                            OnValidateBillToCustomerNoOnAfterConfirmed(Rec);

                            RentalLine.SetRange("Document Type", "Document Type");
                            RentalLine.SetRange("Document No.", "No.");

                            CheckShipmentInfo(RentalLine, true);
                            CheckPrepmtInfo(RentalLine);
                            CheckReturnInfo(RentalLine, true);

                            RentalLine.Reset();
                        end else
                            "Bill-to Customer No." := xRec."Bill-to Customer No.";
                    end;

                GetCust("Bill-to Customer No.");
                IsHandled := false;
                OnValidateBillToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, Cust, IsHandled);
                if not IsHandled then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                Cust.TestField("Customer Posting Group");
                PostingSetupMgt.CheckCustPostingGroupReceivablesAccount("Customer Posting Group");
                CheckCreditLimit;
                OnAfterCheckBillToCust(Rec, xRec, Cust);

                SetBillToCustomerAddressFieldsFromCustomer(Cust);

                if not BilltoCustomerNoChanged then
                    if ShippedTWERentalLinesExist then begin
                        TestField("Customer Disc. Group", xRec."Customer Disc. Group");
                        TestField("Currency Code", xRec."Currency Code");
                    end;

                CreateDim(
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");

                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");
                Validate("Payment Method Code");
                Validate("Currency Code");
                Validate("Prepayment %");

                if (xRec."Rented-to Customer No." = "Rented-to Customer No.") and
                   (xRec."Bill-to Customer No." <> "Bill-to Customer No.")
                then begin
                    RecreateTWERentalLines(BillToCustomerTxt);
                    BilltoCustomerNoChanged := false;
                end;
                if not SkipBillToContact then
                    UpdateBillToCont("Bill-to Customer No.");

                "Bill-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Bill-to IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                OnValidateBillToCustomerNoOnBeforeRecallModifyAddressNotification(Rec);
                if (xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> "Bill-to Customer No.") then
                    RecallModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId);
            end;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            DataClassification = CustomerContent;
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Customer: Record Customer;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToName(Rec, Customer, IsHandled);
                if IsHandled then
                    exit;

                if "Bill-to Customer No." <> '' then
                    Customer.Get("Bill-to Customer No.");

                //if Customer.LookupCustomer(Customer) then begin
                //   xRec := Rec;
                //   "Bill-to Name" := Customer.Name;
                //   Validate("Bill-to Customer No.", Customer."No.");
                // end;
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                OnBeforeValidateBillToCustomerName(Rec, Customer);

                if ShouldSearchForCustomerByName("Bill-to Customer No.") then
                    Validate("Bill-to Customer No.", Customer.GetCustNo("Bill-to Name"));
            end;
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            DataClassification = CustomerContent;
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            DataClassification = CustomerContent;
            TableRelation = IF ("Bill-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Bill-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Bill-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyBillToCustomerAddress;
            end;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                Contact.FilterGroup(2);
                LookupContact("Bill-to Customer No.", "Bill-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Bill-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = CustomerContent;
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            DataClassification = CustomerContent;
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Rented-to Customer No."));

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToCode(Rec, xRec, Cust, ShipToAddr, IsHandled);
                if IsHandled then
                    exit;

                if ("Document Type" = "Document Type"::Contract) and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then begin
                    RentalLine.SetRange("Document Type", RentalLine."Document Type"::Contract);
                    RentalLine.SetRange("Document No.", "No.");
                    RentalLine.SetFilter("Purch. Order Line No.", '<>0');
                    if not RentalLine.IsEmpty then
                        Error(
                          Text006Lbl,
                          FieldCaption("Ship-to Code"));
                    RentalLine.Reset();
                end;

                if not IsCreditDocType then
                    if "Ship-to Code" <> '' then begin
                        if xRec."Ship-to Code" <> '' then begin
                            GetCust("Rented-to Customer No.");
                            if Cust."Location Code" <> '' then
                                Validate("Location Code", Cust."Location Code");
                            "Tax Area Code" := Cust."Tax Area Code";
                        end;
                        ShipToAddr.Get("Rented-to Customer No.", "Ship-to Code");
                        SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr);
                    end else
                        if "Rented-to Customer No." <> '' then begin
                            GetCust("Rented-to Customer No.");
                            CopyShipToCustomerAddressFieldsFromCust(Cust);
                        end;

                GetShippingTime(FieldNo("Ship-to Code"));

                if (xRec."Rented-to Customer No." = "Rented-to Customer No.") and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then
                    if (xRec."VAT Country/Region Code" <> "VAT Country/Region Code") or
                       (xRec."Tax Area Code" <> "Tax Area Code")
                    then
                        RecreateTWERentalLines(FieldCaption("Ship-to Code"))
                    else begin
                        if xRec."Shipping Agent Code" <> "Shipping Agent Code" then
                            MessageIfTWERentalLinesExist(FieldCaption("Shipping Agent Code"));
                        if xRec."Shipping Agent Service Code" <> "Shipping Agent Service Code" then
                            MessageIfTWERentalLinesExist(FieldCaption("Shipping Agent Service Code"));
                        OnValidateShipToCodeOnBeforeValidateTaxLiable(Rec, xRec);
                        if xRec."Tax Liable" <> "Tax Liable" then
                            Validate("Tax Liable");
                    end;
            end;
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            DataClassification = CustomerContent;
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            DataClassification = CustomerContent;
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            DataClassification = CustomerContent;
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            DataClassification = CustomerContent;
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            DataClassification = CustomerContent;
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            DataClassification = CustomerContent;
        }
        field(19; "Order Date"; Date)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Document Type" in ["Document Type"::Quote, "Document Type"::Contract]) and
                   not ("Order Date" = xRec."Order Date")
                then
                    PriceMessageIfTWERentalLinesExist(FieldCaption("Order Date"));
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestField("Posting Date");
                TestNoSeriesDate(
                  "Posting No.", "Posting No. Series",
                  FieldCaption("Posting No."), FieldCaption("Posting No. Series"));
                TestNoSeriesDate(
                  "Prepayment No.", "Prepayment No. Series",
                  FieldCaption("Prepayment No."), FieldCaption("Prepayment No. Series"));

                IsHandled := false;
                OnValidatePostingDateOnBeforeAssignDocumentDate(Rec, IsHandled);
                if not IsHandled then
                    if "Incoming Document Entry No." = 0 then
                        Validate("Document Date", "Posting Date");

                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                   not ("Posting Date" = xRec."Posting Date")
                then
                    PriceMessageIfTWERentalLinesExist(FieldCaption("Posting Date"));

                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor;
                    if "Currency Factor" <> xRec."Currency Factor" then
                        ConfirmCurrencyFactorUpdate();
                end;

                if "Posting Date" <> xRec."Posting Date" then
                    if DeferralHeadersExist then
                        ConfirmUpdateDeferralDate;
                SynchronizeAsmHeader;
            end;
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateTWERentalLinesByFieldNo(FieldNo("Shipment Date"), CurrFieldNo <> 0);
            end;
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            DataClassification = CustomerContent;
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Payment Terms Code");
                    if IsCreditDocType and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeValidateDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            Validate("Due Date", "Document Date");
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end else begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcDueDate(Rec, xRec, FieldNo("Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(Rec, xRec, FieldNo("Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        if not UpdateDocumentDate then
                            Validate("Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    IsHandled := false;
                    OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        Validate("Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end;
                end;
                if xRec."Payment Terms Code" = "Prepmt. Payment Terms Code" then begin
                    if xRec."Prepayment Due Date" = 0D then begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalculatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepayment Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                    end;
                    Validate("Prepmt. Payment Terms Code", "Payment Terms Code");
                end;
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = CustomerContent;
        }
        field(25; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen;
                GLSetup.Get();
                if "Payment Discount %" < GLSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                Validate("VAT Base Discount %");
            end;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            DataClassification = CustomerContent;
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipment Method";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentMethodCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen;
            end;
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Location Code" <> xRec."Location Code") and
                   (xRec."Rented-to Customer No." = "Rented-to Customer No.")
                then
                    MessageIfTWERentalLinesExist(FieldCaption("Location Code"));

                UpdateShipToAddress;
                UpdateOutboundWhseHandlingTime;
            end;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
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
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            var
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date")]) or ("Currency Code" <> xRec."Currency Code") then
                    TestStatusOpen;
                if (CurrFieldNo <> FieldNo("Currency Code")) and ("Currency Code" = xRec."Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then
                        UpdateCurrencyFactor
                    else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmCurrencyFactorUpdate();
                        end;

                // if ("No." <> '') and ("Currency Code" <> xRec."Currency Code") then
                // StandardCodesMgt.CheckShowSalesRecurringLinesNotification(Rec);
            end;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Currency Factor" <> xRec."Currency Factor" then
                    UpdateTWERentalLinesByFieldNo(FieldNo("Currency Factor"), false);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                MessageIfTWERentalLinesExist(FieldCaption("Customer Price Group"));
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                TWERentalLine: Record "TWE Rental Line";
                Currency: Record Currency;
                RecalculatePrice: Boolean;
                VatFactor: Decimal;
                LineInvDiscAmt: Decimal;
                InvDiscRounding: Decimal;
            begin
                TestStatusOpen;

                if "Prices Including VAT" <> xRec."Prices Including VAT" then begin
                    TWERentalLine.Reset();
                    TWERentalLine.SetRange("Document Type", "Document Type");
                    TWERentalLine.SetRange("Document No.", "No.");
                    TWERentalLine.SetFilter("Unit Price", '<>%1', 0);
                    TWERentalLine.SetFilter("VAT %", '<>%1', 0);
                    // if TWERentalLine.FindFirst() then begin
                    //     RecalculatePrice := ConfirmRecalculatePrice(TWERentalLine);
                    //OnAfterConfirmSalesPrice(Rec, TWERentalLine, RecalculatePrice);
                    //  TWERentalLine.SetTWERentalHeader(Rec);

                    if "Currency Code" = '' then
                        Currency.InitRoundingPrecision
                    else
                        Currency.Get("Currency Code");
                    TWERentalLine.LockTable();
                    LockTable();
                    TWERentalLine.FindSet();
                    repeat
                        TWERentalLine.TestField("Quantity Invoiced", 0);
                        TWERentalLine.TestField("Prepmt. Amt. Inv.", 0);
                        if not RecalculatePrice then begin
                            TWERentalLine."VAT Difference" := 0;
                            TWERentalLine.UpdateAmounts;
                        end else begin
                            VatFactor := 1 + TWERentalLine."VAT %" / 100;
                            if VatFactor = 0 then
                                VatFactor := 1;
                            if not "Prices Including VAT" then
                                VatFactor := 1 / VatFactor;
                            if TWERentalLine."VAT Calculation Type" = TWERentalLine."VAT Calculation Type"::"Full VAT" then
                                VatFactor := 1;
                            TWERentalLine."Unit Price" :=
                              Round(TWERentalLine."Unit Price" * VatFactor, Currency."Unit-Amount Rounding Precision");
                            TWERentalLine."Line Discount Amount" :=
                              Round(
                                TWERentalLine.Quantity * TWERentalLine."Unit Price" * TWERentalLine."Line Discount %" / 100,
                                Currency."Amount Rounding Precision");
                            LineInvDiscAmt := InvDiscRounding + TWERentalLine."Inv. Discount Amount" * VatFactor;
                            TWERentalLine."Inv. Discount Amount" := Round(LineInvDiscAmt, Currency."Amount Rounding Precision");
                            InvDiscRounding := LineInvDiscAmt - TWERentalLine."Inv. Discount Amount";
                            if TWERentalLine."VAT Calculation Type" = TWERentalLine."VAT Calculation Type"::"Full VAT" then
                                TWERentalLine."Line Amount" := TWERentalLine."Amount Including VAT"
                            else
                                if "Prices Including VAT" then
                                    TWERentalLine."Line Amount" := TWERentalLine."Amount Including VAT" + TWERentalLine."Inv. Discount Amount"
                                else
                                    TWERentalLine."Line Amount" := TWERentalLine.Amount + TWERentalLine."Inv. Discount Amount";
                        end;
                        OnValidatePricesIncludingVATOnBeforeTWERentalLineModify(Rec, TWERentalLine, Currency, RecalculatePrice);
                        TWERentalLine.Modify();
                    until TWERentalLine.Next() = 0;
                end;
                OnAfterChangePricesIncludingVAT(Rec);
            end;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            AccessByPermission = TableData "Cust. Invoice Disc." = R;
            Caption = 'Invoice Disc. Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfTWERentalLinesExist(FieldCaption("Invoice Disc. Code"));
            end;
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfTWERentalLinesExist(FieldCaption("Customer Disc. Group"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            DataClassification = CustomerContent;
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfTWERentalLinesExist(FieldCaption("Language Code"));
            end;
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            var
                ApprovalEntry: Record "Approval Entry";
                EnumAssignmentMgt: Codeunit "Enum Assignment Management";
            begin
                ValidateSalesPersonOnTWERentalHeader(Rec, false, false);

                ApprovalEntry.SetRange("Table ID", DATABASE::"Sales Header");
                ApprovalEntry.SetRange("Document Type", EnumAssignmentMgt.GetSalesApprovalDocumentType("Document Type"));
                ApprovalEntry.SetRange("Document No.", "No.");
                ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
                if not ApprovalEntry.IsEmpty then
                    Error(Text053Lbl, FieldCaption("Salesperson Code"));

                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");
            end;
        }
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
            DataClassification = CustomerContent;
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE("Document Type" = FIELD("Document Type"),
                                                            "No." = FIELD("No."),
                                                            "Document Line No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
            DataClassification = CustomerContent;
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            DataClassification = CustomerContent;
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                GenJnlLine: Record "Gen. Journal Line";
                GenJnlApply: Codeunit "Gen. Jnl.-Apply";
                ApplyCustEntries: Page "Apply Customer Entries";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, CustLedgEntry, IsHandled);
                if IsHandled then
                    exit;

                TestField("Bal. Account No.", '');
                CustLedgEntry.SetApplyToFilters("Bill-to Customer No.", "Applies-to Doc. Type".AsInteger(), "Applies-to Doc. No.", Amount);
                OnAfterSetApplyToFilters(CustLedgEntry, Rec);

                //  ApplyCustEntries.SetSales(Rec, CustLedgEntry, TWERentalHeader.FieldNo("Applies-to Doc. No."));
                ApplyCustEntries.SetTableView(CustLedgEntry);
                ApplyCustEntries.SetRecord(CustLedgEntry);
                ApplyCustEntries.LookupMode(true);
                if ApplyCustEntries.RunModal = ACTION::LookupOK then begin
                    ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                      "Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                    "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                    OnAfterAppliesToDocNoOnLookup(Rec, CustLedgEntry);
                end;
                Clear(ApplyCustEntries);
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateAppliesToDocNo(Rec, CustLedgEntry);

                if "Applies-to Doc. No." <> '' then
                    TestField("Bal. Account No.", '');

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." <> '') and
                   ("Applies-to Doc. No." <> '')
                then begin
                    CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Bill-to Customer No.");
                    CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Bill-to Customer No.");
                end else
                    if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." = '') then
                        CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Bill-to Customer No.")
                    else
                        if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and ("Applies-to Doc. No." = '') then
                            CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Bill-to Customer No.");
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Bal. Account No." <> '' then
                    case "Bal. Account Type" of
                        "Bal. Account Type"::"G/L Account":
                            begin
                                GLAcc.Get("Bal. Account No.");
                                GLAcc.CheckGLAcc;
                                GLAcc.TestField("Direct Posting", true);
                            end;
                        "Bal. Account Type"::"Bank Account":
                            begin
                                BankAcc.Get("Bal. Account No.");
                                BankAcc.TestField(Blocked, false);
                                BankAcc.TestField("Currency Code", "Currency Code");
                            end;
                    end;
            end;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Recalculate Invoice Disc." = CONST(true)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; Ship; Boolean)
        {
            Caption = 'Ship';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(58; Invoice; Boolean)
        {
            Caption = 'Invoice';
            DataClassification = CustomerContent;
        }
        field(59; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
            DataClassification = CustomerContent;
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Line".Amount WHERE("Document Type" = FIELD("Document Type"),
                                                         "Document No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Line"."Amount Including VAT" WHERE("Document Type" = FIELD("Document Type"),
                                                                         "Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
            DataClassification = CustomerContent;
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
            DataClassification = CustomerContent;
        }
        field(64; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Sales Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(66; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
            DataClassification = CustomerContent;
        }
        field(67; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Invoice Header";
        }
        field(68; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
            DataClassification = CustomerContent;
        }
        field(69; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Cr.Memo Header";
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Customer: Record Customer;
                VATRegistrationLog: Record "VAT Registration Log";
                VATRegistrationNoFormat: Record "VAT Registration No. Format";
                VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
                VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                ResultRecRef: RecordRef;
                ApplicableCountryCode: Code[10];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATRegistrationNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." = xRec."VAT Registration No." then
                    exit;

                GLSetup.GetRecordOnce;
                case GLSetup."Bill-to/Sell-to VAT Calc." of
                    GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.":
                        if not Customer.Get("Bill-to Customer No.") then
                            exit;
                    GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.":
                        if not Customer.Get("Rented-to Customer No.") then
                            exit;
                end;

                if "VAT Registration No." = Customer."VAT Registration No." then
                    exit;

                if not VATRegistrationNoFormat.Test("VAT Registration No.", Customer."Country/Region Code", Customer."No.", DATABASE::Customer) then
                    exit;

                Customer."VAT Registration No." := "VAT Registration No.";
                ApplicableCountryCode := Customer."Country/Region Code";
                if ApplicableCountryCode = '' then
                    ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";

                if not VATRegNoSrvConfig.VATRegNoSrvIsEnabled then begin
                    Customer.Modify(true);
                    exit;
                end;

                VATRegistrationLogMgt.CheckVIESForVATNo(
                    ResultRecRef, VATRegistrationLog, Customer, Customer."No.",
                    ApplicableCountryCode, VATRegistrationLog."Account Type"::Customer.AsInteger());

                if VATRegistrationLog.Status = VATRegistrationLog.Status::Valid then begin
                    Message(ValidVATNoMsg);
                    Customer.Modify(true);
                end else
                    Message(InvalidVatRegNoMsg);
            end;
        }
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
            DataClassification = CustomerContent;
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then begin
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        "VAT Bus. Posting Group" := GenBusPostingGrp."Def. VAT Bus. Posting Group";
                    RecreateTWERentalLines(FieldCaption("Gen. Bus. Posting Group"));
                end;
            end;
        }
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            DataClassification = CustomerContent;
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Type";

            trigger OnValidate()
            begin
                UpdateTWERentalLinesByFieldNo(FieldNo("Transaction Type"), false);
            end;
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            DataClassification = CustomerContent;
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdateTWERentalLinesByFieldNo(FieldNo("Transport Method"), false);
            end;
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(79; "Rented-to Customer Name"; Text[100])
        {
            Caption = 'Rented-to Customer Name';
            DataClassification = CustomerContent;
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                LookupSellToCustomerName();
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
                EnvInfoProxy: Codeunit "Env. Info Proxy";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSellToCustomerName(Rec, Customer, IsHandled);
                if IsHandled then
                    exit;

                if ShouldSearchForCustomerByName("Rented-to Customer No.") then
                    Validate("Rented-to Customer No.", Customer.GetCustNo("Rented-to Customer Name"));

                GetShippingTime(FieldNo("Rented-to Customer Name"));
            end;
        }
        field(80; "Rented-to Customer Name 2"; Text[50])
        {
            Caption = 'Rented-to Customer Name 2';
            DataClassification = CustomerContent;
        }
        field(81; "Rented-to Address"; Text[100])
        {
            Caption = 'Rented-to Address';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Address"));
                ModifyCustomerAddress;
            end;
        }
        field(82; "Rented-to Address 2"; Text[50])
        {
            Caption = 'Rented-to Address 2';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Address 2"));
                ModifyCustomerAddress;
            end;
        }
        field(83; "Rented-to City"; Text[30])
        {
            Caption = 'Rented-to City';
            DataClassification = CustomerContent;
            TableRelation = IF ("Rented-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Rented-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Rented-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Rented-to City", "Rented-to Post Code", "Rented-to County", "Rented-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Rented-to City", "Rented-to Post Code", "Rented-to County", "Rented-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to City"));
                ModifyCustomerAddress;
            end;
        }
        field(84; "Rented-to Contact"; Text[100])
        {
            Caption = 'Rented-to Contact';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                if "Document Type" <> "Document Type"::Quote then
                    if "Rented-to Customer No." = '' then
                        exit;

                Contact.FilterGroup(2);
                LookupContact("Rented-to Customer No.", "Rented-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Rented-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyCustomerAddress;
            end;
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupBillToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateBillToPostCode(Rec, PostCode);

                PostCode.ValidatePostCode(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyBillToCustomerAddress;
            end;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(88; "Rented-to Post Code"; Code[20])
        {
            Caption = 'Rented-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Rented-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Rented-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Rented-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupSellToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Rented-to City", "Rented-to Post Code", "Rented-to County", "Rented-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateSellToPostCode(Rec, PostCode);

                PostCode.ValidatePostCode(
                  "Rented-to City", "Rented-to Post Code", "Rented-to County", "Rented-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Post Code"));
                ModifyCustomerAddress;
            end;
        }
        field(89; "Rented-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Rented-to Country/Region Code";
            Caption = 'Rented-to County';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to County"));
                ModifyCustomerAddress;
            end;
        }
        field(90; "Rented-to Country/Region Code"; Code[10])
        {
            Caption = 'Rented-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Country/Region Code"));
                ModifyCustomerAddress;
                Validate("Ship-to Country/Region Code");
            end;
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupShipToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateShipToPostCode(Rec, PostCode);

                PostCode.ValidatePostCode(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            DataClassification = CustomerContent;
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = CustomerContent;
        }
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            DataClassification = CustomerContent;
            TableRelation = "Entry/Exit Point";

            trigger OnValidate()
            begin
                UpdateTWERentalLinesByFieldNo(FieldNo("Exit Point"), false);
            end;
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
            DataClassification = CustomerContent;
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if xRec."Document Date" <> "Document Date" then
                    UpdateDocumentDate := true;
                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");

                if UpdateDocumentDate and ("Document Type" = "Document Type"::Quote) and ("Document Date" <> 0D) then
                    CalcQuoteValidUntilDate;
            end;
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                WhseSalesRelease: Codeunit "Whse.-Sales Release";
            begin
                // if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) and
                //   ("Document Type" in ["Document Type"::Contract, "Document Type"::"Return Shipment"])
                //then
                //      WhseSalesRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            DataClassification = CustomerContent;
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdateTWERentalLinesByFieldNo(FieldNo(Area), false);
            end;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdateTWERentalLinesByFieldNo(FieldNo("Transaction Specification"), false);
            end;
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                PaymentMethod.Init();
                if "Payment Method Code" <> '' then
                    PaymentMethod.Get("Payment Method Code");
                if PaymentMethod."Direct Debit" then begin
                    "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.", "Due Date");
                    if "Payment Terms Code" = '' then
                        "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
                end else
                    "Direct Debit Mandate ID" := '';
                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                if "Bal. Account No." <> '' then begin
                    TestField("Applies-to Doc. No.", '');
                    TestField("Applies-to ID", '');
                    Clear("Payment Service Set ID");
                end;
            end;
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen;
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FieldNo("Shipping Agent Code"));

                OnValidateShippingAgentCodeOnBeforeUpdateLines(Rec, CurrFieldNo, HideValidationDialog);
                UpdateTWERentalLinesByFieldNo(FieldNo("Shipping Agent Code"), CurrFieldNo <> 0);
            end;
        }
        field(106; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
            DataClassification = CustomerContent;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                RentalHeader := Rec;
                //GetRentalSetup;
                TestNoSeries;
                if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode, "Posting No. Series") then
                    Validate("Posting No. Series");
                Rec := RentalHeader;
            end;

            trigger OnValidate()
            begin
                if Rec."Posting No. Series" <> '' then begin
                    //GetRentalSetup;
                    TestNoSeries;
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode, Rec."Posting No. Series");
                end;
                TestField(Rec."Posting No.", '');
            end;
        }
        field(109; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupShippingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                RentalHeader := Rec;
                //GetRentalSetup;
                RentalSetup.TestField("Posted Rental Shipment Nos.");
                if NoSeriesMgt.LookupSeries(RentalSetup."Posted Rental Shipment Nos.", "Shipping No. Series") then
                    Validate("Shipping No. Series");
                Rec := RentalHeader;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Shipping No. Series" <> '' then begin
                    GetRentalSetup;
                    RentalSetup.TestField("Posted Rental Shipment Nos.");
                    NoSeriesMgt.TestSeries(RentalSetup."Posted Rental Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
                ValidateTaxAreaCode;
                MessageIfTWERentalLinesExist(FieldCaption("Tax Area Code"));
            end;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfTWERentalLinesExist(FieldCaption("Tax Liable"));
            end;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" then
                    RecreateTWERentalLines(FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
            DataClassification = CustomerContent;
            InitValue = Optional;
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
                CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
            begin
                if "Applies-to ID" <> '' then
                    TestField("Bal. Account No.", '');
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open);
                    CustLedgEntry.SetRange("Customer No.", "Bill-to Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("Applies-to ID", xRec."Applies-to ID");
                    if CustLedgEntry.FindFirst() then
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    CustLedgEntry.Reset();
                end;
            end;
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen;
                GLSetup.Get();
                if "VAT Base Discount %" > GLSetup."VAT Tolerance %" then
                    Error(
                      Text007Lbl,
                      FieldCaption("VAT Base Discount %"),
                      GLSetup.FieldCaption("VAT Tolerance %"),
                      GLSetup.TableCaption);

                if ("VAT Base Discount %" = xRec."VAT Base Discount %") and (CurrFieldNo <> 0) then
                    exit;

                UpdateTWERentalLineAmounts;
            end;
        }
        field(120; Status; Enum "Sales Document Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Send IC Document" then begin
                    if "Bill-to IC Partner Code" = '' then
                        TestField("Rented-to IC Partner Code");
                    TestField("IC Direction", "IC Direction"::Outgoing);
                end;
            end;
        }
        field(124; "IC Status"; Option)
        {
            Caption = 'IC Status';
            DataClassification = CustomerContent;
            OptionCaption = 'New,Pending,Sent';
            OptionMembers = New,Pending,Sent;
        }
        field(125; "Rented-to IC Partner Code"; Code[20])
        {
            Caption = 'Rented-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(129; "IC Direction"; Option)
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;

            trigger OnValidate()
            begin
                if "IC Direction" = "IC Direction"::Incoming then
                    "Send IC Document" := false;
            end;
        }
        field(130; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if xRec."Prepayment %" <> "Prepayment %" then
                    UpdateTWERentalLinesByFieldNo(FieldNo("Prepayment %"), CurrFieldNo <> 0);
            end;
        }
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                RentalHeader := Rec;
                GetRentalSetup;
                RentalSetup.TestField("Posted Prepmt. Inv. Nos.");
                if NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode, "Prepayment No. Series") then
                    Validate("Prepayment No. Series");
                Rec := RentalHeader;
            end;

            trigger OnValidate()
            begin
                if "Prepayment No. Series" <> '' then begin
                    GetRentalSetup;
                    RentalSetup.TestField("Posted Prepmt. Inv. Nos.");
                    NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode, "Prepayment No. Series");
                end;
                TestField("Prepayment No.", '');
            end;
        }
        field(132; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(133; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
            DataClassification = CustomerContent;
        }
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                RentalHeader := Rec;
                GetRentalSetup();
                RentalSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                if NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode, "Prepmt. Cr. Memo No. Series") then
                    Validate("Prepmt. Cr. Memo No. Series");
                Rec := RentalHeader;
            end;

            trigger OnValidate()
            begin
                if "Prepmt. Cr. Memo No." <> '' then begin
                    GetRentalSetup;
                    RentalSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                    NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode, "Prepmt. Cr. Memo No. Series");
                end;
                TestField("Prepmt. Cr. Memo No.", '');
            end;
        }
        field(135; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
            DataClassification = CustomerContent;
        }
        field(138; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
            DataClassification = CustomerContent;
        }
        field(139; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerms: Record "Payment Terms";
                IsHandled: Boolean;
            begin
                if ("Prepmt. Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Prepmt. Payment Terms Code");
                    if IsCreditDocType and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                        Validate("Prepayment Due Date", "Document Date");
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end else begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcDueDate(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepayment Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepmt. Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        if not UpdateDocumentDate then
                            Validate("Prepmt. Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    Validate("Prepayment Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end;
                end;
            end;
        }
        field(140; "Prepmt. Payment Discount %"; Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen;
                GLSetup.Get();
                if "Payment Discount %" < GLSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                Validate("VAT Base Discount %");
            end;
        }
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(152; "Quote Valid Until Date"; Date)
        {
            Caption = 'Quote Valid To Date';
            DataClassification = CustomerContent;
        }
        field(153; "Quote Sent to Customer"; DateTime)
        {
            Caption = 'Quote Sent to Customer';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(154; "Quote Accepted"; Boolean)
        {
            Caption = 'Quote Accepted';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Quote Accepted" then begin
                    "Quote Accepted Date" := WorkDate();
                    OnAfterSalesQuoteAccepted(Rec);
                end else
                    "Quote Accepted Date" := 0D;
            end;
        }
        field(155; "Quote Accepted Date"; Date)
        {
            Caption = 'Quote Accepted Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(160; "Job Queue Status"; Option)
        {
            Caption = 'Job Queue Status';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = ' ,Scheduled for Posting,Error,Posting';
            OptionMembers = " ","Scheduled for Posting",Error,Posting;

            trigger OnLookup()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                if "Job Queue Status" = "Job Queue Status"::" " then
                    exit;
                JobQueueEntry.ShowStatusMsg("Job Queue Entry ID");
            end;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;
                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.");
                //else
                //   IncomingDocument.SetSalesDoc(Rec);
            end;
        }
        field(166; "Last Email Sent Time"; DateTime)
        {
            CalcFormula = Max("O365 Document Sent History"."Created Date-Time" WHERE("Document Type" = FIELD("Document Type"),
                                                                                      "Document No." = FIELD("No."),
                                                                                      Posted = CONST(false)));
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
        }
        field(167; "Last Email Sent Status"; Option)
        {
            CalcFormula = Lookup("O365 Document Sent History"."Job Last Status" WHERE("Document Type" = FIELD("Document Type"),
                                                                                       "Document No." = FIELD("No."),
                                                                                       Posted = CONST(false),
                                                                                       "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Sent Status';
            FieldClass = FlowField;
            OptionCaption = 'Not Sent,In Process,Finished,Error';
            OptionMembers = "Not Sent","In Process",Finished,Error;
        }
        field(168; "Sent as Email"; Boolean)
        {
            CalcFormula = Exist("O365 Document Sent History" WHERE("Document Type" = FIELD("Document Type"),
                                                                    "Document No." = FIELD("No."),
                                                                    Posted = CONST(false),
                                                                    "Job Last Status" = CONST(Finished)));
            Caption = 'Sent as Email';
            FieldClass = FlowField;
        }
        field(169; "Last Email Notif Cleared"; Boolean)
        {
            CalcFormula = Lookup("O365 Document Sent History".NotificationCleared WHERE("Document Type" = FIELD("Document Type"),
                                                                                         "Document No." = FIELD("No."),
                                                                                         Posted = CONST(false),
                                                                                         "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Notif Cleared';
            FieldClass = FlowField;
        }
        field(170; IsTest; Boolean)
        {
            Caption = 'IsTest';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(171; "Rented-to Phone No."; Text[30])
        {
            Caption = 'Rented-to Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                //Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Rented-to Phone No.") do
                    //   if Char.IsLetter("Rented-to Phone No."[i]) then
                    Error(PhoneNoCannotContainLettersErr);
            end;
        }
        field(172; "Rented-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Rented-to E-Mail" = '' then
                    exit;
                MailManagement.CheckValidEmailAddresses("Rented-to E-Mail");
            end;
        }
        field(175; "Payment Instructions Id"; Integer)
        {
            Caption = 'Payment Instructions Id';
            DataClassification = CustomerContent;
            TableRelation = "O365 Payment Instructions";
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
        }
        field(300; "Amt. Ship. Not Inv. (LCY)"; Decimal)
        {
            CalcFormula = Sum("TWE Rental Line"."Shipped Not Invoiced (LCY)" WHERE("Document Type" = FIELD("Document Type"),
                                                                               "Document No." = FIELD("No.")));
            Caption = 'Amount Shipped Not Invoiced (LCY) Incl. VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(301; "Amt. Ship. Not Inv. (LCY) Base"; Decimal)
        {
            CalcFormula = Sum("TWE Rental Line"."Shipped Not Inv. (LCY) No VAT" WHERE("Document Type" = FIELD("Document Type"),
                                                                                  "Document No." = FIELD("No.")));
            Caption = 'Amount Shipped Not Invoiced (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(600; "Payment Service Set ID"; Integer)
        {
            Caption = 'Payment Service Set ID';
            DataClassification = CustomerContent;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            DataClassification = CustomerContent;
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Bill-to Customer No."),
                                                               Closed = CONST(false),
                                                               Blocked = CONST(false));
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Inv. Discount Amount" WHERE("Document No." = FIELD("No."),
                                                                         "Document Type" = FIELD("Document Type")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5043; "No. of Archived Versions"; Integer)
        {
            CalcFormula = Max("Sales Header Archive"."Version No." WHERE("Document Type" = FIELD("Document Type"),
                                                                          "No." = FIELD("No."),
                                                                          "Doc. No. Occurrence" = FIELD("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
            DataClassification = CustomerContent;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            DataClassification = CustomerContent;
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");
            end;
        }
        field(5051; "Rented-to Cust. Templ Code"; Code[10])
        {
            Caption = 'Rented-to Customer Template Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Templ.";

            trigger OnValidate()
            var
                SellToCustTemplate: Record "Customer Templ.";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen;

                if not InsertMode and
                   ("Rented-to Cust. Templ Code" <> xRec."Rented-to Cust. Templ Code") and
                   (xRec."Rented-to Cust. Templ Code" <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Rented-to Cust. Templ Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Rented-to Cust. Templ Code", FieldCaption("Rented-to Cust. Templ Code")) then
                            exit
                    end else begin
                        "Rented-to Cust. Templ Code" := xRec."Rented-to Cust. Templ Code";
                        exit;
                    end;
                end;

                if SellToCustTemplate.Get("Rented-to Cust. Templ Code") then
                    CopyFromSellToCustTemplate(SellToCustTemplate);

                if not InsertMode and
                   ((xRec."Rented-to Cust. Templ Code" <> "Rented-to Cust. Templ Code") or
                    (xRec."Currency Code" <> "Currency Code"))
                then
                    RecreateTWERentalLines(FieldCaption("Rented-to Cust. Templ Code"));
            end;
        }
        field(5052; "Rented-to Contact No."; Code[20])
        {
            Caption = 'Rented-to Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupSellToContactNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Rented-to Customer No." <> '' then
                    if Cont.Get("Rented-to Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Rented-to Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Rented-to Contact No." <> '' then
                    if Cont.Get("Rented-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Rented-to Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                Opportunity: Record Opportunity;
                IsHandled: Boolean;
            begin
                TestStatusOpen;

                if "Rented-to Contact No." <> '' then
                    if Cont.Get("Rented-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric;

                if ("Rented-to Contact No." <> xRec."Rented-to Contact No.") and
                   (xRec."Rented-to Contact No." <> '')
                then begin
                    if ("Rented-to Contact No." = '') and ("Opportunity No." <> '') then
                        Error(Text049Lbl, FieldCaption("Rented-to Contact No."));
                    IsHandled := false;
                    OnBeforeConfirmSellToContactNoChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
                    if not IsHandled then
                        if GetHideValidationDialog or not GuiAllowed then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Rented-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Rented-to Contact No.", "Rented-to Customer No.", FieldCaption("Rented-to Contact No.")) then
                            exit;
                        if "Opportunity No." <> '' then begin
                            Opportunity.Get("Opportunity No.");
                            if Opportunity."Contact No." <> "Rented-to Contact No." then begin
                                Modify();
                                Opportunity.Validate("Contact No.", "Rented-to Contact No.");
                                Opportunity.Modify();
                            end
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Rented-to Customer No." <> '') and ("Rented-to Contact No." <> '') then
                    CheckContactRelatedToCustomerCompany("Rented-to Contact No.", "Rented-to Customer No.", CurrFieldNo);

                if "Rented-to Contact No." <> '' then
                    if Cont.Get("Rented-to Contact No.") then
                        if ("Salesperson Code" = '') and (Cont."Salesperson Code" <> '') then
                            Validate("Salesperson Code", Cont."Salesperson Code");

                UpdateSellToCust("Rented-to Contact No.");
                UpdateSellToCustTemplateCode;
                UpdateShipToContact;
            end;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupBillToContactNo(IsHandled);
                if IsHandled then
                    exit;

                if "Bill-to Customer No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Bill-to Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                IsHandled: Boolean;
            begin
                TestStatusOpen;

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric;

                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then begin
                    IsHandled := false;
                    OnBeforeConfirmBillToContactNoChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
                    if not IsHandled then
                        if GetHideValidationDialog or (not GuiAllowed) then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Bill-to Contact No.", "Bill-to Customer No.", FieldCaption("Bill-to Contact No.")) then
                            exit;
                    end else begin
                        "Bill-to Contact No." := xRec."Bill-to Contact No.";
                        exit;
                    end;
                end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then
                    CheckContactRelatedToCustomerCompany("Bill-to Contact No.", "Bill-to Customer No.", CurrFieldNo);

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5054; "Bill-to Customer Template Code"; Code[10])
        {
            Caption = 'Bill-to Customer Template Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Templ.";

            trigger OnValidate()
            var
                BillToCustTemplate: Record "Customer Templ.";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen;

                if not InsertMode and
                   ("Bill-to Customer Template Code" <> xRec."Bill-to Customer Template Code") and
                   (xRec."Bill-to Customer Template Code" <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Customer Template Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Bill-to Customer Template Code", FieldCaption("Bill-to Customer Template Code")) then
                            exit
                    end else begin
                        "Bill-to Customer Template Code" := xRec."Bill-to Customer Template Code";
                        exit;
                    end;
                end;

                Validate("Ship-to Code", '');
                if BillToCustTemplate.Get("Bill-to Customer Template Code") then begin
                    BillToCustTemplate.TestField("Customer Posting Group");
                    "Customer Posting Group" := BillToCustTemplate."Customer Posting Group";
                    "Invoice Disc. Code" := BillToCustTemplate."Invoice Disc. Code";
                    "Customer Price Group" := BillToCustTemplate."Customer Price Group";
                    "Customer Disc. Group" := BillToCustTemplate."Customer Disc. Group";
                    "Allow Line Disc." := BillToCustTemplate."Allow Line Disc.";
                    Validate("Payment Terms Code", BillToCustTemplate."Payment Terms Code");
                    Validate("Payment Method Code", BillToCustTemplate."Payment Method Code");
                    "Prices Including VAT" := BillToCustTemplate."Prices Including VAT";
                    "Shipment Method Code" := BillToCustTemplate."Shipment Method Code";
                end;

                CreateDim(
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");

                OnValidateBilltoCustomerTemplateCodeBeforeRecreateTWERentalLines(Rec, CurrFieldNo);

                if not InsertMode and
                   (xRec."Rented-to Cust. Templ Code" = "Rented-to Cust. Templ Code") and
                   (xRec."Bill-to Customer Template Code" <> "Bill-to Customer Template Code")
                then
                    RecreateTWERentalLines(FieldCaption("Bill-to Customer Template Code"));
            end;
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                LinkSalesDocWithOpportunity(xRec."Opportunity No.");
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            DataClassification = CustomerContent;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
                    Error(
                      Text027Lbl,
                      RespCenter.TableCaption, UserSetupMgt.GetSalesFilter);

                UpdateLocationCode('');
                UpdateOutboundWhseHandlingTime;
                UpdateShipToAddress;

                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");

                if xRec."Responsibility Center" <> "Responsibility Center" then begin
                    RecreateTWERentalLines(FieldCaption("Responsibility Center"));
                    "Assigned User ID" := '';
                end;
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if InventoryPickConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text066Lbl, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                if WhseShipmentConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text070Lbl, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                //WhseSourceHeader.TWERentalHeaderVerifyChange(Rec, xRec);
            end;
        }

        field(5751; "Shipped Not Invoiced"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Qty. Shipped Not Invoiced" = FILTER(<> 0)));
            Caption = 'Shipped Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = Min("Sales Line"."Completely Shipped" WHERE("Document Type" = FIELD("Document Type"),
                                                                       "Document No." = FIELD("No."),
                                                                       Type = FILTER(<> " "),
                                                                       "Location Code" = FIELD("Location Filter")));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Posting from Whse. Ref."; Integer)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Posting from Whse. Ref.';
            DataClassification = CustomerContent;
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5755; Shipped; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Qty. Shipped (Base)" = FILTER(<> 0)));
            Caption = 'Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5756; "Last Shipment Date"; Date)
        {
            CalcFormula = Lookup("Sales Shipment Header"."Shipment Date" WHERE("No." = FIELD("Last Shipping No.")));
            Caption = 'Last Shipment Date';
            FieldClass = FlowField;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckPromisedDeliveryDate();

                if "Requested Delivery Date" <> xRec."Requested Delivery Date" then
                    UpdateTWERentalLinesByFieldNo(FieldNo("Requested Delivery Date"), CurrFieldNo <> 0);
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Promised Delivery Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Promised Delivery Date" <> xRec."Promised Delivery Date" then
                    UpdateTWERentalLinesByFieldNo(FieldNo("Promised Delivery Date"), CurrFieldNo <> 0);
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Shipping Time" <> xRec."Shipping Time" then
                    UpdateTWERentalLinesByFieldNo(FieldNo("Shipping Time"), CurrFieldNo <> 0);
            end;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Outbound Whse. Handling Time';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Outbound Whse. Handling Time" <> xRec."Outbound Whse. Handling Time") and
                   (xRec."Rented-to Customer No." = "Rented-to Customer No.")
                then
                    UpdateTWERentalLinesByFieldNo(FieldNo("Outbound Whse. Handling Time"), CurrFieldNo <> 0);
            end;
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentServiceCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen;
                GetShippingTime(FieldNo("Shipping Agent Service Code"));
                UpdateTWERentalLinesByFieldNo(FieldNo("Shipping Agent Service Code"), CurrFieldNo <> 0);
            end;
        }
        field(5795; "Late Order Shipping"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Exist("TWE Rental Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Rented-to Customer No." = FIELD("Rented-to Customer No."),
                                                    "Document No." = FIELD("No."),
                                                    "Shipment Date" = FIELD("Date Filter"),
                                                    "Outstanding Quantity" = FILTER(<> 0)));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800; Receive; Boolean)
        {
            Caption = 'Receive';
            DataClassification = CustomerContent;
        }
        field(5801; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            DataClassification = CustomerContent;
        }

        field(5803; "Last Return Receipt No."; Code[20])
        {
            Caption = 'Last Return Receipt No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Return Receipt Header";
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

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfTWERentalLinesExist(FieldCaption("Allow Line Disc."));
            end;
        }
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center", "Assigned User ID") then
                    Error(
                      Text061Lbl, "Assigned User ID",
                      RespCenter.TableCaption, UserSetupMgt.GetSalesFilter("Assigned User ID"));
            end;
        }

        field(70704600; "Rental Start"; Date)
        {
            Caption = 'Rental Start';
            DataClassification = CustomerContent;
        }

        field(70704601; "Rental End"; Date)
        {
            Caption = 'Rental End';
            DataClassification = CustomerContent;
        }

        field(70704602; "Rental Contract closed"; Boolean)
        {
            Caption = 'Rental Contract closed';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(70704603; "Invoicing Period"; Code[20])
        {
            Caption = 'Invoicing Period';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Invoicing Period"."Invoicing Period Code";

            trigger OnValidate()
            begin
                SetDataToRentalLine();
            end;
        }
        field(70704604; "Rental Rate Code"; Code[20])
        {
            Caption = 'Rental Rate Code';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Rates"."Rate Code";

            trigger OnValidate()
            begin
                SetDataToRentalLine();
            end;
        }
        field(70704605; "Belongs to Rental Contract"; Code[20])
        {
            Caption = 'Belongs to Rental Contract';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                SetDataToRentalLine();
            end;
        }
    }
    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Document Type")
        {
        }
        key(Key3; "Document Type", "Rented-to Customer No.")
        {
        }
        key(Key4; "Document Type", "Bill-to Customer No.")
        {
        }
        key(Key5; "Document Type", "Combine Shipments", "Bill-to Customer No.", "Currency Code", "EU 3-Party Trade", "Dimension Set ID")
        {
        }
        key(Key6; "Rented-to Customer No.", "External Document No.")
        {
        }
        key(Key7; "Document Type", "Rented-to Contact No.")
        {
        }
        key(Key8; "Bill-to Contact No.")
        {
        }
        key(Key9; "Incoming Document Entry No.")
        {
        }
        key(Key10; "Document Date")
        {
        }
        key(Key11; "Shipment Date", Status, "Location Code", "Responsibility Center")
        {
        }
        key(Key12; "Salesperson Code")
        {
        }
        key(Key13; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Rented-to Customer Name", Amount, "Rented-to Contact", "Amount Including VAT")
        {
        }
        fieldgroup(Brick; "No.", "Rented-to Customer Name", Amount, "Rented-to Contact", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesCommentLine: Record "Sales Comment Line";
        PostSalesDelete: Codeunit "PostSales-Delete";
        ArchiveManagement: Codeunit ArchiveManagement;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        ShowPostedDocsToPrint: Boolean;
    begin
        if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
            Error(
              Text022Lbl,
              RespCenter.TableCaption, UserSetupMgt.GetSalesFilter);

        // ArchiveManagement.AutoArchiveSalesDocument(Rec);
        // PostSalesDelete.DeleteHeader(Rec, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,SalesInvHeaderPrepmt, SalesCrMemoHeaderPrepmt);
        UpdateOpportunity;

        Validate("Applies-to ID", '');
        Validate("Incoming Document Entry No.", 0);

        DeleteRecordInApprovalRequest();
        RentalLine.Reset();
        RentalLine.LockTable();

        WhseRequest.SetRange("Source Type", DATABASE::"Sales Line");
        WhseRequest.SetRange("Source Subtype", "Document Type");
        WhseRequest.SetRange("Source No.", "No.");
        if not WhseRequest.IsEmpty then
            WhseRequest.DeleteAll(true);

        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");

        DeleteTWERentalLines;
        RentalLine.SetRange(Type);
        DeleteTWERentalLines;

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ShowPostedDocsToPrint := (RentalShptHeader."No." <> '') or
           (RentalInvHeader."No." <> '') or
           (RentalCrMemoHeader."No." <> '') or
           (ReturnRcptHeader."No." <> '') or
           (RentalInvHeaderPrepmt."No." <> '') or
           (RentalCrMemoHeaderPrepmt."No." <> '');
        OnBeforeShowPostedDocsToPrintCreatedMsg(ShowPostedDocsToPrint);
        if ShowPostedDocsToPrint then
            Message(PostedDocsToPrintCreatedMsg);
    end;

    trigger OnInsert()
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        InitInsert();
        InsertMode := true;

        SetSellToCustomerFromFilter;

        if GetFilterContNo <> '' then
            Validate("Rented-to Contact No.", GetFilterContNo);

        Validate("Payment Instructions Id", O365SalesInvoiceMgmt.GetDefaultPaymentInstructionsId);

        if "Salesperson Code" = '' then
            SetDefaultSalesperson;

        //if "Rented-to Customer No." <> '' then
        //StandardCodesMgt.CheckCreateSalesRecurringLines(Rec);

        // Remove view filters so that the cards does not show filtered view notification
        SetView('');
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRename(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        Error(Text003Lbl, TableCaption);
    end;

    var
        RentalSetup: Record "TWE Rental Setup";
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        RentalHeader: Record "TWE Rental Header";
        RentalLine: Record "TWE Rental Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
        PostCode: Record "Post Code";
        BankAcc: Record "Bank Account";
        RentalShptHeader: Record "TWE Rental Shipment Header";
        RentalInvHeader: Record "TWE Rental Invoice Header";
        RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        RentalInvHeaderPrepmt: Record "TWE Rental Invoice Header";
        RentalCrMemoHeaderPrepmt: Record "TWE Rental Cr.Memo Header";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        RespCenter: Record "Responsibility Center";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        CompanyInfo: Record "Company Information";
        Salesperson: Record "Salesperson/Purchaser";
        GlobalTWERentalLine: Record "TWE Rental Line";
        UserSetupMgt: Codeunit "User Setup Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        RentalCustCheckCreditLimit: Codeunit "TWE Rent. Cust-Check Cr. Limit";
        DimMgt: Codeunit DimensionManagement;
        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
        WhseSourceHeader: Codeunit "Whse. Validate Source Header";
        TWERentalLineReserve: Codeunit "Sales Line-Reserve";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        CurrencyDate: Date;
        Confirmed: Boolean;
        Text035Lbl: Label 'You cannot Release Quote or Make Order unless you specify a customer on the quote.\\Do you want to create customer(s) now?';
        Text037Lbl: Label 'Contact %1 %2 is not related to customer %3.', Comment = '%1 = Contact "No.",%2 = Contact Name,%3 = Customer No';
        Text038Lbl: Label 'Contact %1 %2 is related to a different company than customer %3.', Comment = '%1 = Contact "No.",%2 = Contact Name,%3 = Customer No';
        ContactIsNotRelatedToAnyCostomerErr: Label 'Contact %1 %2 is not related to a customer.', Comment = '%1 = Contact "No.",%2 = Contact Name';
        Text040Lbl: Label 'A won opportunity is linked to this order.\It has to be changed to status Lost before the Order can be deleted.\Do you want to change the status for this opportunity now?';
        Text044Lbl: Label 'The status of the opportunity has not been changed. The program has aborted deleting the order.';
        SkipSellToContact: Boolean;
        SkipBillToContact: Boolean;
        Text045Lbl: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.', Comment = '%1 = FieldCaption "Posting Date",%2 = NoSeriesCapt,%3 = NoSeriesCode,%4 = FieldCaption "Date Order",%5 = "Date Order",%6 = "Document Type",%7 = NoCapt,%8 = No';
        Text048Lbl: Label 'Rental quote %1 has already been assigned to opportunity %2. Would you like to reassign this quote?', Comment = '%1 = "Rental Document No.",%2 = "No."';
        Text049Lbl: Label 'The %1 field cannot be blank because this quote is linked to an opportunity.', Comment = '%1 = Fieldcaption Rented-to Contact No.';
        InsertMode: Boolean;
        HideCreditCheckDialogue: Boolean;
        Text051Lbl: Label 'The rental %1 %2 already exists.', Comment = '%1 = "Document Type",%2 = "No."';
        Text053Lbl: Label 'You must cancel the approval process if you wish to change the %1.', Comment = '%1 = Salesperson Code';
        Text056Lbl: Label 'Deleting this document will cause a gap in the number series for prepayment invoices. An empty prepayment invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = RentalInvHeaderPrepmt "No."';
        Text057Lbl: Label 'Deleting this document will cause a gap in the number series for prepayment credit memos. An empty prepayment credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = RentalCrMemoHeaderPrepmt "No."';
        Text061Lbl: Label '%1 is set up to process from %2 %3 only.', Comment = '%1 = "Assigned User ID",%2 = RespCenter TableCaption,%3 = GetSalesFilter("Assigned User ID")';
        Text062Lbl: Label 'You cannot change %1 because the corresponding %2 %3 has been assigned to this %4.', Comment = '%1 = FieldCaption "Rented-to Customer No.",%2 = FieldCaption "Opportunity No.",%3 = "Opportunity No.",%4 = "Document Type"';
        Text063Lbl: Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.\\Do you want to continue?';
        Text064Lbl: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateDocumentDate: Boolean;
        Text066Lbl: Label 'You cannot change %1 to %2 because an open inventory pick on the %3.', Comment = '%1 = FieldCaption "Shipping Advice",%2 = "Shipping Advice",%3 = TableCaption';
        Text070Lbl: Label 'You cannot change %1  to %2 because an open warehouse shipment exists for the %3.', Comment = '%1 = FieldCaption "Shipping Advice",%2 = "Shipping Advice",%3 = TableCaption';
        BilltoCustomerNoChanged: Boolean;
        SelectNoSeriesAllowed: Boolean;
        PrepaymentInvoicesNotPaidErr: Label 'You cannot post the document of type %1 with the number %2 before all related prepayment invoices are posted.', Comment = 'You cannot post the document of type Order with the number 1001 before all related prepayment invoices are posted.%1 = Document Type, %2 = No.';
        Text072Lbl: Label 'There are unpaid prepayment invoices related to the document of type %1 with the number %2.', Comment = '%1 = Document Type, %2 = No.';
        DeferralLineQst: Label 'Do you want to update the deferral schedules for the lines?';
        SynchronizingMsg: Label 'Synchronizing ...\ from: Rental Header with %1\ to: Assembly Header with %2.', Comment = '%1 = "No.",%2 = AsmHeader."No."';
        EstimateTxt: Label 'Estimate';
        ShippingAdviceErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        SelectCustomerTemplateQst: Label 'Do you want to select the customer template?';
        ModifyCustomerAddressNotificationLbl: Label 'Update the address';
        DontShowAgainActionLbl: Label 'Don''t show again';
        ModifyCustomerAddressNotificationMsg: Label 'The address you entered for %1 is different from the customer''s existing address.', Comment = '%1=customer name';
        ValidVATNoMsg: Label 'The VAT registration number is valid.';
        InvalidVatRegNoMsg: Label 'The VAT registration number is not valid. Try entering the number again.';
        SellToCustomerTxt: Label 'Rented-to Customer';
        BillToCustomerTxt: Label 'Bill-to Customer';
        ModifySellToCustomerAddressNotificationNameTxt: Label 'Update Rented-to Customer Address';
        ModifySellToCustomerAddressNotificationDescriptionTxt: Label 'Warn if the Rented-to address on sales documents is different from the customer''s existing address.';
        ModifyBillToCustomerAddressNotificationNameTxt: Label 'Update Bill-to Customer Address';
        ModifyBillToCustomerAddressNotificationDescriptionTxt: Label 'Warn if the bill-to address on sales documents is different from the customer''s existing address.';
        DuplicatedCaptionsNotAllowedErr: Label 'Field captions must not be duplicated when using this method. Use UpdateTWERentalLinesByFieldNo instead.';
        PhoneNoCannotContainLettersErr: Label 'You cannot enter letters in this field.';
        MissingExchangeRatesQst: Label 'There are no exchange rates for currency %1 and date %2. Do you want to add them now? Otherwise, the last change you made will be reverted.', Comment = '%1 - currency code, %2 - posting date';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text %1.\Some message text %2.';
        ConfirmEmptyEmailQst: Label 'Contact %1 has no email address specified. The value in the Email field on the rental contract, %2, will be deleted. Do you want to continue?', Comment = '%1 - Contact No., %2 - Email';
        FullRentalTypesTxt: Label 'Rental Quote,Rental Order,Rental Invoice,Rental Credit Memo,Rental Blanket Order,Rental Return Order';
        RecreateTWERentalLinesCancelErr: Label 'You must delete the existing rental lines before you can change %1.', Comment = '%1 - Field Name, Sample: You must delete the existing rental lines before you can change Currency Code.';
        Text003Lbl: Label 'You cannot rename a %1.', Comment = '%1 = TableCaption';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        Text005Lbl: Label 'You cannot reset %1 because the document still has one or more lines.', Comment = '%1 = ContactCaption';
        Text006Lbl: Label 'You cannot change %1 because the order is associated with one or more purchase orders.', Comment = '%1 = FieldCaption "Rented-to Customer No."';
        Text007Lbl: Label '%1 cannot be greater than %2 in the %3 table.', Comment = '%1 = FieldCaption "VAT Base Discount %",%2 = FieldCaption "VAT Tolerance %",%3 = TableCaption';
        Text009Lbl: Label 'Deleting this document will cause a gap in the number series for shipments. An empty shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = RentalShptHeader "No."';
        Text012Lbl: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = RentalInvHeader "No."';
        Text014Lbl: Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = RentalCrMemoHeader "No."';
        RecreateTWERentalLinesMsg: Label 'If you change %1, the existing rental lines will be deleted and new rental lines based on the new information on the header will be created.\\Do you want to continue?', Comment = '%1: FieldCaption';
        ResetItemChargeAssignMsg: Label 'If you change %1, the existing rental lines will be deleted and new rental lines based on the new information on the header will be created.\The amount of the item charge assignment will be reset to 0.\\Do you want to continue?', Comment = '%1: FieldCaption';
        LinesNotUpdatedMsg: Label 'You have changed %1 on the sales header, but it has not been changed on the existing rental lines.', Comment = '%1 You have changed Order Date on the sales header, but it has not been changed on the existing rental lines.';
        Text019Lbl: Label 'You must update the existing rental lines manually.';
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the rental lines.';
        Text021Lbl: Label 'Do you want to update the exchange rate?';
        Text022Lbl: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.', Comment = '%1 = RespCenter TableCaption,%2 = GetSalesFilter';
        Text024Lbl: Label 'You have modified the %1 field. The recalculation of VAT may cause penny differences, so you must check the amounts afterward. Do you want to update the %2 field on the lines to reflect the new value of %1?', Comment = '%1 = FieldCaption "Prices Including VAT",%2 =  FieldCaption "Unit Price",%3 = true)';
        Text027Lbl: Label 'Your identification is set up to process from %1 %2 only.', Comment = '%1 = RespCenter TableCaption,%2 = GetSalesFilter';
        Text028Lbl: Label 'You cannot change the %1 when the %2 has been filled in.', Comment = '%1 = FieldCaption "Requested Delivery Date",%2 = FieldCaption "Promised Delivery Date"';
        Text031Lbl: Label 'You have modified %1.\\Do you want to update the lines?', Comment = 'You have modified Shipment Date.\\Do you want to update the lines? %1 = Field "Field Caption"';

    protected var
        HideValidationDialog: Boolean;
        StatusCheckSuspended: Boolean;

    /// <summary>
    /// InitInsert.
    /// </summary>
    procedure InitInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitInsert(Rec, xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries;
                NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Posting Date", "No.", "No. Series");
            end;

        OnInitInsertOnBeforeInitRecord(Rec, xRec);
        InitRecord();
    end;

    /// <summary>
    /// InitRecord.
    /// </summary>
    procedure InitRecord()
    var
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        GetRentalSetup;
        IsHandled := false;
        OnBeforeInitRecord(Rec, IsHandled, xRec);
        if not IsHandled then
            case "Document Type" of
                "Document Type"::Quote, "Document Type"::Contract:
                    begin
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", RentalSetup."Posted Rental Invoice Nos.");
                        NoSeriesMgt.SetDefaultSeries("Shipping No. Series", RentalSetup."Posted Rental Shipment Nos.");
                        if "Document Type" = "Document Type"::Contract then begin
                            NoSeriesMgt.SetDefaultSeries("Prepayment No. Series", RentalSetup."Posted Prepmt. Inv. Nos.");
                        end;
                    end;
                "Document Type"::Invoice:
                    begin
                        if ("No. Series" <> '') and
                           (RentalSetup."Rental Invoice Nos." = RentalSetup."Posted Rental Invoice Nos.")
                        then
                            "Posting No. Series" := "No. Series"
                        else
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", RentalSetup."Posted Rental Invoice Nos.");
                        if RentalSetup."Shipment on Invoice" then
                            NoSeriesMgt.SetDefaultSeries("Shipping No. Series", RentalSetup."Posted Rental Shipment Nos.");
                    end;

                "Document Type"::"Credit Memo":
                    begin
                        if ("No. Series" <> '') and
                           (RentalSetup."Rental Credit Memo Nos." = RentalSetup."Posted Rental Credit Memo Nos.")
                        then
                            "Posting No. Series" := "No. Series"
                        else
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", RentalSetup."Posted Rental Credit Memo Nos.");
                    end;
            end;

        IsHandled := false;
        OnInitRecordOnBeforeAssignShipmentDate(Rec, IsHandled);
        if not IsHandled then
            if "Document Type" in ["Document Type"::Contract, "Document Type"::Invoice, "Document Type"::Quote] then
                "Shipment Date" := WorkDate();

        IsHandled := false;
        OnInitRecordOnBeforeAssignWorkDateToPostingDate(Rec, IsHandled);
        if not ("Document Type" in ["Document Type"::Quote]) and
           ("Posting Date" = 0D)
        then
            "Posting Date" := WorkDate();

        if RentalSetup."Default Posting Date" = RentalSetup."Default Posting Date"::"No Date" then
            "Posting Date" := 0D;

        "Order Date" := WorkDate();
        "Document Date" := WorkDate();
        if "Document Type" = "Document Type"::Quote then
            CalcQuoteValidUntilDate;

        IF "Rented-to Customer No." <> '' THEN
            GetCust("Rented-to Customer No.");
        UpdateLocationCode(Cust."Location Code");

        if IsCreditDocType() then begin
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
        end;

        InitPostingDescription();

        UpdateOutboundWhseHandlingTime;

        "Responsibility Center" := UserSetupMgt.GetRespCenter(0, "Responsibility Center");
        "Doc. No. Occurrence" := ArchiveManagement.GetNextOccurrenceNo(DATABASE::"TWE Rental Header", "Document Type".AsInteger(), "No.");

        OnAfterInitRecord(Rec);
    end;

    local procedure InitNoSeries()
    begin
        if xRec."Shipping No." <> '' then begin
            "Shipping No. Series" := xRec."Shipping No. Series";
            "Shipping No." := xRec."Shipping No.";
        end;
        if xRec."Posting No." <> '' then begin
            "Posting No. Series" := xRec."Posting No. Series";
            "Posting No." := xRec."Posting No.";
        end;

        if xRec."Prepayment No." <> '' then begin
            "Prepayment No. Series" := xRec."Prepayment No. Series";
            "Prepayment No." := xRec."Prepayment No.";
        end;

        OnAfterInitNoSeries(Rec, xRec);
    end;

    local procedure InitPostingDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPostingDescription(Rec, IsHandled);
        if IsHandled then
            exit;

        "Posting Description" := Format("Document Type") + ' ' + "No.";
    end;

    /// <summary>
    /// AssistEdit.
    /// </summary>
    /// <param name="OldRentalHeader">Record "TWE Rental Header".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure AssistEdit(OldRentalHeader: Record "TWE Rental Header") Result: Boolean
    var
        RentalHeader2: Record "TWE Rental Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldRentalHeader, IsHandled, Result);
        if IsHandled then
            exit;

        Copy(Rec);
        GetRentalSetup;
        TestNoSeries;
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode(), OldRentalHeader."No. Series", "No. Series") then begin
            if ("Rented-to Customer No." = '') and ("Rented-to Contact No." = '') then begin
                HideCreditCheckDialogue := false;
                CheckCreditMaxBeforeInsert;
                HideCreditCheckDialogue := true;
            end;
            NoSeriesMgt.SetSeries("No.");
            if RentalHeader2.Get("Document Type", "No.") then
                Error(Text051Lbl, LowerCase(Format("Document Type")), "No.");
            Rec := RentalHeader;
            exit(true);
        end;
    end;

    /// <summary>
    /// TestNoSeries.
    /// </summary>
    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GetRentalSetup;
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then
            case "Document Type" of
                "Document Type"::Quote:
                    RentalSetup.TestField("Rental Quote Nos.");
                "Document Type"::Contract:
                    RentalSetup.TestField("Rental Contract Nos.");
                "Document Type"::Invoice:
                    begin
                        RentalSetup.TestField("Rental Invoice Nos.");
                        RentalSetup.TestField("Posted Rental Invoice Nos.");
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        RentalSetup.TestField("Rental Credit Memo Nos.");
                        RentalSetup.TestField("Posted Rental Credit Memo Nos.");
                    end;
            end;

        OnAfterTestNoSeries(Rec);
    end;

    /// <summary>
    /// GetNoSeriesCode.
    /// </summary>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GetRentalSetup;
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, RentalSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case "Document Type" of
            "Document Type"::Quote:
                NoSeriesCode := RentalSetup."Rental Quote Nos.";
            "Document Type"::Contract:
                NoSeriesCode := RentalSetup."Rental Contract Nos.";
            "Document Type"::Invoice:
                NoSeriesCode := RentalSetup."Rental Invoice Nos.";
            "Document Type"::"Return Shipment":
                NoSeriesCode := RentalSetup."Rental Return Shipment Nos.";
            "Document Type"::"Credit Memo":
                NoSeriesCode := RentalSetup."Rental Credit Memo Nos.";
        end;
        OnAfterGetNoSeriesCode(Rec, RentalSetup, NoSeriesCode);
        exit(NoSeriesMgt.GetNoSeriesWithCheck(NoSeriesCode, SelectNoSeriesAllowed, "No. Series"));
    end;

    local procedure GetPostingNoSeriesCode() PostingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        GetRentalSetup;
        IsHandled := false;
        OnBeforeGetPostingNoSeriesCode(Rec, RentalSetup, PostingNos, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType then
            PostingNos := RentalSetup."Posted Rental Credit Memo Nos."
        else
            PostingNos := RentalSetup."Posted Rental Invoice Nos.";

        OnAfterGetPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure GetPostingPrepaymentNoSeriesCode() PostingNos: Code[20]
    begin
        PostingNos := RentalSetup."Posted Prepmt. Inv. Nos.";

        OnAfterGetPrepaymentPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure TestNoSeriesDate(No: Code[20]; NoSeriesCode: Code[20]; NoCapt: Text[1024]; NoSeriesCapt: Text[1024])
    var
        NoSeries: Record "No. Series";
    begin
        if (No <> '') and (NoSeriesCode <> '') then begin
            NoSeries.Get(NoSeriesCode);
            if NoSeries."Date Order" then
                Error(
                  Text045Lbl,
                  FieldCaption("Posting Date"), NoSeriesCapt, NoSeriesCode,
                  NoSeries.FieldCaption("Date Order"), NoSeries."Date Order", "Document Type",
                  NoCapt, No);
        end;
    end;

    /// <summary>
    /// ConfirmDeletion.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ConfirmDeletion(): Boolean
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        PostSalesDelete: Codeunit "PostSales-Delete";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforeConfirmDeletion(Rec);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        if RentalShptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text009Lbl, RentalShptHeader."No."), true) then
                exit;
        if RentalInvHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text012Lbl, RentalInvHeader."No."), true) then
                exit;
        if RentalCrMemoHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text014Lbl, RentalCrMemoHeader."No."), true) then
                exit;
        if "Prepayment No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text056Lbl, RentalInvHeaderPrepmt."No."), true) then
                exit;
        if "Prepmt. Cr. Memo No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text057Lbl, RentalCrMemoHeaderPrepmt."No."), true) then
                exit;
        exit(true);
    end;

    /// <summary>
    /// GetCust.
    /// </summary>
    /// <param name="CustNo">Code[20].</param>
    procedure GetCust(CustNo: Code[20])
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        if not (("Document Type" = "Document Type"::Quote) and (CustNo = '')) then begin
            if CustNo <> Cust."No." then
                Cust.Get(CustNo);
        end else
            Clear(Cust);
        if O365SalesInitialSetup.Get then
            Cust."Payment Terms Code" := O365SalesInitialSetup."Default Payment Terms Code";
    end;

    local procedure GetRentalSetup()
    begin
        RentalSetup.Get();
        OnAfterGetRentalSetup(Rec, RentalSetup, CurrFieldNo);
    end;

    /// <summary>
    /// TWERentalLinesExist.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure TWERentalLinesExist(): Boolean
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        exit(not RentalLine.IsEmpty);
    end;

    /// <summary>
    /// RecreateTWERentalLines.
    /// </summary>
    /// <param name="ChangedFieldName">Text[100].</param>
    procedure RecreateTWERentalLines(ChangedFieldName: Text[100])
    var
        TempTWERentalLine: Record "TWE Rental Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        TempInteger: Record "Integer" temporary;
        TempATOLink: Record "Assemble-to-Order Link" temporary;
        RentalCommentLine: Record "TWE Rental Comment Line";
        TempRentalCommentLine: Record "TWE Rental Comment Line" temporary;
        ATOLink: Record "Assemble-to-Order Link";
        ExtendedTextAdded: Boolean;
        ConfirmText: Text;
        IsHandled: Boolean;
    begin
        if not TWERentalLinesExist() then
            exit;

        IsHandled := false;
        OnBeforeRecreateTWERentalLinesHandler(Rec, xRec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnRecreateTWERentalLinesOnBeforeConfirm(Rec, xRec, ChangedFieldName, HideValidationDialog, Confirmed, IsHandled);
        if not IsHandled then
            if GetHideValidationDialog() or not GuiAllowed() then
                Confirmed := true
            else begin
                if HasItemChargeAssignment() then
                    ConfirmText := ResetItemChargeAssignMsg
                else
                    ConfirmText := RecreateTWERentalLinesMsg;
                Confirmed := Confirm(ConfirmText, false, ChangedFieldName);
            end;

        if Confirmed then begin
            RentalLine.LockTable();
            ItemChargeAssgntSales.LockTable();
            ReservEntry.LockTable();
            Modify();
            OnBeforeRecreateTWERentalLines(Rec);
            RentalLine.Reset();
            RentalLine.SetRange("Document Type", "Document Type");
            RentalLine.SetRange("Document No.", "No.");
            OnRecreateTWERentalLinesOnAfterSetTWERentalLineFilters(RentalLine);
            if RentalLine.FindSet() then begin
                TempReservEntry.DeleteAll();
                RecreateReservEntryReqLine(TempTWERentalLine, TempATOLink, ATOLink);
                StoreRentalCommentLineToTemp(TempRentalCommentLine);
                RentalCommentLine.DeleteComments("Document Type".AsInteger(), "No.");
                TransferItemChargeAssgntSalesToTemp(ItemChargeAssgntSales, TempItemChargeAssgntSales);
                IsHandled := false;
                OnRecreateTWERentalLinesOnBeforeTWERentalLineDeleteAll(Rec, RentalLine, CurrFieldNo, IsHandled);
                if not IsHandled then
                    RentalLine.DeleteAll(true);

                RentalLine.Init();
                RentalLine."Line No." := 0;
                OnRecreateTWERentalLinesOnBeforeTempTWERentalLineFindSet(TempTWERentalLine);
                TempTWERentalLine.FindSet();
                ExtendedTextAdded := false;
                RentalLine.BlockDynamicTracking(true);
                repeat
                    RecreateTWERentalLinesHandleSupplementTypes(TempTWERentalLine, ExtendedTextAdded, TempItemChargeAssgntSales, TempInteger);
                    //     TWERentalLineReserve.CopyReservEntryFromTemp(TempReservEntry, TempTWERentalLine, RentalLine."Line No.");
                    //RecreateReqLine(TempTWERentalLine, RentalLine."Line No.", false);
                    SynchronizeForReservations(RentalLine, TempTWERentalLine);

                //if TempATOLink.AsmExistsForTWERentalLine(TempTWERentalLine) then begin
                //    ATOLink := TempATOLink;
                //    ATOLink."Document Line No." := RentalLine."Line No.";
                //    ATOLink.Insert();
                //    ATOLink.UpdateAsmFromTWERentalLineATOExist(RentalLine);
                //    TempATOLink.Delete();
                //end;
                until TempTWERentalLine.Next() = 0;

                RestoreRentalCommentLineFromTemp(TempRentalCommentLine);

                TempTWERentalLine.SetRange(Type);
                TempTWERentalLine.DeleteAll();
                OnAfterDeleteAllTempTWERentalLines(Rec);
                ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
                TempItemChargeAssgntSales.DeleteAll();
            end;
        end else
            Error(RecreateTWERentalLinesCancelErr, ChangedFieldName);

        RentalLine.BlockDynamicTracking(false);

        OnAfterRecreateTWERentalLines(Rec, ChangedFieldName);
    end;

    local procedure RecreateTWERentalLinesHandleSupplementTypes(var TempTWERentalLine: Record "TWE Rental Line" temporary; var ExtendedTextAdded: Boolean; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var TempInteger: Record "Integer" temporary)
    var
        RentalTransferExtendedText: Codeunit "TWE Rental Trans. Ext. Text";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecreateTWERentalLinesHandleSupplementTypes(TempTWERentalLine, IsHandled);
        if IsHandled then
            exit;

        if TempTWERentalLine."Attached to Line No." = 0 then begin
            CreateTWERentalLine(TempTWERentalLine);
            ExtendedTextAdded := false;
            OnAfterRecreateTWERentalLine(RentalLine, TempTWERentalLine);

            if RentalLine.Type = RentalLine.Type::"Rental Item" then
                RecreateTWERentalLinesFillItemChargeAssignment(RentalLine, TempTWERentalLine, TempItemChargeAssgntSales);
        end else
            if not ExtendedTextAdded then begin
                RentalTransferExtendedText.RentalCheckIfAnyExtText(RentalLine, true);
                RentalTransferExtendedText.InsertRentalExtText(RentalLine);
                OnAfterTransferExtendedTextForTWERentalLineRecreation(RentalLine, TempTWERentalLine);

                RentalLine.FindLast();
                ExtendedTextAdded := true;
            end;
    end;

    local procedure StoreRentalCommentLineToTemp(var TempRentalCommentLine: Record "TWE Rental Comment Line" temporary)
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        RentalCommentLine.SetRange("Document Type", "Document Type");
        RentalCommentLine.SetRange("No.", "No.");
        if RentalCommentLine.FindSet() then
            repeat
                TempRentalCommentLine := RentalCommentLine;
                TempRentalCommentLine.Insert();
            until RentalCommentLine.Next() = 0;
    end;

    local procedure RestoreRentalCommentLineFromTemp(var TempRentalCommentLine: Record "TWE Rental Comment Line" temporary)
    var
        RentalCommentLine: Record "TWE Rental Comment Line";
    begin
        TempRentalCommentLine.SetRange("Document Type", "Document Type");
        TempRentalCommentLine.SetRange("No.", "No.");
        if TempRentalCommentLine.FindSet() then
            repeat
                RentalCommentLine := TempRentalCommentLine;
                RentalCommentLine.Insert();
            until TempRentalCommentLine.Next() = 0;
    end;

    local procedure RecreateTWERentalLinesFillItemChargeAssignment(TWERentalLine: Record "TWE Rental Line"; TempTWERentalLine: Record "TWE Rental Line" temporary; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", TempTWERentalLine."Document Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.", TempTWERentalLine."Document No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", TempTWERentalLine."Line No.");
        if TempItemChargeAssgntSales.FindSet() then
            repeat
                if not TempItemChargeAssgntSales.Mark then begin
                    TempItemChargeAssgntSales."Applies-to Doc. Line No." := TWERentalLine."Line No.";
                    TempItemChargeAssgntSales.Description := TWERentalLine.Description;
                    TempItemChargeAssgntSales.Modify();
                    TempItemChargeAssgntSales.Mark(true);
                end;
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    /// <summary>
    /// MessageIfTWERentalLinesExist.
    /// </summary>
    /// <param name="ChangedFieldName">Text[100].</param>
    procedure MessageIfTWERentalLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //   OnBeforeMessageIfTWERentalLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if TWERentalLinesExist and not GetHideValidationDialog then begin
            MessageText := StrSubstNo(LinesNotUpdatedMsg, ChangedFieldName);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, Text019Lbl);
            Message(MessageText);
        end;
    end;

    /// <summary>
    /// PriceMessageIfTWERentalLinesExist.
    /// </summary>
    /// <param name="ChangedFieldName">Text[100].</param>
    procedure PriceMessageIfTWERentalLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        //    OnBeforePriceMessageIfTWERentalLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if TWERentalLinesExist and not GetHideValidationDialog then begin
            MessageText := StrSubstNo(LinesNotUpdatedMsg, ChangedFieldName);
            if "Currency Code" <> '' then
                MessageText := StrSubstNo(SplitMessageTxt, MessageText, AffectExchangeRateMsg);
            Message(MessageText);
        end;
    end;

    /// <summary>
    /// UpdateCurrencyFactor.
    /// </summary>
    procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        ConfirmManagement: Codeunit "Confirm Management";
        Updated: Boolean;
    begin
        OnBeforeUpdateCurrencyFactor(Rec, Updated);
        if Updated then
            exit;

        if "Currency Code" <> '' then begin
            if "Posting Date" <> 0D then
                CurrencyDate := "Posting Date"
            else
                CurrencyDate := WorkDate();

            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, "Currency Code") then begin
                "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
                if "Currency Code" <> xRec."Currency Code" then
                    RecreateTWERentalLines(FieldCaption("Currency Code"));
            end else begin
                if ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(MissingExchangeRatesQst, "Currency Code", CurrencyDate), true)
                then begin
                    Commit();
                    UpdateCurrencyExchangeRates.OpenExchangeRatesPage("Currency Code");
                    UpdateCurrencyFactor;
                end else
                    RevertCurrencyCodeAndPostingDate;
            end;
        end else begin
            "Currency Factor" := 0;
            if "Currency Code" <> xRec."Currency Code" then
                RecreateTWERentalLines(FieldCaption("Currency Code"));
        end;

        OnAfterUpdateCurrencyFactor(Rec, GetHideValidationDialog);
    end;

    /// <summary>
    /// ConfirmCurrencyFactorUpdate.
    /// </summary>
    procedure ConfirmCurrencyFactorUpdate()
    begin
        OnBeforeConfirmUpdateCurrencyFactor(Rec, HideValidationDialog);

        if GetHideValidationDialog or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(Text021Lbl, false);
        if Confirmed then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
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

    /// <summary>
    /// UpdateLocationCode.
    /// </summary>
    /// <param name="LocationCode">Code[10].</param>
    procedure UpdateLocationCode(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLocationCode(Rec, LocationCode, IsHandled);
        if not IsHandled then
            Validate("Location Code", UserSetupMgt.GetLocation(0, LocationCode, "Responsibility Center"));
    end;

    /// <summary>
    /// UpdateTWERentalLines.
    /// </summary>
    /// <param name="ChangedFieldName">Text[100].</param>
    /// <param name="AskQuestion">Boolean.</param>
    procedure UpdateTWERentalLines(ChangedFieldName: Text[100]; AskQuestion: Boolean)
    var
        "Field": Record "Field";
    begin
        OnBeforeUpdateTWERentalLines(Rec, ChangedFieldName, AskQuestion);

        Field.SetRange(TableNo, DATABASE::"TWE Rental Header");
        Field.SetRange("Field Caption", ChangedFieldName);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.Find('-');
        if Field.Next() <> 0 then
            Error(DuplicatedCaptionsNotAllowedErr);
        UpdateTWERentalLinesByFieldNo(Field."No.", AskQuestion);

        OnAfterUpdateTWERentalLines(Rec);
    end;

    local procedure UpdateTWERentalLineAmounts()
    var
        TWERentalLine: Record "TWE Rental Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTWERentalLineAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TWERentalLine.Reset();
        TWERentalLine.SetRange("Document Type", "Document Type");
        TWERentalLine.SetRange("Document No.", "No.");
        TWERentalLine.SetFilter(Type, '<>%1', TWERentalLine.Type::" ");
        TWERentalLine.SetFilter(Quantity, '<>0');
        TWERentalLine.LockTable();
        LockTable();
        if TWERentalLine.FindSet() then begin
            Modify();
            OnUpdateTWERentalLineAmountsOnAfterTWERentalHeaderModify(Rec, TWERentalLine);
            repeat
                if (TWERentalLine."Quantity Invoiced" <> TWERentalLine.Quantity) or
                   ("Shipping Advice" = "Shipping Advice"::Complete) or
                   (CurrFieldNo <> 0)
                then begin
                    TWERentalLine.UpdateAmounts;
                    TWERentalLine.Modify();
                end;
            until TWERentalLine.Next() = 0;
        end;
    end;

    /// <summary>
    /// UpdateTWERentalLinesByFieldNo.
    /// </summary>
    /// <param name="ChangedFieldNo">Integer.</param>
    /// <param name="AskQuestion">Boolean.</param>
    procedure UpdateTWERentalLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        JobTransferLine: Codeunit "Job Transfer Line";
        Question: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTWERentalLinesByFieldNo(Rec, ChangedFieldNo, AskQuestion, IsHandled);
        if IsHandled then
            exit;

        if not TWERentalLinesExist then
            exit;

        if not Field.Get(DATABASE::"TWE Rental Header", ChangedFieldNo) then
            Field.Get(DATABASE::"TWE Rental Line", ChangedFieldNo);

        if AskQuestion then begin
            Question := StrSubstNo(Text031Lbl, Field."Field Caption");
            if GuiAllowed and not GetHideValidationDialog then
                if DIALOG.Confirm(Question, true) then
                    case ChangedFieldNo of
                        FieldNo("Shipment Date"),
                        FieldNo("Shipping Agent Code"),
                        FieldNo("Shipping Agent Service Code"),
                        FieldNo("Shipping Time"),
                        FieldNo("Requested Delivery Date"),
                        FieldNo("Promised Delivery Date"),
                        FieldNo("Outbound Whse. Handling Time"):
                            ConfirmResvDateConflict;
                    end
                else
                    exit
        end;

        RentalLine.LockTable();
        Modify();

        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        if RentalLine.FindSet() then
            repeat
                IsHandled := false;
                //  OnBeforeTWERentalLineByChangedFieldNo(Rec, RentalLine, ChangedFieldNo, IsHandled);
                if not IsHandled then
                    case ChangedFieldNo of
                        FieldNo("Shipment Date"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Shipment Date", "Shipment Date");
                        FieldNo("Currency Factor"):
                            if RentalLine.Type <> RentalLine.Type::" " then begin
                                RentalLine.Validate("Unit Price");
                                RentalLine.Validate("Unit Cost (LCY)");
                                // if RentalLine."Job No." <> '' then
                                //  JobTransferLine.FromTWERentalHeaderToPlanningLine(RentalLine, "Currency Factor");
                            end;
                        FieldNo("Exit Point"):
                            RentalLine.Validate("Exit Point", "Exit Point");
                        FieldNo(Area):
                            RentalLine.Validate(Area, Area);
                        FieldNo("Shipping Agent Code"):
                            RentalLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                        FieldNo("Shipping Agent Service Code"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Shipping Agent Service Code", "Shipping Agent Service Code");
                        FieldNo("Shipping Time"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Shipping Time", "Shipping Time");
                        FieldNo("Prepayment %"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Prepayment %", "Prepayment %");
                        FieldNo("Requested Delivery Date"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Requested Delivery Date", "Requested Delivery Date");
                        FieldNo("Promised Delivery Date"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Promised Delivery Date", "Promised Delivery Date");
                        FieldNo("Outbound Whse. Handling Time"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Outbound Whse. Handling Time", "Outbound Whse. Handling Time");
                        RentalLine.FieldNo("Deferral Code"):
                            if RentalLine."No." <> '' then
                                RentalLine.Validate("Deferral Code");
                    //       else
                    //  OnUpdateTWERentalLineByChangedFieldName(Rec, RentalLine, Field.FieldName, ChangedFieldNo);
                    end;
                // TWERentalLineReserve.AssignForPlanning(RentalLine);
                OnUpdateTWERentalLinesByFieldNoOnBeforeTWERentalLineModify(RentalLine, ChangedFieldNo, CurrFieldNo);
                RentalLine.Modify(true);
            until RentalLine.Next() = 0;
    end;

    local procedure ConfirmResvDateConflict()
    var
        ResvEngMgt:
Codeunit "Reservation Engine Mgt.";
    begin
        //  if ResvEngMgt.ResvExistsForTWERentalHeader(Rec) then
        //   if not Confirm(Text063Lbl, false) then
        //     Error('');
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
    /// <param name="Type4">Integer.</param>
    /// <param name="No4">Code[20].</param>
    /// <param name="Type5">Integer.</param>
    /// <param name="No5">Code[20].</param>
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID:
                            array[10] of Integer;
        No:
                            array[10] of Code[20];
        OldDimSetID:
                            Integer;
        IsHandled:
                            Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" := DimMgt.GetRecDefaultDimID(
                              Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Sales, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo, OldDimSetID);

        if (OldDimSetID <> "Dimension Set ID") and TWERentalLinesExist then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    /// <summary>
    /// ValidateShortcutDimCode.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <param name="ShortcutDimCode">VAR Code[20].</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if TWERentalLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// ShippedTWERentalLinesExist.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ShippedTWERentalLinesExist(): Boolean
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        RentalLine.SetFilter("Quantity Shipped", '<>0');
        exit(RentalLine.FindFirst());
    end;

    /// <summary>
    /// ReturnReceiptExist.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ReturnReceiptExist(): Boolean
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        exit(RentalLine.FindFirst());
    end;

    local procedure DeleteTWERentalLines()
    var
        ReservMgt: Codeunit "Reservation Management";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteTWERentalLines(RentalLine, IsHandled);
        if IsHandled then
            exit;

        if RentalLine.FindSet() then begin
            ReservMgt.DeleteDocumentReservation(DATABASE::"TWE Rental Line", "Document Type".AsInteger(), "No.", GetHideValidationDialog);
            repeat
                RentalLine.SuspendStatusCheck(true);
                RentalLine.Delete(true);
            until RentalLine.Next() = 0;
        end;
    end;

    local procedure DeleteRecordInApprovalRequest()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeDeleteRecordInApprovalRequest(Rec, IsHandled);
        if IsHandled then
            exit;

        RentalApprovalsMgmt.OnDeleteRecordInApprovalRequest(RecordId);
    end;

    local procedure ClearItemAssgntSalesFilter(var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        TempItemChargeAssgntSales.SetRange("Document Line No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
    end;

    /// <summary>
    /// CheckCustomerCreated.
    /// </summary>
    /// <param name="Prompt">Boolean.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure CheckCustomerCreated(Prompt: Boolean): Boolean
    var
        Cont: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ("Bill-to Customer No." <> '') and ("Rented-to Customer No." <> '') then
            exit(true);

        if Prompt then
            if not ConfirmManagement.GetResponseOrDefault(Text035Lbl, true) then
                exit(false);

        if "Rented-to Customer No." = '' then begin
            TestField("Rented-to Contact No.");
            TestField("Rented-to Cust. Templ Code");
            GetContact(Cont, "Rented-to Contact No.");
            CreateCustomerFromSellToCustomerTemplate(Cont);
            Commit();
            Get("Document Type"::Quote, "No.");
        end;

        if "Bill-to Customer No." = '' then begin
            TestField("Bill-to Contact No.");
            TestField("Bill-to Customer Template Code");
            GetContact(Cont, "Bill-to Contact No.");
            CreateCustomerFromBillToCustomerTemplate(Cont);
            Commit();
            Get("Document Type"::Quote, "No.");
        end;

        exit(("Bill-to Customer No." <> '') and ("Rented-to Customer No." <> ''));
    end;

    local procedure CreateCustomerFromSellToCustomerTemplate(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeCreateCustomerFromSellToCustomerTemplate(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        Cont.CreateCustomerFromTemplate("Rented-to Cust. Templ Code");
    end;

    local procedure CreateCustomerFromBillToCustomerTemplate(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeCreateCustomerFromBillToCustomerTemplate(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        Cont.CreateCustomerFromTemplate("Bill-to Customer Template Code");
    end;

    local procedure CheckShipmentInfo(var TWERentalLine: Record "TWE Rental Line"; BillTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeCheckShipmentInfo(Rec, xRec, TWERentalLine, BillTo, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Contract then
            TWERentalLine.SetFilter("Quantity Shipped", '<>0')
        else
            if "Document Type" = "Document Type"::Invoice then begin
                if not BillTo then
                    TWERentalLine.SetRange("Rented-to Customer No.", xRec."Rented-to Customer No.");
                TWERentalLine.SetFilter("Shipment No.", '<>%1', '');
            end;

        if TWERentalLine.FindFirst() then
            //  if "Document Type" = "Document Type"::Contract then
            //     TestQuantityShippedField(TWERentalLine)
            // else
            //       TWERentalLine.TestField("Shipment No.", '');
            TWERentalLine.SetRange("Shipment No.");
        TWERentalLine.SetRange("Quantity Shipped");
    end;

    local procedure CheckPrepmtInfo(var TWERentalLine: Record "TWE Rental Line")
    begin
        if "Document Type" = "Document Type"::Contract then begin
            TWERentalLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if TWERentalLine.Find('-') then
                TWERentalLine.TestField("Prepmt. Amt. Inv.", 0);
            TWERentalLine.SetRange("Prepmt. Amt. Inv.");
        end;
    end;

    local procedure CheckReturnInfo(var TWERentalLine: Record "TWE Rental Line"; BillTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //   OnBeforeCheckReturnInfo(Rec, IsHandled);
        if IsHandled then
            exit;

        //  if "Document Type" = "Document Type"::"Return Order" then
        //     TWERentalLine.SetFilter("Return Qty. Received", '<>0')
        //  else
        //     if "Document Type" = "Document Type"::"Credit Memo" then begin
        //        if not BillTo then
        //            TWERentalLine.SetRange("Rented-to Customer No.", xRec."Rented-to Customer No.");
        //        TWERentalLine.SetFilter("Return Receipt No.", '<>%1', '');
        //    end;

        // if TWERentalLine.FindFirst() then
        //    if "Document Type" = "Document Type"::"Return Order" then
        //       TWERentalLine.TestField("Return Qty. Received", 0)
        //   else
        //      TWERentalLine.TestField("Return Receipt No.", '');
    end;

    local procedure CopyFromSellToCustTemplate(SellToCustTemplate: Record "Customer Templ.")
    begin
        if not ApplicationAreaMgmt.IsSalesTaxEnabled then
            SellToCustTemplate.TestField("Gen. Bus. Posting Group");
        "Gen. Bus. Posting Group" := SellToCustTemplate."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SellToCustTemplate."VAT Bus. Posting Group";
        if "Bill-to Customer No." = '' then
            Validate("Bill-to Customer Template Code", "Rented-to Cust. Templ Code");

        // OnAfterCopyFromSellToCustTemplate(Rec, SellToCustTemplate);
    end;

    local procedure RecreateReqLine(OldTWERentalLine: Record "TWE Rental Line"; NewSourceRefNo: Integer; ToTemp: Boolean)
    var
        ReqLine: Record "Requisition Line";
        TempReqLine: Record "Requisition Line" temporary;
    begin
        if ("Document Type" = "Document Type"::Contract) then
            if ToTemp then begin
                ReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                ReqLine.SetRange("Order Promising ID", OldTWERentalLine."Document No.");
                ReqLine.SetRange("Order Promising Line ID", OldTWERentalLine."Line No.");
                if ReqLine.FindSet() then begin
                    repeat
                        TempReqLine := ReqLine;
                        TempReqLine.Insert();
                    until ReqLine.Next() = 0;
                    ReqLine.DeleteAll();
                end;
            end else begin
                Clear(TempReqLine);
                TempReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                TempReqLine.SetRange("Order Promising ID", OldTWERentalLine."Document No.");
                TempReqLine.SetRange("Order Promising Line ID", OldTWERentalLine."Line No.");
                if TempReqLine.FindSet() then begin
                    repeat
                        ReqLine := TempReqLine;
                        ReqLine."Order Promising Line ID" := NewSourceRefNo;
                        ReqLine.Insert();
                    until TempReqLine.Next() = 0;
                    TempReqLine.DeleteAll();
                end;
            end;
    end;

    local procedure UpdateSellToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        OfficeContact: Record Contact;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.GetContact(OfficeContact, CustomerNo) then begin
            HideValidationDialog := true;
            UpdateSellToCust(OfficeContact."No.");
            HideValidationDialog := false;
        end else
            if Cust.Get(CustomerNo) then begin
                if Cust."Primary Contact No." <> '' then
                    "Rented-to Contact No." := Cust."Primary Contact No."
                else begin
                    ContBusRel.Reset();
                    ContBusRel.SetCurrentKey("Link to Table", "No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("No.", "Rented-to Customer No.");
                    if ContBusRel.FindFirst() then
                        "Rented-to Contact No." := ContBusRel."Contact No."
                    else
                        "Rented-to Contact No." := '';
                end;
                "Rented-to Contact" := Cust.Contact;
            end;
        if "Rented-to Contact No." <> '' then
            if OfficeContact.Get("Rented-to Contact No.") then
                OfficeContact.CheckIfPrivacyBlockedGeneric;

        //   OnAfterUpdateSellToCont(Rec, Cust, OfficeContact, HideValidationDialog);
    end;

    /// <summary>
    /// UpdateBillToCont.
    /// </summary>
    /// <param name="CustomerNo">Code[20].</param>
    procedure UpdateBillToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        Contact: Record Contact;
    begin
        if Cust.Get(CustomerNo) then begin
            if Cust."Primary Contact No." <> '' then
                "Bill-to Contact No." := Cust."Primary Contact No."
            else begin
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("No.", "Bill-to Customer No.");
                if ContBusRel.FindFirst() then
                    "Bill-to Contact No." := ContBusRel."Contact No."
                else
                    "Bill-to Contact No." := '';
            end;
            "Bill-to Contact" := Cust.Contact;
        end;
        if "Bill-to Contact No." <> '' then
            if Contact.Get("Bill-to Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric;

        //  OnAfterUpdateBillToCont(Rec, Cust, Contact);
    end;

    local procedure UpdateSellToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Cont: Record Contact;
        CustTemplate: Record "Customer Templ.";
        SearchContact: Record Contact;
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        //    OnBeforeUpdateSellToCust(Rec, Cont, Customer, ContactNo);

        if not Cont.Get(ContactNo) then begin
            "Rented-to Contact" := '';
            exit;
        end;
        "Rented-to Contact No." := Cont."No.";
        //  OnUpdateSellToCustOnAfterSetSellToContactNo(Rec, Customer, Cont);

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            IsHandled := false;
            OnUpdateSellToCustOnBeforeFindContactBusinessRelation(Cont, ContBusinessRelation, ContactBusinessRelationFound, IsHandled);
            IF not IsHandled THEN
                ContactBusinessRelationFound :=
                    ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;

        if ContactBusinessRelationFound then begin
            CheckCustomerContactRelation(Cont, "Rented-to Customer No.", ContBusinessRelation."No.");

            if "Rented-to Customer No." = '' then begin
                SkipSellToContact := true;
                Validate("Rented-to Customer No.", ContBusinessRelation."No.");
                SkipSellToContact := false;
            end;

            if (Cont."E-Mail" = '') and ("Rented-to E-Mail" <> '') and GuiAllowed then begin
                if Confirm(ConfirmEmptyEmailQst, false, Cont."No.", "Rented-to E-Mail") then
                    Validate("Rented-to E-Mail", Cont."E-Mail");
            end else
                Validate("Rented-to E-Mail", Cont."E-Mail");
            Validate("Rented-to Phone No.", Cont."Phone No.");
        end else begin
            if "Document Type" = "Document Type"::Quote then begin
                if not GetContactAsCompany(Cont, SearchContact) then
                    SearchContact := Cont;
                "Rented-to Customer Name" := SearchContact."Company Name";
                "Rented-to Customer Name 2" := SearchContact."Name 2";
                "Rented-to Phone No." := SearchContact."Phone No.";
                "Rented-to E-Mail" := SearchContact."E-Mail";
                SetShipToAddress(
                  SearchContact."Company Name", SearchContact."Name 2", SearchContact.Address, SearchContact."Address 2",
                  SearchContact.City, SearchContact."Post Code", SearchContact.County, SearchContact."Country/Region Code");
                if ("Rented-to Cust. Templ Code" = '') and (not CustTemplate.IsEmpty) then
                    Validate("Rented-to Cust. Templ Code", Cont.FindNewCustomerTemplate());
                //  OnUpdateSellToCustOnAfterSetFromSearchContact(Rec, SearchContact);
            end else begin
                IsHandled := false;
                //   OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(Rec, Cont, ContBusinessRelation, IsHandled);
                if not IsHandled then
                    Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            end;

            "Rented-to Contact" := Cont.Name;
        end;

        UpdateSellToCustContact(Customer, Cont);

        if "Document Type" = "Document Type"::Quote then begin
            if Customer.Get("Rented-to Customer No.") or Customer.Get(ContBusinessRelation."No.") then begin
                // if Customer."Copy Rented-to Addr. to Qte From" = Customer."Copy Rented-to Addr. to Qte From"::Company then
                //    GetContactAsCompany(Cont, Cont);
            end else
                GetContactAsCompany(Cont, Cont);
            "Rented-to Address" := Cont.Address;
            "Rented-to Address 2" := Cont."Address 2";
            "Rented-to City" := Cont.City;
            "Rented-to Post Code" := Cont."Post Code";
            "Rented-to County" := Cont.County;
            "Rented-to Country/Region Code" := Cont."Country/Region Code";
        end;
        if ("Rented-to Customer No." = "Bill-to Customer No.") or
           ("Bill-to Customer No." = '')
        then
            Validate("Bill-to Contact No.", "Rented-to Contact No.");

        // OnAfterUpdateSellToCust(Rec, Cont);
    end;

    local procedure UpdateSellToCustContact(Customer: Record Customer; Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeUpdateSellToCustContact(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if (Cont.Type = Cont.Type::Company) and Customer.Get("Rented-to Customer No.") then
            "Rented-to Contact" := Customer.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Rented-to Contact" := ''
            else
                "Rented-to Contact" := Cont.Name;
    end;

    local procedure CheckCustomerContactRelation(Cont: Record Contact; CustomerNo: Code[20]; ContBusinessRelationNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeCheckCustomerContactRelation(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if (CustomerNo <> '') and (CustomerNo <> ContBusinessRelationNo) then
            Error(Text037Lbl, Cont."No.", Cont.Name, CustomerNo);
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        CustTemplate: Record "Customer Templ.";
        SearchContact: Record Contact;
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCust(Rec, ContactNo, IsHandled);
        if IsHandled then
            exit;

        if not Cont.Get(ContactNo) then begin
            "Bill-to Contact" := '';
            exit;
        end;
        "Bill-to Contact No." := Cont."No.";

        UpdateBillToCustContact(Cont);

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            IsHandled := false;
            OnUpdateBillToCustOnBeforeFindContactBusinessRelation(Cont, ContBusinessRelation, ContactBusinessRelationFound, IsHandled);
            IF not IsHandled THEN
                ContactBusinessRelationFound :=
                    ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;
        if ContactBusinessRelationFound then begin
            if "Bill-to Customer No." = '' then begin
                SkipBillToContact := true;
                Validate("Bill-to Customer No.", ContBusinessRelation."No.");
                SkipBillToContact := false;
                "Bill-to Customer Template Code" := '';
            end else
                CheckCustomerContactRelation(Cont, "Bill-to Customer No.", ContBusinessRelation."No.");
        end else begin
            if "Document Type" = "Document Type"::Quote then begin
                if not GetContactAsCompany(Cont, SearchContact) then
                    SearchContact := Cont;
                "Bill-to Name" := SearchContact."Company Name";
                "Bill-to Name 2" := SearchContact."Name 2";
                "Bill-to Address" := SearchContact.Address;
                "Bill-to Address 2" := SearchContact."Address 2";
                "Bill-to City" := SearchContact.City;
                "Bill-to Post Code" := SearchContact."Post Code";
                "Bill-to County" := SearchContact.County;
                "Bill-to Country/Region Code" := SearchContact."Country/Region Code";
                "VAT Registration No." := SearchContact."VAT Registration No.";
                Validate("Currency Code", SearchContact."Currency Code");
                "Language Code" := SearchContact."Language Code";

                OnUpdateBillToCustOnAfterRentalQuote(Rec, SearchContact);

                if ("Bill-to Customer Template Code" = '') and (not CustTemplate.IsEmpty) then
                    Validate("Bill-to Customer Template Code", Cont.FindNewCustomerTemplate());
            end else begin
                IsHandled := false;
                OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(Rec, Cont, ContBusinessRelation, IsHandled);
                if not IsHandled then
                    Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            end;
        end;

        OnAfterUpdateBillToCust(RentalHeader, Cont);
    end;

    local procedure UpdateBillToCustContact(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeUpdateBillToCustContact(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if Cust.Get("Bill-to Customer No.") and (Cont.Type = Cont.Type::Company) then
            "Bill-to Contact" := Cust.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Bill-to Contact" := ''
            else
                "Bill-to Contact" := Cont.Name;
    end;

    local procedure UpdateSellToCustTemplateCode()
    begin
        if ("Document Type" = "Document Type"::Quote) and ("Rented-to Customer No." = '') and ("Rented-to Cust. Templ Code" = '') and
           (GetFilterContNo = '')
        then
            Validate("Rented-to Cust. Templ Code", SelectTWERentalHeaderCustomerTemplate);
    end;

    /// <summary>
    /// GetShippingTime.
    /// </summary>
    /// <param name="CalledByFieldNo">Integer.</param>
    procedure GetShippingTime(CalledByFieldNo: Integer)
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeGetShippingTime(Rec, xRec, CalledByFieldNo, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;
        if (CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0) then
            exit;

        if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
            "Shipping Time" := ShippingAgentServices."Shipping Time"
        else begin
            GetCust("Rented-to Customer No.");
            "Shipping Time" := Cust."Shipping Time"
        end;
        if not (CalledByFieldNo in [FieldNo("Shipping Agent Code"), FieldNo("Shipping Agent Service Code")]) then
            Validate("Shipping Time");
    end;

    local procedure GetContact(var Contact: Record Contact; ContactNo: Code[20])
    begin
        Contact.Get(ContactNo);
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
    end;

    /// <summary>
    /// GetSellToCustomerFaxNo.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetSellToCustomerFaxNo(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Rented-to Customer No.") then
            exit(Customer."Fax No.");
    end;

    /// <summary>
    /// CheckCreditMaxBeforeInsert.
    /// </summary>
    procedure CheckCreditMaxBeforeInsert()
    var
        TWERentalHeader: Record "TWE Rental Header";
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditMaxBeforeInsert(Rec, IsHandled, HideCreditCheckDialogue);
        if IsHandled then
            exit;

        if HideCreditCheckDialogue then
            exit;

        if (GetFilterCustNo <> '') or ("Rented-to Customer No." <> '') then begin
            if "Rented-to Customer No." <> '' then
                Cust.Get("Rented-to Customer No.")
            else
                Cust.Get(GetFilterCustNo);
            if Cust."Bill-to Customer No." <> '' then
                TWERentalHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
            else
                TWERentalHeader."Bill-to Customer No." := Cust."No.";
            //CustCheckCreditLimit.TWERentalHeaderCheck(TWERentalHeader);
        end else
            if GetFilterContNo <> '' then begin
                Cont.Get(GetFilterContNo);
                if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
                    Cust.Get(ContBusinessRelation."No.");
                    if Cust."Bill-to Customer No." <> '' then
                        TWERentalHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
                    else
                        TWERentalHeader."Bill-to Customer No." := Cust."No.";
                    //CustCheckCreditLimit.TWERentalHeaderCheck(TWERentalHeader);
                end;
            end;

        OnAfterCheckCreditMaxBeforeInsert(Rec);
    end;

    /// <summary>
    /// CreateInvtPutAwayPick.
    /// </summary>
    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        //  OnBeforeCreateInvtPutAwayPick(Rec);

        if "Document Type" = "Document Type"::Contract then
            if not IsApprovedForPosting then
                exit;
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        case "Document Type" of
            "Document Type"::Contract:
                begin
                    WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Order");
                end;
        // "Document Type"::"Return Order":
        //  WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Return Order");
        end;
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    /// <summary>
    /// CreateTask.
    /// </summary>
    procedure CreateTask()
    var
        TempTask: Record "To-do" temporary;
    begin
        TestField("Rented-to Contact No.");
        // TempTask.CreateTaskFromTWERentalHeader(Rec);
    end;

    /// <summary>
    /// UpdateShipToAddress.
    /// </summary>
    procedure UpdateShipToAddress()
    var
        IsHandled: Boolean;
    begin
        // OnBeforeUpdateShipToAddress(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if IsCreditDocType then
            if "Location Code" <> '' then begin
                Location.Get("Location Code");
                SetShipToAddress(
                  Location.Name, Location."Name 2", Location.Address, Location."Address 2", Location.City,
                  Location."Post Code", Location.County, Location."Country/Region Code");
                "Ship-to Contact" := Location.Contact;
            end else begin
                CompanyInfo.Get();
                "Ship-to Code" := '';
                SetShipToAddress(
                  CompanyInfo."Ship-to Name", CompanyInfo."Ship-to Name 2", CompanyInfo."Ship-to Address", CompanyInfo."Ship-to Address 2",
                  CompanyInfo."Ship-to City", CompanyInfo."Ship-to Post Code", CompanyInfo."Ship-to County",
                  CompanyInfo."Ship-to Country/Region Code");
                "Ship-to Contact" := CompanyInfo."Ship-to Contact";
            end;

        //  OnAfterUpdateShipToAddress(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// ShowDocDim.
    /// </summary>
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //   OnBeforeShowDocDim(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        //  OnShowDocDimOnBeforeUpdateTWERentalLines(Rec, xRec);
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if TWERentalLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure ConfirmUpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer) Confirmed: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeConfirmUpdateAllLineDim(Rec, xRec, NewParentDimSetID, OldParentDimSetID, Confirmed, IsHandled);
        if not IsHandled then
            Confirmed := Confirm(Text064Lbl);
    end;

    /// <summary>
    /// UpdateAllLineDim.
    /// </summary>
    /// <param name="NewParentDimSetID">Integer.</param>
    /// <param name="OldParentDimSetID">Integer.</param>
    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ATOLink: Record "Assemble-to-Order Link";
        NewDimSetID: Integer;
        ShippedReceivedItemLineDimChangeConfirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //   OnBeforeUpdateAllLineDim(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled, xRec);
        if IsHandled then
            exit;

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not GetHideValidationDialog and GuiAllowed then
            if not ConfirmUpdateAllLineDim(NewParentDimSetID, OldParentDimSetID) then
                exit;

        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        RentalLine.LockTable();
        if RentalLine.Find('-') then
            repeat
                OnUpdateAllLineDimOnBeforeGetTWERentalLineNewDimsetID(RentalLine, NewParentDimSetID, OldParentDimSetID);
                NewDimSetID := DimMgt.GetDeltaDimSetID(RentalLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                // OnUpdateAllLineDimOnAfterGetTWERentalLineNewDimsetID(Rec, xRec, RentalLine, NewDimSetID, NewParentDimSetID, OldParentDimSetID);
                if RentalLine."Dimension Set ID" <> NewDimSetID then begin
                    RentalLine."Dimension Set ID" := NewDimSetID;

                    if not GetHideValidationDialog and GuiAllowed then
                        VerifyShippedReceivedItemLineDimChange(ShippedReceivedItemLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      RentalLine."Dimension Set ID", RentalLine."Shortcut Dimension 1 Code", RentalLine."Shortcut Dimension 2 Code");

                    //OnUpdateAllLineDimOnBeforeTWERentalLineModify(RentalLine);
                    RentalLine.Modify();
                    // ATOLink.UpdateAsmDimFromTWERentalLine(RentalLine);
                end;
            until RentalLine.Next() = 0;
    end;

    local procedure VerifyShippedReceivedItemLineDimChange(var ShippedReceivedItemLineDimChangeConfirmed: Boolean)
    begin
        if RentalLine.IsShippedReceivedMainRentalItemDimChanged then
            if not ShippedReceivedItemLineDimChangeConfirmed then
                ShippedReceivedItemLineDimChangeConfirmed := RentalLine.ConfirmShippedReceivedMainRentalItemDimChange;
    end;

    /// <summary>
    /// LookupAdjmtValueEntries.
    /// </summary>
    /// <param name="QtyType">Option General,Invoicing.</param>
    procedure LookupAdjmtValueEntries(QtyType: Option General,Invoicing)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TWERentalLine: Record "TWE Rental Line";
        RentalShptLine: Record "TWE Rental Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        TempValueEntry: Record "Value Entry" temporary;
    begin
        TWERentalLine.SetRange("Document Type", "Document Type");
        TWERentalLine.SetRange("Document No.", "No.");
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();

        case "Document Type" of
            "Document Type"::Contract, "Document Type"::Invoice:
                begin
                    if TWERentalLine.FindSet() then
                        repeat
                            if (TWERentalLine.Type = TWERentalLine.Type::"Rental Item") and (TWERentalLine.Quantity <> 0) then
                                if TWERentalLine."Shipment No." <> '' then begin
                                    RentalShptLine.SetRange("Document No.", TWERentalLine."Shipment No.");
                                    RentalShptLine.SetRange("Line No.", TWERentalLine."Shipment Line No.");
                                end else begin
                                    RentalShptLine.SetCurrentKey("Order No.", "Order Line No.");
                                    RentalShptLine.SetRange("Order No.", TWERentalLine."Document No.");
                                    RentalShptLine.SetRange("Order Line No.", TWERentalLine."Line No.");
                                end;
                            RentalShptLine.SetRange(Correction, false);
                            if QtyType = QtyType::Invoicing then
                                RentalShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');

                            if FindSet() then
                                repeat
                                    RentalShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                    if ItemLedgEntry.FindSet() then
                                        repeat
                                            CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                        until ItemLedgEntry.Next() = 0;
                                until Next() = 0;
                        until TWERentalLine.Next() = 0;
                end;
        //   "Document Type"::"Return Order", "Document Type"::"Credit Memo":
        //       begin
        //          if TWERentalLine.FindSet() then
        //              repeat
        //                  if (TWERentalLine.Type = TWERentalLine.Type::Item) and (TWERentalLine.Quantity <> 0) then
        //                      with ReturnRcptLine do begin
        //                         if TWERentalLine."Return Receipt No." <> '' then begin
        //                             SetRange("Document No.", TWERentalLine."Return Receipt No.");
        //                             SetRange("Line No.", TWERentalLine."Return Receipt Line No.");
        //                         end else begin
        //                             SetCurrentKey("Return Order No.", "Return Order Line No.");
        //                             SetRange("Return Order No.", TWERentalLine."Document No.");
        //                             SetRange("Return Order Line No.", TWERentalLine."Line No.");
        //                         end;
        //                         SetRange(Correction, false);
        //                         if QtyType = QtyType::Invoicing then
        //                             SetFilter("Return Qty. Rcd. Not Invd.", '<>0');

        //                         if FindSet() then
        //                             repeat
        //                                 FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        //                                 if ItemLedgEntry.FindSet() then
        //                                     repeat
        //                                         CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
        //                                     until ItemLedgEntry.Next() = 0;
        //                             until Next() = 0;
        //                     end;
        //           until TWERentalLine.Next() = 0;
        //    end;
        end;
        PAGE.RunModal(0, TempValueEntry);
    end;

    /// <summary>
    /// GetCustomerVATRegistrationNumber.
    /// </summary>
    /// <returns>Return variable ReturnValue of type Text.</returns>
    procedure GetCustomerVATRegistrationNumber() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerVATRegistrationNumber(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit("VAT Registration No.");
    end;

    /// <summary>
    /// GetCustomerVATRegistrationNumberLbl.
    /// </summary>
    /// <returns>Return variable ReturnValue of type Text.</returns>
    procedure GetCustomerVATRegistrationNumberLbl() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerVATRegistrationNumberLbl(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// GetCustomerGlobalLocationNumber.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCustomerGlobalLocationNumber(): Text
    begin
        exit('');
    end;

    /// <summary>
    /// GetCustomerGlobalLocationNumberLbl.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCustomerGlobalLocationNumberLbl(): Text
    begin
        exit('');
    end;

    /// <summary>
    /// GetStatusStyleText.
    /// </summary>
    /// <returns>Return variable StatusStyleText of type Text.</returns>
    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';

        // OnAfterGetStatusStyleText(Rec, StatusStyleText);
    end;

    local procedure CreateTempAdjmtValueEntries(var TempValueEntry: Record "Value Entry" temporary; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ValueEntry.FindSet() then
            repeat
                if ValueEntry.Adjustment then begin
                    TempValueEntry := ValueEntry;
                    if TempValueEntry.Insert() then;
                end;
            until ValueEntry.Next() = 0;
    end;

    /// <summary>
    /// GetPstdDocLinesToReverse.
    /// </summary>
    procedure GetPstdDocLinesToReverse()
    var
        SalesPostedDocLines: Page "Posted Sales Document Lines";
    begin
        GetCust("Rented-to Customer No.");
        // SalesPostedDocLines.SetToTWERentalHeader(Rec);
        SalesPostedDocLines.SetRecord(Cust);
        SalesPostedDocLines.LookupMode := true;
        // if SalesPostedDocLines.RunModal = ACTION::LookupOK then
        //     SalesPostedDocLines.CopyLineToDoc;

        Clear(SalesPostedDocLines);
    end;

    /// <summary>
    /// CalcInvDiscForHeader.
    /// </summary>
    procedure CalcInvDiscForHeader()
    var
        RentalInvDisc: Codeunit "TWE Rental-Calc. Discount";
    begin
        OnBeforeCalcInvDiscForHeader(Rec);

        GetRentalSetup;
        if RentalSetup."Calc. Inv. Discount" then
            RentalInvDisc.CalculateIncDiscForHeader(Rec);
    end;

    /// <summary>
    /// SetSecurityFilterOnRespCenter.
    /// </summary>
    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //  OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if (not IsHandled) and (UserSetupMgt.GetSalesFilter <> '') then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter);
            FilterGroup(0);
        end;

        SetRange("Date Filter", 0D, WorkDate());
    end;

    local procedure SynchronizeForReservations(var NewTWERentalLine: Record "TWE Rental Line"; OldTWERentalLine: Record "TWE Rental Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //OnBeforeSynchronizeForReservations(Rec, NewTWERentalLine, OldTWERentalLine, IsHandled);
        if IsHandled then
            exit;

        NewTWERentalLine.CalcFields("Reserved Quantity");
        if NewTWERentalLine."Reserved Quantity" = 0 then
            exit;
        if NewTWERentalLine."Location Code" <> OldTWERentalLine."Location Code" then
            NewTWERentalLine.Validate("Location Code", OldTWERentalLine."Location Code");
        if NewTWERentalLine."Bin Code" <> OldTWERentalLine."Bin Code" then
            NewTWERentalLine.Validate("Bin Code", OldTWERentalLine."Bin Code");
        if NewTWERentalLine.Modify then;
    end;

    /// <summary>
    /// InventoryPickConflict.
    /// </summary>
    /// <param name="DocType">Enum "TWE Rental Document Type".</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="ShippingAdvice">Enum "Sales Header Shipping Advice".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure InventoryPickConflict(DocType: Enum "TWE Rental Document Type"; DocNo: Code[20];
                                                 ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TWERentalLine: Record "TWE Rental Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"TWE Rental Line");
        WarehouseActivityLine.SetRange("Source Subtype", DocType);
        WarehouseActivityLine.SetRange("Source No.", DocNo);
        if WarehouseActivityLine.IsEmpty then
            exit(false);
        TWERentalLine.SetRange("Document Type", DocType);
        TWERentalLine.SetRange("Document No.", DocNo);
        TWERentalLine.SetRange(Type, TWERentalLine.Type::"Rental Item");
        if TWERentalLine.IsEmpty then
            exit(false);
        exit(true);
    end;

    /// <summary>
    /// WhseShipmentConflict.
    /// </summary>
    /// <param name="DocType">Enum "Sales Document Type".</param>
    /// <param name="DocNo">Code[20].</param>
    /// <param name="ShippingAdvice">Enum "Sales Header Shipping Advice".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure WhseShipmentConflict(DocType: Enum "TWE Rental Document Type"; DocNo: Code[20];
                                                ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"TWE Rental Line");
        WarehouseShipmentLine.SetRange("Source Subtype", DocType);
        WarehouseShipmentLine.SetRange("Source No.", DocNo);
        if WarehouseShipmentLine.IsEmpty then
            exit(false);
        exit(true);
    end;

    local procedure CheckCreditLimit()
    var
        RentalHeader: Record "TWE Rental Header";
        IsHandled: Boolean;
    begin
        RentalHeader := Rec;

        if GuiAllowed and
           (CurrFieldNo <> 0) and CheckCreditLimitCondition and RentalHeader.Find
        then begin
            "Amount Including VAT" := 0;
            if "Document Type" = "Document Type"::Contract then
                if BilltoCustomerNoChanged then begin
                    RentalLine.SetRange("Document Type", RentalLine."Document Type"::Contract);
                    RentalLine.SetRange("Document No.", "No.");
                    RentalLine.CalcSums("Outstanding Amount", "Shipped Not Invoiced");
                    "Amount Including VAT" := RentalLine."Outstanding Amount" + RentalLine."Shipped Not Invoiced";
                end;

            IsHandled := false;
            // OnBeforeCheckCreditLimit(Rec, IsHandled);
            // if not IsHandled then
            //    CustCheckCreditLimit.TWERentalHeaderCheck(Rec);

            CalcFields("Amount Including VAT");
        end;
    end;

    local procedure CheckCreditLimitCondition(): Boolean
    var
        RunCheck: Boolean;
    begin
        RunCheck := ("Document Type".AsInteger() <= "Document Type"::Invoice.AsInteger());
        OnAfterCheckCreditLimitCondition(Rec, RunCheck);
        exit(RunCheck);
    end;

    /// <summary>
    /// CheckItemAvailabilityInLines.
    /// </summary>
    procedure CheckItemAvailabilityInLines()
    var
        TWERentalLine: Record "TWE Rental Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        TWERentalLine.SetRange("Document Type", "Document Type");
        TWERentalLine.SetRange("Document No.", "No.");
        TWERentalLine.SetRange(Type, TWERentalLine.Type::"Rental Item");
        TWERentalLine.SetFilter("No.", '<>%1', '');
        TWERentalLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        OnCheckItemAvailabilityInLinesOnAfterSetFilters(TWERentalLine);
        //  if TWERentalLine.FindSet() then
        //repeat
        //if ItemCheckAvail.TWERentalLineCheck(TWERentalLine) then
        //      ItemCheckAvail.RaiseUpdateInterruptedError();
        // until TWERentalLine.Next() = 0;
    end;

    /// <summary>
    /// QtyToShipIsZero.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure QtyToShipIsZero() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeQtyToShipIsZero(Rec, RentalLine, Result, IsHandled);
        if IsHandled then
            exit;

        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        RentalLine.SetFilter("Qty. to Ship", '<>0');
        Result := RentalLine.IsEmpty();
    end;

    /// <summary>
    /// IsApprovedForPosting.
    /// </summary>
    /// <returns>Return variable Approved of type Boolean.</returns>
    procedure IsApprovedForPosting() Approved: Boolean
    var
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
    begin
        if RentalApprovalsMgmt.PrePostApprovalCheckRental(Rec) then begin
            if RentalPrepaymentMgt.TestRentalPrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if "Document Type" = "Document Type"::Contract then
                if RentalPrepaymentMgt.TestRentalPayment(Rec) then
                    Error(Text072Lbl, "Document Type", "No.");
            Approved := true;
            OnAfterIsApprovedForPosting(Rec, Approved);
        end;
    end;

    /// <summary>
    /// IsApprovedForPostingBatch.
    /// </summary>
    /// <returns>Return variable Approved of type Boolean.</returns>
    procedure IsApprovedForPostingBatch() Approved: Boolean
    begin
        Approved := ApprovedForPostingBatch;
        OnAfterIsApprovedForPostingBatch(Rec, Approved);
    end;

    [TryFunction]
    local procedure ApprovedForPostingBatch()
    var
        RentalPrepaymentMgt: Codeunit "TWE Rental Prepayment Mgt.";
    begin
        if RentalApprovalsMgmt.PrePostApprovalCheckRental(Rec) then begin
            if RentalPrepaymentMgt.TestRentalPrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if RentalPrepaymentMgt.TestRentalPayment(Rec) then
                Error(Text072Lbl, "Document Type", "No.");
        end;
    end;

    /// <summary>
    /// GetLegalStatement.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetLegalStatement(): Text
    begin
        GetRentalSetup;
        //exit(RentalSetup.GetLegalStatement);
    end;

    /// <summary>
    /// SendToPosting.
    /// </summary>
    /// <param name="PostingCodeunitID">Integer.</param>
    /// <returns>Return variable IsSuccess of type Boolean.</returns>
    procedure SendToPosting(PostingCodeunitID: Integer) IsSuccess: Boolean
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        if not IsApprovedForPosting then
            exit;

        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, '');
        IsSuccess := CODEUNIT.Run(PostingCodeunitID, Rec);
        if not IsSuccess then
            ErrorMessageHandler.ShowErrors;
    end;

    /// <summary>
    /// CancelBackgroundPosting.
    /// </summary>
/*     procedure CancelBackgroundPosting()
    var
        RentalPostViaJobQueue: Codeunit "TWE Rental Post Batch VJQ";
    begin
        RentalPostViaJobQueue.CancelQueueEntry(Rec);
    end; */

    /// <summary>
    /// EmailRecords.
    /// </summary>
    /// <param name="ShowDialog">Boolean.</param>
    [Scope('Cloud')]
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyRentalReportSelections: Record "TWE Rental Report Selections";
    begin
        case "Document Type" of
            "Document Type"::Quote:
                begin
                    DocumentSendingProfile.TrySendToEMail(
                      DummyRentalReportSelections.Usage::"R.Quote".AsInteger(), Rec, FieldNo("No."),
                      GetDocTypeTxt, FieldNo("Bill-to Customer No."), ShowDialog);
                    Find;
                    "Quote Sent to Customer" := CurrentDateTime;
                    Modify();
                end;
            "Document Type"::Invoice:
                DocumentSendingProfile.TrySendToEMail(
                  DummyRentalReportSelections.Usage::"Draft R. Invoice".AsInteger(), Rec, FieldNo("No."),
                  GetDocTypeTxt, FieldNo("Bill-to Customer No."), ShowDialog);
        end;

        OnAfterSendTWERentalHeader(Rec, ShowDialog);
    end;

    /// <summary>
    /// GetDocTypeTxt.
    /// </summary>
    /// <returns>Return variable TypeText of type Text[50].</returns>
    procedure GetDocTypeTxt() TypeText: Text[50]
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        TypeText := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        OnAfterGetDocTypeText(Rec, TypeText);
    end;

    /// <summary>
    /// GetFullDocTypeTxt.
    /// </summary>
    /// <returns>Return variable FullDocTypeTxt of type Text.</returns>
    procedure GetFullDocTypeTxt() FullDocTypeTxt: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetFullDocTypeTxt(Rec, FullDocTypeTxt, IsHandled);

        if IsHandled then
            exit;

        FullDocTypeTxt := SelectStr("Document Type".AsInteger() + 1, FullRentalTypesTxt);
    end;

    /// <summary>
    /// LinkSalesDocWithOpportunity.
    /// </summary>
    /// <param name="OldOpportunityNo">Code[20].</param>
    procedure LinkSalesDocWithOpportunity(OldOpportunityNo: Code[20])
    var
        TWERentalHeader: Record "TWE Rental Header";
        Opportunity: Record Opportunity;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Opportunity No." <> OldOpportunityNo then begin
            if "Opportunity No." <> '' then
                if Opportunity.Get("Opportunity No.") then begin
                    Opportunity.TestField(Status, Opportunity.Status::"In Progress");
                    if Opportunity."Sales Document No." <> '' then begin
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text048Lbl, Opportunity."Sales Document No.", Opportunity."No."), true)
                        then begin
                            if TWERentalHeader.Get("Document Type"::Quote, Opportunity."Sales Document No.") then begin
                                TWERentalHeader."Opportunity No." := '';
                                TWERentalHeader.Modify();
                            end;
                            UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::Quote, "No.");
                        end else
                            "Opportunity No." := OldOpportunityNo;
                    end else
                        UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::Quote, "No.");
                end;
            if (OldOpportunityNo <> '') and Opportunity.Get(OldOpportunityNo) then
                UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::" ", '');
        end;
    end;

    local procedure UpdateOpportunityLink(Opportunity: Record Opportunity; SalesDocumentType: Option; TWERentalHeaderNo: Code[20])
    begin
        Opportunity."Sales Document Type" := SalesDocumentType;
        Opportunity."Sales Document No." := TWERentalHeaderNo;
        Opportunity.Modify();
    end;

    /// <summary>
    /// SynchronizeAsmHeader.
    /// </summary>
    procedure SynchronizeAsmHeader()
    var
        AsmHeader: Record "Assembly Header";
        ATOLink: Record "Assemble-to-Order Link";
        Window: Dialog;
    begin
        ATOLink.SetCurrentKey(Type, "Document Type", "Document No.");
        ATOLink.SetRange(Type, ATOLink.Type::Sale);
        ATOLink.SetRange("Document Type", "Document Type");
        ATOLink.SetRange("Document No.", "No.");
        if ATOLink.FindSet() then
            repeat
                if AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.") then
                    if "Posting Date" <> AsmHeader."Posting Date" then begin
                        Window.Open(StrSubstNo(SynchronizingMsg, "No.", AsmHeader."No."));
                        AsmHeader.Validate("Posting Date", "Posting Date");
                        AsmHeader.Modify();
                        Window.Close();
                    end;
            until ATOLink.Next() = 0;
    end;

    local procedure GetContactAsCompany(Contact: Record Contact; var SearchContact: Record Contact): Boolean;
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetContactAsCompany(Contact, SearchContact, IsHandled);
        if not IsHandled then
            if Contact."Company No." <> '' then
                exit(SearchContact.Get(Contact."Company No."));
    end;

    local procedure GetFilterCustNo(): Code[20]
    var
        MinValue: Code[20];
        MaxValue: Code[20];
    begin
        if GetFilter("Rented-to Customer No.") <> '' then begin
            if TryGetFilterCustNoRange(MinValue, MaxValue) then
                if MinValue = MaxValue then
                    exit(MaxValue);
        end;
    end;

    [TryFunction]
    local procedure TryGetFilterCustNoRange(var MinValue: Code[20]; var MaxValue: Code[20])
    begin
        MinValue := GetRangeMin("Rented-to Customer No.");
        MaxValue := GetRangeMax("Rented-to Customer No.");
    end;

    local procedure GetFilterCustNoByApplyingFilter(): Code[20]
    var
        TWERentalHeader: Record "TWE Rental Header";
        MinValue: Code[20];
        MaxValue: Code[20];
    begin
        if GetFilter("Rented-to Customer No.") <> '' then begin
            TWERentalHeader.CopyFilters(Rec);
            TWERentalHeader.SetCurrentKey("Rented-to Customer No.");
            if TWERentalHeader.FindFirst() then
                MinValue := TWERentalHeader."Rented-to Customer No.";
            if TWERentalHeader.FindLast() then
                MaxValue := TWERentalHeader."Rented-to Customer No.";
            if MinValue = MaxValue then
                exit(MaxValue);
        end;
    end;

    local procedure GetFilterContNo(): Code[20]
    begin
        if GetFilter("Rented-to Contact No.") <> '' then
            if GetRangeMin("Rented-to Contact No.") = GetRangeMax("Rented-to Contact No.") then
                exit(GetRangeMax("Rented-to Contact No."));
    end;

    local procedure CheckCreditLimitIfLineNotInsertedYet()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckCreditLimitIfLineNotInsertedYet(Rec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            HideCreditCheckDialogue := false;
            CheckCreditMaxBeforeInsert;
            HideCreditCheckDialogue := true;
        end;
    end;

    /// <summary>
    /// InvoicedLineExists.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure InvoicedLineExists(): Boolean
    var
        TWERentalLine: Record "TWE Rental Line";
    begin
        TWERentalLine.SetRange("Document Type", "Document Type");
        TWERentalLine.SetRange("Document No.", "No.");
        TWERentalLine.SetFilter(Type, '<>%1', TWERentalLine.Type::" ");
        TWERentalLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        exit(not TWERentalLine.IsEmpty);
    end;

    /// <summary>
    /// CreateDimSetForPrepmtAccDefaultDim.
    /// </summary>
    procedure CreateDimSetForPrepmtAccDefaultDim()
    var
        TWERentalLine: Record "TWE Rental Line";
        TempTWERentalLine: Record "TWE Rental Line" temporary;
    begin
        TWERentalLine.SetRange("Document Type", "Document Type");
        TWERentalLine.SetRange("Document No.", "No.");
        TWERentalLine.SetFilter("Prepmt. Amt. Inv.", '<>%1', 0);
        if TWERentalLine.FindSet() then
            repeat
                CollectParamsInBufferForCreateDimSet(TempTWERentalLine, TWERentalLine);
            until TWERentalLine.Next() = 0;
        TempTWERentalLine.Reset();
    end;

    local procedure CollectParamsInBufferForCreateDimSet(var TempTWERentalLine: Record "TWE Rental Line" temporary; TWERentalLine: Record "TWE Rental Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        TempTWERentalLine.SetRange("Gen. Bus. Posting Group", TWERentalLine."Gen. Bus. Posting Group");
        TempTWERentalLine.SetRange("Gen. Prod. Posting Group", TWERentalLine."Gen. Prod. Posting Group");
        if not TempTWERentalLine.FindFirst() then begin
            GenPostingSetup.Get(TWERentalLine."Gen. Bus. Posting Group", TWERentalLine."Gen. Prod. Posting Group");
            DefaultDimension.SetRange("Table ID", DATABASE::"G/L Account");
            DefaultDimension.SetRange("No.", GenPostingSetup.GetSalesPrepmtAccount);
            OnCollectParamsInBufferForCreateDimSetOnBeforeInsertTempTWERentalLineInBuffer(GenPostingSetup, DefaultDimension);
            InsertTempTWERentalLineInBuffer(TempTWERentalLine, TWERentalLine, GenPostingSetup."Sales Prepayments Account", DefaultDimension.IsEmpty);
        end else
            if not TempTWERentalLine.Mark then begin
                TempTWERentalLine.SetRange("Responsibility Center", TWERentalLine."Responsibility Center");
                OnCollectParamsInBufferForCreateDimSetOnAfterSetTempTWERentalLineFilters(TempTWERentalLine, TWERentalLine);
                if TempTWERentalLine.IsEmpty() then
                    InsertTempTWERentalLineInBuffer(TempTWERentalLine, TWERentalLine, TempTWERentalLine."No.", false);
            end;
    end;

    local procedure InsertTempTWERentalLineInBuffer(var TempTWERentalLine: Record "TWE Rental Line" temporary; TWERentalLine: Record "TWE Rental Line"; AccountNo: Code[20]; DefaultDimensionsNotExist: Boolean)
    begin
        TempTWERentalLine.Init();
        TempTWERentalLine."Line No." := TWERentalLine."Line No.";
        TempTWERentalLine."No." := AccountNo;
        TempTWERentalLine."Responsibility Center" := TWERentalLine."Responsibility Center";
        TempTWERentalLine."Gen. Bus. Posting Group" := TWERentalLine."Gen. Bus. Posting Group";
        TempTWERentalLine."Gen. Prod. Posting Group" := TWERentalLine."Gen. Prod. Posting Group";
        TempTWERentalLine.Mark := DefaultDimensionsNotExist;
        OnInsertTempTWERentalLineInBufferOnBeforeTempTWERentalLineInsert(TempTWERentalLine, TWERentalLine);
        TempTWERentalLine.Insert();
    end;

    /// <summary>
    /// OpenRentalOrderStatistics.
    /// </summary>
    procedure OpenRentalContractStatistics()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenRentalContractStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcInvDiscForHeader;
        CreateDimSetForPrepmtAccDefaultDim;
        Commit();
        PAGE.RunModal(PAGE::"Sales Order Statistics", Rec);
    end;

    /// <summary>
    /// GetCardpageID.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    procedure GetCardpageID(): Integer
    begin
        case "Document Type" of
            "Document Type"::Quote:
                exit(PAGE::"TWE Rental Quote");
            "Document Type"::Contract:
                exit(PAGE::"TWE Rental Contract");
            "Document Type"::Invoice:
                exit(PAGE::"TWE Rental Invoice");
            "Document Type"::"Credit Memo":
                exit(PAGE::"TWE Rental Credit Memo");
            "Document Type"::"Return Shipment":
                exit(PAGE::"TWE Rental Return Shipment");
        end;
    end;

    /// <summary>
    /// CheckAvailableCreditLimit.
    /// </summary>
    /// <returns>Return variable ReturnValue of type Decimal.</returns>
    procedure CheckAvailableCreditLimit() ReturnValue: Decimal
    var
        Customer: Record Customer;
        AvailableCreditLimit: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckAvailableCreditLimit(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if ("Bill-to Customer No." = '') and ("Rented-to Customer No." = '') then
            exit(0);

        if not Customer.Get("Bill-to Customer No.") then
            Customer.Get("Rented-to Customer No.");

        AvailableCreditLimit := Customer.CalcAvailableCredit;

        if AvailableCreditLimit < 0 then
            CustomerCreditLimitExceeded()
        else
            CustomerCreditLimitNotExceeded();

        exit(AvailableCreditLimit);
    end;

    /// <summary>
    /// SetStatus.
    /// </summary>
    /// <param name="NewStatus">Option.</param>
    procedure SetStatus(NewStatus: Option)
    begin
        Status := "Sales Document Status".FromInteger(NewStatus);
        Modify();
    end;

    local procedure TestTWERentalLineFieldsBeforeRecreate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestTWERentalLineFieldsBeforeRecreate(Rec, IsHandled, RentalLine);
        if IsHandled then
            exit;

        RentalLine.TestField("Quantity Invoiced", 0);
        RentalLine.TestField("Shipment No.", '');
        RentalLine.TestField("Return Receipt No.", '');
        RentalLine.TestField("Prepmt. Amt. Inv.", 0);
        //TestQuantityShippedField(RentalLine);
    end;

    local procedure RecreateReservEntryReqLine(var TempTWERentalLine: Record "TWE Rental Line" temporary; var TempATOLink: Record "Assemble-to-Order Link" temporary; var ATOLink: Record "Assemble-to-Order Link")
    begin
        repeat
            TestTWERentalLineFieldsBeforeRecreate;
            if (RentalLine."Location Code" <> "Location Code") and (not RentalLine.IsNonInventoriableMainRentalItem) then
                RentalLine.Validate("Location Code", "Location Code");
            TempTWERentalLine := RentalLine;
            if RentalLine.Nonstock then begin
                RentalLine.Nonstock := false;
                RentalLine.Modify();
            end;

            // if ATOLink.AsmExistsForTWERentalLine(TempTWERentalLine) then begin
            //     TempATOLink := ATOLink;
            //     TempATOLink.Insert();
            //    ATOLink.Delete();
            // end;

            TempTWERentalLine.Insert();
            OnAfterInsertTempTWERentalLine(RentalLine, TempTWERentalLine);
            // TWERentalLineReserve.CopyReservEntryToTemp(TempReservEntry, TWERentalLine);
            RecreateReqLine(RentalLine, 0, true);
            OnRecreateReservEntryReqLineOnAfterLoop(Rec);
        until RentalLine.Next() = 0;
    end;

    local procedure TransferItemChargeAssgntSalesToTemp(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "No.");
        if ItemChargeAssgntSales.FindSet() then begin
            repeat
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssgntSales;
                TempItemChargeAssgntSales.Insert();
            until ItemChargeAssgntSales.Next() = 0;
            ItemChargeAssgntSales.DeleteAll();
        end;
    end;

    local procedure CreateTWERentalLine(var TempTWERentalLine: Record "TWE Rental Line" temporary)
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateTWERentalLine(TempTWERentalLine, IsHandled);
        if IsHandled then
            exit;

        RentalLine.Init();
        RentalLine."Line No." := RentalLine."Line No." + 10000;
        RentalLine."Price Calculation Method" := "Price Calculation Method";
        RentalLine.Validate(Type, TempTWERentalLine.Type);
        OnCreateTWERentalLineOnAfterAssignType(RentalLine, TempTWERentalLine);
        if TempTWERentalLine."No." = '' then begin
            RentalLine.Validate(Description, TempTWERentalLine.Description);
            RentalLine.Validate("Description 2", TempTWERentalLine."Description 2");
        end else begin
            RentalLine.Validate("No.", TempTWERentalLine."No.");
            if RentalLine.Type <> RentalLine.Type::" " then begin
                RentalLine.Validate("Unit of Measure Code", TempTWERentalLine."Unit of Measure Code");
                RentalLine.Validate("Variant Code", TempTWERentalLine."Variant Code");
                if TempTWERentalLine.Quantity <> 0 then begin
                    RentalLine.Validate(Quantity, TempTWERentalLine.Quantity);
                    RentalLine.Validate("Qty. to Assemble to Order", TempTWERentalLine."Qty. to Assemble to Order");
                end;
                RentalLine."Purchase Order No." := TempTWERentalLine."Purchase Order No.";
                RentalLine."Purch. Order Line No." := TempTWERentalLine."Purch. Order Line No.";
                RentalLine."Drop Shipment" := TempTWERentalLine."Drop Shipment";
            end;
            RentalLine.Validate("Shipment Date", TempTWERentalLine."Shipment Date");
        end;
        //  OnBeforeTWERentalLineInsert(RentalLine, TempTWERentalLine, Rec);
        RentalLine.Insert();
        OnAfterCreateTWERentalLine(RentalLine, TempTWERentalLine);
    end;

    local procedure UpdateOutboundWhseHandlingTime()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //   OnBeforeUpdateOutboundWhseHandlingTime(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Location Code" <> '' then begin
            if Location.Get("Location Code") then
                "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
        end else
            if InvtSetup.Get then
                "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
    end;

    /// <summary>
    /// CheckRentalPostRestrictions.
    /// </summary>
    [IntegrationEvent(TRUE, false)]
    procedure OnCheckRentalPostRestrictions()
    begin
    end;

    /// <summary>
    /// CheckRentalPostRestrictions.
    /// </summary>
    procedure CheckRentalPostRestrictions()
    begin
        OnCheckRentalPostRestrictions();
    end;

    /// <summary>
    /// OnCustomerCreditLimitExceeded.
    /// </summary>
    /// <param name="NotificationId">Guid.</param>
    [IntegrationEvent(TRUE, false)]
    procedure OnCustomerCreditLimitExceeded(NotificationId: Guid)
    begin
    end;

    /// <summary>
    /// CustomerCreditLimitExceeded.
    /// </summary>
    procedure CustomerCreditLimitExceeded()
    var
        NotificationId: Guid;
    begin
        OnCustomerCreditLimitExceeded(NotificationId);
    end;

    /// <summary>
    /// CustomerCreditLimitExceeded.
    /// </summary>
    /// <param name="NotificationId">Guid.</param>
    procedure CustomerCreditLimitExceeded(NotificationId: Guid)
    begin
        OnCustomerCreditLimitExceeded(NotificationId);
    end;

    /// <summary>
    /// OnCustomerCreditLimitNotExceeded.
    /// </summary>
    [IntegrationEvent(TRUE, false)]
    procedure OnCustomerCreditLimitNotExceeded()
    begin
    end;

    /// <summary>
    /// CustomerCreditLimitNotExceeded.
    /// </summary>
    procedure CustomerCreditLimitNotExceeded()
    begin
        OnCustomerCreditLimitNotExceeded();
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCheckSalesReleaseRestrictions()
    begin
    end;

    /// <summary>
    /// CheckSalesReleaseRestrictions.
    /// </summary>
    procedure CheckSalesReleaseRestrictions()
    var
        RentalApprovalsMgmt: Codeunit "TWE Rental Approvals Mgmt.";
    begin
        OnCheckSalesReleaseRestrictions;
        //ApprovalsMgmt.PrePostApprovalCheckSales(Rec);
    end;

    /// <summary>
    /// DeferralHeadersExist.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure DeferralHeadersExist(): Boolean
    var
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralHeader.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralHeader.SetRange("Gen. Jnl. Template Name", '');
        DeferralHeader.SetRange("Gen. Jnl. Batch Name", '');
        DeferralHeader.SetRange("Document Type", "Document Type");
        DeferralHeader.SetRange("Document No.", "No.");
        exit(not DeferralHeader.IsEmpty);
    end;

    /// <summary>
    /// SetSellToCustomerFromFilter.
    /// </summary>
    procedure SetSellToCustomerFromFilter()
    var
        SellToCustomerNo: Code[20];
    begin
        SellToCustomerNo := GetFilterCustNo;
        if SellToCustomerNo = '' then begin
            FilterGroup(2);
            SellToCustomerNo := GetFilterCustNo;
            if SellToCustomerNo = '' then
                SellToCustomerNo := GetFilterCustNoByApplyingFilter;
            FilterGroup(0);
        end;
        if SellToCustomerNo <> '' then
            Validate("Rented-to Customer No.", SellToCustomerNo);

        // OnAfterSetSellToCustomerFromFilter(Rec);
    end;

    /// <summary>
    /// CopySellToCustomerFilter.
    /// </summary>
    procedure CopySellToCustomerFilter()
    var
        SellToCustomerFilter: Text;
    begin
        SellToCustomerFilter := GetFilter("Rented-to Customer No.");
        if SellToCustomerFilter <> '' then begin
            FilterGroup(2);
            SetFilter("Rented-to Customer No.", SellToCustomerFilter);
            FilterGroup(0)
        end;
    end;

    local procedure ConfirmUpdateDeferralDate()
    begin
        if GetHideValidationDialog or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(DeferralLineQst, false);
        if Confirmed then
            UpdateTWERentalLinesByFieldNo(RentalLine.FieldNo("Deferral Code"), false);
    end;

    /// <summary>
    /// BatchConfirmUpdateDeferralDate.
    /// </summary>
    /// <param name="BatchConfirm">VAR Option " ",Skip,Update.</param>
    /// <param name="ReplacePostingDate">Boolean.</param>
    /// <param name="PostingDateReq">Date.</param>
    procedure BatchConfirmUpdateDeferralDate(var BatchConfirm: Option " ",Skip,Update; ReplacePostingDate: Boolean; PostingDateReq: Date)
    begin
        if (not ReplacePostingDate) or (PostingDateReq = "Posting Date") or (BatchConfirm = BatchConfirm::Skip) then
            exit;

        if not DeferralHeadersExist then
            exit;

        "Posting Date" := PostingDateReq;
        case BatchConfirm of
            BatchConfirm::" ":
                begin
                    ConfirmUpdateDeferralDate;
                    if Confirmed then
                        BatchConfirm := BatchConfirm::Update
                    else
                        BatchConfirm := BatchConfirm::Skip;
                end;
            BatchConfirm::Update:
                UpdateTWERentalLinesByFieldNo(RentalLine.FieldNo("Deferral Code"), false);
        end;
        Commit();
    end;

    /// <summary>
    /// GetSelectedPaymentServicesText.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetSelectedPaymentServicesText(): Text
    var
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        exit(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

    /// <summary>
    /// SetDefaultPaymentServices.
    /// </summary>
    procedure SetDefaultPaymentServices()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        if not PaymentServiceSetup.CanChangePaymentService(Rec) then
            exit;

        if PaymentServiceSetup.GetDefaultPaymentServices(SetID) then
            Validate("Payment Service Set ID", SetID);
    end;

    /// <summary>
    /// ChangePaymentServiceSetting.
    /// </summary>
    procedure ChangePaymentServiceSetting()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        SetID := "Payment Service Set ID";
        if PaymentServiceSetup.SelectPaymentService(SetID) then begin
            Validate("Payment Service Set ID", SetID);
            Modify(true);
        end;
    end;

    /// <summary>
    /// IsCreditDocType.
    /// </summary>
    /// <returns>Return variable CreditDocType of type Boolean.</returns>
    procedure IsCreditDocType() CreditDocType: Boolean
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Shipment", "Document Type"::"Credit Memo"];
        OnBeforeIsCreditDocType(Rec, CreditDocType);
    end;

    /// <summary>
    /// HasSellToAddress.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasSellToAddress(): Boolean
    begin
        case true of
            "Rented-to Address" <> '':
                exit(true);
            "Rented-to Address 2" <> '':
                exit(true);
            "Rented-to City" <> '':
                exit(true);
            "Rented-to Country/Region Code" <> '':
                exit(true);
            "Rented-to County" <> '':
                exit(true);
            "Rented-to Post Code" <> '':
                exit(true);
            "Rented-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// HasShipToAddress.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasShipToAddress(): Boolean
    begin
        case true of
            "Ship-to Address" <> '':
                exit(true);
            "Ship-to Address 2" <> '':
                exit(true);
            "Ship-to City" <> '':
                exit(true);
            "Ship-to Country/Region Code" <> '':
                exit(true);
            "Ship-to County" <> '':
                exit(true);
            "Ship-to Post Code" <> '':
                exit(true);
            "Ship-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// HasBillToAddress.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasBillToAddress(): Boolean
    begin
        case true of
            "Bill-to Address" <> '':
                exit(true);
            "Bill-to Address 2" <> '':
                exit(true);
            "Bill-to City" <> '':
                exit(true);
            "Bill-to Country/Region Code" <> '':
                exit(true);
            "Bill-to County" <> '':
                exit(true);
            "Bill-to Post Code" <> '':
                exit(true);
            "Bill-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    local procedure HasItemChargeAssignment(): Boolean
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "No.");
        ItemChargeAssgntSales.SetFilter("Amount to Assign", '<>%1', 0);
        exit(not ItemChargeAssgntSales.IsEmpty);
    end;

    local procedure CopySellToCustomerAddressFieldsFromCustomer(var SellToCustomer: Record Customer)
    begin
        "Rented-to Cust. Templ Code" := '';
        "Rented-to Customer Name" := Cust.Name;
        "Rented-to Customer Name 2" := Cust."Name 2";
        "Rented-to Phone No." := Cust."Phone No.";
        "Rented-to E-Mail" := Cust."E-Mail";
        if SellToCustomerIsReplaced or ShouldCopyAddressFromSellToCustomer(SellToCustomer) then begin
            "Rented-to Address" := SellToCustomer.Address;
            "Rented-to Address 2" := SellToCustomer."Address 2";
            "Rented-to City" := SellToCustomer.City;
            "Rented-to Post Code" := SellToCustomer."Post Code";
            "Rented-to County" := SellToCustomer.County;
            "Rented-to Country/Region Code" := SellToCustomer."Country/Region Code";
        end;
        if not SkipSellToContact then
            "Rented-to Contact" := SellToCustomer.Contact;
        "Gen. Bus. Posting Group" := SellToCustomer."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SellToCustomer."VAT Bus. Posting Group";
        "Tax Area Code" := SellToCustomer."Tax Area Code";
        "Tax Liable" := SellToCustomer."Tax Liable";
        "VAT Registration No." := SellToCustomer."VAT Registration No.";
        "VAT Country/Region Code" := SellToCustomer."Country/Region Code";
        "Shipping Advice" := SellToCustomer."Shipping Advice";
        "Responsibility Center" := UserSetupMgt.GetRespCenter(0, SellToCustomer."Responsibility Center");
        //    OnCopySelltoCustomerAddressFieldsFromCustomerOnAfterAssignRespCenter(Rec, SellToCustomer, CurrFieldNo);
        UpdateLocationCode(SellToCustomer."Location Code");

        //  OnAfterCopySellToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, CurrFieldNo, SkipBillToContact);
    end;

    local procedure CopyShipToCustomerAddressFieldsFromCust(var SellToCustomer: Record Customer)
    var
        SellToCustTemplate: Record "Customer Templ.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //    OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, IsHandled);
        if IsHandled then
            exit;

        "Ship-to Name" := Cust.Name;
        "Ship-to Name 2" := Cust."Name 2";
        if SellToCustomerIsReplaced or ShipToAddressEqualsOldSellToAddress then begin
            "Ship-to Address" := SellToCustomer.Address;
            "Ship-to Address 2" := SellToCustomer."Address 2";
            "Ship-to City" := SellToCustomer.City;
            "Ship-to Post Code" := SellToCustomer."Post Code";
            "Ship-to County" := SellToCustomer.County;
            Validate("Ship-to Country/Region Code", SellToCustomer."Country/Region Code");
        end;
        "Ship-to Contact" := Cust.Contact;
        if Cust."Shipment Method Code" <> '' then
            Validate("Shipment Method Code", Cust."Shipment Method Code");
        if not SellToCustTemplate.Get("Rented-to Cust. Templ Code") then begin
            "Tax Area Code" := Cust."Tax Area Code";
            "Tax Liable" := Cust."Tax Liable";
        end;
        SetCustomerLocationCode();
        "Shipping Agent Code" := Cust."Shipping Agent Code";
        "Shipping Agent Service Code" := Cust."Shipping Agent Service Code";

        //   OnAfterCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer);
    end;

    local procedure SetCustomerLocationCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeSetCustomerLocationCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if Cust."Location Code" <> '' then
            Validate("Location Code", Cust."Location Code");
    end;

    /// <summary>
    /// SetShipToCustomerAddressFieldsFromShipToAddr.
    /// </summary>
    /// <param name="ShipToAddr">Record "Ship-to Address".</param>
    procedure SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr: Record "Ship-to Address")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr, IsHandled);
        if IsHandled then
            exit;

        "Ship-to Name" := ShipToAddr.Name;
        "Ship-to Name 2" := ShipToAddr."Name 2";
        "Ship-to Address" := ShipToAddr.Address;
        "Ship-to Address 2" := ShipToAddr."Address 2";
        "Ship-to City" := ShipToAddr.City;
        "Ship-to Post Code" := ShipToAddr."Post Code";
        "Ship-to County" := ShipToAddr.County;
        Validate("Ship-to Country/Region Code", ShipToAddr."Country/Region Code");
        "Ship-to Contact" := ShipToAddr.Contact;
        if ShipToAddr."Shipment Method Code" <> '' then
            Validate("Shipment Method Code", ShipToAddr."Shipment Method Code");
        if ShipToAddr."Location Code" <> '' then
            Validate("Location Code", ShipToAddr."Location Code");
        "Shipping Agent Code" := ShipToAddr."Shipping Agent Code";
        "Shipping Agent Service Code" := ShipToAddr."Shipping Agent Service Code";
        if ShipToAddr."Tax Area Code" <> '' then
            "Tax Area Code" := ShipToAddr."Tax Area Code";
        "Tax Liable" := ShipToAddr."Tax Liable";

        //  OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr);
    end;

    /// <summary>
    /// SetBillToCustomerAddressFieldsFromCustomer.
    /// </summary>
    /// <param name="BillToCustomer">VAR Record Customer.</param>
    procedure SetBillToCustomerAddressFieldsFromCustomer(var BillToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetBillToCustomerAddressFieldsFromCustomer(Rec, BillToCustomer, SkipBillToContact, IsHandled);
        if IsHandled then
            exit;

        "Bill-to Customer Template Code" := '';
        "Bill-to Name" := BillToCustomer.Name;
        "Bill-to Name 2" := BillToCustomer."Name 2";
        if BillToCustomerIsReplaced or ShouldCopyAddressFromBillToCustomer(BillToCustomer) then begin
            "Bill-to Address" := BillToCustomer.Address;
            "Bill-to Address 2" := BillToCustomer."Address 2";
            "Bill-to City" := BillToCustomer.City;
            "Bill-to Post Code" := BillToCustomer."Post Code";
            "Bill-to County" := BillToCustomer.County;
            "Bill-to Country/Region Code" := BillToCustomer."Country/Region Code";
        end;
        if not SkipBillToContact then
            "Bill-to Contact" := BillToCustomer.Contact;
        "Payment Terms Code" := BillToCustomer."Payment Terms Code";
        "Prepmt. Payment Terms Code" := BillToCustomer."Payment Terms Code";

        //if "Document Type" in ["Document Type"::"Credit Memo", "Document Type"::"Return Order"] then begin
        //    "Payment Method Code" := '';
        //    if PaymentTerms.Get("Payment Terms Code") then
        //        if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
        //            "Payment Method Code" := BillToCustomer."Payment Method Code"
        //end else
        //    "Payment Method Code" := BillToCustomer."Payment Method Code";

        GLSetup.Get();
        if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then begin
            "VAT Bus. Posting Group" := BillToCustomer."VAT Bus. Posting Group";
            "VAT Country/Region Code" := BillToCustomer."Country/Region Code";
            "VAT Registration No." := BillToCustomer."VAT Registration No.";
            "Gen. Bus. Posting Group" := BillToCustomer."Gen. Bus. Posting Group";
        end;
        "Customer Posting Group" := BillToCustomer."Customer Posting Group";
        "Currency Code" := BillToCustomer."Currency Code";
        "Customer Price Group" := BillToCustomer."Customer Price Group";
        "Prices Including VAT" := BillToCustomer."Prices Including VAT";
        "Price Calculation Method" := Cust.GetPriceCalculationMethod();
        "Allow Line Disc." := BillToCustomer."Allow Line Disc.";
        "Invoice Disc. Code" := BillToCustomer."Invoice Disc. Code";
        "Customer Disc. Group" := BillToCustomer."Customer Disc. Group";
        "Language Code" := BillToCustomer."Language Code";
        SetSalespersonCode(BillToCustomer."Salesperson Code", "Salesperson Code");
        "Combine Shipments" := BillToCustomer."Combine Shipments";
        Reserve := BillToCustomer.Reserve;
        if "Document Type" = "Document Type"::Contract then
            "Prepayment %" := BillToCustomer."Prepayment %";
        "Tax Area Code" := BillToCustomer."Tax Area Code";
        "Tax Liable" := BillToCustomer."Tax Liable";

        OnAfterSetFieldsBilltoCustomer(Rec, BillToCustomer);
    end;

    /// <summary>
    /// SetShipToAddress.
    /// </summary>
    /// <param name="ShipToName">Text[100].</param>
    /// <param name="ShipToName2">Text[50].</param>
    /// <param name="ShipToAddress">Text[100].</param>
    /// <param name="ShipToAddress2">Text[50].</param>
    /// <param name="ShipToCity">Text[30].</param>
    /// <param name="ShipToPostCode">Code[20].</param>
    /// <param name="ShipToCounty">Text[30].</param>
    /// <param name="ShipToCountryRegionCode">Code[10].</param>
    procedure SetShipToAddress(ShipToName: Text[100]; ShipToName2: Text[50]; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        "Ship-to Name" := ShipToName;
        "Ship-to Name 2" := ShipToName2;
        "Ship-to Address" := ShipToAddress;
        "Ship-to Address 2" := ShipToAddress2;
        "Ship-to City" := ShipToCity;
        "Ship-to Post Code" := ShipToPostCode;
        "Ship-to County" := ShipToCounty;
        "Ship-to Country/Region Code" := ShipToCountryRegionCode;
    end;

    local procedure ShouldCopyAddressFromSellToCustomer(SellToCustomer: Record Customer): Boolean
    begin
        exit((not HasSellToAddress) and SellToCustomer.HasAddress);
    end;

    local procedure ShouldCopyAddressFromBillToCustomer(BillToCustomer: Record Customer): Boolean
    begin
        exit((not HasBillToAddress) and BillToCustomer.HasAddress);
    end;

    local procedure SellToCustomerIsReplaced(): Boolean
    begin
        exit((xRec."Rented-to Customer No." <> '') and (xRec."Rented-to Customer No." <> "Rented-to Customer No."));
    end;

    local procedure BillToCustomerIsReplaced(): Boolean
    begin
        exit((xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> "Bill-to Customer No."));
    end;

    local procedure UpdateShipToAddressFromSellToAddress(FieldNumber: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeUpdateShipToAddressFromSellToAddress(Rec, FieldNumber, IsHandled);
        if IsHandled then
            exit;

        if ("Ship-to Code" = '') and ShipToAddressEqualsOldSellToAddress then
            case FieldNumber of
                FieldNo("Ship-to Address"):
                    "Ship-to Address" := "Rented-to Address";
                FieldNo("Ship-to Address 2"):
                    "Ship-to Address 2" := "Rented-to Address 2";
                FieldNo("Ship-to City"), FieldNo("Ship-to Post Code"):
                    begin
                        "Ship-to City" := "Rented-to City";
                        "Ship-to Post Code" := "Rented-to Post Code";
                        "Ship-to County" := "Rented-to County";
                        "Ship-to Country/Region Code" := "Rented-to Country/Region Code";
                    end;
                FieldNo("Ship-to County"):
                    "Ship-to County" := "Rented-to County";
                FieldNo("Ship-to Country/Region Code"):
                    "Ship-to Country/Region Code" := "Rented-to Country/Region Code";
            end;

        //  OnAfterUpdateShipToAddressFromSellToAddress(Rec, xRec, FieldNumber);
    end;

    local procedure ShipToAddressEqualsOldSellToAddress(): Boolean
    begin
        //  exit(IsShipToAddressEqualToSellToAddress(xRec, Rec));
    end;

    /// <summary>
    /// ShipToAddressEqualsSellToAddress.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ShipToAddressEqualsSellToAddress(): Boolean
    begin
        // exit(IsShipToAddressEqualToSellToAddress(Rec, Rec));
    end;

    local procedure IsShipToAddressEqualToSellToAddress(TWERentalHeaderWithSellTo: Record "TWE Rental Header"; TWERentalHeaderWithShipTo: Record "TWE Rental Header"): Boolean
    var
        Result: Boolean;
    begin
        Result :=
          (TWERentalHeaderWithSellTo."Rented-to Address" = TWERentalHeaderWithShipTo."Ship-to Address") and
          (TWERentalHeaderWithSellTo."Rented-to Address 2" = TWERentalHeaderWithShipTo."Ship-to Address 2") and
          (TWERentalHeaderWithSellTo."Rented-to City" = TWERentalHeaderWithShipTo."Ship-to City") and
          (TWERentalHeaderWithSellTo."Rented-to County" = TWERentalHeaderWithShipTo."Ship-to County") and
          (TWERentalHeaderWithSellTo."Rented-to Post Code" = TWERentalHeaderWithShipTo."Ship-to Post Code") and
          (TWERentalHeaderWithSellTo."Rented-to Country/Region Code" = TWERentalHeaderWithShipTo."Ship-to Country/Region Code") and
          (TWERentalHeaderWithSellTo."Rented-to Contact" = TWERentalHeaderWithShipTo."Ship-to Contact");

        //OnAfterIsShipToAddressEqualToSellToAddress(TWERentalHeaderWithSellTo, TWERentalHeaderWithShipTo, Result);
        exit(Result);
    end;

    /// <summary>
    /// BillToAddressEqualsSellToAddress.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure BillToAddressEqualsSellToAddress(): Boolean
    begin
        // exit(IsBillToAddressEqualToSellToAddress(Rec, Rec));
    end;

    local procedure IsBillToAddressEqualToSellToAddress(TWERentalHeaderWithSellTo: Record "TWE Rental Header"; TWERentalHeaderWithBillTo: Record "TWE Rental Header"): Boolean
    begin
        if (TWERentalHeaderWithSellTo."Rented-to Address" = TWERentalHeaderWithBillTo."Bill-to Address") and
           (TWERentalHeaderWithSellTo."Rented-to Address 2" = TWERentalHeaderWithBillTo."Bill-to Address 2") and
           (TWERentalHeaderWithSellTo."Rented-to City" = TWERentalHeaderWithBillTo."Bill-to City") and
           (TWERentalHeaderWithSellTo."Rented-to County" = TWERentalHeaderWithBillTo."Bill-to County") and
           (TWERentalHeaderWithSellTo."Rented-to Post Code" = TWERentalHeaderWithBillTo."Bill-to Post Code") and
           (TWERentalHeaderWithSellTo."Rented-to Country/Region Code" = TWERentalHeaderWithBillTo."Bill-to Country/Region Code") and
           (TWERentalHeaderWithSellTo."Rented-to Contact No." = TWERentalHeaderWithBillTo."Bill-to Contact No.") and
           (TWERentalHeaderWithSellTo."Rented-to Contact" = TWERentalHeaderWithBillTo."Bill-to Contact")
        then
            exit(true);
    end;

    /// <summary>
    /// CopySellToAddressToShipToAddress.
    /// </summary>
    procedure CopySellToAddressToShipToAddress()
    begin
        "Ship-to Address" := "Rented-to Address";
        "Ship-to Address 2" := "Rented-to Address 2";
        "Ship-to City" := "Rented-to City";
        "Ship-to Contact" := "Rented-to Contact";
        "Ship-to Country/Region Code" := "Rented-to Country/Region Code";
        "Ship-to County" := "Rented-to County";
        "Ship-to Post Code" := "Rented-to Post Code";

        // OnAfterCopySellToAddressToShipToAddress(Rec);
    end;

    /// <summary>
    /// CopySellToAddressToBillToAddress.
    /// </summary>
    procedure CopySellToAddressToBillToAddress()
    begin
        if "Bill-to Customer No." = "Rented-to Customer No." then begin
            "Bill-to Address" := "Rented-to Address";
            "Bill-to Address 2" := "Rented-to Address 2";
            "Bill-to Post Code" := "Rented-to Post Code";
            "Bill-to Country/Region Code" := "Rented-to Country/Region Code";
            "Bill-to City" := "Rented-to City";
            "Bill-to County" := "Rented-to County";
            // OnAfterCopySellToAddressToBillToAddress(Rec);
        end;
    end;

    local procedure UpdateShipToContact()
    var
        IsHandled: Boolean;
    begin
        if not (CurrFieldNo in [FieldNo("Rented-to Contact"), FieldNo("Rented-to Contact No.")]) then
            exit;

        if IsCreditDocType then
            exit;

        IsHandled := FALSE;
        //OnUpdateShipToContactOnBeforeValidateShipToContact(Rec, xRec, CurrFieldNo, IsHandled);
        if not IsHandled then
            Validate("Ship-to Contact", "Rented-to Contact");
    end;

    /// <summary>
    /// ConfirmCloseUnposted.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure ConfirmCloseUnposted(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if TWERentalLinesExist then
            if InstructionMgt.IsUnpostedEnabledForRecord(Rec) then
                exit(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst, InstructionMgt.QueryPostOnCloseCode));
        exit(true)
    end;

    local procedure UpdateOpportunity()
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOpportunity(IsHandled);
        if IsHandled then
            exit;

        if not ("Opportunity No." <> '') or not ("Document Type" in ["Document Type"::Quote, "Document Type"::Contract]) then
            exit;

        if not Opp.Get("Opportunity No.") then
            exit;

        if "Document Type" = "Document Type"::Contract then begin
            if not ConfirmManagement.GetResponseOrDefault(Text040Lbl, true) then
                Error(Text044Lbl);

            OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
            OpportunityEntry.ModifyAll(Active, false);

            OpportunityEntry.Init();
            OpportunityEntry.Validate("Opportunity No.", Opp."No.");

            OpportunityEntry.LockTable();
            OpportunityEntry."Entry No." := OpportunityEntry.GetLastEntryNo() + 1;
            OpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
            OpportunityEntry."Contact No." := Opp."Contact No.";
            OpportunityEntry."Contact Company No." := Opp."Contact Company No.";
            OpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
            OpportunityEntry."Campaign No." := Opp."Campaign No.";
            OpportunityEntry."Action Taken" := OpportunityEntry."Action Taken"::Lost;
            OpportunityEntry.Active := true;
            OpportunityEntry."Completed %" := 100;
            OpportunityEntry."Estimated Value (LCY)" := GetOpportunityEntryEstimatedValue;
            OpportunityEntry."Estimated Close Date" := Opp."Date Closed";
            OpportunityEntry.Insert(true);
        end;
        Opp.Find();
        Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
        Opp."Sales Document No." := '';
        Opp.Modify();
        "Opportunity No." := '';
    end;

    local procedure GetOpportunityEntryEstimatedValue(): Decimal
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
        if OpportunityEntry.FindLast() then
            exit(OpportunityEntry."Estimated Value (LCY)");
    end;

    /// <summary>
    /// InitFromTWERentalHeader.
    /// </summary>
    /// <param name="SourceTWERentalHeader">Record "TWE Rental Header".</param>
    procedure InitFromTWERentalHeader(SourceTWERentalHeader: Record "TWE Rental Header")
    begin
        OnBeforeInitFromTWERentalHeader(Rec, SourceTWERentalHeader);

        "Document Date" := SourceTWERentalHeader."Document Date";
        "Shipment Date" := SourceTWERentalHeader."Shipment Date";
        "Shortcut Dimension 1 Code" := SourceTWERentalHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SourceTWERentalHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SourceTWERentalHeader."Dimension Set ID";
        "Location Code" := SourceTWERentalHeader."Location Code";
        SetShipToAddress(
          SourceTWERentalHeader."Ship-to Name", SourceTWERentalHeader."Ship-to Name 2", SourceTWERentalHeader."Ship-to Address",
          SourceTWERentalHeader."Ship-to Address 2", SourceTWERentalHeader."Ship-to City", SourceTWERentalHeader."Ship-to Post Code",
          SourceTWERentalHeader."Ship-to County", SourceTWERentalHeader."Ship-to Country/Region Code");
        "Ship-to Contact" := SourceTWERentalHeader."Ship-to Contact";

        OnAfterInitFromTWERentalHeader(Rec, SourceTWERentalHeader);
    end;

    local procedure InitFromContact(ContactNo: Code[20]; CustomerNo: Code[20]; ContactCaption: Text): Boolean
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        if (ContactNo = '') and (CustomerNo = '') then begin
            if not RentalLine.IsEmpty then
                Error(Text005Lbl, ContactCaption);
            Init;
            GetRentalSetup;
            "No. Series" := xRec."No. Series";
            OnInitFromContactOnBeforeInitRecord(Rec, xRec);
            InitRecord;
            InitNoSeries;
            OnInitFromContactOnAfterInitNoSeries(Rec, xRec);
            exit(true);
        end;
    end;

    local procedure InitFromTemplate(TemplateCode: Code[20]; TemplateCaption: Text): Boolean
    begin
        RentalLine.Reset();
        RentalLine.SetRange("Document Type", "Document Type");
        RentalLine.SetRange("Document No.", "No.");
        if TemplateCode = '' then begin
            if not RentalLine.IsEmpty then
                Error(Text005Lbl, TemplateCaption);
            Init;
            GetRentalSetup;
            "No. Series" := xRec."No. Series";
            OnInitFromTemplateOnBeforeInitRecord(Rec, xRec);
            InitRecord;
            InitNoSeries;
            OnInitFromTemplateOnAfterInitNoSeries(Rec, xRec);
            exit(true);
        end;
    end;

    local procedure ValidateTaxAreaCode()
    var
        TaxArea: Record "Tax Area";
    begin
        if "Tax Area Code" = '' then
            exit;
        TaxArea.Get("Tax Area Code");
    end;

    /// <summary>
    /// SetWorkDescription.
    /// </summary>
    /// <param name="NewWorkDescription">Text.</param>
    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Work Description");
        "Work Description".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    /// <summary>
    /// GetWorkDescription.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkDescription(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    local procedure LookupContact(CustomerNo: Code[20]; ContactNo: Code[20]; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        FilterByContactCompany: Boolean;
    begin
        if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo) then
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
        else
            if "Document Type" = "Document Type"::Quote then
                FilterByContactCompany := true
            else
                Contact.SetRange("Company No.", '');
        if ContactNo <> '' then
            if Contact.Get(ContactNo) then
                if FilterByContactCompany then
                    Contact.SetRange("Company No.", Contact."Company No.");
    end;

    /// <summary>
    /// SetAllowSelectNoSeries.
    /// </summary>
    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetupSalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultSalesperson(Rec, IsHandled);
        if IsHandled then
            exit;

        UserSetupSalespersonCode := GetUserSetupSalespersonCode;
        if UserSetupSalespersonCode <> '' then
            if Salesperson.Get(UserSetupSalespersonCode) then
                if not Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    Validate("Salesperson Code", UserSetupSalespersonCode);
    end;

    local procedure GetUserSetupSalespersonCode(): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        exit(UserSetup."Salespers./Purch. Code");
    end;

    /// <summary>
    /// SelltoCustomerNoOnAfterValidate.
    /// </summary>
    /// <param name="TWERentalHeader">VAR Record "TWE Rental Header".</param>
    /// <param name="xTWERentalHeader">VAR Record "TWE Rental Header".</param>
    procedure SelltoCustomerNoOnAfterValidate(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
        if TWERentalHeader.GetFilter("Rented-to Customer No.") = xTWERentalHeader."Rented-to Customer No." then
            if TWERentalHeader."Rented-to Customer No." <> xTWERentalHeader."Rented-to Customer No." then
                TWERentalHeader.SetRange("Rented-to Customer No.");

        OnAfterSelltoCustomerNoOnAfterValidate(Rec, xRec);
    end;

    /// <summary>
    /// SelectTWERentalHeaderCustomerTemplate.
    /// </summary>
    /// <returns>Return value of type Code[10].</returns>
    procedure SelectTWERentalHeaderCustomerTemplate(): Code[10]
    var
        Contact: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Contact.Get("Rented-to Contact No.");
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
        if not Contact.ContactToCustBusinessRelationExist then
            if ConfirmManagement.GetResponse(SelectCustomerTemplateQst, false) then begin
                Commit();
                exit(Contact.LookupNewCustomerTemplate());
            end;
    end;

    local procedure ModifyBillToCustomerAddress()
    var
        Customer: Record Customer;
    begin
        GetRentalSetup;
        //if RentalSetup."Ignore Updated Addresses" then
        //    exit;
        if IsCreditDocType then
            exit;
        if ("Bill-to Customer No." <> "Rented-to Customer No.") and Customer.Get("Bill-to Customer No.") then
            if HasBillToAddress and HasDifferentBillToAddress(Customer) then
                ShowModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId,
                  ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
                  'CopyBillToCustomerAddressFieldsFromSalesDocument', "Bill-to Customer No.",
                  "Bill-to Name", FieldName("Bill-to Customer No."));
    end;

    local procedure ModifyCustomerAddress()
    var
        Customer: Record Customer;
    begin
        GetRentalSetup;
        //if RentalSetup."Ignore Updated Addresses" then
        //    exit;
        if IsCreditDocType then
            exit;
        if Customer.Get("Rented-to Customer No.") and HasSellToAddress and HasDifferentSellToAddress(Customer) then
            ShowModifyAddressNotification(GetModifyCustomerAddressNotificationId,
              ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
              'CopySellToCustomerAddressFieldsFromSalesDocument', "Rented-to Customer No.",
              "Rented-to Customer Name", FieldName("Rented-to Customer No."));
    end;

    local procedure ShowModifyAddressNotification(NotificationID: Guid; NotificationLbl: Text; NotificationMsg: Text; NotificationFunctionTok: Text; CustomerNumber: Code[20]; CustomerName: Text[100]; CustomerNumberFieldName: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PageMyNotifications: Page "My Notifications";
        ModifyCustomerAddressNotification: Notification;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowModifyAddressNotification(IsHandled);
        if IsHandled then
            exit;

        if not MyNotifications.Get(UserId, NotificationID) then
            PageMyNotifications.InitializeNotificationsWithDefaultState;

        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Message := StrSubstNo(NotificationMsg, CustomerName);
        ModifyCustomerAddressNotification.AddAction(NotificationLbl, CODEUNIT::"Document Notifications", NotificationFunctionTok);
        ModifyCustomerAddressNotification.AddAction(
          DontShowAgainActionLbl, CODEUNIT::"Document Notifications", 'HideNotificationForCurrentUser');
        ModifyCustomerAddressNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        ModifyCustomerAddressNotification.SetData(FieldName("Document Type"), Format("Document Type"));
        ModifyCustomerAddressNotification.SetData(FieldName("No."), "No.");
        ModifyCustomerAddressNotification.SetData(CustomerNumberFieldName, CustomerNumber);
        NotificationLifecycleMgt.SendNotification(ModifyCustomerAddressNotification, RecordId);
    end;

    /// <summary>
    /// RecallModifyAddressNotification.
    /// </summary>
    /// <param name="NotificationID">Guid.</param>
    procedure RecallModifyAddressNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        ModifyCustomerAddressNotification: Notification;
    begin
        if IsCreditDocType or (not MyNotifications.IsEnabled(NotificationID)) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Recall();
    end;

    /// <summary>
    /// GetModifyCustomerAddressNotificationId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetModifyCustomerAddressNotificationId(): Guid
    begin
        exit('509FD112-31EC-4CDC-AEBF-19B8FEBA526F');
    end;

    /// <summary>
    /// GetModifyBillToCustomerAddressNotificationId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetModifyBillToCustomerAddressNotificationId(): Guid
    begin
        exit('2096CE78-6A74-48DB-BC9A-CD5C21504FC1');
    end;

    /// <summary>
    /// GetLineInvoiceDiscountResetNotificationId.
    /// </summary>
    /// <returns>Return value of type Guid.</returns>
    procedure GetLineInvoiceDiscountResetNotificationId(): Guid
    begin
        exit('35AB3090-2E03-4849-BBF9-9664DE464605');
    end;

    /// <summary>
    /// SetModifyBillToCustomerAddressNotificationDefaultState.
    /// </summary>
    procedure SetModifyCustomerAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyCustomerAddressNotificationId,
          ModifySellToCustomerAddressNotificationNameTxt, ModifySellToCustomerAddressNotificationDescriptionTxt, true);
    end;

    /// <summary>
    /// SetModifyBillToCustomerAddressNotificationDefaultState.
    /// </summary>
    procedure SetModifyBillToCustomerAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyBillToCustomerAddressNotificationId,
          ModifyBillToCustomerAddressNotificationNameTxt, ModifyBillToCustomerAddressNotificationDescriptionTxt, true);
    end;

    /// <summary>
    /// DontNotifyCurrentUserAgain.
    /// </summary>
    /// <param name="NotificationID">Guid.</param>
    procedure DontNotifyCurrentUserAgain(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationID) then
            case NotificationID of
                GetModifyCustomerAddressNotificationId:
                    MyNotifications.InsertDefault(NotificationID, ModifySellToCustomerAddressNotificationNameTxt,
                      ModifySellToCustomerAddressNotificationDescriptionTxt, false);
                GetModifyBillToCustomerAddressNotificationId:
                    MyNotifications.InsertDefault(NotificationID, ModifyBillToCustomerAddressNotificationNameTxt,
                      ModifyBillToCustomerAddressNotificationDescriptionTxt, false);
            end;
    end;

    /// <summary>
    /// HasDifferentSellToAddress.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasDifferentSellToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Rented-to Address" <> Customer.Address) or
          ("Rented-to Address 2" <> Customer."Address 2") or
          ("Rented-to City" <> Customer.City) or
          ("Rented-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Rented-to County" <> Customer.County) or
          ("Rented-to Post Code" <> Customer."Post Code") or
          ("Rented-to Contact" <> Customer.Contact));
    end;

    /// <summary>
    /// HasDifferentBillToAddress.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasDifferentBillToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Bill-to Address" <> Customer.Address) or
          ("Bill-to Address 2" <> Customer."Address 2") or
          ("Bill-to City" <> Customer.City) or
          ("Bill-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Bill-to County" <> Customer.County) or
          ("Bill-to Post Code" <> Customer."Post Code") or
          ("Bill-to Contact" <> Customer.Contact));
    end;

    /// <summary>
    /// HasDifferentShipToAddress.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure HasDifferentShipToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Ship-to Address" <> Customer.Address) or
          ("Ship-to Address 2" <> Customer."Address 2") or
          ("Ship-to City" <> Customer.City) or
          ("Ship-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Ship-to County" <> Customer.County) or
          ("Ship-to Post Code" <> Customer."Post Code") or
          ("Ship-to Contact" <> Customer.Contact));
    end;

    /// <summary>
    /// ShowInteractionLogEntries.
    /// </summary>
    procedure ShowInteractionLogEntries()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        if "Bill-to Contact No." <> '' then
            InteractionLogEntry.SetRange("Contact No.", "Bill-to Contact No.");
        case "Document Type" of
            "Document Type"::Contract:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
            "Document Type"::Quote:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Qte.");
        end;

        InteractionLogEntry.SetRange("Document No.", "No.");
        PAGE.Run(PAGE::"Interaction Log Entries", InteractionLogEntry);
    end;

    /// <summary>
    /// GetBillToNo.
    /// </summary>
    /// <returns>Return value of type Code[20].</returns>
    procedure GetBillToNo(): Code[20]
    begin
        if ("Document Type" = "Document Type"::Quote) and
           ("Bill-to Customer No." = '') and ("Bill-to Contact No." <> '') and
           ("Bill-to Customer Template Code" <> '')
        then
            exit("Bill-to Contact No.");
        exit("Bill-to Customer No.");
    end;

    /// <summary>
    /// GetCurrencySymbol.
    /// </summary>
    /// <returns>Return value of type Text[10].</returns>
    procedure GetCurrencySymbol(): Text[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if GeneralLedgerSetup.Get then
            if ("Currency Code" = '') or ("Currency Code" = GeneralLedgerSetup."LCY Code") then
                exit(GeneralLedgerSetup.GetCurrencySymbol);

        if Currency.Get("Currency Code") then
            exit(Currency.GetCurrencySymbol);

        exit("Currency Code");
    end;

    local procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        UserSetupSalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeSetSalespersonCode(Rec, SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        UserSetupSalespersonCode := GetUserSetupSalespersonCode;
        if SalesPersonCodeToCheck <> '' then begin
            if Salesperson.Get(SalesPersonCodeToCheck) then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if UserSetupSalespersonCode = '' then
                        SalesPersonCodeToAssign := ''
                end else
                    SalesPersonCodeToAssign := SalesPersonCodeToCheck;
        end else
            if UserSetupSalespersonCode = '' then
                SalesPersonCodeToAssign := '';
    end;

    /// <summary>
    /// ValidateSalesPersonOnTWERentalHeader.
    /// </summary>
    /// <param name="TWERentalHeader2">Record "TWE Rental Header".</param>
    /// <param name="IsTransaction">Boolean.</param>
    /// <param name="IsPostAction">Boolean.</param>
    procedure ValidateSalesPersonOnTWERentalHeader(TWERentalHeader2: Record "TWE Rental Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if TWERentalHeader2."Salesperson Code" <> '' then
            if Salesperson.Get(TWERentalHeader2."Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedTransactionText(Salesperson, IsPostAction, true));
                    if not IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true));
                end;
    end;

    local procedure RevertCurrencyCodeAndPostingDate()
    begin
        "Currency Code" := xRec."Currency Code";
        "Posting Date" := xRec."Posting Date";
    end;

    /// <summary>
    /// ShouldSearchForCustomerByName.
    /// </summary>
    /// <param name="CustomerNo">Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit(true);

        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;

    local procedure CalcQuoteValidUntilDate()
    var
        BlankDateFormula: DateFormula;
    begin
        GetRentalSetup;
        // if RentalSetup."Quote Validity Calculation" <> BlankDateFormula then
        //    "Quote Valid Until Date" := CalcDate(RentalSetup."Quote Validity Calculation", "Document Date");
    end;

    /// <summary>
    /// TestQuantityShippedField.
    /// </summary>
    /// <param name="TWERentalLine">Record "TWE Rental Line".</param>
    procedure TestQuantityShippedField(TWERentalLine: Record "TWE Rental Line")
    begin
        TWERentalLine.TestField("Quantity Shipped", 0);
        OnAfterTestQuantityShippedField(TWERentalLine);
    end;

    /// <summary>
    /// TestStatusIsNotPendingApproval.
    /// </summary>
    /// <returns>Return variable NotPending of type Boolean.</returns>
    procedure TestStatusIsNotPendingApproval() NotPending: Boolean;
    begin
        NotPending := Status in [Status::Open, Status::"Pending Prepayment", Status::Released];

        //  OnTestStatusIsNotPendingApproval(Rec, NotPending);
    end;

    /// <summary>
    /// TestStatusIsNotPendingPrepayment.
    /// </summary>
    /// <returns>Return variable NotPending of type Boolean.</returns>
    procedure TestStatusIsNotPendingPrepayment() NotPending: Boolean;
    begin
        NotPending := Status in [Status::Open, Status::"Pending Approval", Status::Released];

        // OnTestStatusIsNotPendingPrepayment(Rec, NotPending);
    end;


    /// <summary>
    /// TestStatusIsNotReleased.
    /// </summary>
    /// <returns>Return variable NotReleased of type Boolean.</returns>
    procedure TestStatusIsNotReleased() NotReleased: Boolean;
    begin
        NotReleased := Status in [Status::Open, Status::"Pending Approval", Status::"Pending Prepayment"];

        OnTestStatusIsNotReleased(Rec, NotReleased);
    end;

    /// <summary>
    /// TestStatusOpen.
    /// </summary>
    procedure TestStatusOpen()
    begin
        OnBeforeTestStatusOpen(Rec);

        if StatusCheckSuspended then
            exit;

        TestField(Status, Status::Open);
        OnAfterTestStatusOpen(Rec);
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
    /// CheckForBlockedLines.
    /// </summary>
    procedure CheckForBlockedLines()
    var
        CurrentTWERentalLine: Record "TWE Rental Line";
        TWEMainRentalItem: Record "TWE Main Rental Item";
        Resource: Record Resource;
    begin
        CurrentTWERentalLine.SetCurrentKey("Document Type", "Document No.", Type);
        CurrentTWERentalLine.SetRange("Document Type", "Document Type");
        CurrentTWERentalLine.SetRange("Document No.", "No.");
        CurrentTWERentalLine.SetFilter(Type, '%1|%2', CurrentTWERentalLine.Type::"Rental Item", CurrentTWERentalLine.Type::Resource);
        CurrentTWERentalLine.SetFilter("No.", '<>''''');

        if CurrentTWERentalLine.FindSet() then
            repeat
                case CurrentTWERentalLine.Type of
                    CurrentTWERentalLine.Type::"Rental Item":
                        begin
                            TWEMainRentalItem.Get(CurrentTWERentalLine."No.");
                            TWEMainRentalItem.TestField(Blocked, false);
                        end;
                    CurrentTWERentalLine.Type::Resource:
                        begin
                            Resource.Get(CurrentTWERentalLine."No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;
            until CurrentTWERentalLine.Next() = 0;
    end;

    /// <summary>
    /// CopyDocument.
    /// </summary>
    procedure CopyDocument()
    var
        CopyRentalDocument: Report "TWE Copy Rental Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDocument(Rec, IsHandled);
        if IsHandled then
            exit;

        CopyRentalDocument.SetRentalHeader(Rec);
        CopyRentalDocument.RunModal();
    end;

    local procedure CheckContactRelatedToCustomerCompany(ContactNo: Code[20]; CustomerNo: Code[20]; CurrFieldNo: Integer);
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContactRelatedToCustomerCompany(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Contact.Get(ContactNo);
        if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustomerNo) then
            if (ContBusRel."Contact No." <> Contact."Company No.") and (ContBusRel."Contact No." <> Contact."No.") then
                Error(Text038Lbl, Contact."No.", Contact.Name, CustomerNo);
    end;

    local procedure ConfirmRecalculatePrice(var TWERentalLine: Record "TWE Rental Line") Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRecalculatePrice(Rec, xRec, CurrFieldNo, Result, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        if GetHideValidationDialog or not GuiAllowed then
            Result := true
        else
            Result :=
              ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(Text024Lbl, FieldCaption("Prices Including VAT"), TWERentalLine.FieldCaption("Unit Price")), true);
    end;

    /// <summary>
    /// LookupSellToCustomerName.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure LookupSellToCustomerName(): Boolean
    var
        Customer: Record Customer;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        CustomerList: Page "Customer List";
    begin
        if "Rented-to Customer No." <> '' then
            Customer.Get("Rented-to Customer No.");

        CustomerList.SetRecord(Customer);
        CustomerList.SetTableView(Customer);
        CustomerList.LookUpMode(True);
        if CustomerList.RunModal = Action::LookUpOK then begin
            CustomerList.GetRecord(Customer);
            "Rented-to Customer Name" := Customer.Name;
            Validate("Rented-to Customer No.", Customer."No.");
        end

        //  if Customer.LookupCustomer(Customer) then begin
        //      "Rented-to Customer Name" := Customer.Name;
        //      Validate("Rented-to Customer No.", Customer."No.");
        //      GetShippingTime(FieldNo("Rented-to Customer Name"));
        //      if "No." <> '' then
        //          StandardCodesMgt.CheckCreateSalesRecurringLines(Rec);
        //      exit(true);
        //  end;
    end;

    local procedure CheckPromisedDeliveryDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPromisedDeliveryDate(IsHandled);
        if IsHandled then
            exit;

        if "Promised Delivery Date" <> 0D then
            Error(Text028Lbl, FieldCaption("Requested Delivery Date"), FieldCaption("Promised Delivery Date"));
    end;

    local procedure SetBillToCustomerNo(var Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        //OnBeforeSetBillToCustomerNo(Rec, Cust, IsHandled);
        if IsHandled then
            exit;

        if Cust."Bill-to Customer No." <> '' then
            Validate("Bill-to Customer No.", Cust."Bill-to Customer No.")
        else begin
            if "Bill-to Customer No." = "Rented-to Customer No." then
                SkipBillToContact := true;
            Validate("Bill-to Customer No.", "Rented-to Customer No.");
            SkipBillToContact := false;
        end;
    end;

    /// <summary>
    /// GetStatusCheckSuspended.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetStatusCheckSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    local procedure GetRentalLines(var tweRentalLine: Record "TWE Rental Line"): Boolean
    var
        localTWERentalLine: Record "TWE Rental Line";
    begin
        localTWERentalLine.SetRange("Document Type", Rec."Document Type");
        localTWERentalLine.SetRange("Document No.", Rec."No.");
        if localTWERentalLine.FindSet() then begin
            tweRentalLine := localTWERentalLine;
            exit(true);
        end else begin
            exit(false);
        end;

    end;

    local procedure SetDataToRentalLine()
    var
        localTWERentalLine: Record "TWE Rental Line";
        BusinessRentalMgt: Codeunit "TWE Business Rental Mgt.";
        localTotalQtyDays: Decimal;
        localQtyDaysInvoice: Decimal;
    begin
        if GetRentalLines(localTWERentalLine) then begin
            repeat
                if Rec."Rental Rate Code" <> xRec."Rental Rate Code" then
                    if localTWERentalLine."Rental Rate Code" <> Rec."Rental Rate Code" then
                        localTWERentalLine."Rental Rate Code" := Rec."Rental Rate Code";

                if (Rec."Invoicing Period" = '') or (Rec."Invoicing Period" <> xRec."Invoicing Period") then
                    if localTWERentalLine."Invoicing Period" <> Rec."Invoicing Period" then
                        localTWERentalLine."Invoicing Period" := Rec."Invoicing Period";

                BusinessRentalMgt.CalculateNextInvoiceDates(localTWERentalLine);

                localTotalQtyDays := BusinessRentalMgt.CalculateTotalDaysToInvoice(Rec."Rental Rate Code", Rec."Rental Start", Rec."Rental End");
                localTWERentalLine."Total Days to Invoice" := localTotalQtyDays;


                localQtyDaysInvoice := BusinessRentalMgt.CalculateDaysToInvoice(Rec."Rental Rate Code", Rec."Invoicing Period", localTWERentalLine."Billing Start Date", localTWERentalLine."Billing End Date");
                localTWERentalLine."Duration to be billed" := localQtyDaysInvoice;


                localTWERentalLine.Modify();
            until localTWERentalLine.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNoSeries(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditLimitCondition(var TWERentalHeader: Record "TWE Rental Header"; var RunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditMaxBeforeInsert(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBillToCust(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSellToCust(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckShippingAdvice(var TWERentalHeader: Record "TWE Rental Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmSalesPrice(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateTWERentalLine(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAllTempTWERentalLines(TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTWERentalHeader(var TWERentalHeader: Record "TWE Rental Header"; SourceTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTempTWERentalLine(TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPosting(TWERentalHeader: Record "TWE Rental Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPostingBatch(TWERentalHeader: Record "TWE Rental Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var TWERentalHeader: Record "TWE Rental Header"; RentalSetup: Record "TWE Rental Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingNoSeriesCode(TWERentalHeader: Record "TWE Rental Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepaymentPostingNoSeriesCode(TWERentalHeader: Record "TWE Rental Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRentalSetup(TWERentalHeader: Record "TWE Rental Header"; var RentalSetup: Record "TWE Rental Setup"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocTypeText(var TWERentalHeader: Record "TWE Rental Header"; var TypeText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetStatusStyleText(TWERentalHeader: Record "TWE Rental Header"; var StatusStyleText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCurrencyFactor(var TWERentalHeader: Record "TWE Rental Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliesToDocNoOnLookup(var TWERentalHeader: Record "TWE Rental Header"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTWERentalLineByChangedFieldName(TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; ChangedFieldName: Text[100]; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTWERentalLineAmountsOnAfterTWERentalHeaderModify(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateShipToContactOnBeforeValidateShipToContact(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var TWERentalHeader: Record "TWE Rental Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTWERentalLine(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsShipToAddressEqualToSellToAddress(SellToTWERentalHeader: Record "TWE Rental Header"; ShipToTWERentalHeader: Record "TWE Rental Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteAccepted(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangePricesIncludingVAT(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelltoCustomerNoOnAfterValidate(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendTWERentalHeader(var TWERentalHeader: Record "TWE Rental Header"; ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFieldsBilltoCustomer(var TWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForTWERentalLineRecreation(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSellToCustTemplate(var TWERentalHeader: Record "TWE Rental Header"; SellToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToAddressToShipToAddress(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToAddressToBillToAddress(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToCustomerAddressFieldsFromCustomer(var TWERentalHeader: Record "TWE Rental Header"; SellToCustomer: Record Customer; CurrentFieldNo: Integer; var SkipBillToContact: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromCustomer(var TWERentalHeader: Record "TWE Rental Header"; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(var TWERentalHeader: Record "TWE Rental Header"; ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var TWERentalHeader: Record "TWE Rental Header"; OldRentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailableCreditLimit(var TWERentalHeader: Record "TWE Rental Header"; var ReturnValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimit(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditMaxBeforeInsert(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; HideCreditCheckDialogue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimitIfLineNotInsertedYet(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerContactRelation(var TWERentalHeader: Record "TWE Rental Header"; Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnInfo(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipmentInfo(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; BillTo: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateAllLineDim(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmBillToContactNoChange(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmSellToContactNoChange(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateCurrencyFactor(var TWERentalHeader: Record "TWE Rental Header"; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetContactAsCompany(Contact: Record Contact; var SearchContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDeletion(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(var TWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(var TWERentalHeader: Record "TWE Rental Header"; ShipToAddress: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromSellToCustomerTemplate(var TWERentalHeader: Record "TWE Rental Header"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromBillToCustomerTemplate(var TWERentalHeader: Record "TWE Rental Header"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTWERentalLine(var TempTWERentalLine: Record "TWE Rental Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvtPutAwayPick(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteTWERentalLines(var TWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteRecordInApprovalRequest(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerVATRegistrationNumber(var TWERentalHeader: Record "TWE Rental Header"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerVATRegistrationNumberLbl(var TWERentalHeader: Record "TWE Rental Header"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var TWERentalHeader: Record "TWE Rental Header"; RentalSetup: Record "TWE Rental Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingNoSeriesCode(var TWERentalHeader: Record "TWE Rental Header"; RentalSetup: Record "TWE Rental Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShippingTime(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; var CalledByFieldNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromTWERentalHeader(var TWERentalHeader: Record "TWE Rental Header"; SourceTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitInsert(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPostingDescription(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCreditDocType(TWERentalHeader: Record "TWE Rental Header"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var TWERentalHeader: Record "TWE Rental Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBillToPostCode(var TWERentalHeader: Record "TWE Rental Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToContactNo(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToPostCode(var TWERentalHeader: Record "TWE Rental Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShipToPostCode(var TWERentalHeader: Record "TWE Rental Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShippingNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupReturnReceiptNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenRentalContractStatistics(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyToShipIsZero(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocDim(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyFactor(var TWERentalHeader: Record "TWE Rental Header"; var Updated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToPostCode(var TWERentalHeader: Record "TWE Rental Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReceiptNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToPostCode(var TWERentalHeader: Record "TWE Rental Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToPostCode(var TWERentalHeader: Record "TWE Rental Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATRegistrationNo(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMessageIfTWERentalLinesExist(TWERentalHeader: Record "TWE Rental Header"; ChangedFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePriceMessageIfTWERentalLinesExist(TWERentalHeader: Record "TWE Rental Header"; ChangedFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateTWERentalLines(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateTWERentalLinesHandler(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateTWERentalLinesHandleSupplementTypes(var TempTWERentalLine: Record "TWE Rental Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTWERentalLineByChangedFieldNo(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; ChangedFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTWERentalLineInsert(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary; TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustomerLocationCode(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesperson(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowPostedDocsToPrintCreatedMsg(var ShowPostedDocsToPrint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronizeForReservations(var TWERentalHeader: Record "TWE Rental Header"; var NewTWERentalLine: Record "TWE Rental Line"; OldTWERentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCustContact(var TWERentalHeader: Record "TWE Rental Header"; Conact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCust(var TWERentalHeader: Record "TWE Rental Header"; var Contact: Record Contact; var Customer: Record Customer; ContactNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllLineDim(var TWERentalHeader: Record "TWE Rental Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLocationCode(var TWERentalHeader: Record "TWE Rental Header"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOutboundWhseHandlingTime(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTWERentalLineAmounts(TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTWERentalLinesByFieldNo(var TWERentalHeader: Record "TWE Rental Header"; ChangedFieldNo: Integer; var AskQuestion: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTWERentalLines(var TWERentalHeader: Record "TWE Rental Header"; ChangedFieldName: Text[100]; var AskQuestion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCustContact(var TWERentalHeader: Record "TWE Rental Header"; Conact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddress(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailabilityInLinesOnAfterSetFilters(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnAfterSetTempTWERentalLineFilters(var TempTWERentalLine: Record "TWE Rental Line" temporary; TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySelltoCustomerAddressFieldsFromCustomerOnAfterAssignRespCenter(var TWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; OldDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTWERentalLineOnAfterAssignType(var TWERentalLine: Record "TWE Rental Line"; var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnAfterInitNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnBeforeInitRecord(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnAfterInitNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnBeforeInitRecord(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignShipmentDate(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempTWERentalLineInBufferOnBeforeTempTWERentalLineInsert(var TempTWERentalLine: Record "TWE Rental Line" temporary; TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterRentalQuote(var TWERentalHeader: Record "TWE Rental Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBilltoCustomerTemplateCodeBeforeRecreateTWERentalLines(var TWERentalHeader: Record "TWE Rental Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoAfterInit(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestQuantityShippedField(TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestTWERentalLineFieldsBeforeRecreate(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeTestStatusOpen(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterTestStatusOpen(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCont(var TWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCust(var TWERentalHeader: Record "TWE Rental Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSellToCont(var TWERentalHeader: Record "TWE Rental Header"; Customer: Record Customer; Contact: Record Contact; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSellToCust(var TWERentalHeader: Record "TWE Rental Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTWERentalLines(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToDocNo(var TWERentalHeader: Record "TWE Rental Header"; var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCustomerName(var TWERentalHeader: Record "TWE Rental Header"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToCustomerName(var TWERentalHeader: Record "TWE Rental Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateTWERentalLinesOnAfterSetTWERentalLineFilters(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateTWERentalLinesOnBeforeConfirm(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; ChangedFieldName: Text[100]; HideValidationDialog: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateTWERentalLinesOnBeforeTWERentalLineDeleteAll(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateReservEntryReqLineOnAfterLoop(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingApproval(TWERentalHeader: Record "TWE Rental Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingPrepayment(TWERentalHeader: Record "TWE Rental Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotReleased(TWERentalHeader: Record "TWE Rental Header"; var NotReleased: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeTWERentalLineModify(var TWERentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTWERentalLinesByFieldNoOnBeforeTWERentalLineModify(var TWERentalLine: Record "TWE Rental Line"; ChangedFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(var TWERentalHeader: Record "TWE Rental Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeFindContactBusinessRelation(Contact: Record Contact; var ContBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetFromSearchContact(var TWERentalHeader: Record "TWE Rental Header"; var SearchContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetSellToContactNo(var TWERentalHeader: Record "TWE Rental Header"; var Customer: Record Customer; var Cont: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(var TWERentalHeader: Record "TWE Rental Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeFindContactBusinessRelation(Cont: Record Contact; var ContBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnAfterConfirmed(var TWERentalHeader: Record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcDueDate(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDate(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnBeforeAssignDocumentDate(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculatePrepaymentDueDate(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnBeforeTWERentalLineModify(var TWERentalHeader: Record "TWE Rental Header"; var TWERentalLine: Record "TWE Rental Line"; Currency: Record Currency; RecalculatePrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShippingAgentCodeOnBeforeUpdateLines(var TWERentalHeader: Record "TWE Rental Header"; CallingFieldNo: Integer; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullDocTypeTxt(var TWERentalHeader: Record "TWE Rental Header"; var FullDocTypeTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnBeforeInsertTempTWERentalLineInBuffer(var GenPostingSetup: Record "General Posting Setup"; var DefaultDimension: Record "Default Dimension")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocument(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCust(var TWERentalHeader: Record "TWE Rental Header"; ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateTWERentalLinesOnBeforeTempTWERentalLineFindSet(var TempTWERentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContactRelatedToCustomerCompany(TWERentalHeader: Record "TWE Rental Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowModifyAddressNotification(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnBeforeUpdateTWERentalLines(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRecalculatePrice(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; CurrFieldNo: Integer; var Result: Boolean; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetTWERentalLineNewDimSetID(var TWERentalLine: Record "TWE Rental Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterGetTWERentalLineNewDimsetID(TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; TWERentalLine: Record "TWE Rental Line"; var NewDimSetID: Integer; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingNoSeries(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRename(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupBillToContactNo(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateOpportunity(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPromisedDeliveryDate(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddressFromSellToAddress(var TWERentalHeader: Record "TWE Rental Header"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(var TWERentalHeader: Record "TWE Rental Header"; SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddressFromSellToAddress(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCode(var TWERentalHeader: Record "TWE Rental Header"; xTWERentalHeader: Record "TWE Rental Header"; Cust: Record Customer; ShipToAddr: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(var TWERentalHeader: Record "TWE Rental Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBillToCustomerNo(var TWERentalHeader: Record "TWE Rental Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeCheckBlockedCustOnDocs(var TWERentalHeader: Record "TWE Rental Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateTWERentalLines(var TWERentalHeader: Record "TWE Rental Header"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBillToCustomerAddressFieldsFromCustomer(var TWERentalHeader: Record "TWE Rental Header"; var BillToCustomer: Record Customer; var SkipBillToContact: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSellToCustomerFromFilter(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeRecallModifyAddressNotification(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscForHeader(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToName(var TWERentalHeader: Record "TWE Rental Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeRecallModifyAddressNotification(var TWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeValidateTaxLiable(var TWERentalHeader: Record "TWE Rental Header"; var xTWERentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipmentMethodCode(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentCode(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignWorkDateToPostingDate(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentServiceCode(var TWERentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;
}

