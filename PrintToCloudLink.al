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
        if PerformHealthCheck() then
            Message('Cool beans!')
        else
            Message('Lame beans!');
        // Message('Print Health Check completed.');
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
