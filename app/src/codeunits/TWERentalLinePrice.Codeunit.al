/// <summary>
/// Codeunit TWE Rental Line - Price (ID 50028)
/// </summary>
codeunit 50028 "TWE Rental Line - Price" implements "TWE Rent Line With Price"
{
    var
        RentalHeader: Record "TWE Rental Header";
        RentalLine: Record "TWE Rental Line";
        RentalPriceSourceList: codeunit "TWE Rental Price Source List";
        CurrPriceType: Enum "TWE Rental Price Type";
        PriceCalculated: Boolean;

    /// <summary>
    /// GetTableNo.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    procedure GetTableNo(): Integer
    begin
        exit(Database::"TWE Rental Line")
    end;

    /// <summary>
    /// SetLine.
    /// </summary>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="Line">Variant.</param>
    procedure SetLine(PriceType: Enum "TWE Rental Price Type"; Line: Variant)
    begin
        RentalLine := Line;
        CurrPriceType := PriceType;
        PriceCalculated := false;
        AddSources();
    end;

    /// <summary>
    /// SetLine.
    /// </summary>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="Header">Variant.</param>
    /// <param name="Line">Variant.</param>
    procedure SetLine(PriceType: Enum "TWE Rental Price Type"; Header: Variant; Line: Variant)
    begin
        ClearAll();
        RentalHeader := Header;
        SetLine(PriceType, Line);
    end;

    /// <summary>
    /// SetSources.
    /// </summary>
    /// <param name="NewPriceSourceList">VAR codeunit "Price Source List".</param>
    procedure SetSources(var NewPriceSourceList: codeunit "TWE Rental Price Source List")
    begin
        RentalPriceSourceList.Copy(NewPriceSourceList);
    end;

    /// <summary>
    /// GetLine.
    /// </summary>
    /// <param name="Line">VAR Variant.</param>
    procedure GetLine(var Line: Variant)
    begin
        Line := RentalLine;
    end;

    /// <summary>
    /// GetLine.
    /// </summary>
    /// <param name="Header">VAR Variant.</param>
    /// <param name="Line">VAR Variant.</param>
    procedure GetLine(var Header: Variant; var Line: Variant)
    begin
        Header := RentalHeader;
        Line := RentalLine;
    end;

    /// <summary>
    /// GetPriceType.
    /// </summary>
    /// <returns>Return value of type Enum "Price Type".</returns>
    procedure GetPriceType(): Enum "TWE Rental Price Type"
    begin
        exit(CurrPriceType);
    end;

    /// <summary>
    /// IsPriceUpdateNeeded.
    /// </summary>
    /// <param name="AmountType">enum "Price Amount Type".</param>
    /// <param name="FoundPrice">Boolean.</param>
    /// <param name="CalledByFieldNo">Integer.</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsPriceUpdateNeeded(AmountType: enum "Price Amount Type"; FoundPrice: Boolean; CalledByFieldNo: Integer) Result: Boolean;
    begin
        if FoundPrice then
            Result := true
        else
            Result :=
                Result or
                not (CalledByFieldNo in [RentalLine.FieldNo(Quantity), RentalLine.FieldNo("Variant Code")]);
    end;

    /// <summary>
    /// IsDiscountAllowed.
    /// </summary>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure IsDiscountAllowed() Result: Boolean;
    begin
        Result := RentalLine."Allow Line Disc." or not PriceCalculated;
    end;

    /// <summary>
    /// Verify.
    /// </summary>
    procedure Verify()
    begin
        RentalLine.TestField("Qty. per Unit of Measure");
        if RentalHeader."Currency Code" <> '' then
            RentalHeader.TestField("Currency Factor");
    end;

    /// <summary>
    /// SetAssetSourceForSetup.
    /// </summary>
    /// <param name="RentDtldPriceCalculationSetup">VAR Record "Dtld. Price Calculation Setup".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure SetAssetSourceForSetup(var RentDtldPriceCalculationSetup: Record "TWE Rent Dtld.PriceCalc Setup"): Boolean
    begin
        RentDtldPriceCalculationSetup.Init();
        RentDtldPriceCalculationSetup.Type := CurrPriceType;
        RentDtldPriceCalculationSetup.Method := RentalLine."Price Calculation Method";
        RentDtldPriceCalculationSetup."Asset Type" := GetAssetType();
        RentDtldPriceCalculationSetup."Asset No." := RentalLine."No.";
        exit(RentalPriceSourceList.GetSourceGroup(RentDtldPriceCalculationSetup));
    end;

    local procedure SetAssetSource(var RentalPriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"): Boolean
    begin
        RentalPriceCalculationBuffer."Price Type" := CurrPriceType;
        RentalPriceCalculationBuffer."Asset Type" := GetAssetType();
        RentalPriceCalculationBuffer."Asset No." := RentalLine."No.";
        exit((RentalPriceCalculationBuffer."Asset Type" <> RentalPriceCalculationBuffer."Asset Type"::" ") and (RentalPriceCalculationBuffer."Asset No." <> ''));
    end;

    /// <summary>
    /// GetAssetType.
    /// </summary>
    /// <returns>Return variable AssetType of type Enum "Price Asset Type".</returns>
    procedure GetAssetType() AssetType: Enum "TWE Rental Price Asset Type";
    begin
        case RentalLine.Type of
            RentalLine.Type::"Rental Item":
                AssetType := AssetType::"Rental Item";
            else
                AssetType := AssetType::" ";
        end;
    end;

    /// <summary>
    /// CopyToBuffer.
    /// </summary>
    /// <param name="PriceCalculationBufferMgt">VAR Codeunit "Price Calculation Buffer Mgt.".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure CopyToBuffer(var PriceCalculationBufferMgt: Codeunit "TWE Rental Price Calc Buf Mgt."): Boolean
    var
        PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer";
    begin
        PriceCalculationBuffer.Init();
        if not SetAssetSource(PriceCalculationBuffer) then
            exit(false);

        FillBuffer(PriceCalculationBuffer);
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, RentalPriceSourceList);
        exit(true);
    end;

    local procedure FillBuffer(var PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer")
    var
        MainRentalItem: Record "TWE Main Rental Item";
        Resource: Record Resource;
    begin
        PriceCalculationBuffer."Price Calculation Method" := RentalLine."Price Calculation Method";
        case PriceCalculationBuffer."Asset Type" of
            PriceCalculationBuffer."Asset Type"::"Rental Item":
                begin
                    PriceCalculationBuffer."Variant Code" := RentalLine."Variant Code";
                    MainRentalItem.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := MainRentalItem."Unit Price";
                    PriceCalculationBuffer."Item Disc. Group" := MainRentalItem."Rental Item Disc. Group";

                end;
            PriceCalculationBuffer."Asset Type"::Resource:
                begin
                    PriceCalculationBuffer."Work Type Code" := RentalLine."Work Type Code";
                    Resource.Get(PriceCalculationBuffer."Asset No.");
                    PriceCalculationBuffer."Unit Price" := Resource."Unit Price";

                end;
        end;
        PriceCalculationBuffer."Location Code" := RentalLine."Location Code";
        PriceCalculationBuffer."Document Date" := GetDocumentDate();

        // Currency
        PriceCalculationBuffer.Validate("Currency Code", RentalHeader."Currency Code");
        PriceCalculationBuffer."Currency Factor" := RentalHeader."Currency Factor";

        // Tax
        PriceCalculationBuffer."Prices Including Tax" := RentalHeader."Prices Including VAT";
        PriceCalculationBuffer."Tax %" := RentalLine."VAT %";
        PriceCalculationBuffer."VAT Calculation Type" := RentalLine."VAT Calculation Type".AsInteger();
        PriceCalculationBuffer."VAT Bus. Posting Group" := RentalLine."VAT Bus. Posting Group";
        PriceCalculationBuffer."VAT Prod. Posting Group" := RentalLine."VAT Prod. Posting Group";

        // UoM
        PriceCalculationBuffer.Quantity := Abs(RentalLine.Quantity);
        PriceCalculationBuffer."Unit of Measure Code" := RentalLine."Unit of Measure Code";
        PriceCalculationBuffer."Qty. per Unit of Measure" := RentalLine."Qty. per Unit of Measure";
        // Discounts
        PriceCalculationBuffer."Line Discount %" := RentalLine."Line Discount %";
        PriceCalculationBuffer."Allow Line Disc." := IsDiscountAllowed();
        PriceCalculationBuffer."Allow Invoice Disc." := RentalLine."Allow Invoice Disc.";
        OnAfterFillBuffer(PriceCalculationBuffer, RentalHeader, RentalLine);
    end;

    local procedure AddSources()
    var
        RentalSourceType: Enum "TWE Rental Price Source Type";
    begin
        RentalPriceSourceList.Init();
        case RentalLine.Type of
            RentalLine.Type::"Rental Item":
                begin
                    RentalPriceSourceList.Add(RentalSourceType::"All Customers");
                    RentalPriceSourceList.Add(RentalSourceType::Customer, RentalHeader."Bill-to Customer No.");
                    RentalPriceSourceList.Add(RentalSourceType::Campaign, RentalHeader."Campaign No.");
                    AddActivatedCampaignsAsSource();
                    RentalPriceSourceList.Add(RentalSourceType::"Customer Price Group", RentalLine."Customer Price Group");
                    RentalPriceSourceList.Add(RentalSourceType::"Customer Disc. Group", RentalLine."Customer Disc. Group");
                end;
            RentalLine.Type::Resource:
                RentalPriceSourceList.Add(RentalSourceType::"All Jobs");
        end;
        OnAfterAddSources(RentalHeader, RentalLine, CurrPriceType, RentalPriceSourceList);
    end;

    local procedure GetDocumentDate() DocumentDate: Date;
    begin
        if RentalHeader."Document Type" in
            [RentalHeader."Document Type"::Invoice, RentalHeader."Document Type"::"Credit Memo"]
        then
            DocumentDate := RentalHeader."Posting Date"
        else
            DocumentDate := RentalHeader."Order Date";
        if DocumentDate = 0D then
            DocumentDate := WorkDate();
        OnAfterGetDocumentDate(DocumentDate, RentalHeader);
    end;

    /// <summary>
    /// SetPrice.
    /// </summary>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    /// <param name="PriceListLine">Record "Price List Line".</param>
    procedure SetPrice(AmountType: Enum "Price Amount Type"; PriceListLine: Record "TWE Rental Price List Line")
    begin
        case AmountType of
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Rental:
                        begin
                            RentalLine."Unit Price" := PriceListLine."Unit Price";
                            if PriceListLine.IsRealLine() then
                                RentalLine."Allow Line Disc." := PriceListLine."Allow Line Disc.";
                            RentalLine."Allow Invoice Disc." := PriceListLine."Allow Invoice Disc.";
                            PriceCalculated := true;
                        end;
                    CurrPriceType::Purchase:
                        RentalLine."Unit Cost (LCY)" := PriceListLine."Unit Cost";
                end;
            AmountType::Discount:
                RentalLine."Line Discount %" := PriceListLine."Line Discount %";
        end;
        OnAfterSetPrice(RentalLine, PriceListLine, AmountType);
    end;

    /// <summary>
    /// ValidatePrice.
    /// </summary>
    /// <param name="AmountType">enum "Price Amount Type".</param>
    procedure ValidatePrice(AmountType: enum "Price Amount Type")
    begin
        case AmountType of
            AmountType::Discount:
                begin
                    RentalLine.TestField("Allow Line Disc.");
                    RentalLine.Validate("Line Discount %");
                end;
            AmountType::Price:
                case CurrPriceType of
                    CurrPriceType::Rental:
                        RentalLine.Validate("Unit Price");
                end;
        end;
    end;

    /// <summary>
    /// Update.
    /// </summary>
    /// <param name="AmountType">enum "Price Amount Type".</param>
    procedure Update(AmountType: enum "Price Amount Type")
    begin
        if not RentalLine."Allow Line Disc." then
            RentalLine."Line Discount %" := 0;
    end;

    /// <summary>
    /// AddActivatedCampaignsAsSource.
    /// </summary>
    procedure AddActivatedCampaignsAsSource()
    var
        TempTargetCampaignGr: Record "Campaign Target Group" temporary;
        SourceType: Enum "TWE Rental Price Source Type";
    begin
        if FindActivatedCampaign(TempTargetCampaignGr) then
            repeat
                RentalPriceSourceList.Add(SourceType::Campaign, TempTargetCampaignGr."Campaign No.");
            until TempTargetCampaignGr.Next() = 0;
    end;

    local procedure FindActivatedCampaign(var TempCampaignTargetGr: Record "Campaign Target Group" temporary): Boolean
    var
        RentalPriceSourceType: enum "TWE Rental Price Source Type";
    begin
        TempCampaignTargetGr.Reset();
        TempCampaignTargetGr.DeleteAll();

        if RentalPriceSourceList.GetValue(RentalPriceSourceType::Campaign) = '' then
            FindCustomerCampaigns(RentalPriceSourceList.GetValue(RentalPriceSourceType::Customer), TempCampaignTargetGr);

        exit(TempCampaignTargetGr.FindFirst());
    end;

    local procedure FindCustomerCampaigns(CustomerNo: Code[20]; var TempCampaignTargetGr: Record "Campaign Target Group" temporary) Found: Boolean;
    var
        CampaignTargetGr: Record "Campaign Target Group";
    begin
        CampaignTargetGr.SetRange(Type, CampaignTargetGr.Type::Customer);
        CampaignTargetGr.SetRange("No.", CustomerNo);
        Found := CampaignTargetGr.CopyTo(TempCampaignTargetGr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSources(
        RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line";
        RentalPriceType: Enum "TWE Rental Price Type"; var PriceSourceList: Codeunit "TWE Rental Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBuffer(
        var PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentDate(var DocumentDate: Date; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPrice(var RentalLine: Record "TWE Rental Line"; PriceListLine: Record "TWE Rental Price List Line"; AmountType: Enum "Price Amount Type")
    begin
    end;
}
