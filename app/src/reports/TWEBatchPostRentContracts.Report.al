report 50001 "TWE Batch Post Rent. Contracts"
{
    Caption = 'Batch Post Rental Contracts';
    ProcessingOnly = true;

    dataset
    {
        dataitem("TWE Rental Header"; "TWE Rental Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Contract));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Rental Contract';

            trigger OnPreDataItem()
            var
                RentalBatchPostMgt: Codeunit "TWE Rental Batch Post Mgt.";
            begin
                OnBeforeRentalBatchPostMgt("TWE Rental Header", ShipReq, InvReq);

                RentalBatchPostMgt.SetParameter("Batch Posting Parameter Type"::Print, PrintDocBoolean);
                RentalBatchPostMgt.RunBatch("TWE Rental Header", ReplacePostingDateBoolean, PostingDateReq, ReplaceDocumentDateBoolean, CalcInvDiscBoolean, ShipReq, InvReq);

                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Ship; ShipReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ship';
                        ToolTip = 'Specifies whether the contracts will be shipped when posted. If you place a check in the box, it will apply to all the contracts that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies whether the contracts will be invoiced when posted. If you place a check in the box, it will apply to all the contracts that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';
                    }
                    field(ReplacePostingDate; ReplacePostingDateBoolean)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if the new posting date will be applied.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDateBoolean then
                                Message(Text003Lbl);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDateBoolean)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the rental contracts'' document date with the date in the Posting Date field.';
                    }
                    field(CalcInvDisc; CalcInvDiscBoolean)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the contracts before posting.';

                        trigger OnValidate()
                        var
                            RentalSetup: Record "TWE Rental Setup";
                        begin
                            RentalSetup.Get();
                            RentalSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDocBoolean)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the contract after posting. In the Report Output Type field on the Rental Setup page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            RentalSetup: Record "TWE Rental Setup";
                        begin
                            if PrintDocBoolean then begin
                                RentalSetup.Get();
                                if RentalSetup."Post with Job Queue" then
                                    RentalSetup.TestField("Post & Print with Job Queue");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            RentalSetup: Record "TWE Rental Setup";
        begin
            RentalSetup.Get();
            CalcInvDiscBoolean := RentalSetup."Calc. Inv. Discount";
            ReplacePostingDateBoolean := false;
            ReplaceDocumentDateBoolean := false;
            PrintDocBoolean := false;
            PrintDocVisible := RentalSetup."Post & Print with Job Queue";
        end;
    }

    labels
    {
    }

    var
        Text003Lbl: Label 'The exchange rate associated with the new posting date on the rental header will not apply to the rental lines.';
        ShipReq: Boolean;
        InvReq: Boolean;
        PostingDateReq: Date;
        ReplacePostingDateBoolean: Boolean;
        ReplaceDocumentDateBoolean: Boolean;
        CalcInvDiscBoolean: Boolean;
        PrintDocBoolean: Boolean;
        [InDataSet]
        PrintDocVisible: Boolean;

    procedure InitializeRequest(ShipParam: Boolean; InvoiceParam: Boolean; PostingDateParam: Date; ReplacePostingDateParam: Boolean; ReplaceDocumentDateParam: Boolean; CalcInvDiscParam: Boolean)
    begin
        ShipReq := ShipParam;
        InvReq := InvoiceParam;
        PostingDateReq := PostingDateParam;
        ReplacePostingDateBoolean := ReplacePostingDateParam;
        ReplaceDocumentDateBoolean := ReplaceDocumentDateParam;
        CalcInvDiscBoolean := CalcInvDiscParam;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalBatchPostMgt(var RentalHeader: Record "TWE Rental Header"; var ShipReq: Boolean; var InvReq: Boolean)
    begin
    end;
}

