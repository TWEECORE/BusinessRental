/// <summary>
/// Codeunit TWE Rental Price UX Management (ID 70704652).
/// </summary>
codeunit 50052 "TWE Rental Price UX Management"
{
    var
        MissingAlternateImplementationErr: Label 'You cannot setup exceptions because there is no alternate implementation.';
        EmptyPriceSourceErr: Label 'Price source information is missing.';

    /// <summary>
    /// GetFirstSourceFromFilter.
    /// </summary>
    /// <param name="PriceListHeader">VAR Record "TWE Rental Price List Header".</param>
    /// <param name="RentalPriceSource">VAR Record "TWE Rental Price Source".</param>
    /// <param name="DefaultSourceType">Enum "TWE Rental Price Source Type".</param>
    procedure GetFirstSourceFromFilter(var PriceListHeader: Record "TWE Rental Price List Header"; var RentalPriceSource: Record "TWE Rental Price Source"; DefaultSourceType: Enum "TWE Rental Price Source Type")
    var
        RentalSourceType: Enum "TWE Rental Price Source Type";
    begin
        RentalPriceSource.InitSource();
        PriceListHeader.FilterGroup(2);
        if PriceListHeader.GetFilter("Rental Source Type") = '' then
            RentalPriceSource.Validate("Source Type", DefaultSourceType)
        else begin
            Evaluate(RentalSourceType, GetFirstFilterValue(PriceListHeader.GetFilter("Rental Source Type")));
            RentalPriceSource.Validate("Source Type", RentalSourceType);
            RentalPriceSource.Validate(
                "Parent Source No.", GetFirstFilterValue(PriceListHeader.GetFilter("Parent Source No.")));
            RentalPriceSource.Validate(
                "Source No.", GetFirstFilterValue(PriceListHeader.GetFilter("Source No.")));
            if RentalPriceSource."Source Group" = RentalPriceSource."Source Group"::All then
                RentalPriceSource."Source Group" := PriceListHeader."Rental Source Group";
        end;
        Evaluate(RentalPriceSource."Price Type", PriceListHeader.GetFilter("Rental Price Type"));
        PriceListHeader.FilterGroup(0);
    end;

    /// <summary>
    /// IsAmountTypeFiltered.
    /// </summary>
    /// <param name="RentalPriceListHeader">VAR Record "Price List Header".</param>
    /// <returns>Return variable AmountTypeIsFiltered of type Boolean.</returns>
    procedure IsAmountTypeFiltered(var RentalPriceListHeader: Record "TWE Rental Price List Header") AmountTypeIsFiltered: Boolean;
    var
        Dummy: Enum "Price Amount Type";
    begin
        exit(IsAmountTypeFiltered(RentalPriceListHeader, Dummy))
    end;

    /// <summary>
    /// IsAmountTypeFiltered.
    /// </summary>
    /// <param name="RentalPriceListHeader">VAR Record "Price List Header".</param>
    /// <param name="FirstFilterValue">VAR Enum "Price Amount Type".</param>
    /// <returns>Return variable AmountTypeIsFiltered of type Boolean.</returns>
    procedure IsAmountTypeFiltered(var RentalPriceListHeader: Record "TWE Rental Price List Header"; var FirstFilterValue: Enum "Price Amount Type") AmountTypeIsFiltered: Boolean;
    var
        AmountTypeFilterText: Text;
    begin
        RentalPriceListHeader.FilterGroup(2);
        AmountTypeFilterText := RentalPriceListHeader.GetFilter("Amount Type");
        RentalPriceListHeader.FilterGroup(0);

        if AmountTypeFilterText <> '' then
            AmountTypeIsFiltered := Evaluate(FirstFilterValue, GetFirstFilterValue(AmountTypeFilterText));
        if not AmountTypeIsFiltered then
            FirstFilterValue := FirstFilterValue::Any;
    end;

    local procedure GetFirstFilterValue(FilterValue: Text) FirstValue: Text;
    var
        Pos: Integer;
    begin
        if FilterValue = '' then
            exit('');
        Pos := StrPos(FilterValue, '|');
        if Pos = 0 then
            FirstValue := FilterValue
        else
            FirstValue := CopyStr(FilterValue, 1, Pos - 1);
    end;

    /// <summary>
    /// GetSupportedMethods.
    /// </summary>
    /// <param name="TempPriceCalculationSetup">Temporary VAR Record "Price Calculation Setup".</param>
    /// <param name="ImplementationsPerMethod">VAR Dictionary of [Integer, Integer].</param>
    procedure GetSupportedMethods(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary; var ImplementationsPerMethod: Dictionary of [Integer, Integer])
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        Implementations: List of [Integer];
        CurrMethod: Enum "Price Calculation Method";
    begin
        PriceCalculationSetup.SetCurrentKey(Method);
        if PriceCalculationSetup.FindSet() then begin
            repeat
                if CurrMethod <> PriceCalculationSetup.Method then begin
                    if CurrMethod.AsInteger() <> 0 then begin
                        ImplementationsPerMethod.Add(CurrMethod.AsInteger(), Implementations.Count());
                        Clear(Implementations);
                    end;

                    CurrMethod := PriceCalculationSetup.Method;
                    TempPriceCalculationSetup.Validate(Method, CurrMethod);
                    TempPriceCalculationSetup.Insert(true);
                end;
                if not Implementations.Contains(PriceCalculationSetup.Implementation.AsInteger()) then
                    Implementations.Add(PriceCalculationSetup.Implementation.AsInteger());
            until PriceCalculationSetup.Next() = 0;

            ImplementationsPerMethod.Add(CurrMethod.AsInteger(), Implementations.Count());
            if TempPriceCalculationSetup.FindFirst() then;
        end;
    end;

    /// <summary>
    /// PickImplementation.
    /// </summary>
    /// <param name="CurrPriceCalculationSetup">VAR Record "Price Calculation Setup".</param>
    procedure PickImplementation(var CurrPriceCalculationSetup: Record "Price Calculation Setup")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        TempPriceCalculationSetup: Record "Price Calculation Setup" temporary;
        PriceCalcImplementations: Page "Price Calc. Implementations";
    begin
        CollectAvailableImplementations(CurrPriceCalculationSetup, TempPriceCalculationSetup);

        PriceCalcImplementations.SetData(TempPriceCalculationSetup);
        PriceCalcImplementations.LookupMode := true;
        if PriceCalcImplementations.RunModal() = Action::LookupOK then begin
            PriceCalcImplementations.GetRecord(TempPriceCalculationSetup);

            if CurrPriceCalculationSetup.Code <> TempPriceCalculationSetup.Code then begin
                PriceCalculationSetup.Get(TempPriceCalculationSetup.Code);
                PriceCalculationSetup.Validate(Default, true);
                PriceCalculationSetup.Modify();

                CurrPriceCalculationSetup.Delete();
                CurrPriceCalculationSetup := PriceCalculationSetup;
                CurrPriceCalculationSetup.Insert();
            end;
        end;
    end;

    local procedure CollectAvailableImplementations(CurrPriceCalculationSetup: Record "Price Calculation Setup"; var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary)
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DefaultCode: Code[100];
    begin
        PriceCalculationSetup.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.FindSet() then begin
            repeat
                TempPriceCalculationSetup := PriceCalculationSetup;
                TempPriceCalculationSetup.Insert();
                if PriceCalculationSetup.Default then
                    DefaultCode := PriceCalculationSetup.Code;
            until PriceCalculationSetup.Next() = 0;

            if DefaultCode <> '' then
                TempPriceCalculationSetup.Get(DefaultCode)
            else
                TempPriceCalculationSetup.FindFirst();
        end;
    end;

    local procedure LookupJobPriceLists(var PriceListHeader: Record "Price List Header"; var PriceListCode: Code[20]) IsPicked: Boolean;
    var
        PurchaseJobPriceLists: Page "Purchase Job Price Lists";
        SalesJobPriceLists: Page "Sales Job Price Lists";
    begin
        PriceListCode := '';
        case PriceListHeader."Price Type" of
            "Price Type"::Sale:
                begin
                    SalesJobPriceLists.LookupMode(true);
                    SalesJobPriceLists.SetRecordFilter(PriceListHeader);
                    if SalesJobPriceLists.RunModal() = Action::LookupOK then
                        SalesJobPriceLists.GetRecord(PriceListHeader);
                end;
            "Price Type"::Purchase:
                begin
                    PurchaseJobPriceLists.LookupMode(true);
                    PurchaseJobPriceLists.SetRecordFilter(PriceListHeader);
                    if PurchaseJobPriceLists.RunModal() = Action::LookupOK then
                        PurchaseJobPriceLists.GetRecord(PriceListHeader);
                end;
        end;
        PriceListCode := PriceListHeader.Code;
        IsPicked := PriceListCode <> '';
    end;

    local procedure LookupPriceLists(var PriceListHeader: Record "Price List Header"; var PriceListCode: Code[20]) IsPicked: Boolean;
    var
        PurchasePriceLists: Page "Purchase Price Lists";
        SalesPriceLists: Page "Sales Price Lists";
    begin
        PriceListCode := '';
        case PriceListHeader."Price Type" of
            "Price Type"::Sale:
                begin
                    SalesPriceLists.LookupMode(true);
                    SalesPriceLists.SetRecordFilter(PriceListHeader);
                    if SalesPriceLists.RunModal() = Action::LookupOK then
                        SalesPriceLists.GetRecord(PriceListHeader);
                end;
            "Price Type"::Purchase:
                begin
                    PurchasePriceLists.LookupMode(true);
                    PurchasePriceLists.SetRecordFilter(PriceListHeader);
                    if PurchasePriceLists.RunModal() = Action::LookupOK then
                        PurchasePriceLists.GetRecord(PriceListHeader);
                end;
        end;
        PriceListCode := PriceListHeader.Code;
        IsPicked := PriceListCode <> '';
    end;

    /// <summary>
    /// LookupPriceLists.
    /// </summary>
    /// <param name="SourceGroup">Enum "Price Source Group".</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="PriceListCode">VAR Code[20].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure LookupPriceLists(SourceGroup: Enum "Price Source Group"; PriceType: Enum "Price Type"; var PriceListCode: Code[20]): Boolean;
    var
        PriceListHeader: Record "Price List Header";
    begin
        if PriceListCode <> '' then begin
            PriceListHeader.Get(PriceListCode);
            PriceListHeader.SetFilter(Code, '<>%1', PriceListCode);
        end else begin
            PriceListHeader."Source Group" := SourceGroup;
            PriceListHeader."Price Type" := PriceType;
        end;
        case SourceGroup of
            SourceGroup::Job:
                exit(LookupJobPriceLists(PriceListHeader, PriceListCode));
            SourceGroup::Customer,
            SourceGroup::Vendor:
                exit(LookupPriceLists(PriceListHeader, PriceListCode));
        end;
    end;

    /// <summary>
    /// ShowExceptions.
    /// </summary>
    /// <param name="CurrPriceCalculationSetup">Record "Price Calculation Setup".</param>
    procedure ShowExceptions(CurrPriceCalculationSetup: Record "Price Calculation Setup")
    var
        DtldPriceCalculationSetup: Page "Dtld. Price Calculation Setup";
    begin
        DtldPriceCalculationSetup.Set(CurrPriceCalculationSetup);
        DtldPriceCalculationSetup.RunModal();
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="Campaign">Record Campaign.</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceLists(Campaign: Record Campaign; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Campaign, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Campaign, PriceType, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="Contact">Record Contact.</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceLists(Contact: Record Contact; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Contact, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Contact, PriceType, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="Customer">Record Customer.</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceLists(Customer: Record Customer; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Customer, "Price Type"::Sale, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Customer, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="CustomerDiscountGroup">Record "Customer Discount Group".</param>
    procedure ShowPriceLists(CustomerDiscountGroup: Record "Customer Discount Group")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(CustomerDiscountGroup, "Price Type"::Sale, "Price Amount Type"::Discount, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(CustomerDiscountGroup, PriceSourceList);
        ShowPriceLists(PriceSourceList, "Price Amount Type"::Discount);
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="CustomerPriceGroup">Record "Customer Price Group".</param>
    procedure ShowPriceLists(CustomerPriceGroup: Record "Customer Price Group")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(CustomerPriceGroup, "Price Type"::Sale, "Price Amount Type"::Price, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(CustomerPriceGroup, PriceSourceList);
        ShowPriceLists(PriceSourceList, "Price Amount Type"::Price);
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="Vendor">Record Vendor.</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceLists(Vendor: Record Vendor; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Vendor, "Price Type"::Purchase, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Vendor, PriceSourceList);
        ShowPriceLists(PriceSourceList, AmountType);
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="Job">Record Job.</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceLists(Job: Record Job; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSourceList: Codeunit "Price Source List";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceLists(Job, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        GetPriceSource(Job, PriceType, PriceSourceList);
        ShowJobPriceLists(PriceSourceList, AmountType);
    end;

    local procedure ShowJobPriceLists(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PurchaseJobPriceLists: Page "Purchase Job Price Lists";
        SalesJobPriceLists: Page "Sales Job Price Lists";
        PriceType: Enum "Price Type";
    begin
        PriceType := PriceSourceList.GetPriceType();
        case PriceType of
            PriceType::Sale:
                begin
                    SalesJobPriceLists.SetSource(PriceSourceList, AmountType);
                    SalesJobPriceLists.Run();
                end;
            PriceType::Purchase:
                begin
                    PurchaseJobPriceLists.SetSource(PriceSourceList, AmountType);
                    PurchaseJobPriceLists.Run();
                end;
        end
    end;

    /// <summary>
    /// ShowPriceListLines.
    /// </summary>
    /// <param name="PriceAsset">Record "Price Asset".</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceListLines(PriceAsset: Record "TWE Rental Price Asset"; PriceType: Enum "TWE Rental Price Type"; AmountType: Enum "Price Amount Type")
    var
        DummyPriceSource: Record "TWE Rental Price Source";
        RentalPriceAssetList: Codeunit "TWE Rental Price Asset List";
        PriceListLineReview: Page "TWE Rental Price List Line Rev";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceListLines(DummyPriceSource, PriceAsset, PriceType, AmountType, IsHandled);
        if IsHandled then
            exit;
        RentalPriceAssetList.Init();
        RentalPriceAssetList.Add(PriceAsset);
        PriceListLineReview.Set(RentalPriceAssetList, PriceType, AmountType);
        PriceListLineReview.Run();
    end;

    /// <summary>
    /// ShowPriceListLines.
    /// </summary>
    /// <param name="PriceSource">Record "Price Source".</param>
    /// <param name="PriceAsset">Record "Price Asset".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceListLines(PriceSource: Record "TWE Rental Price Source"; PriceAsset: Record "TWE Rental Price Asset"; AmountType: Enum "Price Amount Type")
    var
        PriceAssetList: Codeunit "TWE Rental Price Asset List";
        PriceListLineReview: Page "TWE Rental Price List Line Rev";
        IsHandled: Boolean;
    begin
        OnBeforeShowPriceListLines(PriceSource, PriceAsset, PriceSource."Price Type", AmountType, IsHandled);
        if IsHandled then
            exit;
        PriceAssetList.Init();
        PriceAssetList.Add(PriceAsset);
        PriceListLineReview.Set(PriceSource, PriceAssetList, AmountType);
        PriceListLineReview.Run();
    end;

    /// <summary>
    /// ShowPriceLists.
    /// </summary>
    /// <param name="PriceSourceList">Codeunit "Price Source List".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure ShowPriceLists(PriceSourceList: Codeunit "Price Source List"; AmountType: Enum "Price Amount Type")
    var
        PurchasePriceLists: Page "Purchase Price Lists";
        SalesPriceLists: Page "Sales Price Lists";
        PriceType: Enum "Price Type";
    begin
        PriceType := PriceSourceList.GetPriceType();
        case PriceType of
            PriceType::Sale:
                begin
                    SalesPriceLists.SetSource(PriceSourceList, AmountType);
                    SalesPriceLists.Run();
                end;
            PriceType::Purchase:
                begin
                    PurchasePriceLists.SetSource(PriceSourceList, AmountType);
                    PurchasePriceLists.Run();
                end;
        end;
    end;

    local procedure GetPriceSource(Campaign: Record Campaign; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Campaign, Campaign."No.");
        PriceSourceList.SetPriceType(PriceType);
    end;

    local procedure GetPriceSource(Contact: Record Contact; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Contact, Contact."No.");
        PriceSourceList.SetPriceType(PriceType);
    end;

    local procedure GetPriceSource(Customer: Record Customer; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Customer, Customer."No.");
        PriceSourceList.Add(PriceSourceType::"All Customers");
        if Customer."Customer Price Group" <> '' then
            PriceSourceList.Add(PriceSourceType::"Customer Price Group", Customer."Customer Price Group");
        if Customer."Customer Disc. Group" <> '' then
            PriceSourceList.Add(PriceSourceType::"Customer Disc. Group", Customer."Customer Disc. Group");
    end;

    local procedure GetPriceSource(CustomerPriceGroup: Record "Customer Price Group"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::"Customer Price Group", CustomerPriceGroup.Code);
    end;

    local procedure GetPriceSource(CustomerDiscountGroup: Record "Customer Discount Group"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::"Customer Disc. Group", CustomerDiscountGroup.Code);
    end;

    local procedure GetPriceSource(Vendor: Record Vendor; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Vendor, Vendor."No.");
        PriceSourceList.Add(PriceSourceType::"All Vendors");
    end;

    local procedure GetPriceSource(Job: Record Job; PriceType: Enum "Price Type"; var PriceSourceList: Codeunit "Price Source List")
    var
        PriceSourceType: Enum "Price Source Type";
    begin
        PriceSourceList.Add(PriceSourceType::Job, Job."No.");
        PriceSourceList.Add(PriceSourceType::"All Jobs");
        PriceSourceList.SetPriceType(PriceType);
    end;

    /// <summary>
    /// SetPriceListsFilters.
    /// </summary>
    /// <param name="PriceListHeader">VAR Record "Price List Header".</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure SetPriceListsFilters(var PriceListHeader: Record "TWE Rental Price List Header"; PriceType: Enum "TWE Rental Price Type"; AmountType: Enum "Price Amount Type")
    begin
        PriceListHeader.FilterGroup(2);
        PriceListHeader.SetRange("Rental Price Type", PriceType);
        if AmountType <> AmountType::Any then
            PriceListHeader.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);
        PriceListHeader.FilterGroup(0);
    end;

    /// <summary>
    /// SetPriceListsFilters.
    /// </summary>
    /// <param name="PriceListHeader">VAR Record "Price List Header".</param>
    /// <param name="PriceSourceList">Codeunit "Price Source List".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure SetPriceListsFilters(var PriceListHeader: Record "TWE Rental Price List Header"; PriceSourceList: Codeunit "TWE Rental Price Source List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListHeader.FilterGroup(2);
        if AmountType <> AmountType::Any then
            PriceListHeader.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);
        SetSourceFilters(PriceSourceList, PriceListHeader);
        PriceListHeader.FilterGroup(0);
    end;

    /// <summary>
    /// SetPriceListLineFilters.
    /// </summary>
    /// <param name="PriceListLine">VAR Record "Price List Line".</param>
    /// <param name="PriceAssetList">Codeunit "Price Asset List".</param>
    /// <param name="PriceType">Enum "Price Type".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure SetPriceListLineFilters(var PriceListLine: Record "TWE Rental Price List Line"; PriceAssetList: Codeunit "TWE Rental Price Asset List"; PriceType: Enum "TWE Rental Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceSource: Record "TWE Rental Price Source";
    begin
        PriceSource."Price Type" := PriceType;
        SetPriceListLineFilters(PriceListLine, PriceSource, PriceAssetList, AmountType);
    end;

    /// <summary>
    /// SetPriceListLineFilters.
    /// </summary>
    /// <param name="PriceListLine">VAR Record "Price List Line".</param>
    /// <param name="PriceSource">Record "Price Source".</param>
    /// <param name="PriceAssetList">Codeunit "Price Asset List".</param>
    /// <param name="AmountType">Enum "Price Amount Type".</param>
    procedure SetPriceListLineFilters(var PriceListLine: Record "TWE Rental Price List Line"; PriceSource: Record "TWE Rental Price Source"; PriceAssetList: Codeunit "TWE Rental Price Asset List"; AmountType: Enum "Price Amount Type")
    begin
        PriceListLine.FilterGroup(2);
        PriceListLine.SetRange("Price Type", PriceSource."Price Type");
        if AmountType = AmountType::Any then
            PriceListLine.SetRange("Amount Type")
        else
            PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, AmountType::Any);

        if PriceSource."Source Type" <> PriceSource."Source Type"::All then begin
            PriceListLine.SetRange("Source Type", PriceSource."Source Type");
            PriceListLine.SetRange("Source No.", PriceSource."Source No.");
        end;
        BuildAssetFilters(PriceListLine, PriceAssetList);
        PriceListLine.MarkedOnly(true);
        PriceListLine.FilterGroup(0);
    end;

    local procedure BuildAssetFilters(var PriceListLine: Record "TWE Rental Price List Line"; PriceAssetList: Codeunit "TWE Rental Price Asset List")
    var
        PriceAsset: Record "TWE Rental Price Asset";
    begin
        if PriceAssetList.First(PriceAsset, 0) then
            repeat
                PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
                PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
                if PriceAsset."Variant Code" <> '' then
                    PriceListLine.SetRange("Variant Code", PriceAsset."Variant Code")
                else
                    PriceListLine.SetRange("Variant Code");
                if PriceListLine.FindSet() then
                    repeat
                        PriceListLine.Mark(true);
                    until PriceListLine.Next() = 0;
            until not PriceAssetList.Next(PriceAsset);

        PriceListLine.SetRange("Asset Type");
        PriceListLine.SetRange("Asset No.");
        PriceListLine.SetRange("Variant Code");
    end;

    local procedure SetSourceFilters(RentalPriceSourceList: Codeunit "TWE Rental Price Source List"; var PriceListHeader: Record "TWE Rental Price List Header")
    var
        RentalPriceSource: Record "TWE Rental Price Source";
        SourceFilter: array[3] of Text;
    begin
        RentalPriceSourceList.GetList(RentalPriceSource);
        if not RentalPriceSource.FindSet() then
            Error(EmptyPriceSourceErr);

        PriceListHeader.SetRange("Rental Price Type", RentalPriceSource."Price Type");
        PriceListHeader.SetRange("Rental Source Group", RentalPriceSource."Source Group");

        BuildSourceFilters(RentalPriceSource, SourceFilter);
        if SourceFilter[3] <> '' then
            PriceListHeader.SetFilter("Filter Source No.", SourceFilter[3])
        else begin
            PriceListHeader.SetFilter("Rental Source Type", SourceFilter[1]);
            PriceListHeader.SetFilter("Source No.", SourceFilter[2]);
        end;
    end;

    local procedure BuildSourceFilters(var RentalPriceSource: Record "TWE Rental Price Source"; var SourceFilter: array[3] of Text)
    var
        OrSeparator: Text[1];
    begin
        repeat
            if RentalPriceSource."Source Group" = RentalPriceSource."Source Group"::Job then
                SourceFilter[3] += OrSeparator + GetFilterText(RentalPriceSource."Filter Source No.")
            else begin
                SourceFilter[1] += OrSeparator + Format(RentalPriceSource."Source Type");
                SourceFilter[2] += OrSeparator + GetFilterText(RentalPriceSource."Source No.");
            end;
            OrSeparator := '|';
        until RentalPriceSource.Next() = 0;
    end;

    local procedure GetFilterText(SourceNo: Code[20]): Text;
    begin
        if SourceNo = '' then
            exit('''''');
        exit(SourceNo);
    end;

    /// <summary>
    /// GetFirstAlternateSetupCode.
    /// </summary>
    /// <param name="CurrPriceCalculationSetup">Record "Price Calculation Setup".</param>
    /// <returns>Return value of type Code[100].</returns>
    procedure GetFirstAlternateSetupCode(CurrPriceCalculationSetup: Record "Price Calculation Setup"): Code[100];
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if CurrPriceCalculationSetup."Group Id" = '' then
            exit('');
        PriceCalculationSetup.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        if PriceCalculationSetup.FindFirst() then
            exit(PriceCalculationSetup.Code)
    end;

    /// <summary>
    /// PickAlternateImplementation.
    /// </summary>
    /// <param name="DtldPriceCalculationSetup">VAR Record "Dtld. Price Calculation Setup".</param>
    procedure PickAlternateImplementation(var DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup");
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange("Group Id", DtldPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        if Page.RunModal(Page::"Price Calc. Implementations", PriceCalculationSetup) = ACTION::LookupOK then
            DtldPriceCalculationSetup.Validate(Implementation, PriceCalculationSetup.Implementation);
    end;

    /// <summary>
    /// TestAlternateImplementation.
    /// </summary>
    /// <param name="CurrPriceCalculationSetup">Record "Price Calculation Setup".</param>
    procedure TestAlternateImplementation(CurrPriceCalculationSetup: Record "Price Calculation Setup")
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange("Group Id", CurrPriceCalculationSetup."Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        if PriceCalculationSetup.IsEmpty() then
            Error(MissingAlternateImplementationErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPriceLists(FromRecord: Variant; PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPriceListLines(PriceSource: Record "TWE Rental Price Source"; TWERentalPriceAsset: Record "TWE Rental Price Asset"; TWEREntalPriceType: Enum "TWE Rental Price Type"; AmountType: Enum "Price Amount Type"; var IsHandled: Boolean)
    begin
    end;
}
