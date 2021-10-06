/// <summary>
/// Table TWE Rental Invoice Header (ID 50010).
/// </summary>
table 50010 "TWE Rental Invoice Header"
{
    Caption = 'Rental Invoice Header';
    DataCaptionFields = "No.", "Rented-to Customer Name";
    DrillDownPageID = "TWE Posted Rental Invoices";
    LookupPageID = "TWE Posted Rental Invoices";

    fields
    {
        field(2; "Rented-to Customer No."; Code[20])
        {
            Caption = 'Rented-to Customer No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Customer;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            DataClassification = CustomerContent;
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
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            DataClassification = CustomerContent;
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            DataClassification = CustomerContent;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            DataClassification = CustomerContent;
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
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            DataClassification = CustomerContent;
        }
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
            DataClassification = CustomerContent;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            DataClassification = CustomerContent;
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
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
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
            Editable = false;
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Price Group";
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            DataClassification = CustomerContent;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            DataClassification = CustomerContent;
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Discount Group";
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            DataClassification = CustomerContent;
            TableRelation = Language;
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser";
        }
        field(44; "Order No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE("Document Type" = CONST("Posted Invoice"),
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
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                CustLedgEntry.SetCurrentKey("Document No.");
                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                OnLookupAppliesToDocNoOnAfterSetFilters(CustLedgEntry, Rec);
                PAGE.Run(0, CustLedgEntry);
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = CustomerContent;
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Invoice Line".Amount WHERE("Document No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Invoice Line"."Amount Including VAT" WHERE("Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
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
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            DataClassification = CustomerContent;
            TableRelation = "Transport Method";
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
        }
        field(82; "Rented-to Address 2"; Text[50])
        {
            Caption = 'Rented-to Address 2';
            DataClassification = CustomerContent;
        }
        field(83; "Rented-to City"; Text[30])
        {
            Caption = 'Rented-to City';
            DataClassification = CustomerContent;
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(84; "Rented-to Contact"; Text[100])
        {
            Caption = 'Rented-to Contact';
            DataClassification = CustomerContent;
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            DataClassification = CustomerContent;
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(88; "Rented-to Post Code"; Code[20])
        {
            Caption = 'Rented-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(89; "Rented-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Rented-to Country/Region Code";
            Caption = 'Rented-to County';
            DataClassification = CustomerContent;
        }
        field(90; "Rented-to Country/Region Code"; Code[10])
        {
            Caption = 'Rented-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
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
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            DataClassification = CustomerContent;
            TableRelation = Area;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Specification";
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Method";
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipping Agent";
        }
        field(106; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
            DataClassification = CustomerContent;
        }
        field(107; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(108; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "No. Series";
        }
        field(110; "Order No. Series"; Code[20])
        {
            Caption = 'Order No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(111; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
            DataClassification = CustomerContent;
        }
        field(112; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(113; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = CustomerContent;
            TableRelation = "Source Code";
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area";
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = CustomerContent;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            DataClassification = CustomerContent;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            DataClassification = CustomerContent;
        }
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(136; "Prepayment Invoice"; Boolean)
        {
            Caption = 'Prepayment Invoice';
            DataClassification = CustomerContent;
        }
        field(137; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
            DataClassification = CustomerContent;
        }
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(166; "Last Email Sent Time"; DateTime)
        {
            CalcFormula = Max("O365 Document Sent History"."Created Date-Time" WHERE("Document Type" = CONST(Invoice),
                                                                                      "Document No." = FIELD("No."),
                                                                                      Posted = CONST(true)));
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
        }
        field(167; "Last Email Sent Status"; Option)
        {
            CalcFormula = Lookup("O365 Document Sent History"."Job Last Status" WHERE("Document Type" = CONST(Invoice),
                                                                                       "Document No." = FIELD("No."),
                                                                                       Posted = CONST(true),
                                                                                       "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Sent Status';
            FieldClass = FlowField;
            OptionCaption = 'Not Sent,In Process,Finished,Error';
            OptionMembers = "Not Sent","In Process",Finished,Error;
        }
        field(168; "Sent as Email"; Boolean)
        {
            CalcFormula = Exist("O365 Document Sent History" WHERE("Document Type" = CONST(Invoice),
                                                                    "Document No." = FIELD("No."),
                                                                    Posted = CONST(true),
                                                                    "Job Last Status" = CONST(Finished)));
            Caption = 'Sent as Email';
            FieldClass = FlowField;
        }
        field(169; "Last Email Notif Cleared"; Boolean)
        {
            CalcFormula = Lookup("O365 Document Sent History".NotificationCleared WHERE("Document Type" = CONST(Invoice),
                                                                                         "Document No." = FIELD("No."),
                                                                                         Posted = CONST(true),
                                                                                         "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Notif Cleared';
            FieldClass = FlowField;
        }
        field(171; "Rented-to Phone No."; Text[30])
        {
            Caption = 'Rented-to Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }
        field(172; "Rented-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
        field(176; "Payment Instructions"; BLOB)
        {
            Caption = 'Payment Instructions';
            DataClassification = CustomerContent;
        }
        field(177; "Payment Instructions Name"; Text[20])
        {
            Caption = 'Payment Instructions Name';
            DataClassification = CustomerContent;
        }
        field(180; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            DataClassification = CustomerContent;
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
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
        field(600; "Payment Service Set ID"; Integer)
        {
            Caption = 'Payment Service Set ID';
            DataClassification = CustomerContent;
        }
        field(710; "Document Exchange Identifier"; Text[50])
        {
            Caption = 'Document Exchange Identifier';
            DataClassification = CustomerContent;
        }
        field(711; "Document Exchange Status"; Option)
        {
            Caption = 'Document Exchange Status';
            DataClassification = CustomerContent;
            OptionCaption = 'Not Sent,Sent to Document Exchange Service,Delivered to Recipient,Delivery Failed,Pending Connection to Recipient';
            OptionMembers = "Not Sent","Sent to Document Exchange Service","Delivered to Recipient","Delivery Failed","Pending Connection to Recipient";
        }
        field(712; "Doc. Exch. Original Identifier"; Text[50])
        {
            Caption = 'Doc. Exch. Original Identifier';
            DataClassification = CustomerContent;
        }
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            DataClassification = CustomerContent;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            DataClassification = CustomerContent;
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Bill-to Customer No."));
        }
        field(1302; Closed; Boolean)
        {
            CalcFormula = - Exist("Cust. Ledger Entry" WHERE("Entry No." = FIELD("Cust. Ledger Entry No."),
                                                             Open = FILTER(true)));
            Caption = 'Closed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Cust. Ledg. Entry".Amount WHERE("Cust. Ledger Entry No." = FIELD("Cust. Ledger Entry No.")));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1304; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Invoice Line"."Inv. Discount Amount" WHERE("Document No." = FIELD("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = Exist("Cancelled Document" WHERE("Source ID" = CONST(112),
                                                            "Cancelled Doc. No." = FIELD("No.")));
            Caption = 'Cancelled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1311; Corrective; Boolean)
        {
            CalcFormula = Exist("Cancelled Document" WHERE("Source ID" = CONST(114),
                                                            "Cancelled By Doc. No." = FIELD("No.")));
            Caption = 'Corrective';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1312; Reversed; Boolean)
        {
            Caption = 'Reversed';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Cust. Ledger Entry".Reversed where("Entry No." = field("Cust. Ledger Entry No.")));
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            DataClassification = CustomerContent;
            TableRelation = Campaign;
        }
        field(5052; "Rented-to Contact No."; Code[20])
        {
            Caption = 'Rented-to Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact;
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            DataClassification = CustomerContent;
            TableRelation = Opportunity;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            DataClassification = CustomerContent;
            TableRelation = "Responsibility Center";
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
        }
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
            DataClassification = CustomerContent;
        }
        field(8001; "Draft Invoice SystemId"; Guid)
        {
            Caption = 'Draft Invoice SystemId';
            DataClassification = SystemMetadata;
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
        }

        field(70704603; "Invoicing Period"; Code[20])
        {
            Caption = 'Invoicing Period';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Invoicing Period"."Invoicing Period Code";
        }
        field(70704604; "Rental Rate Code"; Code[20])
        {
            Caption = 'Rental Rate Code';
            DataClassification = CustomerContent;
            TableRelation = "TWE Rental Rates"."Rate Code";

        }
        field(70704605; "Belongs to Rental Contract"; Code[20])
        {
            Caption = 'Belongs to Rental Contract';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.")
        {
        }
        key(Key3; "Pre-Assigned No.")
        {
        }
        key(Key4; "Rented-to Customer No.", "External Document No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "Rented-to Customer No.", "Order Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "Rented-to Customer No.")
        {
        }
        key(Key7; "Prepayment Order No.", "Prepayment Invoice")
        {
        }
        key(Key8; "Bill-to Customer No.")
        {
        }
        key(Key9; "Posting Date")
        {
        }
        key(Key10; "Document Exchange Status")
        {
        }
        key(Key11; "Due Date")
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
        fieldgroup(DropDown; "No.", "Rented-to Customer No.", "Bill-to Customer No.", "Posting Date", "Posting Description")
        {
        }
        fieldgroup(Brick; "No.", "Rented-to Customer Name", Amount, "Due Date", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostSalesDelete: Codeunit "PostSales-Delete";
    begin
        PostSalesDelete.IsDocumentDeletionAllowed("Posting Date");
        TestField("No. Printed");
        LockTable();
        //PostSalesDelete.DeleteSalesInvLines(Rec);

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Invoice");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);

        PostedDeferralHeader.DeleteForDoc(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(), "No.");
    end;

    var
        SalesCommentLine: Record "Sales Comment Line";
        RentalSetup: Record "TWE Rental Setup";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";
        DocTxt: Label 'Invoice';
        PaymentReference: Text;
        PaymentReferenceLbl: Text;

    /// <summary>
    /// IsFullyOpen.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsFullyOpen(): Boolean
    begin
        CalcFields("Amount Including VAT", "Remaining Amount");
        exit("Amount Including VAT" = "Remaining Amount");
    end;

    /// <summary>
    /// SendRecords.
    /// </summary>
    procedure SendRecords()
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        DummyRentalReportSelections: Record "TWE Rental Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeSendRecords(DummyRentalReportSelections, Rec, DocumentTypeTxt, IsHandled);
        if not IsHandled then
            RentalDocumentSendingProfile.SendCustomerRecords(
              DummyRentalReportSelections.Usage::"R.Invoice".AsInteger(), Rec, DocumentTypeTxt, "Bill-to Customer No.", "No.",
              FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// SendProfile.
    /// </summary>
    /// <param name="RentalDocumentSendingProfile">VAR Record "Document Sending Profile".</param>
    procedure SendProfile(var RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    var
        DummyRentalReportSelections: Record "TWE Rental Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeSendProfile(DummyRentalReportSelections, Rec, DocumentTypeTxt, IsHandled, RentalDocumentSendingProfile);
        if not IsHandled then
            RentalDocumentSendingProfile.Send(
              DummyRentalReportSelections.Usage::"R.Invoice".AsInteger(), Rec, "No.", "Bill-to Customer No.",
              DocumentTypeTxt, FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// PrintRecords.
    /// </summary>
    /// <param name="ShowRequestPage">Boolean.</param>
    procedure PrintRecords(ShowRequestPage: Boolean)
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        DummyRentalReportSelections: Record "TWE Rental Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(DummyRentalReportSelections, Rec, ShowRequestPage, IsHandled);
        if not IsHandled then
            RentalDocumentSendingProfile.TrySendToPrinter(
              DummyRentalReportSelections.Usage::"R.Invoice".AsInteger(), Rec, FieldNo("Bill-to Customer No."), ShowRequestPage);
    end;

    /// <summary>
    /// PrintToDocumentAttachment.
    /// </summary>
    /// <param name="RentalInvoiceHeader">VAR Record "TWE Rental Invoice Header".</param>
    procedure PrintToDocumentAttachment(var RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := RentalInvoiceHeader.Count() = 1;
        if RentalInvoiceHeader.FindSet() then
            repeat
                DoPrintToDocumentAttachment(RentalInvoiceHeader, ShowNotificationAction);
            until RentalInvoiceHeader.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(RentalInvoiceHeader: Record "TWE Rental Invoice Header"; ShowNotificationAction: Boolean)
    var
        RentalReportSelections: Record "TWE Rental Report Selections";
    begin
        RentalInvoiceHeader.SetRecFilter();
        RentalReportSelections.SaveAsDocumentAttachment(
            RentalReportSelections.Usage::"R.Invoice".AsInteger(), RentalInvoiceHeader, RentalInvoiceHeader."No.", RentalInvoiceHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    /// <summary>
    /// EmailRecords.
    /// </summary>
    /// <param name="ShowDialog">Boolean.</param>
    procedure EmailRecords(ShowDialog: Boolean)
    var
        RentalDocumentSendingProfile: Record "TWE Rental Doc. Send. Profile";
        DummyRentalReportSelections: Record "TWE Rental Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeEmailRecords(DummyRentalReportSelections, Rec, DocumentTypeTxt, ShowDialog, IsHandled);
        if not IsHandled then
            RentalDocumentSendingProfile.TrySendToEMail(
              DummyRentalReportSelections.Usage::"R.Invoice".AsInteger(), Rec, FieldNo("No."), DocumentTypeTxt,
              FieldNo("Bill-to Customer No."), ShowDialog);
    end;

    /// <summary>
    /// GetDocTypeTxt.
    /// </summary>
    /// <returns>Return value of type Text[50].</returns>
    procedure GetDocTypeTxt(): Text[50]
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        exit(ReportDistributionMgt.GetFullDocumentTypeText(Rec));
    end;

    /// <summary>
    /// Navigate.
    /// </summary>
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    /// <summary>
    /// LookupAdjmtValueEntries.
    /// </summary>
    procedure LookupAdjmtValueEntries()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Rental Invoice");
        ValueEntry.SetRange(Adjustment, true);
        PAGE.RunModal(0, ValueEntry);
    end;

    /// <summary>
    /// GetCustomerVATRegistrationNumber.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    /// <summary>
    /// GetCustomerVATRegistrationNumberLbl.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// GetCustomerGlobalLocationNumber.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCustomerGlobalLocationNumber(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Rented-to Customer No.") then
            exit(Customer.GLN);
        exit('');
    end;

    /// <summary>
    /// GetCustomerGlobalLocationNumberLbl.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetCustomerGlobalLocationNumberLbl(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Rented-to Customer No.") then
            exit(Customer.FieldCaption(GLN));
        exit('');
    end;

    /// <summary>
    /// GetSellToCustomerFaxNo.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetRentedToCustomerFaxNo(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Rented-to Customer No.") then
            exit(Customer."Fax No.");
    end;

    /// <summary>
    /// GetPaymentReference.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetPaymentReference(): Text
    begin
        OnGetPaymentReference(PaymentReference);
        exit(PaymentReference);
    end;

    /// <summary>
    /// GetPaymentReferenceLbl.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetPaymentReferenceLbl(): Text
    begin
        OnGetPaymentReferenceLbl(PaymentReferenceLbl);
        exit(PaymentReferenceLbl);
    end;

    /// <summary>
    /// GetLegalStatement.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetLegalStatement(): Text
    begin
        RentalSetup.Get();
        exit(RentalSetup.GetLegalStatement());
    end;

    /// <summary>
    /// GetRemainingAmount.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure GetRemainingAmount(): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", "Bill-to Customer No.");
        CustLedgerEntry.SetRange("Posting Date", "Posting Date");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", "No.");
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");

        if not CustLedgerEntry.FindFirst() then
            exit(0);

        exit(CustLedgerEntry."Remaining Amount");
    end;

    procedure ShowDimensions()
    var
        Placeholder001Lbl: Label '%1 %2', Comment = '%1 = Document Type, %2 = No.';
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo(Placeholder001Lbl, TableCaption, "No."), 1, 250));
    end;

    procedure SetSecurityFilterOnRespCenter()
    begin
        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    /// <summary>
    /// GetDocExchStatusStyle.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetDocExchStatusStyle(): Text
    begin
        case "Document Exchange Status" of
            "Document Exchange Status"::"Not Sent":
                exit('Standard');
            "Document Exchange Status"::"Sent to Document Exchange Service":
                exit('Ambiguous');
            "Document Exchange Status"::"Delivered to Recipient":
                exit('Favorable');
            else
                exit('Unfavorable');
        end;
    end;

    /// <summary>
    /// ShowActivityLog.
    /// </summary>
    procedure ShowActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.ShowEntries(RecordId);
    end;

    /// <summary>
    /// StartTrackingSite.
    /// </summary>
    procedure StartTrackingSite()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        TestField("Shipping Agent Code");
        ShippingAgent.Get("Shipping Agent Code");
        HyperLink(ShippingAgent.GetTrackingInternetAddr("Package Tracking No."));
    end;

    /// <summary>
    /// GetSelectedPaymentsText.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetSelectedPaymentsText(): Text
    var
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        exit(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

    /// <summary>
    /// GetWorkDescription.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetWorkDescription(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo("Work Description"));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
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
        if GeneralLedgerSetup.Get() then
            if ("Currency Code" = '') or ("Currency Code" = GeneralLedgerSetup."LCY Code") then
                exit(GeneralLedgerSetup.GetCurrencySymbol());

        if Currency.Get("Currency Code") then
            exit(Currency.GetCurrencySymbol());

        exit("Currency Code");
    end;

    /// <summary>
    /// DocExchangeStatusIsSent.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure DocExchangeStatusIsSent(): Boolean
    begin
        exit("Document Exchange Status" <> "Document Exchange Status"::"Not Sent");
    end;

    /// <summary>
    /// ShowCanceledOrCorrCrMemo.
    /// </summary>
    procedure ShowCanceledOrCorrCrMemo()
    begin
        CalcFields(Cancelled, Corrective);
        case true of
            Cancelled:
                ShowCorrectiveCreditMemo();
            Corrective:
                ShowCancelledCreditMemo();
        end;
    end;

    /// <summary>
    /// ShowCorrectiveCreditMemo.
    /// </summary>
    procedure ShowCorrectiveCreditMemo()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        CalcFields(Cancelled);
        if not Cancelled then
            exit;

        if CancelledDocument.FindSalesCancelledInvoice("No.") then begin
            SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");
            PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
        end;
    end;

    /// <summary>
    /// ShowCancelledCreditMemo.
    /// </summary>
    procedure ShowCancelledCreditMemo()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        CalcFields(Corrective);
        if not Corrective then
            exit;

        if CancelledDocument.FindSalesCorrectiveInvoice("No.") then begin
            SalesCrMemoHeader.Get(CancelledDocument."Cancelled Doc. No.");
            PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
        end;
    end;

    /// <summary>
    /// GetDefaultEmailDocumentName.
    /// </summary>
    /// <returns>Return value of type Text[150].</returns>
    procedure GetDefaultEmailDocumentName(): Text[150]
    begin
        exit(DocTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var RentalReportSelections: Record "TWE Rental Report Selections"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; DocTxt: Text; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var RentalReportSelections: Record "TWE Rental Report Selections"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendProfile(var RentalReportSelections: Record "TWE Rental Report Selections"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "TWE Rental Doc. Send. Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(var RentalReportSelections: Record "TWE Rental Report Selections"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; DocTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnGetPaymentReference(var PaymentReference: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPaymentReferenceLbl(var PaymentReferenceLbl: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
    end;
}

