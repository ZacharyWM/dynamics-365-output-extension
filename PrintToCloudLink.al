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
        // Ping the PrinterCloud healthcheck endpoint after each print and report status to the user.
        // if PerformHealthCheck() then
        //     Message('Cool beans!')
        // else
        //     Message('Lame beans!');
        Message('Object ID: %1, Object Payload: %2', ObjectId, ObjectPayload);

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
