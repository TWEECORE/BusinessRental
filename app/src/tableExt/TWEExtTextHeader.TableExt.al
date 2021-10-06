tableextension 50000 "TWE Ext. Text Header" extends "Extended Text Header"
{
    fields
    {
        field(70704600; "TWE Rental Quote"; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Header" = R;
            Caption = 'Rental Quote';
            InitValue = true;
            DataClassification = CustomerContent;
        }
        field(70704601; "TWE Rental Invoice"; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Header" = R;
            Caption = 'Rental Invoice';
            InitValue = true;
            DataClassification = CustomerContent;
        }
        field(70704602; "TWE Rental Contract"; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Shipment Header" = R;
            Caption = 'Rental Contract';
            InitValue = true;
            DataClassification = CustomerContent;
        }
        field(70704603; "TWE Rental Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Header" = R;
            Caption = 'Rental Credit Memo';
            InitValue = true;
            DataClassification = CustomerContent;
        }
        field(70704604; "TWE Rental Ret. Shipment"; Boolean)
        {
            AccessByPermission = TableData "TWE Rental Header" = R;
            Caption = 'Rental Return Shipment';
            InitValue = true;
            DataClassification = CustomerContent;
        }
    }
}
