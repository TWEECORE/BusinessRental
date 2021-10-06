/// <summary>
/// Codeunit TWE Rental Price List Mgt. (ID 50042).
/// </summary>
codeunit 50042 "TWE Rental Price List Mgt."
{
    /// <summary>
    /// AddLines.
    /// </summary>
    /// <param name="RentalPriceListHeader">VAR Record "TWE Rental Price List Header".</param>
    procedure AddLines(var RentalPriceListHeader: Record "TWE Rental Price List Header")
    var
        PriceLineFilters: Record "TWE Rental Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        PriceLineFilters.Initialize(RentalPriceListHeader, false);
        SuggestPriceLine.SetRecord(PriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(PriceLineFilters);
            AddLines(RentalPriceListHeader, PriceLineFilters);
        end;
    end;

    /// <summary>
    /// AddLines.
    /// </summary>
    /// <param name="ToPriceListHeader">VAR Record "TWE Rental Price List Header".</param>
    /// <param name="RentalPriceLineFilters">Record "TWE Rental Price Line Filters".</param>
    procedure AddLines(var ToPriceListHeader: Record "TWE Rental Price List Header"; RentalPriceLineFilters: Record "TWE Rental Price Line Filters")
    var
        RentalPriceAsset: Record "TWE Rental Price Asset";
        RecRef: RecordRef;
    begin
        RecRef.Open(RentalPriceLineFilters."Table Id");
        if RentalPriceLineFilters."Asset Filter" <> '' then
            RecRef.SetView(RentalPriceLineFilters."Asset Filter");
        if RecRef.FindSet() then begin
            RentalPriceAsset."Rental Price Type" := ToPriceListHeader."Rental Price Type";
            RentalPriceAsset.Validate("Asset Type", RentalPriceLineFilters."Asset Type");
            repeat
                RentalPriceAsset.Validate("Asset ID", RecRef.Field(RecRef.SystemIdNo()).Value());
                if RentalPriceAsset."Asset No." <> '' then
                    AddLine(ToPriceListHeader, RentalPriceAsset, RentalPriceLineFilters);
            until RecRef.Next() = 0;
        end;
        RecRef.Close();
    end;

    local procedure AddLine(var ToPriceListHeader: Record "TWE Rental Price List Header"; RentalPriceAsset: Record "TWE Rental Price Asset"; RentalPriceLineFilters: Record "TWE Rental Price Line Filters")
    var
        RentalPriceListLine: Record "TWE Rental Price List Line";
    begin
        RentalPriceListLine."Price List Code" := ToPriceListHeader.Code;
        RentalPriceListLine."Line No." := 0; // autoincrement
        RentalPriceListLine.CopyFrom(ToPriceListHeader);
        RentalPriceListLine.Status := RentalPriceListLine.Status::Draft;
        RentalPriceListLine."Amount Type" := "Price Amount Type"::Price;
        RentalPriceListLine.CopyFrom(RentalPriceAsset);
        RentalPriceListLine.Validate("Minimum Quantity", RentalPriceLineFilters."Minimum Quantity");
        AdjustAmount(RentalPriceAsset."Unit Price", RentalPriceLineFilters);
        case ToPriceListHeader."Rental Price Type" of
            "TWE Rental Price Type"::Sale:
                RentalPriceListLine.Validate("Unit Price", RentalPriceAsset."Unit Price");
        end;
        RentalPriceListLine.Insert(true);
    end;

    local procedure AdjustAmount(var Price: Decimal; RentalPriceLineFilters: Record "TWE Rental Price Line Filters")
    var
        NewPrice: Decimal;
    begin
        if Price = 0 then
            exit;

        NewPrice := ConvertCurrency(Price, RentalPriceLineFilters);
        NewPrice := NewPrice * RentalPriceLineFilters."Adjustment Factor";

        if not ApplyRoundingMethod(RentalPriceLineFilters."Rounding Method Code", NewPrice) then
            NewPrice := Round(NewPrice, RentalPriceLineFilters."Amount Rounding Precision");

        Price := NewPrice;
    end;

    local procedure ConvertCurrency(Price: Decimal; RentalPriceLineFilters: Record "TWE Rental Price Line Filters") NewPrice: Decimal;
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        NewPrice := Price;
        if RentalPriceLineFilters."From Currency Code" <> RentalPriceLineFilters."To Currency Code" then
            if RentalPriceLineFilters."From Currency Code" = '' then
                NewPrice :=
                    Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                            RentalPriceLineFilters."Exchange Rate Date", RentalPriceLineFilters."To Currency Code", Price,
                            CurrExchRate.ExchangeRate(RentalPriceLineFilters."Exchange Rate Date", RentalPriceLineFilters."To Currency Code")),
                        RentalPriceLineFilters."Amount Rounding Precision")
            else
                if RentalPriceLineFilters."To Currency Code" = '' then
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                                RentalPriceLineFilters."Exchange Rate Date", RentalPriceLineFilters."From Currency Code", Price,
                                CurrExchRate.ExchangeRate(RentalPriceLineFilters."Exchange Rate Date", RentalPriceLineFilters."From Currency Code")),
                            RentalPriceLineFilters."Amount Rounding Precision")
                else
                    NewPrice :=
                        Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                                RentalPriceLineFilters."Exchange Rate Date",
                                RentalPriceLineFilters."From Currency Code", RentalPriceLineFilters."To Currency Code",
                                Price),
                            RentalPriceLineFilters."Amount Rounding Precision");
    end;

    local procedure ApplyRoundingMethod(RoundingMethodCode: Code[10]; var Price: Decimal) Rounded: Boolean;
    var
        RoundingMethod: Record "Rounding Method";
    begin
        if Price <= 0 then
            exit(false);

        if RoundingMethodCode <> '' then begin
            RoundingMethod.SetRange(Code, RoundingMethodCode);
            RoundingMethod.SetFilter("Minimum Amount", '<=%1', Price);
            if RoundingMethod.FindLast() then begin
                Price := Price + RoundingMethod."Amount Added Before";
                if RoundingMethod.Precision > 0 then
                    Price :=
                      Round(
                        Price,
                        RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
                Price := Price + RoundingMethod."Amount Added After";
                Rounded := true;
            end;
        end;
        if Price < 0 then
            Price := 0;
    end;

    /// <summary>
    /// CopyLines.
    /// </summary>
    /// <param name="ToPriceListHeader">VAR Record "TWE Rental Price List Header".</param>
    procedure CopyLines(var ToPriceListHeader: Record "TWE Rental Price List Header")
    var
        RentalPriceLineFilters: Record "TWE Rental Price Line Filters";
        SuggestPriceLine: Page "Suggest Price Lines";
    begin
        RentalPriceLineFilters.Initialize(ToPriceListHeader, true);
        SuggestPriceLine.SetRecord(RentalPriceLineFilters);
        if SuggestPriceLine.RunModal() = Action::OK then begin
            SuggestPriceLine.GetRecord(RentalPriceLineFilters);
            CopyLines(ToPriceListHeader, RentalPriceLineFilters);
        end;
    end;

    /// <summary>
    /// CopyLines.
    /// </summary>
    /// <param name="ToPriceListHeader">VAR Record "TWE Rental Price List Header".</param>
    /// <param name="RentalPriceLineFilters">Record "TWE Rental Price Line Filters".</param>
    procedure CopyLines(var ToPriceListHeader: Record "TWE Rental Price List Header"; RentalPriceLineFilters: Record "TWE Rental Price Line Filters")
    var
        FromPriceListHeader: Record "TWE Rental Price List Header";
        FromPriceListLine: Record "TWE Rental Price List Line";
    begin
        FromPriceListHeader.Get(RentalPriceLineFilters."From Price List Code");
        if RentalPriceLineFilters."Rental Price Line Filter" <> '' then
            FromPriceListLine.SetView(RentalPriceLineFilters."Rental Price Line Filter");
        FromPriceListLine.SetRange("Price List Code", RentalPriceLineFilters."From Price List Code");
        if FromPriceListLine.FindSet() then
            repeat
                CopyLine(RentalPriceLineFilters, FromPriceListLine, ToPriceListHeader);
            until FromPriceListLine.Next() = 0;
    end;

    local procedure CopyLine(RentalPriceLineFilters: Record "TWE Rental Price Line Filters"; FromPriceListLine: Record "TWE Rental Price List Line"; ToPriceListHeader: Record "TWE Rental Price List Header")
    var
        ToPriceListLine: Record "TWE Rental Price List Line";
    begin
        ToPriceListLine := FromPriceListLine;
        ToPriceListLine."Price List Code" := RentalPriceLineFilters."To Price List Code";
        ToPriceListLine.CopyFrom(ToPriceListHeader);
        ToPriceListLine.Status := ToPriceListLine.Status::Draft;
        AdjustAmount(ToPriceListLine."Unit Price", RentalPriceLineFilters);
        AdjustAmount(ToPriceListLine."Direct Unit Cost", RentalPriceLineFilters);
        ToPriceListLine."Line No." := 0;
        ToPriceListLine.Insert(true);
    end;

    /// <summary>
    /// FindDuplicatePrices.
    /// </summary>
    /// <param name="RentalPriceListHeader">Record "TWE Rental Price List Header".</param>
    /// <param name="SearchInside">Boolean.</param>
    /// <param name="DuplicatePriceLine">VAR Record "TWE Rental Dup. Price Line".</param>
    /// <returns>Return variable Found of type Boolean.</returns>
    procedure FindDuplicatePrices(RentalPriceListHeader: Record "TWE Rental Price List Header"; SearchInside: Boolean; var DuplicatePriceLine: Record "TWE Rental Dup. Price Line") Found: Boolean;
    var
        PriceListLine: Record "TWE Rental Price List Line";
        DuplicatePriceListLine: Record "TWE Rental Price List Line";
        LineNo: Integer;
    begin
        DuplicatePriceLine.Reset();
        DuplicatePriceLine.DeleteAll();

        PriceListLine.SetRange("Price List Code", RentalPriceListHeader.Code);
        if PriceListLine.FindSet() then
            repeat
                if not DuplicatePriceLine.Get(PriceListLine."Price List Code", PriceListLine."Line No.") then
                    if FindDuplicatePrice(PriceListLine, RentalPriceListHeader."Allow Updating Defaults", SearchInside, DuplicatePriceListLine) then
                        if DuplicatePriceLine.Get(DuplicatePriceListLine."Price List Code", DuplicatePriceListLine."Line No.") then
                            DuplicatePriceLine.Add(LineNo, DuplicatePriceLine."Line No.", PriceListLine)
                        else
                            DuplicatePriceLine.Add(LineNo, PriceListLine, DuplicatePriceListLine);
            until PriceListLine.Next() = 0;
        Found := LineNo > 0;
    end;

    local procedure FindDuplicatePrice(RentalPriceListLine: Record "TWE Rental Price List Line"; AsLineDefaults: Boolean; SearchInside: Boolean; var DuplicateRentalPriceListLine: Record "TWE Rental Price List Line"): Boolean;
    begin
        DuplicateRentalPriceListLine.Reset();
        if SearchInside then begin
            DuplicateRentalPriceListLine.SetRange("Price List Code", RentalPriceListLine."Price List Code");
            DuplicateRentalPriceListLine.SetFilter("Line No.", '<>%1', RentalPriceListLine."Line No.");
            if AsLineDefaults then
                SetHeadersFilters(RentalPriceListLine, DuplicateRentalPriceListLine);
        end else begin
            DuplicateRentalPriceListLine.SetFilter("Price List Code", '<>%1', RentalPriceListLine."Price List Code");
            SetHeadersFilters(RentalPriceListLine, DuplicateRentalPriceListLine);
        end;
        SetAssetFilters(RentalPriceListLine, DuplicateRentalPriceListLine);
        OnBeforeFindDuplicatePriceListLine(RentalPriceListLine, DuplicateRentalPriceListLine);
        exit(DuplicateRentalPriceListLine.FindFirst());
    end;

    local procedure SetHeadersFilters(RentalPriceListLine: Record "TWE Rental Price List Line"; var DuplicatePriceListLine: Record "TWE Rental Price List Line")
    begin
        DuplicatePriceListLine.SetRange("Price Type", RentalPriceListLine."Price Type");
        DuplicatePriceListLine.SetRange(Status, "Price Status"::Active);
        DuplicatePriceListLine.SetRange("Source Type", RentalPriceListLine."Source Type");
        DuplicatePriceListLine.SetRange("Parent Source No.", RentalPriceListLine."Parent Source No.");
        DuplicatePriceListLine.SetRange("Source No.", RentalPriceListLine."Source No.");
        DuplicatePriceListLine.SetRange("Currency Code", RentalPriceListLine."Currency Code");
        DuplicatePriceListLine.SetRange("Starting Date", RentalPriceListLine."Starting Date");
    end;

    local procedure SetAssetFilters(RentalPriceListLine: Record "TWE Rental Price List Line"; var DuplicatePriceListLine: Record "TWE Rental Price List Line")
    begin
        if RentalPriceListLine."Amount Type" in ["Price Amount Type"::Price, "Price Amount Type"::Discount] then
            DuplicatePriceListLine.SetFilter("Amount Type", '%1|%2', RentalPriceListLine."Amount Type", "Price Amount Type"::Any);
        DuplicatePriceListLine.SetRange("Asset Type", RentalPriceListLine."Asset Type");
        DuplicatePriceListLine.SetRange("Asset No.", RentalPriceListLine."Asset No.");
        DuplicatePriceListLine.SetRange("Unit of Measure Code", RentalPriceListLine."Unit of Measure Code");
        DuplicatePriceListLine.SetRange("Minimum Quantity", RentalPriceListLine."Minimum Quantity");
    end;

    /// <summary>
    /// ResolveDuplicatePrices.
    /// </summary>
    /// <param name="RentalPriceListHeader">Record "TWE Rental Price List Header".</param>
    /// <param name="RentalDuplicatePriceLine">VAR Record "TWE Rental Dup. Price Line".</param>
    /// <returns>Return variable Resolved of type Boolean.</returns>
    procedure ResolveDuplicatePrices(RentalPriceListHeader: Record "TWE Rental Price List Header"; var RentalDuplicatePriceLine: Record "TWE Rental Dup. Price Line") Resolved: Boolean;
    var
        PriceListLine: Record "TWE Rental Price List Line";
        DuplicatePriceLines: Page "TWE Rental Dup. Price Lines";
    begin
        DuplicatePriceLines.Set(RentalPriceListHeader."Rental Price Type", RentalPriceListHeader."Amount Type", RentalDuplicatePriceLine);
        DuplicatePriceLines.LookupMode(true);
        if DuplicatePriceLines.RunModal() = Action::LookupOK then begin
            DuplicatePriceLines.GetLines(RentalDuplicatePriceLine);
            RentalDuplicatePriceLine.SetRange(Remove, true);
            if RentalDuplicatePriceLine.FindSet() then
                repeat
                    if PriceListLine.Get(RentalDuplicatePriceLine."Price List Code", RentalDuplicatePriceLine."Price List Line No.") then
                        PriceListLine.Delete();
                until RentalDuplicatePriceLine.Next() = 0;
            Resolved := true;
            Commit();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDuplicatePriceListLine(PriceListLine: Record "TWE Rental Price List Line"; var DuplicatePriceListLine: Record "TWE Rental Price List Line")
    begin
    end;
}
