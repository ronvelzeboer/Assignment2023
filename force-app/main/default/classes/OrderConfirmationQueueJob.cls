/**
 * Created by user on 9/16/23.
 */

public class OrderConfirmationQueueJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public String query = 'SELECT Id, Order__c, RetryCount__c, Data__c FROM OrderConfirmationQueue__c '
                        + 'WHERE Status__c NOT IN ("' +
                                KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_FAILED + '", "' +
                                KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_COMPLETED + '") LIMIT 10';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<OrderConfirmationQueue__c> scope) {
        String endpoint = 'https://rvkpnassignment.requestcatcher.com/test'; // TODO: do not hardcode endpoint
        List<Order> ordersToUpdate = new List<Order>();
        List<OrderConfirmationQueue__c> queueItemsToUpdate = new List<OrderConfirmationQueue__c>();

        for (OrderConfirmationQueue__c queueItem : scope) {
            HttpResponse response = sendConfirmationCallout(endpoint, queueItem.Data__c);

            queueItem.LastResponseMessage__c = response.toString();

            Order order = new Order(Id = queueItem.Order__c);

            // handle success response
            if (response.getStatusCode() == 200) {
                queueItem.Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_COMPLETED;
                order.OrderConfirmationStatus__c = KPNConstants.ORDER_CONFIRMATION_STATUS_DELIVERED;
                ordersToUpdate.add(order);
            } else {
                // handle errors
                if (queueItem.RetryCount__c < 5) { // TODO: do not hardcode
                    queueItem.Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_RETRY;
                    queueItem.RetryCount__c += 1;
                } else {
                    // could not deliver order confirmation
                    queueItem.Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_FAILED;
                    order.OrderConfirmationStatus__c = KPNConstants.ORDER_CONFIRMATION_STATUS_FAILED;
                    ordersToUpdate.add(order);
                }
            }
            queueItemsToUpdate.add(queueItem);
        }
        update queueItemsToUpdate;
        update ordersToUpdate;
    }

    public void finish(Database.BatchableContext bc) {}

    public HttpResponse sendConfirmationCallout(String endpoint, String payload) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);

        return http.send(request);
    }
}

