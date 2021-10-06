/// <summary>
/// Page TWE Rental Price List (ID 50011).
/// </summary>
page 50011 "TWE Rental Price List"
{
    Caption = 'Rental Price List';
    PageType = ListPlus;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    RefreshOnActivate = true;
    SourceTable = "TWE Rental Price List Header";
    SourceTableView = WHERE("Rental Price Type" = CONST(Rental));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the unique identifier of the price list.';
                    Editable = PriceListIsEditable;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEditCode(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(SourceType; CustomerSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    Editable = PriceListIsEditable;
                    Visible = IsCustomerGroup;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the customer or customer price group.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(CustomerSourceType.AsInteger());
                    end;
                }
                field(JobSourceType; JobSourceType)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Applies-to Type';
                    Editable = PriceListIsEditable;
                    Visible = IsJobGroup;
                    ToolTip = 'Specifies the source of the price on the price list line. For example, the price can come from the job or job task.';

                    trigger OnValidate()
                    begin
                        ValidateSourceType(JobSourceType.AsInteger());
                    end;
                }
                field(SourceNo; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Enabled = SourceNoEnabled;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                group(Tax)
                {
                    Caption = 'VAT';
                    field(VATBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the default VAT business posting group code.';
                    }
                    field(PriceIncludesVAT; Rec."Price Includes VAT")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies the if prices include VAT.';
                    }
                }
                group(View)
                {
                    Caption = 'View';
                    Visible = ViewGroupIsVisible;
                    field(AmountType; ViewAmountType)
                    {
                        ApplicationArea = All;
                        Caption = 'View Columns for';
                        ToolTip = 'Specifies the amount type filter that defines the columns shown in the price list lines.';
                        trigger OnValidate()
                        begin
                            CurrPage.Lines.Page.SetSubFormLinkFilter(ViewAmountType);
                        end;
                    }
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';

                    trigger OnValidate()
                    begin
                        PriceListIsEditable := Rec.IsEditable();
                    end;
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field(StartingDate; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Editable = PriceListIsEditable;
                    ToolTip = 'Specifies the last date that the price is valid.';
                }
                group(LineDefaults)
                {
                    Caption = 'Line Defaults';
                    field(AllowUpdatingDefaults; Rec."Allow Updating Defaults")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies whether users can change the values in the fields on the price list line that contain default values from the header.';
                        trigger OnValidate()
                        begin
                            CurrPage.Lines.Page.SetHeader(Rec);
                        end;
                    }
                    field(AllowInvoiceDisc; Rec."Allow Invoice Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies whether invoice discount is allowed. You can change this value on the lines.';
                    }
                    field(AllowLineDisc; Rec."Allow Line Disc.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        Editable = PriceListIsEditable;
                        ToolTip = 'Specifies whether line discounts are allowed. You can change this value on the lines.';
                    }
                }
            }
            part(Lines; "TWE Rental Price List Lines")
            {
                ApplicationArea = Basic, Suite;
                Editable = PriceListIsEditable;
                SubPageLink = "Price List Code" = FIELD(Code);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SuggestLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = SuggestItemPrice;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Suggest Lines';
                ToolTip = 'Creates the rental price list lines based on the unit price in the product cards, like item or resource. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "TWE Rental Price List Mgt.";
                begin
                    PriceListManagement.AddLines(Rec);
                end;
            }
            action(CopyLines)
            {
                ApplicationArea = Basic, Suite;
                Enabled = PriceListIsEditable;
                Ellipsis = true;
                Image = CopyWorksheet;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Copy Lines';
                ToolTip = 'Copies the lines from the existing price list. New prices can be adjusted by a factor and rounded differently. Change the price list status to ''Draft'' to run this action.';

                trigger OnAction()
                var
                    PriceListManagement: Codeunit "TWE Rental Price List Mgt.";
                begin
                    PriceListManagement.CopyLines(Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
    begin
        UpdateSourceType();
        RentalPriceUXManagement.GetFirstSourceFromFilter(Rec, OriginalPriceSource, DefaultSourceType);
        SetSourceNoEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
        PriceListIsEditable := Rec.IsEditable();
        UpdateSourceType();
        ViewAmountType := Rec."Amount Type";
        if ViewAmountType = ViewAmountType::Any then
            ViewGroupIsVisible := true
        else
            ViewGroupIsVisible := not RentalPriceUXManagement.IsAmountTypeFiltered(Rec);

        CurrPage.Lines.Page.SetHeader(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DefaultAmountType: Enum "Price Amount Type";
    begin
        Rec.CopyFrom(OriginalPriceSource);
        UpdateSourceType();
        if RentalPriceUXManagement.IsAmountTypeFiltered(Rec, DefaultAmountType) then
            Rec."Amount Type" := DefaultAmountType;
        SetSourceNoEnabled();
    end;

    trigger OnClosePage()
    begin
        if Rec.Code <> '' then
            Rec.UpdateAmountType();
    end;

    local procedure UpdateSourceType()
    begin
        case Rec."Rental Source Group" of
            Rec."Rental Source Group"::Customer:
                begin
                    IsCustomerGroup := true;
                    CustomerSourceType := "Sales Price Source Type".FromInteger(Rec."Rental Source Type".AsInteger());
                    DefaultSourceType := Rec."Rental Source Type"::"All Customers";
                end;
            Rec."Rental Source Group"::Job:
                begin
                    IsJobGroup := true;
                    JobSourceType := "Job Price Source Type".FromInteger(Rec."Rental Source Type".AsInteger());
                    DefaultSourceType := Rec."Rental Source Type"::"All Jobs";
                end;
        end;
    end;

    var
        OriginalPriceSource: Record "TWE Rental Price Source";
        RentalPriceUXManagement: Codeunit "TWE Rental Price UX Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        DefaultSourceType: Enum "TWE Rental Price Source Type";
        JobSourceType: Enum "Job Price Source Type";
        CustomerSourceType: Enum "Sales Price Source Type";
        ViewAmountType: Enum "Price Amount Type";
        IsCustomerGroup: Boolean;
        IsJobGroup: Boolean;
        SourceNoEnabled: Boolean;
        PriceListIsEditable: Boolean;
        ViewGroupIsVisible: Boolean;

    local procedure SetSourceNoEnabled()
    begin
        SourceNoEnabled := Rec.IsSourceNoAllowed();
    end;

    local procedure ValidateSourceType(SourceType: Integer)
    begin
        Rec.Validate("Rental Source Type", SourceType);
        SetSourceNoEnabled();
        CurrPage.SaveRecord();
    end;
}
