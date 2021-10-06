/// <summary>
/// Page TWE Rental Contract Subform (ID 70704614).
/// </summary>
page 50002 "TWE Closed Rent. Cont. Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "TWE Rental Line";
    SourceTableView = WHERE("Document Type" = FILTER(Contract));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entity that will be posted for this rental line, such as Item, Resource, or G/L Account.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                        SetLocationCodeMandatory();
                        UpdateEditableOnRow();
                        UpdateTypeText();
                        DeltaUpdateTotals();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = NOT IsCommentLine;
                    ToolTip = 'Specifies the number of a general ledger account, item, resource, additional cost, or fixed asset, depending on the contents of the Type field.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                        UpdateEditableOnRow();
                        Rec.ShowShortcutDimCode(ShortcutDimCode);

                        QuantityOnAfterValidate();
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
                    QuickEntry = false;
                    ShowMandatory = NOT IsCommentLine;
                    ToolTip = 'Specifies a description of the entry of the product to be sold. To add a non-transactional text line, fill in the Description field only.';

                    trigger OnValidate()
                    begin
                        UpdateEditableOnRow();

                        if Rec."No." = xRec."No." then
                            exit;

                        NoOnAfterValidate();
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        UpdateTypeText();
                        DeltaUpdateTotals();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = NOT IsCommentLine;
                    Enabled = NOT IsCommentLine;
                    ShowMandatory = (NOT IsCommentLine) AND (Rec."No." <> '');
                    ToolTip = 'Specifies how many units are being sold.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                        DeltaUpdateTotals();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = UnitofMeasureCodeIsChangeable;
                    Enabled = UnitofMeasureCodeIsChangeable;
                    QuickEntry = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValidate();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = NOT IsBlankNumber;
                    Enabled = NOT IsBlankNumber;
                    QuickEntry = false;
                    ShowMandatory = LocationCodeMandatory;
                    ToolTip = 'Specifies the inventory location from which the items sold should be picked and where the inventory decrease is registered.';
                    Visible = LocationCodeVisible;

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate();
                        DeltaUpdateTotals();
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
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;

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
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';

                    trigger OnValidate()
                    begin
                        if Rec."Qty. to Asm. to Order (Base)" <> 0 then begin
                            CurrPage.SaveRecord();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as shipped.';
                }

                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Return Quantity"; Rec."Return Quantity")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the rental return quantity.';
                }
                field("Quantity returned"; Rec."Quantity Returned")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the rental quantity returned.';
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
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment percentage to use to calculate the prepayment for rental.';
                    Visible = false;
                }
                field("Prepmt. Line Amount"; Rec."Prepmt. Line Amount")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment amount of the line in the currency of the rental document if a prepayment percentage is specified for the rental line.';
                    Visible = false;
                }
                field("Prepmt. Amt. Inv."; Rec."Prepmt. Amt. Inv.")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment amount that has already been invoiced to the customer for this rental line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        AmountWithDiscountAllowed := DocumentTotals.CalcTotalRentalAmountOnlyDiscountAllowed(Rec);
                        InvoiceDiscountAmount := Round(AmountWithDiscountAllowed * InvoiceDiscountPct / 100, Currency."Amount Rounding Precision");
                        ValidateInvoiceDiscountAmount();
                    end;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Inv. Disc. Amount to Invoice"; Rec."Inv. Disc. Amount to Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual invoice discount amount that will be posted for the line in next invoice.';
                    Visible = false;
                }
                field("Invoicing Date"; Rec."Invoicing Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the rental invoicing date.';
                }
                field("Billing Start Date"; Rec."Billing Start Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the billing start date.';
                }
                field("Billing End Date"; Rec."Billing End Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the billing end date.';
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
                field("Line Closed"; Rec."Line Closed")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if line is closed.';
                }
                field("Prepmt Amt to Deduct"; Rec."Prepmt Amt to Deduct")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment amount that has already been deducted from ordinary invoices posted for this rental contract line.';
                    Visible = false;
                }
                field("Prepmt Amt Deducted"; Rec."Prepmt Amt Deducted")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment amount that has already been deducted from ordinary invoices posted for this rental contract line.';
                    Visible = false;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the customer has asked for the contract to be delivered.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        UpdateForm(true);
                    end;
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies the date that you have promised to deliver the contract, as a result of the Order Promising function.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        UpdateForm(true);
                    end;
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = Planning;
                    QuickEntry = false;
                    ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';

                    trigger OnValidate()
                    begin
                        UpdateForm(true);
                    end;
                }
                field("Planned Shipment Date"; Rec."Planned Shipment Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date that the shipment should ship from the warehouse. If the customer requests a delivery date, the program calculates the planned shipment date by subtracting the shipping time from the requested delivery date. If the customer does not request a delivery date or the requested delivery date cannot be met, the program calculates the content of this field by adding the shipment time to the shipping date.';

                    trigger OnValidate()
                    begin
                        UpdateForm(true);
                    end;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';

                    trigger OnValidate()
                    begin
                        ShipmentDateOnAfterValidate();
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
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible3;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of seven shortcut dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible4;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of seven shortcut dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible5;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of seven shortcut dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible6;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of seven shortcut dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible7;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of seven shortcut dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible8;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of seven shortcut dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(8);
                    end;
                }
            }
            group(Control51)
            {
                ShowCaption = false;
                group(Control45)
                {
                    ShowCaption = false;
                    field(TotalRentalLineLineAmount; TotalRentalLine."Line Amount")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(Currency.Code, TotalRentalHeader."Prices Including VAT");
                        Caption = 'Subtotal Excl. VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document.';
                    }
                    field("Invoice Discount Amount"; InvoiceDiscountAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetInvoiceDiscAmountWithVATAndCurrencyCaption(Rec.FieldCaption("Inv. Discount Amount"), Currency.Code);
                        Caption = 'Invoice Discount Amount';
                        Editable = InvDiscAmountEditable;
                        ToolTip = 'Specifies a discount amount that is deducted from the value in the Total Incl. VAT field. You can enter or change the amount manually.';

                        trigger OnValidate()
                        begin
                            DocumentTotals.RentalDocTotalsNotUpToDate();
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
                            DocumentTotals.RentalDocTotalsNotUpToDate();
                            AmountWithDiscountAllowed := DocumentTotals.CalcTotalRentalAmountOnlyDiscountAllowed(Rec);
                            InvoiceDiscountAmount := Round(AmountWithDiscountAllowed * InvoiceDiscountPct / 100, Currency."Amount Rounding Precision");
                            ValidateInvoiceDiscountAmount();
                        end;
                    }
                }
                group(Control28)
                {
                    ShowCaption = false;
                    field("Total Amount Excl. VAT"; TotalRentalLine.Amount)
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalExclVATCaption(Currency.Code);
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
                        CaptionClass = DocumentTotals.GetTotalVATCaption(Currency.Code);
                        Caption = 'Total VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of VAT amounts on all lines in the document.';
                    }
                    field("Total Amount Incl. VAT"; TotalRentalLine."Amount Including VAT")
                    {
                        ApplicationArea = Basic, Suite;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalInclVATCaption(Currency.Code);
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
            //action(SelectMultiItems)
            // {
            //     AccessByPermission = TableData Item = R;
            //     ApplicationArea = Basic, Suite;
            //      Caption = 'Select items';
            //      Ellipsis = true;
            //      Image = NewItem;
            //      ToolTip = 'Add two or more items from the full list of your inventory items.';

            //trigger OnAction()
            //begin
            //SelectMultipleItems();
            //end;
            //            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("F&unctions")
                {
                    Caption = 'F&unctions';
                    Image = "Action";
                    action(GetPrices)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Get Price';
                        Ellipsis = true;
                        Image = Price;
                        Visible = true;
                        ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                        trigger OnAction()
                        begin
                            ShowPrices();
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
                            ShowLineDisc();
                        end;
                    }
                    action("Insert Ext. Texts")
                    {
                        AccessByPermission = TableData "Extended Text Header" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Insert &Ext. Texts';
                        Image = Text;
                        ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                        trigger OnAction()
                        begin
                            InsertExtendedText(true);
                        end;
                    }
                    action(Reserve)
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reserve';
                        Ellipsis = true;
                        Image = Reserve;
                        Enabled = Rec.Type = Rec.Type::"Rental Item";
                        ToolTip = 'Reserve the quantity of the selected item that is required on the document line from which you opened this page. This action is available only for lines that contain an item.';

                        trigger OnAction()
                        begin
                            Rec.Find();
                            Rec.ShowReservation();
                        end;
                    }
                    action(OrderTracking)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order &Tracking';
                        Image = OrderTracking;
                        Enabled = Rec.Type = Rec.Type::"Rental Item";
                        ToolTip = 'Track the connection of a supply to its corresponding demand for the selected item. This can help you find the original demand that created a specific production order or purchase order. This action is available only for lines that contain an item.';

                        trigger OnAction()
                        begin
                            ShowTracking();
                        end;
                    }
                }
                group("Item Availability by")
                {
                    Enabled = Rec.Type = Rec.Type::"Rental Item";
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    // action("<Action3>")
                    //  {
                    //       ApplicationArea = Basic, Suite;
                    //       Caption = 'Event';
                    //       Image = "Event";
                    //      ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    //     trigger OnAction()
                    //      begin
                    //           //    ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, ItemAvailFormsMgt.ByEvent)
                    //       end;
                    //     }
                    //      action(ItemAvailabilityByPeriod)
                    //       {
                    //           ApplicationArea = Basic, Suite;
                    //           Caption = 'Period';
                    //          Image = Period;
                    //          ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

                    //     trigger OnAction()
                    //     begin
                    //     ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, ItemAvailFormsMgt.ByPeriod)
                    //     end;
                    // }
                    //    action(ItemAvailabilityByVariant)
                    ////   {
                    //         ApplicationArea = Planning;
                    //         Caption = 'Variant';
                    //         Image = ItemVariant;
                    //         ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                    //         trigger OnAction()
                    //         begin
                    // ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, ItemAvailFormsMgt.ByVariant)
                    //          end;
                    ////     }
                    //       action(ItemAvailabilityByLocation)
                    ////          {
                    ////             AccessByPermission = TableData Location = R;
                    //          ApplicationArea = Location;
                    //           Caption = 'Location';
                    //           Image = Warehouse;
                    //           ToolTip = 'View the actual and projected quantity of the item per location.';

                    //            trigger OnAction()
                    //             begin
                    //                 //     ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, ItemAvailFormsMgt.ByLocation)
                    //             end;
                    //         }
                    //        action(ItemAvailabilityByUnitOfMeasure)
                    //         {
                    //             ApplicationArea = Basic, Suite;
                    //             Caption = 'Unit of Measure';
                    //             Image = UnitOfMeasure;
                    //             ToolTip = 'View the item''s availability by a unit of measure.';

                    //             trigger OnAction()
                    ////             begin
                    //    ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, ItemAvailFormsMgt.ByUOM);
                    //             end;
                    //         }
                }
                group("Related Information")
                {
                    Caption = 'Related Information';
                    action("Reservation Entries")
                    {
                        AccessByPermission = TableData Item = R;
                        ApplicationArea = Reservation;
                        Caption = 'Reservation Entries';
                        Image = ReservationLedger;
                        Enabled = Rec.Type = Rec.Type::"Rental Item";
                        ToolTip = 'View all reservation entries for the selected item. This action is available only for lines that contain an item.';

                        trigger OnAction()
                        begin
                            Rec.ShowReservationEntries(true);
                        end;
                    }
                    //        action(ItemTrackingLines)
                    //         {
                    //             ApplicationArea = ItemTracking;
                    //             Caption = 'Item &Tracking Lines';
                    //             Image = ItemTrackingLines;
                    //             ShortCutKey = 'Shift+Ctrl+I';
                    //             Enabled = Rec.Type = Rec.Type::"Rental Item";
                    //             ToolTip = 'View or edit serial and lot numbers for the selected item. This action is available only for lines that contain an item.';

                    //             trigger OnAction()
                    //             begin
                    //OpenItemTrackingLines();
                    //             end;
                    //         }

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
                    action(OrderPromising)
                    {
                        AccessByPermission = TableData "Order Promising Line" = R;
                        ApplicationArea = OrderPromising;
                        Caption = 'Order &Promising';
                        Image = OrderPromising;
                        ToolTip = 'Calculate the shipment and delivery dates based on the item''s known and expected availability dates, and then promise the dates to the customer.';

                        trigger OnAction()
                        begin
                            OrderPromisingLine();
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

                    /*    action(DocumentLineTracking)
                       {
                           ApplicationArea = Basic, Suite;
                           Caption = 'Document &Line Tracking';
                           Image = Navigate;
                           ToolTip = 'View related open, posted, or archived documents or document lines. ';

                           trigger OnAction()
                           begin
                               ShowDocumentLineTracking();
                           end;
                       } */
                }
            }
            group("O&rder")
            {
                Caption = 'C&ontract';
                Image = "Order";
                group("Dr&op Shipment")
                {
                    Caption = 'Dr&op Shipment';
                    Image = Delivery;
                    action("Purchase &Order")
                    {
                        AccessByPermission = TableData "Purch. Rcpt. Header" = R;
                        ApplicationArea = Suite;
                        Caption = 'Purchase &Order';
                        Image = Document;
                        ToolTip = 'View the purchase order that is linked to the rental order, for drop shipment or special order.';

                        trigger OnAction()
                        begin
                            OpenPurchOrderForm();
                        end;
                    }
                }
                group("Speci&al Order")
                {
                    Caption = 'Speci&al Order';
                    Image = SpecialOrder;
                    action(OpenSpecialPurchaseOrder)
                    {
                        AccessByPermission = TableData "Purch. Rcpt. Header" = R;
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase &Order';
                        Image = Document;
                        ToolTip = 'View the purchase order that is linked to the rental contract, for drop shipment or special order.';

                        trigger OnAction()
                        begin
                            OpenSpecialPurchOrderForm();
                        end;
                    }
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
                        ODataUtility.EditWorksheetInExcel('Rental_Contract_Line', CurrPage.ObjectId(false), StrSubstNo(Placeholder001Lbl, Rec."Document No."));
                    end;

                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetTotalRentalHeader();
        CalculateTotals();
        SetLocationCodeMandatory();
        UpdateEditableOnRow();
        UpdateTypeText();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        UpdateTypeText();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        DocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        DocumentTotals.RentalCheckAndClearTotals(Rec, xRec, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        exit(Rec.Find(Which));
    end;

    trigger OnInit()
    var
        LocalApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        RentalSetup.GetSetup();
        Currency.InitRoundingPrecision();
        IsFoundation := LocalApplicationAreaMgmtFacade.IsFoundationEnabled();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        DocumentTotals.RentalCheckIfDocumentChanged(Rec, xRec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.InitType();
        SetDefaultType();

        // Default to Item for the first line and to previous line type for the others
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
            if xRec."Document No." = '' then
                Rec.Type := Rec.Type::"Rental Item";
        Clear(ShortcutDimCode);
        UpdateTypeText();
    end;

    trigger OnOpenPage()
    var
        Location: Record Location;
        ServerSetting: Codeunit "Server Setting";
    begin
        if Location.ReadPermission then
            LocationCodeVisible := not Location.IsEmpty();

        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        SuppressTotals := CurrentClientType() = ClientType::ODataV4;

        SetDimensionsVisibility();
        //SetItemReferenceVisibility();
    end;

    var
        Currency: Record Currency;
        TotalRentalHeader: Record "TWE Rental Header";
        TotalRentalLine: Record "TWE Rental Line";
        RentalSetup: Record "TWE Rental Setup";
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        RentalTransferExtendedText: Codeunit "TWE Rental Trans. Ext. Text";
        //ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        RentalCalcDiscountByType: Codeunit "TWE Rental-Calc Disc. By Type";
        DocumentTotals: Codeunit "TWE Rental Document Totals";
        VATAmount: Decimal;
        AmountWithDiscountAllowed: Decimal;
        LocationCodeMandatory: Boolean;
        InvDiscAmountEditable: Boolean;
        UnitofMeasureCodeIsChangeable: Boolean;
        LocationCodeVisible: Boolean;
        IsFoundation: Boolean;
        CurrPageIsEditable: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
        //ItemChargeStyleExpression: Text;
        TypeAsText: Text[30];
        SuppressTotals: Boolean;
        Text001Lbl: Label 'You cannot use the Explode BOM function because a prepayment of the rental contract has been invoiced.';
        UpdateInvDiscountQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';

    //[InDataSet]
    //ItemReferenceVisible: Boolean;

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
        IsCommentLine: Boolean;
        IsBlankNumber: Boolean;

    /// <summary>
    /// ApproveCalcInvDisc.
    /// </summary>
    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", Rec);
        DocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    local procedure ValidateInvoiceDiscountAmount()
    var
        RentalHeader: Record "TWE Rental Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if SuppressTotals then
            exit;

        RentalHeader.Get(Rec."Document Type", Rec."Document No.");
        if RentalHeader.InvoicedLineExists() then
            if not ConfirmManagement.GetResponseOrDefault(UpdateInvDiscountQst, true) then
                exit;

        RentalCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, RentalHeader);
        DocumentTotals.RentalDocTotalsNotUpToDate();
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
        DocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    /// <summary>
    /// ExplodeBOM.
    /// </summary>
    procedure ExplodeBOM()
    begin
        if Rec."Prepmt. Amt. Inv." <> 0 then
            Error(Text001Lbl);
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", Rec);
        DocumentTotals.RentalDocTotalsNotUpToDate();
    end;

    /// <summary>
    /// OpenPurchOrderForm.
    /// </summary>
    procedure OpenPurchOrderForm()
    var
        PurchHeader: Record "Purchase Header";
        PurchOrder: Page "Purchase Order";
    begin
        Rec.TestField("Purchase Order No.");
        PurchHeader.SetRange("No.", Rec."Purchase Order No.");
        PurchOrder.SetTableView(PurchHeader);
        PurchOrder.Editable := false;
        PurchOrder.Run();
    end;

    /// <summary>
    /// OpenSpecialPurchOrderForm.
    /// </summary>
    procedure OpenSpecialPurchOrderForm()
    var
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchOrder: Page "Purchase Order";
    begin
        Rec.TestField("Special Order Purchase No.");
        PurchHeader.SetRange("No.", Rec."Special Order Purchase No.");
        if not PurchHeader.IsEmpty then begin
            PurchOrder.SetTableView(PurchHeader);
            PurchOrder.Editable := false;
            PurchOrder.Run();
        end else begin
            PurchRcptHeader.SetRange("Order No.", Rec."Special Order Purchase No.");
            if PurchRcptHeader.Count = 1 then
                PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader)
            else
                PAGE.Run(PAGE::"Posted Purchase Receipts", PurchRcptHeader);
        end;
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

    /// <summary>
    /// ShowNonstockItems.
    /// </summary>
    procedure ShowNonstockItems()
    begin
        Rec.ShowNonstock();
    end;

    /// <summary>
    /// ShowTracking.
    /// </summary>
    procedure ShowTracking()
    var
        TrackingForm: Page "Order Tracking";
    begin
        // TrackingForm.SetSalesLine(Rec);
        TrackingForm.RunModal();
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
    /// ShowPrices.
    /// </summary>
    procedure ShowPrices()
    begin
        Rec.PickPrice();
    end;

    procedure ShowLineDisc()
    begin
        Rec.PickDiscount();
    end;

    procedure OrderPromisingLine()
    var
        TempOrderPromisingLine: Record "Order Promising Line" temporary;
        OrderPromisingLines: Page "Order Promising Lines";
    begin
        TempOrderPromisingLine.SetRange("Source Type", Rec."Document Type");
        TempOrderPromisingLine.SetRange("Source ID", Rec."Document No.");
        TempOrderPromisingLine.SetRange("Source Line No.", Rec."Line No.");

        OrderPromisingLines.SetSourceType(TempOrderPromisingLine."Source Type"::Sales.AsInteger());
        OrderPromisingLines.SetTableView(TempOrderPromisingLine);
        OrderPromisingLines.RunModal();
    end;

    procedure NoOnAfterValidate()
    begin
        //InsertExtendedText(false);
        if (Rec."No." <> xRec."No.") and
           (xRec."No." <> '')
        then
            CurrPage.SaveRecord();

        OnNoOnAfterValidateOnBeforeSaveAndAutoAsmToOrder();

        SaveAndAutoAsmToOrder();

        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            if (Rec."Outstanding Qty. (Base)" <> 0) and (Rec."No." <> xRec."No.") then begin
                Rec.AutoReserve();
                CurrPage.Update(false);
            end;
        end;

        OnAfterNoOnAfterValidate(Rec, xRec);
    end;

    protected procedure VariantCodeOnAfterValidate()
    begin
        SaveAndAutoAsmToOrder();
    end;

    /// <summary>
    /// LocationCodeOnAfterValidate.
    /// </summary>
    procedure LocationCodeOnAfterValidate()
    begin
        SaveAndAutoAsmToOrder();

        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."Location Code" <> xRec."Location Code")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    protected procedure ReserveOnAfterValidate()
    begin
        if (Rec.Reserve = Rec.Reserve::Always) and (Rec."Outstanding Qty. (Base)" <> 0) then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        if Rec.Type = Rec.Type::"Rental Item" then begin
            CurrPage.SaveRecord();
            case Rec.Reserve of
                Rec.Reserve::Always:
                    Rec.AutoReserve();
            end;
        end;

        OnAfterQuantityOnAfterValidate(Rec, xRec);
    end;

    protected procedure QtyToAsmToOrderOnAfterValidate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeQtyToAsmToOrderOnAfterValidate(Rec, IsHandled);
        if IsHandled then
            exit;

        CurrPage.SaveRecord();
        if Rec.Reserve = Rec.Reserve::Always then
            Rec.AutoReserve();
        CurrPage.Update(true);
    end;

    protected procedure UnitofMeasureCodeOnAfterValidate()
    begin
        DeltaUpdateTotals();
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    protected procedure ShipmentDateOnAfterValidate()
    begin
        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."Shipment Date" <> xRec."Shipment Date")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end else
            CurrPage.Update(true);
    end;

    protected procedure SaveAndAutoAsmToOrder()
    begin
        if (Rec.Type = Rec.Type::"Rental Item") and Rec.IsAsmToOrderRequired() then begin
            CurrPage.SaveRecord();
            Rec.AutoAsmToOrder();
            CurrPage.Update(false);
        end;
    end;

    /*     procedure ShowDocumentLineTracking()
        var
            DocumentLineTracking: Page "Document Line Tracking";
        begin
            Clear(DocumentLineTracking);
            // DocumentLineTracking.SetDoc(0, Rec."Document No.", Rec."Line No.", Rec."Blanket Order No.", Rec."Blanket Order Line No.", '', 0);
            DocumentLineTracking.RunModal();
        end; */

    local procedure SetLocationCodeMandatory()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LocationCodeMandatory := InventorySetup."Location Mandatory" and (Rec.Type = Rec.Type::"Rental Item");
    end;

    local procedure GetTotalRentalHeader()
    begin
        DocumentTotals.GetTotalRentalHeaderAndCurrency(Rec, TotalRentalHeader, Currency);
    end;

    local procedure CalculateTotals()
    begin
        if SuppressTotals then
            exit;

        DocumentTotals.RentalCheckIfDocumentChanged(Rec, xRec);
        DocumentTotals.CalculateRentalSubPageTotals(TotalRentalHeader, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        DocumentTotals.RefreshRentalLine(Rec);
    end;

    procedure DeltaUpdateTotals()
    begin
        if SuppressTotals then
            exit;

        DocumentTotals.RentalDeltaUpdateTotals(Rec, xRec, TotalRentalLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
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
        DocumentTotals.RentalRedistributeInvoiceDiscountAmounts(Rec, VATAmount, TotalRentalLine);
        CurrPage.Update(false);
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

    /// <summary>
    /// UpdateTypeText.
    /// </summary>
    procedure UpdateTypeText()
    var
        RecRef: RecordRef;
    begin
        if not IsFoundation then
            exit;

        OnBeforeUpdateTypeText(Rec);

        RecRef.GetTable(Rec);
        TypeAsText := TempOptionLookupBuffer.FormatOption(RecRef.Field(Rec.FieldNo(Type)));
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
    /* 
        local procedure SetItemReferenceVisibility()
        var
            ItemReferenceMgt: Codeunit "Item Reference Management";
        begin
            ItemReferenceVisible := ItemReferenceMgt.IsEnabled();
        end; */

    local procedure SetDefaultType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultType(Rec, xRec, IsHandled);
        if not IsHandled then // Set default type Item
            if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                if xRec."Document No." = '' then
                    Rec.Type := Rec.Type::"Rental Item";
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

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterQuantityOnAfterValidate(var RentalLine: Record "TWE Rental Line"; xRentalLine: Record "TWE Rental Line")
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
    local procedure OnBeforeSetDefaultType(var RentalLine: Record "TWE Rental Line"; var xRentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTypeText(var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnNoOnAfterValidateOnBeforeSaveAndAutoAsmToOrder()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyToAsmToOrderOnAfterValidate(var RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;
}

