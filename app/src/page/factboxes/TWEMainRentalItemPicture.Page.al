/// <summary>
/// Page TWE Main Rental Item Picture (ID 50000).
/// </summary>
page 50000 "TWE Main Rental Item Picture"
{
    Caption = 'Main Rental Item Picture';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = "TWE Main Rental Item";

    layout
    {
        area(content)
        {
            field(Picture; Rec.Picture)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ShowCaption = false;
                ToolTip = 'Specifies the picture that has been inserted for the item.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            /*             action(TakePicture)
                        {
                            ApplicationArea = All;
                            Caption = 'Take';
                            Image = Camera;
                            Promoted = true;
                            PromotedCategory = Process;
                            PromotedIsBig = true;
                            ToolTip = 'Activate the camera on the device.';
                            Visible = CameraAvailable AND (HideActions = FALSE);

                            trigger OnAction()
                            begin
                                TakeNewPicture();
                            end;
                        } */
            /*  action(ImportPicture)
             {
                 ApplicationArea = All;
                 Caption = 'Import';
                 Image = Import;
                 ToolTip = 'Import a picture file.';
                 Visible = HideActions = FALSE;

                 trigger OnAction()
                 begin
                     ImportFromDevice;
                 end;
             } */
            /*  action(ExportFile)
             {
                 ApplicationArea = All;
                 Caption = 'Export';
                 Enabled = DeleteExportEnabled;
                 Image = Export;
                 ToolTip = 'Export the picture to a file.';
                 Visible = HideActions = FALSE;

                 trigger OnAction()
                 var
                     DummyPictureEntity: Record "Picture Entity";
                     FileManagement: Codeunit "File Management";
                     ToFile: Text;
                     ExportPath: Text;
                 begin
                     Rec.TestField("No.");
                     Rec.TestField(Description);

                     ToFile := DummyPictureEntity.GetDefaultMediaDescription(Rec);
                     ExportPath := TemporaryPath + Rec."No." + Format(Rec.Picture.MediaId);
                     Rec.Picture.ExportFile(ExportPath + '.' + DummyPictureEntity.GetDefaultExtension);

                     FileManagement.ExportImage(ExportPath, ToFile);
                 end;
             } */
            /*             action(DeletePicture)
                        {
                            ApplicationArea = All;
                            Caption = 'Delete';
                            Enabled = DeleteExportEnabled;
                            Image = Delete;
                            ToolTip = 'Delete the record.';
                            Visible = HideActions = FALSE;

                            trigger OnAction()
                            begin
                                DeleteItemPicture();
                            end;
                        } */
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        //SetEditableOnPictureActions();
    end;

    trigger OnOpenPage()
    begin
        //CameraAvailable := Camera.IsAvailable();
    end;

    var
        Camera: Codeunit Camera;
        //[InDataSet]
        //CameraAvailable: Boolean;
        //DeleteExportEnabled: Boolean;
        // HideActions: Boolean;
        //OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
    //SelectPictureTxt: Label 'Select a picture to upload';
    //MustSpecifyDescriptionErr: Label 'You must add a description to the item before you can import a picture.';

    /// <summary>
    /// TakeNewPicture.
    /// </summary>
    procedure TakeNewPicture()
    begin
        Rec.Find();
        Rec.TestField("No.");
        Rec.TestField(Description);

        Camera.AddPicture(Rec, Rec.FieldNo(Picture));
    end;

    /// <summary>
    /// ImportFromDevice.
    /// </summary>
    /*     procedure ImportFromDevice()
        var
            FileManagement: Codeunit "File Management";
            FileName: Text;
            ClientFileName: Text;
        begin
            Rec.Find();
            Rec.TestField("No.");
            if Rec.Description = '' then
                Error(MustSpecifyDescriptionErr);

            if Rec.Picture.Count > 0 then
                if not Confirm(OverrideImageQst) then
                    Error('');

            ClientFileName := '';
            //FileName := FileManagement.UploadFile(SelectPictureTxt, ClientFileName);
            if FileName = '' then
                Error('');

            Clear(Rec.Picture);
            Rec.Picture.ImportFile(FileName, ClientFileName);
            Rec.Modify(true);

            if FileManagement.DeleteServerFile(FileName) then;
        end; */
    /* 
         local procedure SetEditableOnPictureActions()
        begin
            DeleteExportEnabled := Rec.Picture.Count <> 0;
        end;  */

    /// <summary>
    /// IsCameraAvailable.
    /// </summary>
    /// <returns>Return value of type Boolean.</returns>
    procedure IsCameraAvailable(): Boolean
    begin
        exit(Camera.IsAvailable());
    end;

    /// <summary>
    /// SetHideActions.
    /// </summary>
 /*    procedure SetHideActions()
    begin
        HideActions := true;
    end; */

    /// <summary>
    /// DeleteItemPicture.
    /// </summary>
    procedure DeleteItemPicture()
    begin
        Rec.TestField("No.");

        if not Confirm(DeleteImageQst) then
            exit;

        Clear(Rec.Picture);
        Rec.Modify(true);
    end;
}

