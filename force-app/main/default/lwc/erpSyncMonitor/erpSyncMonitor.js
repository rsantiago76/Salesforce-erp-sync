import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSyncLogs from '@salesforce/apex/ERPSyncController.getSyncLogs';
import getSyncStats from '@salesforce/apex/ERPSyncController.getSyncStats';
import retrySyncOrder from '@salesforce/apex/ERPSyncController.retrySyncOrder';

export default class ErpSyncMonitor extends LightningElement {
    @track logs = [];
    @track stats;
    @track error;
    @track isLoading = true;
    wiredLogsResult;
    wiredStatsResult;

    @wire(getSyncLogs)
    wiredLogs(result) {
        this.wiredLogsResult = result;
        this.isLoading = false;
        if (result.data) {
            this.logs = result.data.map(log => ({
                ...log,
                isFailed: log.Status__c === 'Failed',
                statusClass: log.Status__c === 'Success'
                    ? 'slds-badge slds-theme_success'
                    : 'slds-badge slds-theme_error',
                syncedAt: new Date(log.CreatedDate).toLocaleString()
            }));
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Error loading logs';
            this.logs = [];
        }
    }

    @wire(getSyncStats)
    wiredStats(result) {
        this.wiredStatsResult = result;
        if (result.data) {
            this.stats = result.data;
        }
    }

    get hasLogs() {
        return this.logs && this.logs.length > 0;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredLogsResult);
        refreshApex(this.wiredStatsResult);
        this.isLoading = false;
    }

    handleRetry(event) {
        const orderId = event.target.dataset.id;
        retrySyncOrder({ orderId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Retry Initiated',
                    message: 'Order sync retry has been triggered.',
                    variant: 'success'
                }));
                setTimeout(() => this.handleRefresh(), 2000);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Retry Failed',
                    message: error.body?.message || 'Failed to retry sync',
                    variant: 'error'
                }));
            });
    }
}