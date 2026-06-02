public with sharing class ERPSyncController {

    @AuraEnabled(cacheable=true)
    public static List<SyncLog__c> getSyncLogs() {
        return [
            SELECT Id, Name, OrderId__c, Status__c,
                   ErrorMessage__c, RetryCount__c, CreatedDate
            FROM SyncLog__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getSyncStats() {
        Map<String, Integer> stats = new Map<String, Integer>();
        stats.put('totalSuccess', [
            SELECT COUNT() FROM SyncLog__c WHERE Status__c = 'Success'
        ]);
        stats.put('totalFailed', [
            SELECT COUNT() FROM SyncLog__c WHERE Status__c = 'Failed'
        ]);
        stats.put('totalToday', [
            SELECT COUNT() FROM SyncLog__c WHERE CreatedDate = TODAY
        ]);
        return stats;
    }

    @AuraEnabled
    public static void retrySyncOrder(Id orderId) {
        ERPCalloutService.syncOrder(orderId);
    }
}