/// <summary>
/// Page TWE Report Selection - Rental (ID 70704670).
/// </summary>
page 50022 "TWE Report Selection - Rental"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Rental';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "TWE Rental Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Quote,Contract,Invoice,Return Shipment,Credit Memo,Shipment,Rental Document - Test,Prepayment Document - Test,Archived Quote,Archived Contract,Draft Invoice,Pro Forma Invoice';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                FreezeColumn = "Report Caption";
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related document will be attached to the email.';
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body layout that is used.';

                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK(Rec."Report ID") then
                            Rec.Validate("Email Body Layout Code", CustomReportLayout.Code);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option Quote,"Contract",Invoice,"Return Shipment","Credit Memo",Shipment,"Rental Document - Test","Prepayment Document - Test","Archived Quote","Archived Contract","Draft Invoice","Pro Forma Invoice";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                Rec.SetRange(Usage, Rec.Usage::"R.Quote");
            ReportUsage2::Contract:
                Rec.SetRange(Usage, Rec.Usage::"R.Contract");
            ReportUsage2::Invoice:
                Rec.SetRange(Usage, Rec.Usage::"R.Invoice");
            ReportUsage2::"Return Shipment":
                Rec.SetRange(Usage, Rec.Usage::"R.Ret.Shpt.");
            ReportUsage2::"Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::"R.Cr.Memo");
            ReportUsage2::Shipment:
                Rec.SetRange(Usage, Rec.Usage::"R.Shipment");
            ReportUsage2::"Rental Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"R.Test");
            ReportUsage2::"Prepayment Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"R.Test Prepmt.");
            ReportUsage2::"Archived Quote":
                Rec.SetRange(Usage, Rec.Usage::"R.Arch.Quote");
            ReportUsage2::"Archived Contract":
                Rec.SetRange(Usage, Rec.Usage::"R.Arch.Contract");
            ReportUsage2::"Pro Forma Invoice":
                Rec.SetRange(Usage, Rec.Usage::"Pro Forma R. Invoice");
            ReportUsage2::"Draft Invoice":
                Rec.SetRange(Usage, Rec.Usage::"Draft R. Invoice");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        DummyReportSelections: Record "Report Selections";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(DummyReportSelections.Usage, Rec.GetFilter(Usage)) then
                case DummyReportSelections.Usage of
                    Rec.Usage::"R.Quote":
                        ReportUsage2 := ReportUsage2::Quote;
                    Rec.Usage::"R.Contract":
                        ReportUsage2 := ReportUsage2::Contract;
                    Rec.Usage::"R.Invoice":
                        ReportUsage2 := ReportUsage2::Invoice;
                    Rec.Usage::"R.Ret.Shpt.":
                        ReportUsage2 := ReportUsage2::"Return Shipment";
                    Rec.Usage::"R.Cr.Memo":
                        ReportUsage2 := ReportUsage2::"Credit Memo";
                    Rec.Usage::"R.Shipment":
                        ReportUsage2 := ReportUsage2::Shipment;
                    Rec.Usage::"R.Test":
                        ReportUsage2 := ReportUsage2::"Rental Document - Test";
                    Rec.Usage::"R.Test Prepmt.":
                        ReportUsage2 := ReportUsage2::"Prepayment Document - Test";
                    Rec.Usage::"R.Arch.Quote":
                        ReportUsage2 := ReportUsage2::"Archived Quote";
                    Rec.Usage::"R.Arch.Contract":
                        ReportUsage2 := ReportUsage2::"Archived Contract";
                    Rec.Usage::"Pro Forma R. Invoice":
                        ReportUsage2 := ReportUsage2::"Pro Forma Invoice";
                    Rec.Usage::"Draft R. Invoice":
                        ReportUsage2 := ReportUsage2::"Draft Invoice";
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "TWE Rental Report Selections"; ReportUsage2: Option)
    begin
    end;
}

