/**
 * Created by user on 9/16/23.
 */

public class OrderConfirmationQueueJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public String query = 'SELECT Id, Order__c, DeliveryAttemptCount__c, Data__c FROM OrderConfirmationQueue__c WHERE Status__c NOT IN :queueItemStatusList LIMIT 10';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> queueItemStatusList = new List<String> {
            KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_FAILED,
            KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_COMPLETED
        };
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<OrderConfirmationQueue__c> scope) {
        OrderConfirmationEndpoint__mdt endpointConfig = getEndpointConfig(KPNConstants.ENDPOINT_DEVELOPERNAME_ORDER_CONFIRMATION_GENERIC);
        
        List<Order> ordersToUpdate = new List<Order>();
        List<OrderConfirmationQueue__c> queueItemsToUpdate = new List<OrderConfirmationQueue__c>();

        for (OrderConfirmationQueue__c queueItem : scope) {
            HttpResponse response = sendConfirmationCallout(endpointConfig.EndPoint__c, queueItem.Data__c);

            queueItem.LastResponseMessage__c = response.toString();
            queueItem.DeliveryAttemptCount__c += 1;

            Order order = new Order(Id = queueItem.Order__c);

            // handle success response
            if (response.getStatusCode() == KPNConstants.HTTP_STATUS_CODE_OK) {
                queueItem.Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_COMPLETED;
                order.OrderConfirmationStatus__c = KPNConstants.ORDER_CONFIRMATION_STATUS_DELIVERED;
                ordersToUpdate.add(order);
            } else {
                // handle errors
                if (queueItem.DeliveryAttemptCount__c < endpointConfig.MaxDeliveryAttempts__c) {
                    queueItem.Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_RETRY;
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

    public OrderConfirmationEndpoint__mdt getEndpointConfig(String developerName) {
        List<OrderConfirmationEndpoint__mdt> endpointConfig = [SELECT EndPoint__c, MaxDeliveryAttempts__c FROM OrderConfirmationEndpoint__mdt WHERE DeveloperName = :developerName LIMIT 1];

        if (endpointConfig.isEmpty()) {
            throw new IllegalArgumentException('Endpoint config developerName does not exist [' + developerName + ']');
        }
        return endpointConfig[0];
    }
}

