/// <summary>
/// Page TWE SO Processor Activities (ID 50004).
/// </summary>
page 50004 "TWE SO Processor Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "TWE Rental Cue";

    layout
    {
        area(content)
        {
            cuegroup("For Release")
            {
                Caption = 'For Release';
                field("Rental Quotes - Open"; Rec."Rental Quotes - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "TWE Rental Quotes";
                    ToolTip = 'Specifies the number of sales quotes that are not yet converted to invoices or orders.';
                }
                field("Rental Contracts - Open"; Rec."Rental Contracts - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies the number of sales orders that are not fully posted.';
                }

                actions
                {
                    action("New Rental Quote")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Rental Quote';
                        RunObject = Page "TWE Rental Quote";
                        RunPageMode = Create;
                        ToolTip = 'Offer items or services to a customer.';
                    }
                    action("New Rental Contract")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Rental Contract';
                        RunObject = Page "TWE Rental Contract";
                        RunPageMode = Create;
                        ToolTip = 'Create a new sales order for items or services that require partial posting.';
                    }
                }
            }
            cuegroup("Rental Contracts Released Not Shipped")
            {
                Caption = 'Rental Contracts Released Not Shipped';
                field(ReadyToShip; Rec."Ready to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ready To Ship';
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies the number of sales documents that are ready to ship.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowContracts(Rec.FieldNo("Ready to Ship"));
                    end;
                }
                field(DelayedContracts; Rec.Delayed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delayed';
                    DrillDownPageID = "TWE Rental Contract List";
                    ToolTip = 'Specifies the number of sales documents where your delivery is delayed.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowContracts(Rec.FieldNo(Delayed));
                    end;
                }
                field("Average Days Delayed"; Rec."Average Days Delayed")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 0 : 1;
                    Image = Calendar;
                    ToolTip = 'Specifies the number of days that your order deliveries are delayed on average.';
                }

                actions
                {
                    action(Navigate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        RunObject = Page Navigate;
                        ShortCutKey = 'Shift+Ctrl+I';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
            }
            cuegroup(Returns)
            {
                Caption = 'Returns';
                field("Rental Return Shipments - Open"; Rec."Rental Return Shipments - Open")
                {
                    ApplicationArea = SalesReturnOrder;
                    DrillDownPageID = "TWE Rental Return Ship. List";
                    ToolTip = 'Specifies the number of sales return orders documents that are displayed in the Sales Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Rental Credit Memos - Open"; Rec."Rental Credit Memos - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "TWE Rental Credit Memos";
                    ToolTip = 'Specifies the number of sales credit memos that are not yet posted.';
                }

                actions
                {
                    action("New Rental Return Shipment")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'New Rental Return Order';
                        RunObject = Page "TWE Rental Return Shipment";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund that requires inventory handling by creating a new sales return order.';
                    }
                    action("New Rental Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Rental Credit Memo';
                        RunObject = Page "TWE Rental Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund by creating a new sales credit memo.';
                    }
                }
            }
            cuegroup("Document Exchange Service")
            {
                Caption = 'Document Exchange Service';
                Visible = ShowDocumentsPendingDodExchService;
                field("Rental Inv. - Pending Doc.Exch."; Rec."Rental Inv. - Pendi. Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
                    Visible = ShowDocumentsPendingDodExchService;
                }
                field("Rental CrM. - Pending Doc.Exch."; Rec."Rental CrM. - Pend. Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies rental credit memos that await sending to the customer through the document exchange service.';
                    Visible = ShowDocumentsPendingDodExchService;
                }
            }
            /* usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                trigger ResponseReceived(Status: Integer; Response: Text)
                var
                    SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
                begin
                    SatisfactionSurveyMgt.TryShowSurvey(Status, Response);
                end;

                trigger ControlAddInReady();
                begin
                    IsAddInReady := true;
                    CheckIfSurveyEnabled();
                end;
            } */
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        RoleCenterNotificationMgt.HideEvaluationNotificationAfterStartingTrial();
    end;

    trigger OnAfterGetRecord()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        CalculateCueFieldValues();
        ShowDocumentsPendingDodExchService := false;
        if DocExchServiceSetup.Get() then
            ShowDocumentsPendingDodExchService := DocExchServiceSetup.Enabled;
    end;

    trigger OnOpenPage()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRespCenterFilter();
        Rec.SetRange("Date Filter", 0D, WorkDate() - 1);
        Rec.SetFilter("Date Filter2", '>=%1', WorkDate());
        Rec.SetRange("User ID Filter", UserId);

        RoleCenterNotificationMgt.ShowNotifications();
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent();

        /*        if PageNotifier.IsAvailable then begin
                   PageNotifier := PageNotifier.Create();
                   PageNotifier.NotifyPageReady();
               end; */
    end;

    var
        CuesAndKpis: Codeunit "Cues And KPIs";
        //UserTaskManagement: Codeunit "User Task Management";
        //PageNotifier: DotNet PageNotifier;
        ShowDocumentsPendingDodExchService: Boolean;
    //IsAddInReady: Boolean;
    //IsPageReady: Boolean;

    local procedure CalculateCueFieldValues()
    begin
        if Rec.FieldActive("Average Days Delayed") then
            Rec."Average Days Delayed" := Rec.CalculateAverageDaysDelayed();

        if Rec.FieldActive("Ready to Ship") then
            Rec."Ready to Ship" := Rec.CountContracts(Rec.FieldNo("Ready to Ship"));

        if Rec.FieldActive(Delayed) then
            Rec.Delayed := Rec.CountContracts(Rec.FieldNo(Delayed));
    end;

    /*     trigger PageNotifier::PageReady()
        begin
            IsPageReady := true;
            CheckIfSurveyEnabled();
        end; */

    /*     local procedure CheckIfSurveyEnabled()
        var
            SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
            CheckUrl: Text;
        begin
            if not IsAddInReady then
                exit;
            if not IsPageReady then
                exit;
            if not SatisfactionSurveyMgt.DeactivateSurvey() then
                exit;
            if not SatisfactionSurveyMgt.TryGetCheckUrl(CheckUrl) then
                exit;
            CurrPage.SATAsyncLoader.SendRequest(CheckUrl, SatisfactionSurveyMgt.GetRequestTimeoutAsync());
        end; */
}

