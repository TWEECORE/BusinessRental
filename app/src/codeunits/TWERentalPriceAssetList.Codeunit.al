/// <summary>
/// Codeunit TWE Rental Price Asset List (ID 70704653).
/// </summary>
codeunit 50039 "TWE Rental Price Asset List"
{
    var
        TempPriceAsset: Record "TWE Rental Price Asset" temporary;
        CurrentLevel: Integer;

    /// <summary>
    /// Init.
    /// </summary>
    procedure Init()
    begin
        CurrentLevel := 0;
        TempPriceAsset.Reset();
        TempPriceAsset.DeleteAll();
    end;

    /// <summary>
    /// Count.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    procedure Count(): Integer;
    begin
        TempPriceAsset.Reset();
        exit(TempPriceAsset.Count());
    end;

    /// <summary>
    /// GetMinMaxLevel.
    /// </summary>
    /// <param name="Level">VAR array[2] of Integer.</param>
    procedure GetMinMaxLevel(var Level: array[2] of Integer)
    var
        TempLocalPriceAsset: Record "TWE Rental Price Asset" temporary;
    begin
        TempLocalPriceAsset.Copy(TempPriceAsset, true);
        TempLocalPriceAsset.Reset();
        if TempLocalPriceAsset.IsEmpty then begin
            Level[2] := Level[1] - 1;
            exit;
        end;

        TempLocalPriceAsset.SetCurrentKey(Level);
        TempLocalPriceAsset.FindFirst();
        Level[1] := TempLocalPriceAsset.Level;
        TempLocalPriceAsset.FindLast();
        Level[2] := TempLocalPriceAsset.Level;
    end;

    /// <summary>
    /// IncLevel.
    /// </summary>
    procedure IncLevel()
    begin
        CurrentLevel += 1;
    end;

    /// <summary>
    /// SetLevel.
    /// </summary>
    /// <param name="Level">Integer.</param>
    procedure SetLevel(Level: Integer)
    begin
        CurrentLevel := Level;
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="AssetType">Enum "Price Asset Type".</param>
    /// <param name="AssetNo">Code[20].</param>
    procedure Add(AssetType: Enum "TWE Rental Price Asset Type"; AssetNo: Code[20])
    begin
        if AssetNo = '' then
            exit;
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        TempPriceAsset.Validate("Asset No.", AssetNo);
        if TempPriceAsset."Asset No." = '' then
            exit;
        AppendRelatedAssets();
        InsertAsset();
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="AssetType">Enum "Price Asset Type".</param>
    /// <param name="AssetId">Guid.</param>
    procedure Add(AssetType: Enum "TWE Rental Price Asset Type"; AssetId: Guid)
    begin
        if IsNullGuid(AssetId) then
            exit;
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        TempPriceAsset.Validate("Asset ID", AssetId);
        AppendRelatedAssets();
        InsertAsset();
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="AssetType">Enum "Price Asset Type".</param>
    procedure Add(AssetType: Enum "TWE Rental Price Asset Type")
    begin
        TempPriceAsset.NewEntry(AssetType, CurrentLevel);
        AppendRelatedAssets();
        InsertAsset();
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="PriceAsset">Record "TWE Rental Price Asset".</param>
    procedure Add(PriceAsset: Record "TWE Rental Price Asset")
    begin
        PriceAsset.Level := CurrentLevel;
        TempPriceAsset.TransferFields(PriceAsset);
        AppendRelatedAssets();
        InsertAsset();
    end;

    /// <summary>
    /// Add.
    /// </summary>
    /// <param name="PriceCalculationBuffer">Record "Price Calculation Buffer".</param>
    procedure Add(PriceCalculationBuffer: Record "TWE Rental Price Calc. Buffer")
    begin
        TempPriceAsset.Level := CurrentLevel;
        TempPriceAsset.FillFromBuffer(PriceCalculationBuffer);
        AppendRelatedAssets();
        InsertAsset();
    end;

    local procedure AppendRelatedAssets()
    var
        PriceAssetList: Codeunit "TWE Rental Price Asset List";
    begin
        TempPriceAsset.PutRelatedAssetsToList(PriceAssetList);
        Append(PriceAssetList);
    end;

    local procedure InsertAsset()
    begin
        OnAddOnBeforeInsert(TempPriceAsset);
        TempPriceAsset.Insert(true);
    end;

    /// <summary>
    /// GetValue.
    /// </summary>
    /// <param name="AssetType">Enum "Price Asset Type".</param>
    /// <returns>Return variable Result of type Code[20].</returns>
    procedure GetValue(AssetType: Enum "TWE Rental Price Asset Type") Result: Code[20];
    var
        TempLocalPriceAsset: Record "TWE Rental Price Asset" temporary;
        PriceAssetInterface: Interface "TWE Rental Price Asset";
    begin
        TempLocalPriceAsset.Copy(TempPriceAsset, true);
        TempLocalPriceAsset.Reset();
        TempLocalPriceAsset.SetRange("Asset Type", AssetType);
        If TempLocalPriceAsset.FindFirst() then begin
            PriceAssetInterface := TempLocalPriceAsset."Asset Type";
            Result := TempLocalPriceAsset."Asset No.";
        end;
        OnAfterGetValue(AssetType, Result);
    end;

    /// <summary>
    /// Copy.
    /// </summary>
    /// <param name="FromPriceAssetList">VAR Codeunit "Price Asset List".</param>
    procedure Copy(var FromPriceAssetList: Codeunit "TWE Rental Price Asset List")
    begin
        Init();
        FromPriceAssetList.GetList(TempPriceAsset);
    end;

    /// <summary>
    /// Append.
    /// </summary>
    /// <param name="FromPriceAssetList">VAR Codeunit "Price Asset List".</param>
    procedure Append(var FromPriceAssetList: Codeunit "TWE Rental Price Asset List")
    var
        TempFromTempPriceAsset: Record "TWE Rental Price Asset" temporary;
        TempToTempPriceAsset: Record "TWE Rental Price Asset" temporary;
        Level: Array[2] of Integer;
        CurrLevel: Integer;
    begin
        TempToTempPriceAsset.Copy(TempPriceAsset, true);
        FromPriceAssetList.GetMinMaxLevel(Level);
        for CurrLevel := Level[2] downto Level[1] do
            if FromPriceAssetList.First(TempFromTempPriceAsset, CurrLevel) then
                repeat
                    TempToTempPriceAsset.TransferFields(TempFromTempPriceAsset, false);
                    TempToTempPriceAsset.Insert(true);
                until not FromPriceAssetList.Next(TempFromTempPriceAsset);
    end;

    /// <summary>
    /// GetList.
    /// </summary>
    /// <param name="ToTempPriceAsset">Temporary VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure GetList(var ToTempPriceAsset: Record "TWE Rental Price Asset" temporary): Boolean
    begin
        if ToTempPriceAsset.IsTemporary then
            ToTempPriceAsset.Copy(TempPriceAsset, true);
        exit(ToTempPriceAsset.FindSet())
    end;

    /// <summary>
    /// First.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <param name="AtLevel">Integer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure First(var PriceAsset: Record "TWE Rental Price Asset"; AtLevel: Integer): Boolean;
    begin
        TempPriceAsset.Reset();
        TempPriceAsset.SetCurrentKey(Level);
        TempPriceAsset.SetRange(Level, AtLevel);
        exit(GetRecordIfFound(TempPriceAsset.FindSet(), PriceAsset))
    end;

    /// <summary>
    /// Next.
    /// </summary>
    /// <param name="PriceAsset">VAR Record "TWE Rental Price Asset".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure Next(var PriceAsset: Record "TWE Rental Price Asset"): Boolean;
    begin
        exit(GetRecordIfFound(TempPriceAsset.Next() > 0, PriceAsset))
    end;

    local procedure GetRecordIfFound(Found: Boolean; var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    begin
        if Found then begin
            PriceAsset := TempPriceAsset;
            CurrentLevel := TempPriceAsset.Level;
        end else
            Clear(PriceAsset);
        exit(Found)
    end;

    /// <summary>
    /// Remove.
    /// </summary>
    /// <param name="AssetType">Enum "Price Asset Type".</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure Remove(AssetType: Enum "TWE Rental Price Asset Type"): Boolean;
    var
        PriceAsset: Record "TWE Rental Price Asset";
    begin
        PriceAsset.SetRange("Asset Type", AssetType);
        exit(Remove(PriceAsset));
    end;

    /// <summary>
    /// RemoveAtLevel.
    /// </summary>
    /// <param name="AssetType">Enum "Price Asset Type".</param>
    /// <param name="Level">Integer.</param>
    /// <returns>Return value of type Boolean.</returns>
    procedure RemoveAtLevel(AssetType: Enum "TWE Rental Price Asset Type"; Level: Integer): Boolean;
    var
        PriceAsset: Record "TWE Rental Price Asset";
    begin
        PriceAsset.SetRange(Level, Level);
        PriceAsset.SetRange("Asset Type", AssetType);
        exit(Remove(PriceAsset));
    end;

    local procedure Remove(var PriceAsset: Record "TWE Rental Price Asset"): Boolean
    var
        TempLocalPriceAsset: Record "TWE Rental Price Asset" temporary;
    begin
        TempLocalPriceAsset.Copy(TempPriceAsset, true);
        TempLocalPriceAsset.CopyFilters(PriceAsset);
        if not TempLocalPriceAsset.IsEmpty() then begin
            TempLocalPriceAsset.DeleteAll();
            exit(true);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAddOnBeforeInsert(var PriceAsset: Record "TWE Rental Price Asset")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetValue(AssetType: Enum "TWE Rental Price Asset Type"; var Result: Code[20])
    begin
    end;
}
