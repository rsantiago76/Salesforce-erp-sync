public with sharing class ERPCalloutService {

    private static final String ERP_ENDPOINT = 'https://webhook.site/e7732bfa-9e13-45ed-85bb-81e2d5d8bab6';
    private static final Integer MAX_RETRIES = 3;

    public class ERPResponse {
        public Boolean success;
        public String message;
        public Integer statusCode;
    }

    public static ERPResponse syncOrder(Id orderId) {
        Order o = [
            SELECT Id, OrderNumber, Status, TotalAmount,
                   Account.Name, Account.Id,
                   EffectiveDate, EndDate, Description
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'salesforceId'  => o.Id,
            'orderNumber'   => o.OrderNumber,
            'status'        => o.Status,
            'totalAmount'   => o.TotalAmount,
            'accountName'   => o.Account.Name,
            'accountId'     => o.Account.Id,
            'effectiveDate' => String.valueOf(o.EffectiveDate),
            'description'   => o.Description,
            'syncedAt'      => String.valueOf(Datetime.now())
        };

        ERPResponse response = makeCallout(JSON.serialize(payload), orderId);
        logSync(orderId, response);
        return response;
    }

    private static ERPResponse makeCallout(String body, Id orderId) {
        ERPResponse result = new ERPResponse();
        Integer attempts = 0;

        while (attempts < MAX_RETRIES) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(ERP_ENDPOINT);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('X-Source', 'Salesforce');
                req.setHeader('X-Order-Id', orderId);
                req.setBody(body);
                req.setTimeout(10000);

                Http http = new Http();
                HttpResponse res = http.send(req);

                result.statusCode = res.getStatusCode();

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    result.success = true;
                    result.message = 'Sync successful. ERP responded: ' + res.getStatusCode();
                    return result;
                } else {
                    result.success = false;
                    result.message = 'ERP returned ' + res.getStatusCode() + ': ' + res.getBody();
                }
            } catch (Exception e) {
                result.success = false;
                result.message = 'Callout error: ' + e.getMessage();
            }
            attempts++;
        }

        result.message = '[DEAD-LETTER] Max retries reached. Last error: ' + result.message;
        return result;
    }

    private static void logSync(Id orderId, ERPResponse response) {
        SyncLog__c log = new SyncLog__c(
            OrderId__c      = orderId,
            Status__c       = response.success ? 'Success' : 'Failed',
            ErrorMessage__c = response.success ? null : response.message
        );
        insert log;
    }
}