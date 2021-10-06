/// <summary>
/// Table TWE Rent. Incoming Doc. Att. (ID 50012).
/// </summary>
tableextension 50012 "TWE Rent. Incoming Doc. Att." extends "Incoming Document Attachment"
{
    /// <summary>
    /// NewAttachmentFromRentalDocument.
    /// </summary>
    /// <param name="RentalHeader">Record "TWE Rental Header".</param>
    procedure NewAttachmentFromRentalDocument(RentalHeader: Record "TWE Rental Header")
    begin
        NewAttachmentFromDocument(
          RentalHeader."Incoming Document Entry No.",
          DATABASE::"TWE Rental Header",
          RentalHeader."Document Type".AsInteger(),
          RentalHeader."No.");
    end;
}
