/// <summary>
/// Table TWE Rental Setup (ID 50101).
/// </summary>
table 50030 "TWE Rental Setup"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = AccountData;
        }
        field(2; "Automatic Cost Posting"; Boolean)
        {
            Caption = 'Automatic Cost Posting';
            DataClassification = AccountData;

            /* trigger OnValidate()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if "Automatic Cost Posting" then
                    if GLSetup.Get() then
                        if not GLSetup."Use Legacy G/L Entry Locking" then
                            Message(Text002Lbl,
                              FieldCaption("Automatic Cost Posting"),
                              "Automatic Cost Posting",
                              GLSetup.FieldCaption("Use Legacy G/L Entry Locking"),
                              GLSetup.TableCaption,
                              GLSetup."Use Legacy G/L Entry Locking");
            end; */
        }
        field(3; "Location Mandatory"; Boolean)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Mandatory';
            DataClassification = AccountData;
        }
        field(4; "Rental Item Nos."; Code[20])
        {
            Caption = 'Rental Item Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(5; "Default Costing Method"; Enum "Costing Method")
        {
            Caption = 'Default Costing Method';
            DataClassification = AccountData;
        }
        field(6; "Rent. Item Group Dim. Code"; Code[20])
        {
            Caption = 'Rental Item Group Dimension Code';
            DataClassification = AccountData;
            TableRelation = Dimension;
        }
        field(7; "Calc. Inv. Discount"; Boolean)
        {
            Caption = 'Calc. Inv. Discount';
            DataClassification = AccountData;
        }

        field(8; "Discount Posting"; Option)
        {
            Caption = 'Discount Posting';
            DataClassification = AccountData;
            OptionCaption = 'No Discounts,Invoice Discounts,Line Discounts,All Discounts';
            OptionMembers = "No Discounts","Invoice Discounts","Line Discounts","All Discounts";

            trigger OnValidate()
            var
                DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
            begin
                DiscountNotificationMgt.NotifyAboutMissingSetup(RecordId, '', "Discount Posting", 0);
            end;
        }

        field(10; "Rental Quote Nos."; Code[20])
        {
            Caption = 'Rental Quote Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(11; "Rental Contract Nos."; Code[20])
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Rental Contract Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(12; "Rental Invoice Nos."; Code[20])
        {
            Caption = 'Rental Invoice Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(13; "Posted Rental Invoice Nos."; Code[20])
        {
            Caption = 'Posted Rental Invoice Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(14; "Rental Credit Memo Nos."; Code[20])
        {
            Caption = 'Rental Credit Memo Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(15; "Posted Rental Credit Memo Nos."; Code[20])
        {
            Caption = 'Posted Rental Credit Memo Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(16; "Rental Shipment Nos."; Code[20])
        {
            Caption = 'Rental Shipment Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(17; "Posted Rental Shipment Nos."; Code[20])
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Posted Rental Shipment Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }

        field(18; "Rental Return Shipment Nos."; Code[20])
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Rental Return Shipment Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(19; "Post. Rent. Return Shipm. Nos."; Code[20])
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Posted Rental Return Shipment Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(20; "Posted Prepmt. Inv. Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Inv. Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(21; "Main Rental Item Nos."; Code[20])
        {
            Caption = 'Main Rental Item Nos.';
            DataClassification = AccountData;
            TableRelation = "No. Series";
        }
        field(30; "Credit Warnings"; Option)
        {
            Caption = 'Credit Warnings';
            DataClassification = AccountData;
            OptionCaption = 'Both Warnings,Credit Limit,Overdue Balance,No Warning';
            OptionMembers = "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        }
        field(31; "Shipment on Invoice"; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Shipment on Invoice';
            DataClassification = AccountData;
        }
        field(32; "Invoice Rounding"; Boolean)
        {
            Caption = 'Invoice Rounding';
            DataClassification = AccountData;
        }
        field(33; "Ext. Doc. No. Mandatory"; Boolean)
        {
            Caption = 'Ext. Doc. No. Mandatory';
            DataClassification = AccountData;
        }
        field(34; "Copy Comments Contract to Inv."; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            DataClassification = AccountData;
            Caption = 'Copy Comments Order to Invoice';
            InitValue = true;
        }
        field(35; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';
            DataClassification = AccountData;
        }
        field(36; "Default Posting Date"; Enum "Default Posting Date")
        {
            Caption = 'Default Posting Date';
            DataClassification = AccountData;
        }
        field(38; "Post with Job Queue"; Boolean)
        {
            Caption = 'Post with Job Queue';
            DataClassification = AccountData;

            trigger OnValidate()
            begin
                if not "Post with Job Queue" then
                    "Post & Print with Job Queue" := false;
            end;
        }
        field(39; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            DataClassification = AccountData;
            TableRelation = "Job Queue Category";
        }
        field(40; "Job Queue Priority for Post"; Integer)
        {
            Caption = 'Job Queue Priority for Post';
            DataClassification = AccountData;
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001Lbl);
            end;
        }
        field(41; "Post & Print with Job Queue"; Boolean)
        {
            Caption = 'Post & Print with Job Queue';
            DataClassification = AccountData;

            trigger OnValidate()
            begin
                if "Post & Print with Job Queue" then
                    "Post with Job Queue" := true;
            end;
        }
        field(42; "Job Q. Prio. for Post & Print"; Integer)
        {
            Caption = 'Job Q. Prio. for Post & Print';
            DataClassification = AccountData;
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001Lbl);
            end;
        }
        field(43; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
            DataClassification = AccountData;
        }
        field(50; "Copy Comments Contr. to Shpt."; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Copy Comments Contract to Shpt.';
            DataClassification = AccountData;
            InitValue = true;
        }
        field(51; "Default Quantity to Ship"; Option)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Default Quantity to Ship';
            DataClassification = AccountData;
            OptionCaption = 'Remainder,Blank';
            OptionMembers = Remainder,Blank;
        }
        field(52; "Calc. Inv. Disc. per VAT ID"; Boolean)
        {
            Caption = 'Calc. Inv. Disc. per VAT ID';
            DataClassification = AccountData;
        }
        field(60; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            DataClassification = AccountData;
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(61; "Display of the address line"; Boolean)
        {
            Caption = 'Display of the address line';
            DataClassification = AccountData;
        }
        field(100; "Create an unbooked Invoice"; Boolean)
        {
            Caption = 'Create an unbooked Invoice when invoicing';
            DataClassification = AccountData;
        }
        field(150; "Archive Quotes"; Option)
        {
            Caption = 'Archive Quotes';
            DataClassification = AccountData;
            OptionCaption = 'Never,Question,Always';
            OptionMembers = Never,Question,Always;
        }
        field(151; "Archive Contracts"; Boolean)
        {
            Caption = 'Archive Contracts';
            DataClassification = AccountData;
        }
        field(152; "Delete Contract"; Boolean)
        {
            Caption = 'Delete Contracts after completion';
            DataClassification = AccountData;
            InitValue = true;
        }
        field(200; "Base Unit for new Rental Item"; Code[20])
        {
            Caption = 'Base Unit for new Rental Item';
            DataClassification = AccountData;
            TableRelation = "Unit of Measure".Code;
        }
        field(300; "Standard Item Jnl. Batch Name"; Code[20])
        {
            Caption = 'Standard Item Batch Name for convert.';
            DataClassification = AccountData;
            TableRelation = "Item Journal Batch".Name;
        }
        field(301; "Standard Jnl. Template Name"; Code[20])
        {
            Caption = 'Standard Item Jnl. Name for convert.';
            DataClassification = AccountData;
            TableRelation = "Item Journal Template";
        }
        field(302; "Stand. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Standard Gen. Bus. Posting Group.';
            DataClassification = AccountData;
            TableRelation = "Gen. Business Posting Group";
        }
        field(303; "Report Output Type"; Option)
        {
            Caption = 'Report Output Type';
            DataClassification = CustomerContent;
            OptionCaption = 'PDF,,,Print';
            OptionMembers = PDF,,,Print;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS() then
                        TestField("Report Output Type", "Report Output Type"::PDF);
            end;
        }
        field(304; "Check Prepmt. when Posting"; Boolean)
        {
            Caption = 'Check Prepmt. when Posting';
            DataClassification = CustomerContent;
        }
        field(22; "Posted Prepmt. Cr. Memo Nos."; Code[20])
        {
            Caption = 'Posted Prepmt. Cr. Memo Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(400; "Auto. Creation of Assets"; Boolean)
        {
            Caption = 'Auto. Creation of Assets';
            DataClassification = CustomerContent;
        }
        field(411; "Standard Asset Posting Group"; Code[20])
        {
            Caption = 'Standard Asset Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "FA Posting Group";
        }
        field(401; "Stand. Asset Class Code"; Code[20])
        {
            Caption = 'Standard Fixed Asset Class Code';
            DataClassification = CustomerContent;
            TableRelation = "FA Class";
        }
        field(402; "Stand. Asset Subclass Code"; Code[20])
        {
            Caption = 'Standard Fixed Asset Subclass Code';
            DataClassification = CustomerContent;
            TableRelation = "FA Subclass";
        }
        field(410; "Stand. Asset Location Code"; Code[20])
        {
            Caption = 'Standard Asset Location Code';
            DataClassification = CustomerContent;
            TableRelation = "FA Location";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001Lbl: Label 'Job Queue Priority must be zero or positive.';


    /// <summary>
    /// GetLegalStatement.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetLegalStatement(): Text
    begin
        exit('');
    end;

    /// <summary>
    /// JobQueueActive.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure JobQueueActive(): Boolean
    begin
        Rec.Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

    /// <summary>
    /// GetSetup.
    /// Gets or initializes setup data.
    /// </summary>
    procedure GetSetup()
    begin
        if not FindFirst() then begin
            Init();
            Insert();
        end;
    end;


}
