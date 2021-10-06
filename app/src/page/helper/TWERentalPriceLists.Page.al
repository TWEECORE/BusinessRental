page 50014 "TWE Rental Price Lists"
{
    Caption = 'Rental Price Lists';
    CardPageID = "TWE Rental Price List";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report';
    QueryCategory = 'Rental Price Lists';
    RefreshOnActivate = true;
    SourceTable = "TWE Rental Price List Header";
    SourceTableView = WHERE("Rental Source Group" = CONST(Customer), "Rental Price Type" = CONST(Rental));
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Caption = 'Code';
                    ToolTip = 'Specifies the unique identifier of the price list.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the price list.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the price list is in Draft status and can be edited, Inactive and cannot be edited or used, or Active and used for price calculations.';
                }
                field("Allow Updating Defaults"; Rec."Allow Updating Defaults")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Multi-Type Price List';
                    ToolTip = 'Specifies whether users can change the values in the fields on the price list line that contain default values from the header.';
                }
                field(Defines; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Defines';
                    ToolTip = 'Specifies whether the price list defines prices, discounts, or both.';
                }
                field("Currency Code"; CurrRec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency';
                    ToolTip = 'Specifies the currency that is used on the price list.';
                }
                field(SourceGroup; Rec."Rental Source Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Group';
                    Visible = false;
                    ToolTip = 'Specifies whether the prices come from groups of customers, vendors or jobs.';
                }
                field(SourceType; CurrRec."Rental Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Type';
                    ToolTip = 'Specifies the source type of the price list.';
                }
                field(SourceNo; CurrRec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to No.';
                    ToolTip = 'Specifies the unique identifier of the source of the price on the price list line.';
                }
                field("Starting Date"; CurrRec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrRec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date when the sales price agreement ends.';
                }
            }
        }
    }

    trigger OnInit()
    var
    begin
    end;

    trigger OnAfterGetRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrRec := Rec;
        CurrRec.BlankDefaults();
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnOpenPage()
    begin
    end;

    var
        CurrRec: Record "TWE Rental Price List Header";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    procedure SetRecordFilter(var RentalPriceListHeader: Record "TWE Rental Price List Header")
    begin
        Rec.FilterGroup := 2;
        Rec.CopyFilters(RentalPriceListHeader);
        Rec.SetRange("Rental Source Group", Rec."Rental Source Group"::Customer);
        Rec.SetRange("Rental Price Type", Rec."Rental Price Type"::Rental);
        Rec.FilterGroup := 0;
    end;

    procedure SetSource(RentalPriceSourceList: Codeunit "TWE Rental Price Source List"; AmountType: Enum "Price Amount Type")
    var
        RentalPriceUXManagement: Codeunit "TWE Rental Price UX Management";
    begin
        RentalPriceUXManagement.SetPriceListsFilters(Rec, RentalPriceSourceList, AmountType);
    end;

    procedure SetAsset(RentalPriceAsset: Record "TWE Rental Price Asset"; AmountType: Enum "Price Amount Type")
    var
        RentalPriceUXManagement: Codeunit "TWE Rental Price UX Management";
    begin
        RentalPriceUXManagement.SetPriceListsFilters(Rec, RentalPriceAsset."Rental Price Type", AmountType);
    end;
}
