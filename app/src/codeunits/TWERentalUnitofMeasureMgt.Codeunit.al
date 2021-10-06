/// <summary>
/// Codeunit TWE Rental Unit of Measure Mgt (ID 50061).
/// </summary>
codeunit 50061 "TWE Rental Unit of Measure Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        RentalItemUnitOfMeasure: Record "TWE Rental Item Unit of Meas.";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        Text001Lbl: Label 'Quantity per unit of measure must be defined.';

    /// <summary>
    /// GetQtyPerUnitOfMeasure.
    /// </summary>
    /// <param name="MainRentalItem">Record "TWE Main Rental Item".</param>
    /// <param name="UnitOfMeasureCode">Code[10].</param>
    /// <returns>Return variable QtyPerUnitOfMeasure of type Decimal.</returns>
    procedure GetQtyPerUnitOfMeasure(MainRentalItem: Record "TWE Main Rental Item"; UnitOfMeasureCode: Code[10]) QtyPerUnitOfMeasure: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetQtyPerUnitOfMeasure(MainRentalItem, UnitOfMeasureCode, QtyPerUnitOfMeasure, IsHandled);
        if IsHandled then
            exit(QtyPerUnitOfMeasure);

        MainRentalItem.TestField("No.");
        if UnitOfMeasureCode in [MainRentalItem."Base Unit of Measure", ''] then
            exit(1);
        if (MainRentalItem."No." <> RentalItemUnitOfMeasure."Item No.") or
           (UnitOfMeasureCode <> RentalItemUnitOfMeasure.Code)
        then
            RentalItemUnitOfMeasure.Get(MainRentalItem."No.", UnitOfMeasureCode);
        RentalItemUnitOfMeasure.TestField("Qty. per Unit of Measure");
        exit(RentalItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    /// <summary>
    /// GetResQtyPerUnitOfMeasure.
    /// </summary>
    /// <param name="Resource">Record Resource.</param>
    /// <param name="UnitOfMeasureCode">Code[10].</param>
    /// <returns>Return variable QtyPerUnitOfMeasure of type Decimal.</returns>
    procedure GetResQtyPerUnitOfMeasure(Resource: Record Resource; UnitOfMeasureCode: Code[10]) QtyPerUnitOfMeasure: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetResQtyPerUnitOfMeasure(Resource, UnitOfMeasureCode, QtyPerUnitOfMeasure, IsHandled);
        if IsHandled then
            exit(QtyPerUnitOfMeasure);

        Resource.TestField("No.");
        if UnitOfMeasureCode in [Resource."Base Unit of Measure", ''] then
            exit(1);
        if (Resource."No." <> ResourceUnitOfMeasure."Resource No.") or
           (UnitOfMeasureCode <> ResourceUnitOfMeasure.Code)
        then
            ResourceUnitOfMeasure.Get(Resource."No.", UnitOfMeasureCode);
        ResourceUnitOfMeasure.TestField("Qty. per Unit of Measure");
        exit(ResourceUnitOfMeasure."Qty. per Unit of Measure");
    end;

    /// <summary>
    /// CalcBaseQty.
    /// </summary>
    /// <param name="Qty">Decimal.</param>
    /// <param name="QtyPerUOM">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcBaseQty(Qty: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        exit(CalcBaseQty('', '', '', Qty, QtyPerUOM));
    end;

    /// <summary>
    /// CalcBaseQty.
    /// </summary>
    /// <param name="MainRentalItemNo">Code[20].</param>
    /// <param name="VariantCode">Code[10].</param>
    /// <param name="UOMCode">Code[10].</param>
    /// <param name="QtyBase">Decimal.</param>
    /// <param name="QtyPerUOM">Decimal.</param>
    /// <returns>Return variable QtyRounded of type Decimal.</returns>
    procedure CalcBaseQty(MainRentalItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal) QtyRounded: Decimal
    begin
        QtyRounded := RoundQty(QtyBase * QtyPerUOM);

        OnAfterCalcBaseQtyPerUnitOfMeasure(MainRentalItemNo, VariantCode, UOMCode, QtyPerUOM, QtyBase, QtyRounded);
    end;

    /// <summary>
    /// CalcQtyFromBase.
    /// </summary>
    /// <param name="QtyBase">Decimal.</param>
    /// <param name="QtyPerUOM">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure CalcQtyFromBase(QtyBase: Decimal; QtyPerUOM: Decimal): Decimal
    begin
        exit(CalcQtyFromBase('', '', '', QtyBase, QtyPerUOM));
    end;

    /// <summary>
    /// CalcQtyFromBase.
    /// </summary>
    /// <param name="MainRentalItemNo">Code[20].</param>
    /// <param name="VariantCode">Code[10].</param>
    /// <param name="UOMCode">Code[10].</param>
    /// <param name="QtyBase">Decimal.</param>
    /// <param name="QtyPerUOM">Decimal.</param>
    /// <returns>Return variable QtyRounded of type Decimal.</returns>
    procedure CalcQtyFromBase(MainRentalItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal) QtyRounded: Decimal
    begin
        if QtyPerUOM = 0 then
            Error(Text001Lbl);

        QtyRounded := RoundQty(QtyBase / QtyPerUOM);

        OnAfterCalcQtyFromBasePerUnitOfMeasure(MainRentalItemNo, VariantCode, UOMCode, QtyPerUOM, QtyBase, QtyRounded);
    end;

    /// <summary>
    /// RoundQty.
    /// </summary>
    /// <param name="Qty">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure RoundQty(Qty: Decimal): Decimal
    begin
        exit(Round(Qty, QtyRndPrecision()));
    end;

    /// <summary>
    /// RoundToItemRndPrecision.
    /// </summary>
    /// <param name="Qty">Decimal.</param>
    /// <param name="ItemRndPrecision">Decimal.</param>
    /// <returns>Return value of type Decimal.</returns>
    procedure RoundToItemRndPrecision(Qty: Decimal; ItemRndPrecision: Decimal): Decimal
    begin
        exit(Round(RoundQty(Qty), ItemRndPrecision, '>'));
    end;

    /// <summary>
    /// QtyRndPrecision.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure QtyRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeQtyRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    /// <summary>
    /// CubageRndPrecision.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure CubageRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeCubageRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    /// <summary>
    /// TimeRndPrecision.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure TimeRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeTimeRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    /// <summary>
    /// WeightRndPrecision.
    /// </summary>
    /// <returns>Return value of type Decimal.</returns>
    procedure WeightRndPrecision(): Decimal
    var
        RoundingPrecision: Decimal;
    begin
        OnBeforeWeightRndPrecision(RoundingPrecision);
        if RoundingPrecision = 0 then
            RoundingPrecision := 0.00001;
        exit(RoundingPrecision);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQtyPerUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; var QtyRounded: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyFromBasePerUnitOfMeasure(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; QtyBase: Decimal; QtyPerUOM: Decimal; var QtyRounded: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetQtyPerUnitOfMeasure(MainRentalItem: Record "TWE Main Rental Item"; UnitOfMeasureCode: Code[10]; var QtyPerUnitOfMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetResQtyPerUnitOfMeasure(Resource: Record Resource; ResUnitOfMeasureCode: Code[10]; var QtyPerUnitOfMeasure: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCubageRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTimeRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWeightRndPrecision(var RoundingPrecision: Decimal)
    begin
    end;
}

