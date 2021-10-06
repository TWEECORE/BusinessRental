/// <summary>
/// Codeunit TWE Rental Format Address (ID 50021).
/// </summary>
codeunit 50021 "TWE Rental Format Address"
{
    SingleInstance = true;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        GLSetupRead: Boolean;
        i: Integer;
        LanguageCode: Code[10];

    /// <summary>
    /// FormatAddr.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="Name">Text[100].</param>
    /// <param name="Name2">Text[100].</param>
    /// <param name="Contact">Text[100].</param>
    /// <param name="Addr">Text[100].</param>
    /// <param name="Addr2">Text[50].</param>
    /// <param name="City">Text[50].</param>
    /// <param name="PostCode">Code[20].</param>
    /// <param name="County">Text[50].</param>
    /// <param name="CountryCode">Code[10].</param>
    procedure FormatAddr(var AddrArray: array[8] of Text[100]; Name: Text[100]; Name2: Text[100]; Contact: Text[100]; Addr: Text[100]; Addr2: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10])
    var
        Country: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        InsertText: Integer;
        Index: Integer;
        NameLineNo: Integer;
        Name2LineNo: Integer;
        AddrLineNo: Integer;
        Addr2LineNo: Integer;
        ContLineNo: Integer;
        PostCodeCityLineNo: Integer;
        CountyLineNo: Integer;
        CountryLineNo: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeFormatAddr(Country, CountryCode);
        Clear(AddrArray);

        if CountryCode = '' then begin
            GetGLSetup();
            Clear(Country);
            Country."Address Format" := GLSetup."Local Address Format";
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            if not Country.Get(CountryCode) then begin
                Country.Init();
                Country.Name := CountryCode;
            end;
        IsHandled := false;
        OnFormatAddrOnAfterGetCountry(
            AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, LanguageCode, IsHandled, Country);
        if IsHandled then
            exit;

        if Country."Address Format" = Country."Address Format"::Custom then begin
            CustomAddressFormat.Reset();
            CustomAddressFormat.SetCurrentKey("Country/Region Code", "Line Position");
            CustomAddressFormat.SetRange("Country/Region Code", CountryCode);
            if CustomAddressFormat.FindSet() then
                repeat
                    case CustomAddressFormat."Field ID" of
                        CompanyInfo.FieldNo(Name):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Name;
                        CompanyInfo.FieldNo("Name 2"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Name2;
                        CompanyInfo.FieldNo("Contact Person"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Contact;
                        CompanyInfo.FieldNo(Address):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Addr;
                        CompanyInfo.FieldNo("Address 2"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Addr2;
                        CompanyInfo.FieldNo(City):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := City;
                        CompanyInfo.FieldNo("Post Code"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := PostCode;
                        CompanyInfo.FieldNo(County):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := County;
                        CompanyInfo.FieldNo("Country/Region Code"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Country.Name;
                        else
                            GenerateCustomPostCodeCity(AddrArray[CustomAddressFormat."Line Position" + 1], City, PostCode, County, Country);
                    end;
                until CustomAddressFormat.Next() = 0;

            CompressArray(AddrArray);
        end else begin
            SetLineNos(Country, NameLineNo, Name2LineNo, AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo);

            IsHandled := false;
            OnBeforeFormatAddress(
              Country, AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, NameLineNo, Name2LineNo,
              AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo, IsHandled);
            if IsHandled then
                exit;

            AddrArray[NameLineNo] := Name;
            AddrArray[Name2LineNo] := Name2;
            AddrArray[AddrLineNo] := Addr;
            AddrArray[Addr2LineNo] := Addr2;

            case Country."Address Format" of
                Country."Address Format"::"Post Code+City",
                Country."Address Format"::"City+County+Post Code",
                Country."Address Format"::"City+Post Code":
                    UpdateAddrArrayForPostCodeCity(AddrArray, Contact, ContLineNo, Country, CountryLineNo, PostCodeCityLineNo, CountyLineNo, City, PostCode, County);

                Country."Address Format"::"Blank Line+Post Code+City":
                    begin
                        if ContLineNo < PostCodeCityLineNo then
                            AddrArray[ContLineNo] := Contact;
                        CompressArray(AddrArray);

                        Index := 1;
                        InsertText := 1;
                        repeat
                            if AddrArray[Index] = '' then begin
                                case InsertText of
                                    2:
                                        GeneratePostCodeCity(AddrArray[Index], AddrArray[Index + 1], City, PostCode, County, Country);
                                    3:
                                        AddrArray[Index] := Country.Name;
                                    4:
                                        if ContLineNo > PostCodeCityLineNo then
                                            AddrArray[Index] := Contact;
                                end;
                                InsertText := InsertText + 1;
                            end;
                            Index := Index + 1;
                        until Index = 9;
                    end;
            end;
        end;
        OnAfterFormatAddress(AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, LanguageCode);
    end;

    local procedure UpdateAddrArrayForPostCodeCity(var AddrArray: array[8] of Text[100]; Contact: Text[100]; ContLineNo: Integer; Country: Record "Country/Region"; CountryLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; City: Text[50]; PostCode: Code[20]; County: Text[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAddrArrayForPostCodeCity(AddrArray, Contact, ContLineNo, Country, CountryLineNo, PostCodeCityLineNo, CountyLineNo, City, PostCode, County, IsHandled);
        if IsHandled then
            exit;

        AddrArray[ContLineNo] := Contact;
        GeneratePostCodeCity(AddrArray[PostCodeCityLineNo], AddrArray[CountyLineNo], City, PostCode, County, Country);
        AddrArray[CountryLineNo] := Country.Name;
        CompressArray(AddrArray);
    end;

    /// <summary>
    /// FormatPostCodeCity.
    /// </summary>
    /// <param name="PostCodeCityText">VAR Text[100].</param>
    /// <param name="CountyText">VAR Text[50].</param>
    /// <param name="City">Text[50].</param>
    /// <param name="PostCode">Code[20].</param>
    /// <param name="County">Text[50].</param>
    /// <param name="CountryCode">Code[10].</param>
    procedure FormatPostCodeCity(var PostCodeCityText: Text[100]; var CountyText: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10])
    var
        Country: Record "Country/Region";
    begin
        OnBeforeFormatPostCodeCity(Country, CountryCode);
        Clear(PostCodeCityText);
        Clear(CountyText);

        if CountryCode = '' then begin
            GetGLSetup();
            Clear(Country);
            Country."Address Format" := GLSetup."Local Address Format";
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            Country.Get(CountryCode);

        if Country."Address Format" = Country."Address Format"::Custom then
            GenerateCustomPostCodeCity(PostCodeCityText, City, PostCode, County, Country)
        else
            GeneratePostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, Country);
    end;

    local procedure GeneratePostCodeCity(var PostCodeCityText: Text[100]; var CountyText: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; Country: Record "Country/Region")
    var
        DummyString: Text;
        OverMaxStrLen: Integer;
    begin
        DummyString := '';
        OverMaxStrLen := MaxStrLen(PostCodeCityText);
        if OverMaxStrLen < MaxStrLen(DummyString) then
            OverMaxStrLen += 1;

        case Country."Address Format" of
            Country."Address Format"::"Post Code+City":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := CopyStr(DelStr(PostCode + ' ' + City, OverMaxStrLen), 1, MaxStrLen(PostCodeCityText))
                    else
                        PostCodeCityText := City;
                    SetCountyTextForDACH(CountyText, County, Country.Code);
                end;
            Country."Address Format"::"City+County+Post Code":
                if (County <> '') and (PostCode <> '') then
                    PostCodeCityText :=
                      CopyStr(DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - StrLen(County) - 3) +
                      ', ' + County + ' ' + PostCode, 1, MaxStrLen(PostCodeCityText))
                else
                    if PostCode = '' then begin
                        PostCodeCityText := City;
                        CountyText := County;
                    end else
                        if (County = '') and (PostCode <> '') then
                            PostCodeCityText := DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ', ' + PostCode;

            Country."Address Format"::"City+Post Code":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ', ' + PostCode
                    else
                        PostCodeCityText := City;
                    SetCountyTextForDACH(CountyText, County, Country.Code);
                end;
            Country."Address Format"::"Blank Line+Post Code+City":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := CopyStr(DelStr(PostCode + ' ' + City, OverMaxStrLen), 1, MaxStrLen(PostCodeCityText))
                    else
                        PostCodeCityText := City;
                    SetCountyTextForDACH(CountyText, County, Country.Code);
                end;
        end;

        OnAfterGeneratePostCodeCity(Country, PostCode, PostCodeCityText, City, CountyText, County);
    end;

    local procedure GenerateCustomPostCodeCity(var PostCodeCityText: Text[100]; City: Text[50]; PostCode: Code[20]; County: Text[50]; Country: Record "Country/Region")
    var
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
        PostCodeCityLine: Text;
        CustomAddressFormatLineQty: Integer;
        Counter: Integer;
    begin
        PostCodeCityLine := '';

        CustomAddressFormat.Reset();
        CustomAddressFormat.SetRange("Country/Region Code", Country.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        if not CustomAddressFormat.FindFirst() then
            exit;

        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        CustomAddressFormatLine.SetRange("Country/Region Code", CustomAddressFormat."Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        CustomAddressFormatLineQty := CustomAddressFormatLine.Count();
        if CustomAddressFormatLine.FindSet() then
            repeat
                Counter += 1;
                case CustomAddressFormatLine."Field ID" of
                    CompanyInfo.FieldNo(City):
                        PostCodeCityLine += City;
                    CompanyInfo.FieldNo("Post Code"):
                        PostCodeCityLine += PostCode;
                    CompanyInfo.FieldNo(County):
                        PostCodeCityLine += County;
                end;
                if Counter < CustomAddressFormatLineQty then
                    if CustomAddressFormatLine.Separator <> '' then
                        PostCodeCityLine += CustomAddressFormatLine.Separator
                    else
                        PostCodeCityLine += ' ';
            until CustomAddressFormatLine.Next() = 0;

        PostCodeCityText := CopyStr(DelStr(PostCodeCityLine, MaxStrLen(PostCodeCityText)), 1, MaxStrLen(PostCodeCityText));
    end;

    /// <summary>
    /// GetCompanyAddr.
    /// </summary>
    /// <param name="RespCenterCode">Code[10].</param>
    /// <param name="ResponsibilityCenter">VAR Record "Responsibility Center".</param>
    /// <param name="CompanyInfo">VAR Record "Company Information".</param>
    /// <param name="CompanyAddr">VAR array[8] of Text[100].</param>
    procedure GetCompanyAddr(RespCenterCode: Code[10]; var ResponsibilityCenter: Record "Responsibility Center"; var CompanyInfo: Record "Company Information"; var CompanyAddr: array[8] of Text[100])
    begin
        if ResponsibilityCenter.Get(RespCenterCode) then begin
            RespCenter(CompanyAddr, ResponsibilityCenter);
            CompanyInfo."Phone No." := ResponsibilityCenter."Phone No.";
            CompanyInfo."Fax No." := ResponsibilityCenter."Fax No.";
        end else
            Company(CompanyAddr, CompanyInfo);
    end;

    /// <summary>
    /// Company.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="CompanyInfo">VAR Record "Company Information".</param>
    procedure Company(var AddrArray: array[8] of Text[100]; var CompanyInfo: Record "Company Information")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCompany(AddrArray, CompanyInfo, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, CompanyInfo.Name, CompanyInfo."Name 2", '', CompanyInfo.Address, CompanyInfo."Address 2",
          CompanyInfo.City, CompanyInfo."Post Code", CompanyInfo.County, '');
    end;

    /// <summary>
    /// Customer.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="Cust">VAR Record Customer.</param>
    procedure Customer(var AddrArray: array[8] of Text[100]; var Cust: Record Customer)
    var
        Handled: Boolean;
    begin
        OnBeforeCustomer(AddrArray, Cust, Handled);
        if Handled then
            exit;

        FormatAddr(
          AddrArray, Cust.Name, Cust."Name 2", Cust.Contact, Cust.Address, Cust."Address 2",
          Cust.City, Cust."Post Code", Cust.County, Cust."Country/Region Code");
    end;

    /// <summary>
    /// RespCenter.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RespCenter">VAR Record "Responsibility Center".</param>
    procedure RespCenter(var AddrArray: array[8] of Text[100]; var RespCenter: Record "Responsibility Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRespCenter(AddrArray, RespCenter, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RespCenter.Name, RespCenter."Name 2", RespCenter.Contact, RespCenter.Address, RespCenter."Address 2",
          RespCenter.City, RespCenter."Post Code", RespCenter.County, RespCenter."Country/Region Code");
    end;

    /// <summary>
    /// PostalBarCode.
    /// </summary>
    /// <param name="AddressType">Option.</param>
    /// <returns>Return value of type Text[100].</returns>
    procedure PostalBarCode(AddressType: Option): Text[100]
    begin
        if AddressType = AddressType then
            exit('');
        exit('');
    end;


    /// <summary>
    /// RentalHeaderSellTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure RentalHeaderSellTo(var AddrArray: array[8] of Text[100]; var RentalHeader: Record "TWE Rental Header")
    var
        Handled: Boolean;
    begin
        OnBeforeRentalHeaderSellTo(AddrArray, RentalHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
          AddrArray, RentalHeader."Rented-to Customer Name", RentalHeader."Rented-to Customer Name 2", RentalHeader."Rented-to Contact", RentalHeader."Rented-to Address", RentalHeader."Rented-to Address 2",
          RentalHeader."Rented-to City", RentalHeader."Rented-to Post Code", RentalHeader."Rented-to County", RentalHeader."Rented-to Country/Region Code");
    end;

    /// <summary>
    /// RentalHeaderBillTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    procedure RentalHeaderBillTo(var AddrArray: array[8] of Text[100]; var RentalHeader: Record "TWE Rental Header")
    var
        Handled: Boolean;
    begin
        OnBeforeRentalHeaderBillTo(AddrArray, RentalHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
          AddrArray, RentalHeader."Bill-to Name", RentalHeader."Bill-to Name 2", RentalHeader."Bill-to Contact", RentalHeader."Bill-to Address", RentalHeader."Bill-to Address 2",
          RentalHeader."Bill-to City", RentalHeader."Bill-to Post Code", RentalHeader."Bill-to County", RentalHeader."Bill-to Country/Region Code");
    end;

    /// <summary>
    /// RentalHeaderShipTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="CustAddr">array[8] of Text[100].</param>
    /// <param name="RentalHeader">VAR Record "TWE Rental Header".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure RentalHeaderShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var RentalHeader: Record "TWE Rental Header") Result: Boolean
    var
        CountryRegion: Record "Country/Region";
        SellToCountry: Code[50];
        Handled: Boolean;
    begin
        OnBeforeRentalHeaderShipTo(AddrArray, CustAddr, RentalHeader, Handled, Result);
        if Handled then
            exit(Result);

        FormatAddr(
          AddrArray, RentalHeader."Ship-to Name", RentalHeader."Ship-to Name 2", RentalHeader."Ship-to Contact", RentalHeader."Ship-to Address", RentalHeader."Ship-to Address 2",
          RentalHeader."Ship-to City", RentalHeader."Ship-to Post Code", RentalHeader."Ship-to County", RentalHeader."Ship-to Country/Region Code");
        if CountryRegion.Get(RentalHeader."Rented-to Country/Region Code") then
            SellToCountry := CountryRegion.Name;
        if RentalHeader."Rented-to Customer No." <> RentalHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                exit(true);
        exit(false);
    end;

    /// <summary>
    /// RentalShptSellTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalShptHeader">VAR Record "TWE Rental Shipment Header".</param>
    procedure RentalShptSellTo(var AddrArray: array[8] of Text[100]; var RentalShptHeader: Record "TWE Rental Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalShptSellTo(AddrArray, RentalShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalShptHeader."Rented-to Customer Name", RentalShptHeader."Rented-to Customer Name 2", RentalShptHeader."Rented-to Contact", RentalShptHeader."Rented-to Address", RentalShptHeader."Rented-to Address 2",
          RentalShptHeader."Rented-to City", RentalShptHeader."Rented-to Post Code", RentalShptHeader."Rented-to County", RentalShptHeader."Rented-to Country/Region Code");
    end;

    /// <summary>
    /// RentalShptBillTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="ShipToAddr">array[8] of Text[100].</param>
    /// <param name="RentalShptHeader">VAR Record "TWE Rental Shipment Header".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure RentalShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var RentalShptHeader: Record "TWE Rental Shipment Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalShptBillTo(AddrArray, ShipToAddr, RentalShptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
          AddrArray, RentalShptHeader."Bill-to Name", RentalShptHeader."Bill-to Name 2", RentalShptHeader."Bill-to Contact", RentalShptHeader."Bill-to Address", RentalShptHeader."Bill-to Address 2",
          RentalShptHeader."Bill-to City", RentalShptHeader."Bill-to Post Code", RentalShptHeader."Bill-to County", RentalShptHeader."Bill-to Country/Region Code");
        if RentalShptHeader."Bill-to Customer No." <> RentalShptHeader."Rented-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if ShipToAddr[i] <> AddrArray[i] then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// RentalShptShipTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalShptHeader">VAR Record "TWE Rental Shipment Header".</param>
    procedure RentalShptShipTo(var AddrArray: array[8] of Text[100]; var RentalShptHeader: Record "TWE Rental Shipment Header")
    var
        Handled: Boolean;
    begin
        OnBeforeRentalShptShipTo(AddrArray, RentalShptHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
          AddrArray, RentalShptHeader."Ship-to Name", RentalShptHeader."Ship-to Name 2", RentalShptHeader."Ship-to Contact", RentalShptHeader."Ship-to Address", RentalShptHeader."Ship-to Address 2",
          RentalShptHeader."Ship-to City", RentalShptHeader."Ship-to Post Code", RentalShptHeader."Ship-to County", RentalShptHeader."Ship-to Country/Region Code");
    end;

    /// <summary>
    /// RentalInvSellTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalInvHeader">VAR Record "TWE Rental Invoice Header".</param>
    procedure RentalInvSellTo(var AddrArray: array[8] of Text[100]; var RentalInvHeader: Record "TWE Rental Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalInvSellTo(AddrArray, RentalInvHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalInvHeader."Rented-to Customer Name", RentalInvHeader."Rented-to Customer Name 2", RentalInvHeader."Rented-to Contact", RentalInvHeader."Rented-to Address", RentalInvHeader."Rented-to Address 2",
          RentalInvHeader."Rented-to City", RentalInvHeader."Rented-to Post Code", RentalInvHeader."Rented-to County", RentalInvHeader."Rented-to Country/Region Code");
    end;

    /// <summary>
    /// RentalInvBillTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalInvHeader">VAR Record "TWE Rental Invoice Header".</param>
    procedure RentalInvBillTo(var AddrArray: array[8] of Text[100]; var RentalInvHeader: Record "TWE Rental Invoice Header")
    var
        Handled: Boolean;
    begin
        OnBeforeRentalInvBillTo(AddrArray, RentalInvHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
          AddrArray, RentalInvHeader."Bill-to Name", RentalInvHeader."Bill-to Name 2", RentalInvHeader."Bill-to Contact", RentalInvHeader."Bill-to Address", RentalInvHeader."Bill-to Address 2",
          RentalInvHeader."Bill-to City", RentalInvHeader."Bill-to Post Code", RentalInvHeader."Bill-to County", RentalInvHeader."Bill-to Country/Region Code");
    end;

    /// <summary>
    /// RentalInvShipTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="CustAddr">array[8] of Text[100].</param>
    /// <param name="RentalInvHeader">VAR Record "TWE Rental Invoice Header".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure RentalInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var RentalInvHeader: Record "TWE Rental Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeRentalInvShipTo(AddrArray, RentalInvHeader, IsHandled, Result, CustAddr);
        if IsHandled then
            exit(Result);

        FormatAddr(
          AddrArray, RentalInvHeader."Ship-to Name", RentalInvHeader."Ship-to Name 2", RentalInvHeader."Ship-to Contact", RentalInvHeader."Ship-to Address", RentalInvHeader."Ship-to Address 2",
          RentalInvHeader."Ship-to City", RentalInvHeader."Ship-to Post Code", RentalInvHeader."Ship-to County", RentalInvHeader."Ship-to Country/Region Code");
        if RentalInvHeader."Rented-to Customer No." <> RentalInvHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// RentalCrMemoSellTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalCrMemoHeader">VAR Record "TWE Rental Cr.Memo Header".</param>
    procedure RentalCrMemoSellTo(var AddrArray: array[8] of Text[100]; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalCrMemoSellTo(AddrArray, RentalCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalCrMemoHeader."Rented-to Customer Name", RentalCrMemoHeader."Rented-to Customer Name 2", RentalCrMemoHeader."Rented-to Contact", RentalCrMemoHeader."Rented-to Address", RentalCrMemoHeader."Rented-to Address 2",
           RentalCrMemoHeader."Rented-to City", RentalCrMemoHeader."Rented-to Post Code", RentalCrMemoHeader."Rented-to County", RentalCrMemoHeader."Rented-to Country/Region Code");
    end;

    /// <summary>
    /// RentalCrMemoBillTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalCrMemoHeader">VAR Record "TWE Rental Cr.Memo Header".</param>
    procedure RentalCrMemoBillTo(var AddrArray: array[8] of Text[100]; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalCrMemoBillTo(AddrArray, RentalCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalCrMemoHeader."Bill-to Name", RentalCrMemoHeader."Bill-to Name 2", RentalCrMemoHeader."Bill-to Contact", RentalCrMemoHeader."Bill-to Address", RentalCrMemoHeader."Bill-to Address 2",
          RentalCrMemoHeader."Bill-to City", RentalCrMemoHeader."Bill-to Post Code", RentalCrMemoHeader."Bill-to County", RentalCrMemoHeader."Bill-to Country/Region Code");
    end;

    /// <summary>
    /// RentalCrMemoShipTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="CustAddr">array[8] of Text[100].</param>
    /// <param name="RentalCrMemoHeader">VAR Record "TWE Rental Cr.Memo Header".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure RentalCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalCrMemoShipTo(AddrArray, CustAddr, RentalCrMemoHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
          AddrArray, RentalCrMemoHeader."Ship-to Name", RentalCrMemoHeader."Ship-to Name 2", RentalCrMemoHeader."Ship-to Contact", RentalCrMemoHeader."Ship-to Address", RentalCrMemoHeader."Ship-to Address 2",
          RentalCrMemoHeader."Ship-to City", RentalCrMemoHeader."Ship-to Post Code", RentalCrMemoHeader."Ship-to County", RentalCrMemoHeader."Ship-to Country/Region Code");
        if RentalCrMemoHeader."Rented-to Customer No." <> RentalCrMemoHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// RentalReturnShipSellTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalReturnShipHeader">VAR Record "TWE Rental Return Ship. Header".</param>
    procedure RentalReturnShipSellTo(var AddrArray: array[8] of Text[100]; var RentalReturnShipHeader: Record "TWE Rental Return Ship. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalReturnShipSellTo(AddrArray, RentalReturnShipHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalReturnShipHeader."Rented-to Customer Name", RentalReturnShipHeader."Rented-to Customer Name 2", RentalReturnShipHeader."Rented-to Contact", RentalReturnShipHeader."Rented-to Address",
          RentalReturnShipHeader."Rented-to Address 2", RentalReturnShipHeader."Rented-to City", RentalReturnShipHeader."Rented-to Post Code", RentalReturnShipHeader."Rented-to County", RentalReturnShipHeader."Rented-to Country/Region Code");
    end;

    /// <summary>
    /// RentalReturnShipBillTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="ShipToAddr">array[8] of Text[100].</param>
    /// <param name="RentalReturnShipHeader">VAR Record "TWE Rental Return Ship. Header".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure RentalReturnShipBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var RentalReturnShipHeader: Record "TWE Rental Return Ship. Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalReturnShipBillTo(AddrArray, ShipToAddr, RentalReturnShipHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
          AddrArray, RentalReturnShipHeader."Bill-to Name", RentalReturnShipHeader."Bill-to Name 2", RentalReturnShipHeader."Bill-to Contact", RentalReturnShipHeader."Bill-to Address", RentalReturnShipHeader."Bill-to Address 2",
          RentalReturnShipHeader."Bill-to City", RentalReturnShipHeader."Bill-to Post Code", RentalReturnShipHeader."Bill-to County", RentalReturnShipHeader."Bill-to Country/Region Code");
        if RentalReturnShipHeader."Bill-to Customer No." <> RentalReturnShipHeader."Rented-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> ShipToAddr[i] then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// RentalReturnShipmentShipTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalReturnShipHeader">VAR Record "TWE Rental Return Ship. Header".</param>
    procedure RentalReturnShipmentShipTo(var AddrArray: array[8] of Text[100]; var RentalReturnShipHeader: Record "TWE Rental Return Ship. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalReturnShipmentShipTo(AddrArray, RentalReturnShipHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalReturnShipHeader."Ship-to Name", RentalReturnShipHeader."Ship-to Name 2", RentalReturnShipHeader."Ship-to Contact", RentalReturnShipHeader."Ship-to Address", RentalReturnShipHeader."Ship-to Address 2",
          RentalReturnShipHeader."Ship-to City", RentalReturnShipHeader."Ship-to Post Code", RentalReturnShipHeader."Ship-to County", RentalReturnShipHeader."Ship-to Country/Region Code");
    end;

    /// <summary>
    /// RentalHeaderArchBillTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="RentalHeaderArch">VAR Record "TWE Rental Header Archive".</param>
    procedure RentalHeaderArchBillTo(var AddrArray: array[8] of Text[100]; var RentalHeaderArch: Record "TWE Rental Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalHeaderArchBillTo(AddrArray, RentalHeaderArch, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, RentalHeaderArch."Bill-to Name", RentalHeaderArch."Bill-to Name 2", RentalHeaderArch."Bill-to Contact", RentalHeaderArch."Bill-to Address", RentalHeaderArch."Bill-to Address 2",
          RentalHeaderArch."Bill-to City", RentalHeaderArch."Bill-to Post Code", RentalHeaderArch."Bill-to County", RentalHeaderArch."Bill-to Country/Region Code");
    end;

    /// <summary>
    /// RentalHeaderArchShipTo.
    /// </summary>
    /// <param name="AddrArray">VAR array[8] of Text[100].</param>
    /// <param name="CustAddr">array[8] of Text[100].</param>
    /// <param name="RentalHeaderArch">VAR Record "TWE Rental Header Archive".</param>
    /// <returns>Return variable Result of type Boolean.</returns>
    procedure RentalHeaderArchShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var RentalHeaderArch: Record "TWE Rental Header Archive") Result: Boolean
    var
        CountryRegion: Record "Country/Region";
        SellToCountry: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRentalHeaderArchShipTo(AddrArray, CustAddr, RentalHeaderArch, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
          AddrArray, RentalHeaderArch."Ship-to Name", RentalHeaderArch."Ship-to Name 2", RentalHeaderArch."Ship-to Contact", RentalHeaderArch."Ship-to Address", RentalHeaderArch."Ship-to Address 2",
          RentalHeaderArch."Ship-to City", RentalHeaderArch."Ship-to Post Code", RentalHeaderArch."Ship-to County", RentalHeaderArch."Ship-to Country/Region Code");
        if RentalHeaderArch."Rented-to Customer No." <> RentalHeaderArch."Bill-to Customer No." then
            exit(true);
        if CountryRegion.Get(RentalHeaderArch."Rented-to Country/Region Code") then
            SellToCountry := CountryRegion.Name;
        for i := 1 to ArrayLen(AddrArray) do
            if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                exit(true);

        exit(false);
    end;

    local procedure SetCountyTextForDACH(var CountyText: Text[50]; County: Text[50]; CountryCode: Code[10])
    begin
        CountyText := County;
        if CountryCode in ['', 'AT', 'CH', 'DE'] then
            CountyText := '';
    end;


    /// <summary>
    /// UseCounty.
    /// </summary>
    /// <param name="CountryCode">Code[10].</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure UseCounty(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
    begin
        if CountryCode = '' then begin
            GetGLSetup();
            case true of
                GLSetup."Local Address Format" = GLSetup."Local Address Format"::"City+County+Post Code":
                    exit(true);
                CustomAddressFormat.UseCounty(''):
                    exit(true);
            end;
        end;

        if CountryRegion.Get(CountryCode) then
            case true of
                CountryRegion."Address Format" = CountryRegion."Address Format"::"City+County+Post Code":
                    exit(true);
                CustomAddressFormat.UseCounty(CountryCode):
                    exit(true);
            end;

        exit(false);
    end;

    local procedure SetLineNos(Country: Record "Country/Region"; var NameLineNo: Integer; var Name2LineNo: Integer; var AddrLineNo: Integer; var Addr2LineNo: Integer; var ContLineNo: Integer; var PostCodeCityLineNo: Integer; var CountyLineNo: Integer; var CountryLineNo: Integer)
    begin
        case Country."Contact Address Format" of
            Country."Contact Address Format"::First:
                begin
                    NameLineNo := 2;
                    Name2LineNo := 3;
                    ContLineNo := 1;
                    AddrLineNo := 4;
                    Addr2LineNo := 5;
                    PostCodeCityLineNo := 6;
                    CountyLineNo := 7;
                    CountryLineNo := 8;
                end;
            Country."Contact Address Format"::"After Company Name":
                begin
                    NameLineNo := 1;
                    Name2LineNo := 2;
                    ContLineNo := 3;
                    AddrLineNo := 4;
                    Addr2LineNo := 5;
                    PostCodeCityLineNo := 6;
                    CountyLineNo := 7;
                    CountryLineNo := 8;
                end;
            Country."Contact Address Format"::Last:
                begin
                    NameLineNo := 1;
                    Name2LineNo := 2;
                    ContLineNo := 8;
                    AddrLineNo := 3;
                    Addr2LineNo := 4;
                    PostCodeCityLineNo := 5;
                    CountyLineNo := 6;
                    CountryLineNo := 7;
                end;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;
        GLSetupRead := true;
        GLSetup.Get();
    end;

    /// <summary>
    /// SetLanguageCode.
    /// </summary>
    /// <param name="NewLanguageCode">Code[10].</param>
    procedure SetLanguageCode(NewLanguageCode: Code[10])
    begin
        LanguageCode := NewLanguageCode;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupModify()
    begin
        GLSetupRead := false;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompany(var AddrArray: array[8] of Text[100]; var CompanyInfo: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatAddress(var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGeneratePostCodeCity(var Country: Record "Country/Region"; var PostCode: Code[20]; var PostCodeCityText: Text[100]; var City: Text[50]; var CountyText: Text[50]; var County: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomer(var AddrArray: array[8] of Text[100]; var Cust: Record Customer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatAddress(Country: Record "Country/Region"; var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; NameLineNo: Integer; Name2LineNo: Integer; AddrLineNo: Integer; Addr2LineNo: Integer; ContLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; CountryLineNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatAddr(var Country: Record "Country/Region"; CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatPostCodeCity(var Country: Record "Country/Region"; CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderArchBillTo(var AddrArray: array[8] of Text[100]; var RentalHeaderArch: Record "TWE Rental Header Archive"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderArchShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var RentalHeaderArch: Record "TWE Rental Header Archive"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderBillTo(var AddrArray: array[8] of Text[100]; var RentalHeader: Record "TWE Rental Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderSellTo(var AddrArray: array[8] of Text[100]; var RentalHeader: Record "TWE Rental Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalHeaderShipTo(var AddrArray: array[8] of Text[100]; var CustAddr: array[8] of Text[100]; var RentalHeader: Record "TWE Rental Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalInvBillTo(var AddrArray: array[8] of Text[100]; var RentalInvHeader: Record "TWE Rental Invoice Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalInvShipTo(var AddrArray: array[8] of Text[100]; var RentalInvHeader: Record "TWE Rental Invoice Header"; var Handled: Boolean; var Result: Boolean; var CustAddr: array[8] of Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalCrMemoBillTo(var AddrArray: array[8] of Text[100]; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalCrMemoSellTo(var AddrArray: array[8] of Text[100]; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalCrMemoShipTo(var AddrArray: array[8] of Text[100]; var CustAddr: array[8] of Text[100]; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalShptShipTo(var AddrArray: array[8] of Text[100]; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalShptBillTo(var AddrArray: array[8] of Text[100]; var ShipToAddr: array[8] of Text[100]; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalShptSellTo(var AddrArray: array[8] of Text[100]; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalReturnShipSellTo(var AddrArray: array[8] of Text[100]; var RentalReturnShipHeader: Record "TWE Rental Return Ship. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalReturnShipmentShipTo(var AddrArray: array[8] of Text[100]; var RentalReturnShipHeader: Record "TWE Rental Return Ship. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalReturnShipBillTo(var AddrArray: array[8] of Text[100]; var ShipToAddr: array[8] of Text[100]; var RentalReturnShipHeader: Record "TWE Rental Return Ship. Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRentalInvSellTo(var AddrArray: array[8] of Text[100]; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAddrArrayForPostCodeCity(var AddrArray: array[8] of Text[100]; Contact: Text[100]; ContLineNo: Integer; Country: Record "Country/Region"; CountryLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; City: Text[50]; PostCode: Code[20]; County: Text[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatAddrOnAfterGetCountry(var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; LanguageCode: Code[10]; var IsHandled: Boolean; var Country: Record "Country/Region")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRespCenter(var AddrArray: array[8] of Text[100]; var RespCenter: Record "Responsibility Center"; var IsHandled: Boolean)
    begin
    end;
}

