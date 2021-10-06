codeunit 50032 "TWE Rental-Post Events"
{
    [IntegrationEvent(false, false)]
    procedure OnBeforePostLines(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnBeforePostRentalDoc(var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostCommitRentalDoc(var RentalHeader: Record "TWE Rental Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; var ModifyHeader: Boolean; var CommitIsSuppressed: Boolean; var TempRentalLineGlobal: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCalcInvoice(var TempRentalLine: Record "TWE Rental Line" temporary; var NewInvoice: Boolean; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCheckRentalDoc(var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCheckAndUpdate(var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCheckTrackingAndWarehouseForReceive(var RentalHeader: Record "TWE Rental Header"; var Receive: Boolean; CommitIsSuppressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCheckTrackingAndWarehouseForShip(var RentalHeader: Record "TWE Rental Header"; var Ship: Boolean; CommitIsSuppressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterDeleteAfterPosting(RentalHeader: Record "TWE Rental Header"; RentalInvoiceHeader: Record "TWE Rental Invoice Header"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetGLSetup(var GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetLineDataFromOrder(var RentalLine: Record "TWE Rental Line"; RentalOrderLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetRentalAccount(RentalLine: Record "TWE Rental Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterGetRentalSetup(var SalesSetup: Record "TWE Rental Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterFillInvoicePostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; RentalLine: Record "TWE Rental Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInvoicePostingBufferAssignAmounts(RentalLine: Record "TWE Rental Line"; var TotalAmount: Decimal; var TotalAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInvoicePostingBufferSetAmounts(var InvoicePostBuffer: Record "Invoice Post. Buffer"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterIncrAmount(var TotalRentalLine: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInitAssocItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInvoiceRoundingAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TotalRentalLine: Record "TWE Rental Line"; UseTempData: Boolean; InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInsertDropOrderPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInsertedPrepmtVATBaseToDeduct(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; PrepmtLineNo: Integer; TotalPrepmtAmtToDeduct: Decimal; var TempPrepmtDeductLCYRentalLine: Record "TWE Rental Line" temporary; var PrepmtVATBaseToDeduct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInsertPostedHeaders(var RentalHeader: Record "TWE Rental Header"; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHdr: Record "TWE Rental Cr.Memo Header"; var ReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostRentalDoc(var RentalHeader: Record "TWE Rental Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostRentalDocDropShipment(PurchRcptNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; var RentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; var RentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var RentalHeader: Record "TWE Rental Header"; GLEntryNo: Integer; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnAfterPostItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; var RentalItemJnlPostLine: Codeunit "TWE Rental Item Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostRentalLines(var RentalHeader: Record "TWE Rental Header"; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; WhseShip: Boolean; WhseReceive: Boolean; var RentalLinesProcessed: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostRentalLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; var RentalInvLine: Record "TWE Rental Invoice Line"; var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; var xRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostUpdateInvoiceLine(var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdatePostingNos(var RentalHeader: Record "TWE Rental Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCheckMandatoryFields(var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalInvHeaderInsert(var RentalInvHeader: Record "TWE Rental Invoice Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalInvLineInsert(var RentalInvLine: Record "TWE Rental Invoice Line"; RentalInvHeader: Record "TWE Rental Invoice Header"; RentalLine: Record "TWE Rental Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; var RentalHeader: Record "TWE Rental Header"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalCrMemoHeaderInsert(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalCrMemoLineInsert(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalShptHeaderInsert(var RentalShipmentHeader: Record "TWE Rental Shipment Header"; RentalHeader: Record "TWE Rental Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalShptLineInsert(var RentalShipmentLine: Record "TWE Rental Shipment Line"; RentalLine: Record "TWE Rental Line"; ItemShptLedEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; RentalInvoiceHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchOrderLine: Record "Purchase Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalRtnShipHeaderInsert(var RentalRtnShipHeader: Record "TWE Rental Return Ship. Header"; RentalHeader: Record "TWE Rental Header"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRentalRtnShipLineInsert(var RentalRtnShipLine: Record "TWE Rental Return Ship. Line"; RentalRtnShipHeader: Record "TWE Rental Return Ship. Header"; RentalLine: Record "TWE Rental Line"; ItemShptLedEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterFinalizePosting(var RentalHeader: Record "TWE Rental Header"; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterFinalizePostingOnBeforeCommit(var RentalHeader: Record "TWE Rental Header"; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; WhseShip: Boolean; WhseReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterResetTempLines(var TempRentalLineLocal: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRestoreRentalHeader(var RentalHeader: Record "TWE Rental Header"; RentalHeaderCopy: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdateAfterPosting(var RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdateLastPostingNos(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdateRentalHeader(var CustLedgerEntry: Record "Cust. Ledger Entry"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; GenJnlLineDocType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdateSalesLineBeforePost(var RentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeArchiveUnpostedOrder(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCreatePostedWhseRcptHeader(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCreatePrepaymentLines(RentalHeader: Record "TWE Rental Header"; var TempPrepmtRentalLine: Record "TWE Rental Line" temporary; CompleteFunctionality: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeBlanketOrderSalesLineModify(var BlanketOrderRentalLine: Record "TWE Rental Line"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCreatePostedWhseShptHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeFinalizePosting(var RentalHeader: Record "TWE Rental Header"; var TempRentalLineGlobal: Record "TWE Rental Line" temporary; var EverythingInvoiced: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInitAssocItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertICGenJnlLine(var ICGenJournalLine: Record "Gen. Journal Line"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertPostedHeaders(var RentalHeader: Record "TWE Rental Header"; var TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWarehouseReceiptHeader: Record "Warehouse Receipt Header" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertReturnReceiptHeader(RentalHeader: Record "TWE Rental Header"; var ReturnReceiptHeader: Record "TWE Rental Return Ship. Header"; var Handled: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInvoiceRoundingAmount(RentalHeader: Record "TWE Rental Header"; TotalAmountIncludingVAT: Decimal; UseTempData: Boolean; var InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean; var TotalRentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeItemJnlPostLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeLockTables(var RentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeProcessAssocItemJnlLine(var RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesLineDeleteAll(var RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesShptHeaderInsert(var RentalShptHeader: Record "TWE Rental Shipment Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesShptLineInsert(var RentalShptLine: Record "TWE Rental Shipment Line"; RentalShptHeader: Record "TWE Rental Shipment Header"; RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; RentalHeader: Record "TWE Rental Header"; WhseShip: Boolean; WhseReceive: Boolean; ItemLedgShptEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesInvHeaderInsert(var RentalInvHeader: Record "TWE Rental Invoice Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesInvLineInsert(var RentalInvLine: Record "TWE Rental Invoice Line"; RentalInvHeader: Record "TWE Rental Invoice Header"; RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesCrMemoHeaderInsert(var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesCrMemoLineInsert(var RentalCrMemoLine: Record "TWE Rental Cr.Memo Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePurchRcptLineInsert(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchOrderLine: Record "Purchase Line"; DropShptPostBuffer: Record "Drop Shpt. Post. Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeRentalRtnShipHeaderInsert(var RentalRtnShipHeader: Record "TWE Rental Return Ship. Header"; RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeRentalRtnShipLineInsert(var RentalRtnShipLine: Record "TWE Rental Return Ship. Line"; RentalRtnShipHeader: Record "TWE Rental Return Ship. Header"; RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; var RentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeRunPostCustomerEntry(var RentalHeader: Record "TWE Rental Header"; var TotalRentalLine2: Record "TWE Rental Line"; var TotalRentalLineLCY2: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                                                                                                                                                                ExtDocNo: Code[35];
                                                                                                                                                                                                                                                SourceCode: Code[10]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; RentalHeader: Record "TWE Rental Header"; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostInvoicePostBuffer(RentalHeader: Record "TWE Rental Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostAssocItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var PurchaseLine: Record "Purchase Line"; CommitIsSuppressed: Boolean; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnBeforePostItemJnlLine(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var QtyToBeShipped: Decimal; var QtyToBeShippedBase: Decimal; var QtyToBeInvoiced: Decimal; var QtyToBeInvoicedBase: Decimal; var ItemLedgShptEntryNo: Integer; var ItemChargeNo: Code[20]; var TrackingSpecification: Record "Tracking Specification"; var IsATO: Boolean; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostItemChargePerOrder(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var RentalItemJnlLine2: Record "TWE Rental Item Journal Line"; var ItemChargeRentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdatePostingNos(var RentalHeader: Record "TWE Rental Header"; var NoSeriesMgt: Codeunit NoSeriesManagement; CommitIsSuppressed: Boolean; var ModifyHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostItemJnlLineBeforePost(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostItemJnlLineWhseLine(RentalLine: Record "TWE Rental Line"; ItemLedgEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostItemTrackingReturnRcpt(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalShipmentLine: Record "TWE Rental Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ReturnReceiptLine: Record "Return Receipt Line"; RentalLine: Record "TWE Rental Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostItemTrackingForShipment(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalShipmentLine: Record "TWE Rental Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; RentalLine: Record "TWE Rental Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostItemLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostItemCharge(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; TempItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterTestSalesLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostUpdateOrderLineModifyTempLine(RentalLine: Record "TWE Rental Line"; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostGLAndCustomer(var RentalHeader: Record "TWE Rental Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; TotalRentalLine: Record "TWE Rental Line"; TotalRentalLineLCY: Record "TWE Rental Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostResJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; JobTaskRentalLine: Record "TWE Rental Line"; ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReverseAmount(var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterDivideAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRoundAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; SalesLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdatePrepmtSalesLineWithRounding(var PrepmtRentalLine: Record "TWE Rental Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdateWhseDocuments(RentalHeader: Record "TWE Rental Header"; WhseShip: Boolean; WhseReceive: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseRcptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterUpdateAssosOrderPostingNos(RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary; var DropShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReleaseSalesDoc(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterValidatePostingAndDocumentDate(var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcLineDiscountPosting(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckCustBlockage(RentalHeader: Record "TWE Rental Header"; CustCode: Code[20]; var ExecuteDocCheck: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckTotalInvoiceAmount(RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckWarehouse(var TempItemRentalLine: Record "TWE Rental Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeClearRemAmtIfNotItemJnlRollRndg(RentalLine: Record "TWE Rental Line"; ItemJnlRollRndg: Boolean; var RemAmt: Decimal; var RemDiscAmt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeDivideAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; QtyType: Option General,Invoicing,Shipping; var SalesLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInvoicePostingBufferSetAmounts(RentalLine: Record "TWE Rental Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeRoundAmount(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; RentalLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostATO(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempPostedATOLink: Record "Posted Assemble-to-Order Link" temporary; var AsmPost: Codeunit "Assembly-Post"; var RentalItemJnlPostLine: Codeunit "TWE Rental Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line"; HideProgressWindow: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostDropOrderShipment(var RentalHeader: Record "TWE Rental Header"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostGLAndCustomer(var RentalHeader: Record "TWE Rental Header"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; var CustLedgerEntry: Record "Cust. Ledger Entry"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostItemCharge(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; TempItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostItemTrackingCheckShipment(RentalLine: Record "TWE Rental Line"; RemQtyToBeInvoiced: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostItemTrackingReturnRcpt(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalShipmentLine: Record "TWE Rental Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ReturnReceiptLine: Record "Return Receipt Line"; RentalLine: Record "TWE Rental Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostItemTrackingForShipment(var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalShipmentLine: Record "TWE Rental Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecificationExists: Boolean; RentalLine: Record "TWE Rental Line"; QtyToBeInvoiced: Decimal; QtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostResJnlLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var JobTaskRentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostUpdateOrderLine(RentalHeader: Record "TWE Rental Header"; var TempRentalLineGlobal: Record "TWE Rental Line" temporary; CommitIsSuppressed: Boolean; var RentalSetup: Record "TWE Rental Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostUpdateOrderLineModifyTempLine(var TempRentalLine: Record "TWE Rental Line" temporary; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostWhseRcptLineFromShipmentLine(var WhseRcptLine: Record "Warehouse Receipt Line"; RentalShptLine: Record "TWE Rental Shipment Line"; var RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeValidatePostingAndDocumentDate(var RentalHeader: Record "TWE Rental Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateInvoicedQtyOnShipmentLine(var RentalShipmentLine: Record "TWE Rental Shipment Line"; RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; RentalInvoiceHeader: Record "TWE Rental Invoice Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSendICDocument(var RentalHeader: Record "TWE Rental Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestRentalLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestSalesLineFixedAsset(RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestSalesLineItemCharge(RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestSalesLineJob(RentalLine: Record "TWE Rental Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestSalesLineOthers(RentalLine: Record "TWE Rental Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTestStatusRelease(RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; RentalLine: Record "TWE Rental Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTempPrepmtSalesLineInsert(var TempPrepmtRentalLine: Record "TWE Rental Line" temporary; var TempRentalLine: Record "TWE Rental Line" temporary; RentalHeader: Record "TWE Rental Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeTempPrepmtSalesLineModify(var TempPrepmtRentalLine: Record "TWE Rental Line" temporary; var TempRentalLine: Record "TWE Rental Line" temporary; RentalHeader: Record "TWE Rental Header"; CompleteFunctionality: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeReleaseSalesDoc(var RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateAssocLines(var RentalOrderLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateHandledICInboxTransaction(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdatePostingNo(var RentalHeader: Record "TWE Rental Header"; PreviewMode: Boolean; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdatePrepmtSalesLineWithRounding(var PrepmtRentalLine: Record "TWE Rental Line"; TotalRoundingAmount: array[2] of Decimal; TotalPrepmtAmount: array[2] of Decimal; FinalInvoice: Boolean; PricesInclVATRoundingAmount: array[2] of Decimal; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateRentalHeader(var CustLedgerEntry: Record "Cust. Ledger Entry"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; GenJnlLineDocType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateSalesLineBeforePost(var RentalLine: Record "TWE Rental Line"; var RentalHeader: Record "TWE Rental Header"; WhseShip: Boolean; WhseReceive: Boolean; RoundingLineInserted: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateShippingNo(var RentalHeader: Record "TWE Rental Header"; WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean; PreviewMode: Boolean; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeWhseHandlingRequired(RentalLine: Record "TWE Rental Line"; var Required: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnInvoiceRentalShptLine(RentalShipmentLine: Record "TWE Rental Shipment Line"; InvoiceNo: Code[20]; InvoiceLineNo: Integer; QtyToInvoice: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnArchivePurchaseOrdersOnBeforePurchOrderLineModify(var PurchOrderLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeDeleteAfterPosting(var RentalHeader: Record "TWE Rental Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var SkipDelete: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFillInvoicePostingBufferOnBeforeDeferrals(var RentalLine: Record "TWE Rental Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeGetCountryCode(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var CountryRegionCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInitPostATO(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var AsmPost: Codeunit "Assembly-Post"; HideProgressWindow: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertRentalRtnShipLine(RentalLine: Record "TWE Rental Line"; RentalRtnShipLine: Record "TWE Rental Return Ship. Line"; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostATOAssocItemJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var PostedATOLink: Record "Posted Assemble-to-Order Link"; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; var ItemLedgShptEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostItemTrackingForShipmentCondition(RentalLine: Record "TWE Rental Line"; RentalShptLine: Record "TWE Rental Shipment Line"; var Condition: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostRentalLines(var RentalHeader: Record "TWE Rental Header"; var TempRentalLineGlobal: Record "TWE Rental Line" temporary; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeShouldPostWhseJnlLine(RentalLine: Record "TWE Rental Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostWhseShptLines(var WhseShptLine2: Record "Warehouse Shipment Line"; RentalShptLine2: Record "TWE Rental Shipment Line"; var RentalLine2: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCalcInvDiscountSetFilter(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCopyAndCheckItemChargeOnBeforeLoop(var TempRentalLine: Record "TWE Rental Line" temporary; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCopyToTempLinesOnAfterSetFilters(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnInsertPostedHeadersOnBeforeInsertInvoiceHeader(RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSumSalesLines2OnBeforeDivideAmount(var OldRentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSumSalesLines2SetFilter(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header"; InsertSalesLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnAfterTestUpdatedSalesLine(var RentalLine: Record "TWE Rental Line"; var EverythingInvoiced: Boolean; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostUpdateOrderLineOnBeforeInitOutstanding(var RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostUpdateOrderLineOnBeforeInitTempRentalLineQuantities(var RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostUpdateOrderLineOnBeforeUpdateInvoicedValues(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostUpdateOrderLineOnSetDefaultQtyBlank(var RentalHeader: Record "TWE Rental Header"; var TempRentalLine: Record "TWE Rental Line" temporary; RentalSetup: Record "TWE Rental Setup"; var SetDefaultQtyBlank: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckAndUpdateOnAfterCalcInvDiscount(RentalHeader: Record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckAndUpdateOnAfterSetPostingFlags(var RentalHeader: Record "TWE Rental Header"; var TempRentalLineGlobal: Record "TWE Rental Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckAndUpdateOnAfterSetSourceCode(RentalHeader: Record "TWE Rental Header"; SourceCodeSetup: Record "Source Code Setup"; var SrcCode: Code[10]);
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckAndUpdateOnBeforeCalcInvDiscount(var RentalHeader: Record "TWE Rental Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseReceive: Boolean; WhseShip: Boolean; var RefreshNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckAssosOrderLinesOnAfterSetFilters(var RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckTrackingAndWarehouseForShipOnBeforeCheck(var RentalHeader: Record "TWE Rental Header"; var TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWhseReceiptHeader: Record "Warehouse Receipt Header" temporary; var Ship: Boolean; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCheckTrackingAndWarehouseForReceiveOnBeforeCheck(var RentalHeader: Record "TWE Rental Header"; var TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary; var TempWhseReceiptHeader: Record "Warehouse Receipt Header" temporary; var Receive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFillInvoicePostingBufferOnBeforeSetAccount(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var SalesAccount: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFillInvoicePostingBufferOnAfterSetLineDiscAccount(var RentalLine: Record "TWE Rental Line"; var GenPostingSetup: Record "General Posting Setup"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFillInvoicePostingBufferOnBeforeSetInvDiscAccount(RentalLine: Record "TWE Rental Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFillInvoicePostingBufferOnBeforeSetLineDiscAccount(RentalLine: Record "TWE Rental Line"; GenPostingSetup: Record "General Posting Setup"; var LineDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnFinalizePostingOnBeforeCreateOutboxSalesTrans(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostAssocItemJnlLineOnBeforePost(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostATOOnBeforePostedATOLinkInsert(var PostedATOLink: Record "Posted Assemble-to-Order Link"; var AssemblyHeader: Record "Assembly Header"; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostBalancingEntryOnBeforeFindCustLedgEntry(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35]; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemJnlLineOnAfterCopyDocumentFields(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemJnlLineOnAfterPrepareItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; RentalLine: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemJnlLineOnAfterCopyItemCharge(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemJnlLineOnBeforePostItemJnlLineWhseLine(var RentalItemJnlLine: Record "TWE Rental Item Journal Line"; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var TempWhseTrackingSpecification: Record "Tracking Specification" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemJnlLineOnBeforeTransferReservToItemJnlLine(RentalLine: Record "TWE Rental Line"; RentalItemJnlLine: Record "TWE Rental Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargeOnBeforePostItemJnlLine(var SalesLineToPost: Record "TWE Rental Line"; var RentalLine: Record "TWE Rental Line"; QtyToAssign: Decimal; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargePerOrderOnAfterCopyToItemJnlLine(var RentalItemJournalLine: Record "TWE Rental Item Journal Line"; var RentalLine: Record "TWE Rental Line"; GeneralLedgerSetup: Record "General Ledger Setup"; QtyToInvoice: Decimal; var TempItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargePerOrderOnBeforeTestJobNo(RentalLine: Record "TWE Rental Line"; var SkipTestJobNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargePerShptOnBeforeTestJobNo(RentalShipmentLine: Record "TWE Rental Shipment Line"; var SkipTestJobNo: Boolean; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargePerRetRcptOnBeforeTestFieldJobNo(ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; var RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemTrackingForShipmentOnAfterSetFilters(var RentalShipmentLine: Record "TWE Rental Shipment Line"; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemTrackingForShipmentOnBeforeShipmentInvoiceErr(RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemTrackingForShipmentOnBeforeReturnReceiptInvoiceErr(RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnBeforeInsertCrMemoLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean; xRentalLine: Record "TWE Rental Line"; RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnBeforeInsertInvoiceLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean; xRentalLine: Record "TWE Rental Line"; RentalInvHeader: Record "TWE Rental Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnBeforeInsertReturnReceiptLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnBeforeInsertShipmentLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean; RentalLineACY: Record "TWE Rental Line"; DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnAfterCaseType(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocType: Integer; SrcCode: Code[10]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnAfterSetEverythingInvoiced(RentalLine: Record "TWE Rental Line"; var EverythingInvoiced: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnBeforeTestJobNo(RentalLine: Record "TWE Rental Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnAfterPostItemTrackingLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostSalesLineOnBeforePostItemTrackingLine(var RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; WhseShip: Boolean; WhseReceive: Boolean; InvtPickPutaway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostUpdateInvoiceLineOnBeforeInitQtyToInvoice(var RentalOrderLine: Record "TWE Rental Line"; var TempRentalLine: Record "TWE Rental Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRoundAmountOnBeforeIncrAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; SalesLineQty: Decimal; var TotalRentalLine: Record "TWE Rental Line"; var TotalRentalLineLCY: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRunOnBeforeFinalizePosting(var RentalHeader: Record "TWE Rental Header"; var RentalShipmentHeader: Record "TWE Rental Shipment Header"; var RentalInvoiceHeader: Record "TWE Rental Invoice Header"; var RentalCrMemoHeader: Record "TWE Rental Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetPostedDocumentRecordElseCase(RentalHeader: Record "TWE Rental Header"; var PostedSalesDocumentVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargeOnAfterPostItemJnlLine(RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostItemChargeLineOnBeforePostItemCharge(var TempItemChargeAssgntSales: record "Item Charge Assignment (Sales)" temporary; RentalHeader: Record "TWE Rental Header"; RentalLine: Record "TWE Rental Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnReleaseSalesDocumentOnBeforeSetStatus(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean; SavedStatus: Enum "Sales Document Status"; PreviewMode: Boolean; SuppressCommit: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRoundAmountOnAfterAssignSalesLines(var xRentalLine: Record "TWE Rental Line"; var RentalLineACY: Record "TWE Rental Line"; RentalHeader: Record "TWE Rental Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSaveInvoiceSpecificationOnAfterUpdateTempTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempInvoicingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendICDocumentOnBeforeSetICStatus(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendPostedDocumentRecordElseCase(RentalHeader: Record "TWE Rental Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateAssosOrderOnAfterPurchOrderHeaderModify(var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateAssocOrderOnAfterModifyPurchLine(var PurchOrderLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateAssocOrderOnBeforeModifyPurchLine(var PurchOrderLine: Record "Purchase Line"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateAssosOrderPostingNosOnAfterReleasePurchaseDocument(var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateAssosOrderPostingNosOnBeforeReleasePurchaseDocument(var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnDivideAmountOnBeforeTempVATAmountLineRemainderModify(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcVATBaseAmount(RentalHeader: Record "TWE Rental Header"; var RentalLine: Record "TWE Rental Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforePostUpdateInvoiceLine(var TempRentalLineGlobal: Record "TWE Rental Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertTrackingSpecification(RentalHeader: Record "TWE Rental Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSendPostedDocumentRecord(var RentalHeader: Record "TWE Rental Header"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    procedure OnSendSalesDocument(ShipAndInvoice: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;
}
