/// <summary>
/// Table TWE Rental Cue (ID 50002).
/// </summary>
table 50002 "TWE Rental Cue"
{
    Caption = 'Rental Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Rental Quotes - Open"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = FILTER(Quote),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Rental Quotes - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Rental Contracts - Open"; Integer)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = FILTER(Contract),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Rental Contracts - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Ready to Ship"; Integer)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = FILTER(Contract),
                                                      Status = FILTER(Released),
                                                      "Completely Shipped" = CONST(false),
                                                      "Shipment Date" = FIELD("Date Filter2"),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Ready to Ship';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Delayed; Integer)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = FILTER(Contract),
                                                      Status = FILTER(Released),
                                                      "Completely Shipped" = CONST(false),
                                                      "Shipment Date" = FIELD("Date Filter"),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter"),
                                                      "Late Order Shipping" = FILTER(true)));
            Caption = 'Delayed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Rental Return Shipments - Open"; Integer)
        {
            AccessByPermission = TableData "TWE Rental Return Ship. Header" = R;
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = FILTER("Return Shipment"),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Rental Return Orders - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Rental Credit Memos - Open"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = FILTER("Credit Memo"),
                                                      Status = FILTER(Open),
                                                      "Responsibility Center" = FIELD("Responsibility Center Filter")));
            Caption = 'Rental Credit Memos - Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Average Days Delayed"; Decimal)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Average Days Delayed';
            DataClassification = CustomerContent;
            DecimalPlaces = 1 : 1;
            Editable = false;
        }
        field(9; "Rental Inv. - Pendi. Doc.Exch."; Integer)
        {
            CalcFormula = Count("TWE Rental Invoice Header" WHERE("Document Exchange Status" = FILTER("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Rental Invoices - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Rental CrM. - Pend. Doc.Exch."; Integer)
        {
            CalcFormula = Count("TWE Rental Cr.Memo Header" WHERE("Document Exchange Status" = FILTER("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Rental Credit Memos - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter 2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Responsibility Center Filter"; Code[10])
        {
            Caption = 'Responsibility Center Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
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

    /// <summary>
    /// SetRespCenterFilter.
    /// </summary>
    procedure SetRespCenterFilter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        RespCenterCode: Code[10];
    begin
        RespCenterCode := UserSetupMgt.GetSalesFilter();
        if RespCenterCode <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center Filter", RespCenterCode);
            FilterGroup(0);
        end;
    end;

    /// <summary>
    /// CalculateAverageDaysDelayed.
    /// </summary>
    /// <returns>Return variable AverageDays of type Decimal.</returns>
    procedure CalculateAverageDaysDelayed() AverageDays: Decimal
    var
        RentalHeader: Record "TWE Rental Header";
        SumDelayDays: Integer;
        CountDelayedInvoices: Integer;
    begin
        FilterOrders(RentalHeader, FieldNo(Delayed));
        if RentalHeader.FindSet() then begin
            repeat
                SummarizeDelayedData(RentalHeader, SumDelayDays, CountDelayedInvoices);
            until RentalHeader.Next() = 0;
            AverageDays := SumDelayDays / CountDelayedInvoices;
        end;
    end;

    local procedure MaximumDelayAmongLines(RentalHeader: Record "TWE Rental Header") MaxDelay: Integer
    var
        RentalLine: Record "TWE Rental Line";
    begin
        MaxDelay := 0;
        RentalLine.SetRange("Document Type", RentalHeader."Document Type");
        RentalLine.SetRange("Document No.", RentalHeader."No.");
        RentalLine.SetFilter("Shipment Date", '<%1&<>%2', WorkDate(), 0D);
        if RentalLine.FindSet() then
            repeat
                if WorkDate() - RentalLine."Shipment Date" > MaxDelay then
                    MaxDelay := WorkDate() - RentalLine."Shipment Date";
            until RentalLine.Next() = 0;
    end;

    /// <summary>
    /// CountContracts.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    /// <returns>Return value of type Integer.</returns>
    procedure CountContracts(FieldNumber: Integer): Integer
    var
        RentalHeader: Record "TWE Rental Header";
        CountRentalContracts: Query "TWE Count Rental Contracts";
    begin
        CountRentalContracts.SetRange(Status, RentalHeader.Status::Released);
        CountRentalContracts.SetRange(Completely_Shipped, false);
        FilterGroup(2);
        CountRentalContracts.SetFilter(Responsibility_Center, GetFilter("Responsibility Center Filter"));
        OnCountOrdersOnAfterCountPurchOrdersSetFilters(CountRentalContracts);
        FilterGroup(0);

        case FieldNumber of
            FieldNo("Ready to Ship"):
                begin
                    CountRentalContracts.SetRange(Ship);
                    CountRentalContracts.SetFilter(Shipment_Date, GetFilter("Date Filter2"));
                end;
            FieldNo(Delayed):
                begin
                    CountRentalContracts.SetRange(Ship);
                    CountRentalContracts.SetFilter(Date_Filter, GetFilter("Date Filter"));
                    CountRentalContracts.SetRange(Late_Order_Shipping, true);
                end;
        end;
        CountRentalContracts.Open();
        CountRentalContracts.Read();
        exit(CountRentalContracts.Count_Contracts);
    end;

    local procedure FilterOrders(var RentalHeader: Record "TWE Rental Header"; FieldNumber: Integer)
    begin
        RentalHeader.SetRange("Document Type", RentalHeader."Document Type"::Contract);
        RentalHeader.SetRange(Status, RentalHeader.Status::Released);
        RentalHeader.SetRange("Completely Shipped", false);
        case FieldNumber of
            FieldNo("Ready to Ship"):
                begin
                    RentalHeader.SetRange(Ship);
                    RentalHeader.SetFilter("Shipment Date", GetFilter("Date Filter2"));
                end;
            FieldNo(Delayed):
                begin
                    RentalHeader.SetRange(Ship);
                    RentalHeader.SetFilter("Date Filter", GetFilter("Date Filter"));
                    RentalHeader.SetRange("Late Order Shipping", true);
                end;
        end;
        FilterGroup(2);
        RentalHeader.SetFilter("Responsibility Center", GetFilter("Responsibility Center Filter"));
        OnFilterOrdersOnAfterRentalHeaderSetFilters(RentalHeader);
        FilterGroup(0);
    end;

    /// <summary>
    /// ShowContracts.
    /// </summary>
    /// <param name="FieldNumber">Integer.</param>
    procedure ShowContracts(FieldNumber: Integer)
    var
        RentalHeader: Record "TWE Rental Header";
    begin
        FilterOrders(RentalHeader, FieldNumber);
        PAGE.Run(PAGE::"TWE Rental Contract List", RentalHeader);
    end;

    local procedure SummarizeDelayedData(var RentalHeader: Record "TWE Rental Header"; var SumDelayDays: Integer; var CountDelayedInvoices: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSummarizeDelayedData(RentalHeader, SumDelayDays, CountDelayedInvoices, IsHandled);
        if IsHandled then
            exit;

        SumDelayDays += MaximumDelayAmongLines(RentalHeader);
        CountDelayedInvoices += 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCountOrdersOnAfterCountPurchOrdersSetFilters(var CountRentalContracts: Query "TWE Count Rental Contracts")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterOrdersOnAfterRentalHeaderSetFilters(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSummarizeDelayedData(var RentalHeader: Record "TWE Rental Header"; var SumDelayDays: Integer; var CountDelayedInvoices: Integer; var IsHandled: Boolean)
    begin
    end;
}

