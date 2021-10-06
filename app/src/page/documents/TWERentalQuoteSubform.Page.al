/// <summary>
/// Page TWE Rental Quote Subform (ID 50016).
/// </summary>
page 50016 "TWE Rental Quote Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "TWE Rental Line";
    SourceTableView = WHERE("Document Type" = FILTER(Quote));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the type of entity that will be posted for this rental line, such as RentalItem, Resource, or G/L Account.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                        UpdateEditableOnRow();
                        UpdateTypeText();
                        DeltaUpdateTotals();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = NOT IsCommentLine;
                    ToolTip = 'Specifies the number of a general ledger account, RentalItem, resource, additional cost, or fixed asset, depending on the contents of the Type field.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate();
                        UpdateEditableOnRow();
                        UpdateTypeText();
                        DeltaUpdateTotals();

                        CurrPage.Update();
                    end;
                }
                field("Rental Item"; Rec."Rental Item")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = NOT IsCommentLine;
                    ToolTip = 'Specifies the number of a Service Item (Rental Item).';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = NOT IsCommentLine;
                    ToolTip = 'Specifies a description of the entry of the product to be sold. To add a non-transactional text line, fill in the Description field only.';

                    trigger OnValidate()
                    begin
                        UpdateEditableOnRow();

                        if Rec."No." = xRec."No." then
                            exit;

                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate();
                        UpdateTypeText();
                        DeltaUpdateTotals();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = NOT IsBlankNumber;
                    Enabled = NOT IsBlankNumber;
                    ToolTip = 'Specifies the inventory location from which the RentalItems sold should be picked and where the inventory decrease is registered.';

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate();
                        DeltaUpdateTotals();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = NOT IsBlankNumber;
                    Enabled = NOT IsBlankNumber;
                    ShowMandatory = (NOT IsCommentLine) AND (Rec."No." <> '');
                    ToolTip = 'Specifies how many units are being sold.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        QuantityOnAfterValidate();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = UnitofMeasureCodeIsChangeable;
                    Enabled = UnitofMeasureCodeIsChangeable;
                    ToolTip = 'Specifies how each unit of the RentalItem or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the RentalItem or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValidate();
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = NOT IsBlankNumber;
                    Enabled = NOT IsBlankNumber;
                    ShowMandatory = (NOT IsCommentLine) AND (Rec."No." <> '');
                    ToolTip = 'Specifies the price for one unit on the rental line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = NOT IsBlankNumber;
                    Enabled = NOT IsBlankNumber;
                    ToolTip = 'Specifies the discount percentage that is granted for the RentalItem on the line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount amount that is granted for the RentalItem on the line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = NOT IsBlankNumber;
                    Enabled = NOT IsBlankNumber;
                    ShowMandatory = (NOT IsCommentLine) AND (Rec."No." <> '');
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Rental Rate Code"; Rec."Rental Rate Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the rental rate code.';
                }
                field("Invoicing Period"; Rec."Invoicing Period")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the rental invoicing period.';
                }
                field("Total Days to Invoice"; Rec."Total Days to Invoice")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the total day to invoice.';
                }
                field("Duration to be billed"; Rec."Duration to be billed")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the duration to be billed.';
                }
                field("Invoiced Duration"; Rec."Invoiced Duration")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the invoiced duration.';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        AmountWithDiscountAllowed := RentalDocumentTotals.CalcTotalRentalAmountOnlyDiscountAllowed(Rec);
                        InvoiceDiscountAmount := Round(AmountWithDiscountAllowed * InvoiceDiscountPct / 100, Currency."Amount Rounding Precision");
                        ValidateInvoiceDiscountAmount();
                    end;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        UpdatePage();
                        DeltaUpdateTotals();
                    end;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';

                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of six local dimension codes that you set up in the General Ledger Setup window.';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of six local dimension codes that you set up in the General Ledger Setup window.';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of six local dimension codes that you set up in the General Ledger Setup window.';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of six local dimension codes that you set up in the General Ledger Setup window.';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of six local dimension codes that you set up in the General Ledger Setup window.';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of six local dimension codes that you set up in the General Ledger Setup window.';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(8);
                    end;
                }

            }
            group(Control53)
            {
                ShowCaption = false;
                group(Control49)
                {
                    ShowCaption = false;
                    field("Subtotal Excl. VAT"; TotalRentalLine."Line Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = RentalDocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(Currency.Code, TotalRentalHeader."Prices Including VAT");
                        Caption = 'Subtotal Excl. VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document.';
                    }
                    field("Invoice Discount Amount"; InvoiceDiscountAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = RentalDocumentTotals.GetInvoiceDiscAmountWithVATAndCurrencyCaption(Rec.FieldCaption("Inv. Discount Amount"), Currency.Code);
                        Caption = 'Invoice Discount Amount';
                        Editable = InvDiscAmountEditable;
                        ToolTip = 'Specifies a discount amount that is deducted from the value in the Total Incl. VAT field. You can enter or change the amount manually.';

                        trigger OnValidate()
                        begin
                            ValidateInvoiceDiscountAmount();
                        end;
                    }
                    field("Invoice Disc. Pct."; InvoiceDiscountPct)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invoice Discount %';
                        DecimalPlaces = 0 : 3;
                        Editable = InvDiscAmountEditable;
                        ToolTip = 'Specifies a discount percentage that is granted if criteria that you have set up for the customer are met.';

                        trigger OnValidate()
                        begin
                            AmountWithDiscountAllowed := RentalDocumentTotals.CalcTotalRentalAmountOnlyDiscountAllowed(Rec);
                            InvoiceDiscountAmount := Round(AmountWithDiscountAllowed * InvoiceDiscountPct / 100, Currency."Amount Rounding Precision");
                            ValidateInvoiceDiscountAmount();
                        end;
                    }
                }
                group(Control35)
                {
                    ShowCaption = false;
                    field("Total Amount Excl. VAT"; TotalRentalLine.Amount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = RentalDocumentTotals.GetTotalExclVATCaption(Currency.Code);
                        Caption = 'Total Amount Excl. VAT';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                    }
                    field("Total VAT Amount"; VATAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = RentalDocumentTotals.GetTotalVATCaption(Currency.Code);
                        Caption = 'Total VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of VAT amounts on all lines in the document.';
                    }
                    field("Total Amount Incl. VAT"; TotalRentalLine."Amount Including VAT")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = RentalDocumentTotals.GetTotalInclVATCaption(Currency.Code);
                        Caption = 'Total Amount Incl. VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Incl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {

            action(InsertExtTexts)
            {
                AccessByPermission = TableData "Extended Text Header" = R;
                ApplicationArea = Suite;
                Caption = 'Insert &Ext. Texts';
                Image = Text;
                ToolTip = 'Insert the extended RentalItem description that is set up for the RentalItem that is being processed on the line.';

                trigger OnAction()
                begin
                    InsertExtendedText(true);
                end;
            }
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to rental and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                end;
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("RentalItem Availability by")
                {
                    Enabled = Rec.Type = Rec.Type::"Rental Item";
                    Caption = 'RentalItem Availability by';
                    Image = ItemAvailability;
                    //  action(Events)
                    //  {
                    //      ApplicationArea = Basic, Suite;
                    //      Caption = 'Event';
                    //      Image = "Event";
                    //      ToolTip = 'View how the actual and the projected available balance of an RentalItem will develop over time according to supply and demand events.';

                    //trigger OnAction()
                    //begin
                    // RentalItemAvailFormsMgt.ShowRentalItemAvailFromSalesLine(Rec, RentalItemAvailFormsMgt.ByEvent)
                    //end;
                    //}
                    // action(Period)
                    //  {
                    //    ApplicationArea = Basic, Suite;
                    //    Caption = 'Period';
                    //    Image = Period;
                    //    ToolTip = 'Show the projected quantity of the RentalItem over time according to time periods, such as day, week, or month.';

                    //trigger OnAction()
                    //begin
                    // RentalItemAvailFormsMgt.ShowRentalItemAvailFromSalesLine(Rec, RentalItemAvailFormsMgt.ByPeriod)
                    //end;
                    //}
                    // action("Variant")
                    // {
                    //     ApplicationArea = Planning;
                    //     Caption = 'Variant';
                    //     Image = RentalItemVariant;
                    //     ToolTip = 'View or edit the RentalItem''s variants. Instead of setting up each color of an RentalItem as a separate RentalItem, you can set up the various colors as variants of the RentalItem.';

                    //   trigger OnAction()
                    //   begin
                    //   RentalItemAvailFormsMgt.ShowRentalItemAvailFromSalesLine(Rec, RentalItemAvailFormsMgt.ByVariant)
                    // end;
                    //}
                    //   action(Location)
                    //   {
                    //       AccessByPermission = TableData Location = R;
                    //       ApplicationArea = Location;
                    //       Caption = 'Location';
                    //      Image = Warehouse;
                    //      ToolTip = 'View the actual and projected quantity of the RentalItem per location.';

                    //    trigger OnAction()
                    //   begin
                    //    RentalItemAvailFormsMgt.ShowRentalItemAvailFromSalesLine(Rec, RentalItemAvailFormsMgt.ByLocation)
                    // end;
                    //}
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                action("RentalItem &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'RentalItem &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Shift+Ctrl+I';
                    Enabled = Rec.Type = Rec.Type::"Rental Item";
                    ToolTip = 'View or edit serial and lot numbers for the selected RentalItem. This action is available only for lines that contain an RentalItem.';

                    trigger OnAction()
                    var
                        RentalItem: Record "TWE Main Rental Item";
                    begin
                        RentalItem.Get(Rec."No.");
                        RentalItem.TestField("Assembly Policy", RentalItem."Assembly Policy"::"Assemble-to-Stock");
                        Rec.TestField("Qty. to Asm. to Order (Base)", 0);
                        //Rec.OpenItemTrackingLines();
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(GetPrice)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get &Price';
                    Ellipsis = true;
                    Image = Price;
                    Visible = true;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickPrice();
                    end;
                }
                action(GetLineDiscount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Li&ne Discount';
                    Ellipsis = true;
                    Image = LineDiscount;
                    Visible = true;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickDiscount();
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';

                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Visible = IsSaaSExcelAddinEnabled;
                    ToolTip = 'Send the data in the sub page to an Excel file for analysis or editing';
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                        Placeholder001Lbl: Label 'Document_No eq ''%1''', Comment = '%1 = Document No.';
                    begin
                        ODataUtility.EditWorksheetInExcel('Rental_QuoteRentalLines', CurrPage.ObjectId(false), StrSubstNo(Placeholder001Lbl, Rec."Document No."));
                    end;

                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetTotalRentalHeader();
        CalculateTotals();
        UpdateEditableOnRow();
        UpdateTypeText();
        SetRentalItemChargeFieldsStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        UpdateTypeText();
        SetRentalItemChargeFieldsStyle();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        RentalDocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RentalDocumentTotals.RentalCheckAndClearTotals(Rec, xRec, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        exit(Rec.Find(Which));
    end;

    trigger OnInit()
    begin
        RentalSetup.Get();
        Currency.InitRoundingPrecision();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        RentalDocumentTotals.RentalCheckIfDocumentChanged(Rec, xRec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Rec.InitType();
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
            if xRec."Document No." = '' then
                Rec.Type := Rec.Type::"Rental Item";

        Clear(ShortcutDimCode);
        UpdateTypeText();
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        SuppressTotals := CurrentClientType() = ClientType::ODataV4;

        SetDimensionsVisibility();
        SetRentalItemReferenceVisibility();
    end;

    var
        TotalRentalHeader: Record "TWE Rental Header";
        TotalRentalLine: Record "TWE Rental Line";
        Currency: Record Currency;
        RentalSetup: Record "TWE Rental Setup";
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        RentalTransferExtendedText: Codeunit "TWE Rental Trans. Ext. Text";
        RentalCalcDiscByType: Codeunit "TWE Rental-Calc Disc. By Type";
        RentalDocumentTotals: Codeunit "TWE Rental Document Totals";
        VATAmount: Decimal;
        AmountWithDiscountAllowed: Decimal;
        CurrPageIsEditable: Boolean;
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
        InvDiscAmountEditable: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        RentalItemChargeStyleExpression: Text;
        TypeAsText: Text[30];

    protected var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        IsBlankNumber: Boolean;
        IsCommentLine: Boolean;
        SuppressTotals: Boolean;
        [InDataSet]
        RentalItemReferenceVisible: Boolean;
        UnitofMeasureCodeIsChangeable: Boolean;

    /// <summary>
    /// ApproveCalcInvDisc.
    /// </summary>
    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", Rec);
        RentalDocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    local procedure ValidateInvoiceDiscountAmount()
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        if SuppressTotals then
            exit;

        RentalHeader.Get(Rec."Document Type", Rec."Document No.");
        RentalCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, RentalHeader);
        RentalDocumentTotals.RentalDocTotalsNotUpToDate();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// CalcInvDisc.
    /// </summary>
    procedure CalcInvDisc()
    var
        RentalCalcDiscount: Codeunit "TWE Rental-Calc. Discount";
    begin
        RentalCalcDiscount.CalculateInvoiceDiscountOnLine(Rec);
        RentalDocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    /// <summary>
    /// InsertExtendedText.
    /// </summary>
    /// <param name="Unconditionally">Boolean.</param>
    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        OnBeforeInsertExtendedText(Rec);
        if RentalTransferExtendedText.RentalCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            Commit();
            RentalTransferExtendedText.InsertRentalExtText(Rec);
        end;
        if RentalTransferExtendedText.MakeUpdate() then
            UpdateForm(true);
    end;

    local procedure ShowRentalItemSub()
    begin
        ShowRentalItemSub();
    end;

    /// <summary>
    /// UpdateForm.
    /// </summary>
    /// <param name="SetSaveRecord">Boolean.</param>
    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    /// <summary>
    /// NoOnAfterValidate.
    /// </summary>
    procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
        if (Rec."No." <> xRec."No.") and (xRec."No." <> '')
        then
            CurrPage.SaveRecord();

        OnAfterNoOnAfterValidate(Rec, xRec);

        SaveAndAutoAsmToOrder();
    end;

    protected procedure LocationCodeOnAfterValidate()
    begin
        SaveAndAutoAsmToOrder();
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;
        DeltaUpdateTotals();
    end;

    protected procedure UnitofMeasureCodeOnAfterValidate()
    begin
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;
        DeltaUpdateTotals();
    end;

    local procedure SaveAndAutoAsmToOrder()
    begin
        if (Rec.Type = Rec.Type::"Rental Item") and Rec.IsAsmToOrderRequired() then begin
            CurrPage.SaveRecord();
            Rec.AutoAsmToOrder();
        end;
    end;

    /// <summary>
    /// UpdateEditableOnRow.
    /// </summary>
    procedure UpdateEditableOnRow()
    begin
        IsCommentLine := not Rec.HasTypeToFillMandatoryFields();
        IsBlankNumber := IsCommentLine;
        UnitofMeasureCodeIsChangeable := not IsCommentLine;

        CurrPageIsEditable := CurrPage.Editable;
        InvDiscAmountEditable := CurrPageIsEditable and not RentalSetup."Calc. Inv. Discount";

        OnAfterUpdateEditableOnRow(Rec, IsCommentLine, IsBlankNumber);
    end;

    local procedure UpdatePage()
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        CurrPage.Update();
        RentalHeader.Get(Rec."Document Type", Rec."Document No.");
        //SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(TotalRentalHeader."Invoice Discount Amount", RentalHeader);
    end;

    local procedure GetTotalRentalHeader()
    begin
        RentalDocumentTotals.GetTotalRentalHeaderAndCurrency(Rec, TotalRentalHeader, Currency);
    end;

    local procedure CalculateTotals()
    begin
        if SuppressTotals then
            exit;

        RentalDocumentTotals.RentalCheckIfDocumentChanged(Rec, xRec);
        RentalDocumentTotals.CalculateRentalSubPageTotals(TotalRentalHeader, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        RentalDocumentTotals.RefreshRentalLine(Rec);
    end;

    /// <summary>
    /// DeltaUpdateTotals.
    /// </summary>
    procedure DeltaUpdateTotals()
    begin
        if SuppressTotals then
            exit;

        RentalDocumentTotals.RentalDeltaUpdateTotals(Rec, xRec, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        if Rec."Line Amount" <> xRec."Line Amount" then
            Rec.SendLineInvoiceDiscountResetNotification();
    end;

    /// <summary>
    /// RedistributeTotalsOnAfterValidate.
    /// </summary>
    procedure RedistributeTotalsOnAfterValidate()
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        if SuppressTotals then
            exit;

        CurrPage.SaveRecord();

        RentalHeader.Get(Rec."Document Type", Rec."Document No.");
        RentalDocumentTotals.RentalRedistributeInvoiceDiscountAmounts(Rec, VATAmount, TotalRentalLine);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// UpdateTypeText.
    /// </summary>
    procedure UpdateTypeText()
    var
        RecRef: RecordRef;
    begin
        OnBeforeUpdateTypeText(Rec);

        RecRef.GetTable(Rec);
        TypeAsText := TempOptionLookupBuffer.FormatOption(RecRef.Field(Rec.FieldNo(Type)));
    end;

    /// <summary>
    /// SetRentalItemChargeFieldsStyle.
    /// </summary>
    procedure SetRentalItemChargeFieldsStyle()
    begin
        RentalItemChargeStyleExpression := '';
        //   if AssignedRentalItemCharge then
        //      RentalItemChargeStyleExpression := 'Unfavorable';
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    local procedure SetRentalItemReferenceVisibility()
    var
        RentalItemReferenceMgt: Codeunit "Item Reference Management";
    begin
        RentalItemReferenceVisible := RentalItemReferenceMgt.IsEnabled();
    end;

    local procedure ValidateShortcutDimension(DimIndex: Integer)
    begin
        Rec.ValidateShortcutDimCode(DimIndex, ShortcutDimCode[DimIndex]);

        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, DimIndex);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterNoOnAfterValidate(var RentalLine: Record "TWE Rental Line"; xRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateEditableOnRow(RentalLine: Record "TWE Rental Line"; var IsCommentLine: Boolean; var IsBlankNumber: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var RentalLine: Record "TWE Rental Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTypeText(var RentalLine: Record "TWE Rental Line")
    begin
    end;
}

