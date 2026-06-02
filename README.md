# Salesforce ERP Sync — Bidirectional Order Integration 🔄

A production-grade Salesforce integration that syncs Order data to an external ERP system in real time using Platform Events, Apex REST callouts, retry logic, and a Lightning Web Component sync monitor.

## 🎯 What It Does

- **Publishes Platform Events** when an Order is created or its status changes
- **Async subscriber trigger** processes events and calls the ERP REST endpoint
- **Retry logic** — retries failed callouts up to 3 times before dead-lettering
- **SyncLog__c** — every sync attempt is logged with status, error message, and timestamp
- **LWC Sync Monitor** — real-time dashboard showing sync stats and retry capability

## 🏗️ Architecture

Salesforce Order (insert/update)
→ OrderSyncTrigger (publishes Platform Event)
→ OrderSyncEvent__e (async delivery)
→ OrderSyncSubscriber (processes event)
→ ERPCalloutService (REST POST with retry)
→ Mock ERP (webhook.site)
→ SyncLog__c (success/failure logged)
→ erpSyncMonitor LWC (real-time visibility)

## 📁 Project Structure

force-app/main/default/
├── classes/
│   ├── ERPCalloutService.cls          # REST callout + retry logic + dead-letter logging
│   └── ERPSyncController.cls          # LWC Apex controller
├── triggers/
│   ├── OrderSyncTrigger.trigger       # Publishes Platform Event on Order change
│   └── OrderSyncSubscriber.trigger    # Subscribes to event, calls ERP
├── objects/
│   ├── OrderSyncEvent__e/             # Platform Event definition + fields
│   └── SyncLog__c/                    # Custom sync log object + fields
├── lwc/
│   └── erpSyncMonitor/               # Real-time sync dashboard
└── remoteSiteSettings/
└── WebhookSite.remoteSite-meta.xml

## ⚙️ Key Components

### OrderSyncTrigger
Fires `after insert` and `after update` on Order. Only publishes a Platform Event when the Order status changes — avoiding unnecessary syncs.

### OrderSyncEvent__e (Platform Event)
Custom Platform Event carrying `OrderId__c`, `OrderNumber__c`, `Status__c`, and `TotalAmount__c`. Delivered asynchronously by the Salesforce Event Bus.

### OrderSyncSubscriber
Listens to `OrderSyncEvent__e` and calls `ERPCalloutService.syncOrder()` for each event.

### ERPCalloutService
- Queries full Order + Account data
- Builds JSON payload
- POSTs to ERP endpoint with custom headers (`X-Source: Salesforce`, `X-Order-Id`)
- Retries up to 3 times on failure
- Logs result to `SyncLog__c` — marks as dead-letter after max retries

### SyncLog__c
Custom object tracking every sync attempt:
- `OrderId__c` — Salesforce Order ID
- `Status__c` — Success / Failed / Retry
- `ErrorMessage__c` — Full error details
- `RetryCount__c` — Number of retry attempts

### erpSyncMonitor LWC
Real-time dashboard on the Order record page showing:
- Total successful syncs
- Total failed syncs
- Syncs today
- Full log table with retry button for failed records

## 📦 Payload Example

```json
{
  "salesforceId": "801g500000Pa06oAAF",
  "orderNumber": "00000100",
  "status": "Draft",
  "totalAmount": 0,
  "accountName": "Test Account 1",
  "accountId": "001g500000NezHFAAZ",
  "effectiveDate": "2026-06-02",
  "syncedAt": "2026-06-02 14:03:31"
}
```

## 🚀 Deployment

```bash
# Authenticate
sf org login web --alias my-org --set-default

# Deploy all metadata
sf project deploy start --source-dir force-app

# Test callout via Anonymous Apex
sf apex run
```

Then paste:
```java
Order o = [SELECT Id FROM Order LIMIT 1];
ERPCalloutService.ERPResponse r = ERPCalloutService.syncOrder(o.Id);
System.debug(r.message);
```

## 🛠️ Tech Stack

- **Platform Events** — async event-driven architecture
- **Apex Callouts** — REST POST with headers and retry logic
- **Custom Objects** — SyncLog__c for audit trail
- **LWC** — Wire service, toast notifications, real-time refresh
- **Salesforce DX** — Source-driven development

## 👨‍💻 Author

**Richard Santiago** — Senior Salesforce Developer  
[Portfolio](https://rsantiago76.github.io/Salesforce-Developer-Portfolio/) · [LinkedIn](https://www.linkedin.com/in/richardsantiago01) · [Trailhead](https://www.salesforce.com/trailblazer/ew1493yn43lni5gwiz)
