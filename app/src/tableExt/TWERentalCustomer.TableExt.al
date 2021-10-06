/// <summary>
/// TableExtension TWE Rental Customer (ID 50002) extends Record Customer.
/// </summary>
tableextension 50002 "TWE Rental Customer" extends Customer
{
    fields
    {
        field(70704600; "TWE No. of Quotes"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST(Quote),
                                                      "Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Rental Quotes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704601; "TWE No. of Contracts"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST(Contract),
                                                      "Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Rental Contracts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704602; "TWE No. of Invoices"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST(Invoice),
                                                      "Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Rental Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704603; "TWE No. of Post. Invoices"; Integer)
        {
            CalcFormula = Count("TWE Rental Invoice Header" WHERE("Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Posted Rental Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50002; "TWE No. of Post. Shipments"; Integer)
        {
            CalcFormula = Count("TWE Rental Shipment Header" WHERE("Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Posted Rental Shipments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704605; "TWE No. of Return Shipments"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST("Return Shipment"),
                                                      "Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Rental Return Shipments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704606; "TWE No. of Post. Return Shipm."; Integer)
        {
            CalcFormula = Count("TWE Rental Return Ship. Header" WHERE("Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Posted Rental Return Shipments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704607; "TWE No. of Cr. Memos"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST("Credit Memo"),
                                                      "Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Rental Cr. Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704608; "TWE No. of Post. Cr. Memos"; Integer)
        {
            CalcFormula = Count("TWE Rental Cr.Memo Header" WHERE("Rented-to Customer No." = FIELD("No.")));
            Caption = 'No. of Posted Rental Cr. Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704609; "TWE Outstanding Contr. (LCY)"; Decimal)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Line"."Outstanding Amount (LCY)" WHERE("Document Type" = CONST(Contract),
                                                                             "Bill-to Customer No." = FIELD("No."),
                                                                             "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Currency Code" = FIELD("Currency Filter")));
            Caption = 'Outstanding Contracts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704610; "TWE Shipped Not Invoiced (LCY)"; Decimal)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Line"."Shipped Not Invoiced (LCY)" WHERE("Document Type" = CONST(Contract),
                                                                               "Bill-to Customer No." = FIELD("No."),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Currency Code" = FIELD("Currency Filter")));
            Caption = 'Shipped Not Invoiced (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704611; "TWE Outstanding Invoices (LCY)"; Decimal)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            AutoFormatType = 1;
            CalcFormula = Sum("TWE Rental Line"."Outstanding Amount (LCY)" WHERE("Document Type" = CONST(Invoice),
                                                                             "Bill-to Customer No." = FIELD("No."),
                                                                             "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                             "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                             "Currency Code" = FIELD("Currency Filter")));
            Caption = 'Outstanding Invoices (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704620; "TWE Bill-To No. of Quotes"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST(Quote),
                                                      "Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Quotes';
            Editable = false;
            FieldClass = FlowField;
        }

        field(70704621; "TWE Bill-To No. of Contracts"; Integer)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST(Contract),
                                                      "Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Contracts';
            Editable = false;
            FieldClass = FlowField;
        }

        field(70704622; "TWE Bill-To No. of Invoices"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST(Invoice),
                                                      "Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704623; "TWE Bill-To No. of Ret. Shipm."; Integer)
        {
            AccessByPermission = TableData "TWE Rental Return Ship. Header" = R;
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST("Return Shipment"),
                                                      "Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Return Shipments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704624; "TWE Bill-To No. of Cr. Memos"; Integer)
        {
            CalcFormula = Count("TWE Rental Header" WHERE("Document Type" = CONST("Credit Memo"),
                                                      "Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Credit Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704625; "TWE Bill-To No. of Pstd. Ship."; Integer)
        {
            CalcFormula = Count("TWE Rental Shipment Header" WHERE("Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Pstd. Shipments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704626; "TWE Bill-To No. of Pstd. Inv."; Integer)
        {
            CalcFormula = Count("TWE Rental Invoice Header" WHERE("Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Pstd. Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704627; "TWE Bill-To No. of P. Ret. S."; Integer)
        {
            CalcFormula = Count("TWE Rental Return Ship. Header" WHERE("Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Pstd. Return Shipm.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70704628; "TWE Bill-To No. P. Cr. Memos"; Integer)
        {
            CalcFormula = Count("TWE Rental Cr.Memo Header" WHERE("Bill-to Customer No." = FIELD("No.")));
            Caption = 'Bill-To No. of Pstd. Cr. Memos';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
