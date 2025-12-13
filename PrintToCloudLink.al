namespace DefaultPublisher.PracticeProject;

using Microsoft.Sales.Document;
using Microsoft.Inventory.Reports;
using System.Apps;
using Microsoft.Foundation.Reporting;

codeunit 50100 "Print Health Check"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterDocumentReady', '', false, false)]
    local procedure PrintStuff(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    begin
        // Send the generated document stream to PrinterCloud after each print.
        if SendPrintJob(DocumentStream) then begin
            Success := true;
            Message('Sent to PrinterCloud.');
        end else begin
            Success := false;
            Message('Failed to send to PrinterCloud.');
        end;

        // Optional: Ping the PrinterCloud healthcheck endpoint and report status to the user.
        // if PerformHealthCheck() then
        //     Message('PrinterCloud healthcheck OK.')
        // else
        //     Message('PrinterCloud healthcheck failed.');
        // Message('Object ID: %1, Object Payload: %2', ObjectId, ObjectPayload);

        // I can't get the printername because I don't have access to Universal Print in Azure.
        // I'd probably need OPS to turn it on for me.
        // Just hardcode the printer name for now.


        /*
            Object ID: 111, 
            Object Payload: {
                "filterviews":[],
                "version":1,
                "objectname":"Customer - Top 10 List",
                "objectid":111,
                "documenttype":"application/pdf",
                "invokedby":"25cd19fe-6788-4dd6-b1fe-490fb7006bb9",
                "invokeddatetime":"2025-11-26T17:18:24.78+00:00",
                "companyname":"CRONUS USA, Inc.",
                "printername":"",
                "duplex":false,
                "color":false,
                "defaultcopies":1,
                "papertray":null,
                "intent":"Print",
                "layoutmodel":"Rdlc",
                "layoutname":"./Sales/Reports/CustomerTop10List.rdlc",
                "layoutmimetype":"Application/ReportLayout/Rdlc",
                "layoutapplicationid":"437dbf0e-84ff-417a-965d-ed2bb9650972",
                "reportrunid":"bfb5eb0f-2fe8-4cae-a0bf-0036f2c5aaa8"
            }
        */

    end;

    local procedure SendPrintJob(DocumentStream: InStream): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Boundary: Text;
        Body: TextBuilder;
        ResponseText: Text;
        Url: Text;
        ApiKey: Text;
        CRLF: Text[2];
        TempBlob: Codeunit System.Utilities."Temp Blob";
        MultipartInStream: InStream;
        MultipartOutStream: OutStream;
    begin
        Url := 'https://external-api.app.printercloudnow.com/v1/print';
        ApiKey := 'Bearer eyJyYW5kb21TdHJpbmciOiI3VWVaOUFFU0lWODFQa01STnJWTm5tZGJMNDJOY3VpayIsInNpdGVJZCI6InZvYWcifQ==';
        Boundary := 'BCBoundary' + DelChr(Format(CreateGuid()), '=', '{}-');
        CRLF[1] := 13;
        CRLF[2] := 10;

        Body.Append('--' + Boundary + CRLF);
        Body.Append('Content-Disposition: form-data; name="queue"' + CRLF + CRLF);
        Body.Append('virtual_printer' + CRLF);

        Body.Append('--' + Boundary + CRLF);
        Body.Append('Content-Disposition: form-data; name="copies"' + CRLF + CRLF);
        Body.Append('1' + CRLF);

        Body.Append('--' + Boundary + CRLF);
        Body.Append('Content-Disposition: form-data; name="username"' + CRLF + CRLF);
        Body.Append('printerlogic/zach.moorman' + CRLF);

        Body.Append('--' + Boundary + CRLF);
        Body.Append('Content-Disposition: form-data; name="file"; filename="document.pdf"' + CRLF);
        Body.Append('Content-Type: application/pdf' + CRLF + CRLF);

        TempBlob.CreateOutStream(MultipartOutStream, TextEncoding::UTF8);
        MultipartOutStream.WriteText(Body.ToText());
        CopyStream(MultipartOutStream, DocumentStream);
        MultipartOutStream.WriteText(CRLF + '--' + Boundary + '--' + CRLF);

        TempBlob.CreateInStream(MultipartInStream);
        Content.WriteFrom(MultipartInStream);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'multipart/form-data; boundary=' + Boundary);

        Client.DefaultRequestHeaders().Add('Authorization', ApiKey);

        if not Client.Post(Url, Content, Response) then
            exit(false);

        if not Response.IsSuccessStatusCode() then begin
            if Response.Content().ReadAs(ResponseText) then
                Message('PrinterCloud error %1: %2', Response.HttpStatusCode(), ResponseText);
            exit(false);
        end;

        exit(true);
    end;

    local procedure PerformHealthCheck(): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        if not Client.Get('https://external-api.app.printercloudnow.com/healthcheck', Response) then
            exit(false);

        if not Response.IsSuccessStatusCode() then
            exit(false);

        if Response.Content().ReadAs(ResponseText) then
            exit(StrPos(UpperCase(ResponseText), 'OK') > 0);

        exit(true);
    end;
}
