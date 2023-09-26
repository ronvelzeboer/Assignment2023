/**
 * @author Ron Velzeboer
 * @date 16/09/2023
 * @description Batch processes OrderConfirmationQueue__c records that are new or needs to be retried.
 * Makes HTTP Requests to an external system to deliver an order confirmation
 */
public class OrderConfirmationQueueJob implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public String query = 'SELECT Id, Order__c, DeliveryAttemptCount__c, Data__c FROM OrderConfirmationQueue__c WHERE Status__c IN :queueItemStatusList';

    /**
     * @param bc BatchableContext
     *
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> queueItemStatusList = new List<String> {
            KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW,
            KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_RETRY
        };
        return Database.getQueryLocator(query);
    }

    /**
     * @description Bulk processing of OrderConfirmationQueue__c records and makes callout to deliver a order confirmation
     * to an endpoint
     * @param bc BatchableContext
     * @param scope List or records to process
     */
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

    /**
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {}

    /**
     * @description Creates a HttpRequest with Order Confirmation JSON data and send this request to the endpoint
     * @param endpoint endpoint to send the order confirmation to
     * @param payload JSON data formatted according the specs of the external system
     *
     * @return the HttpResponse data for further processing
     */
    public HttpResponse sendConfirmationCallout(String endpoint, String payload) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);

        return http.send(request);
    }

    /**
     * @description Retrieve specific endpoint data stored in the OrderConfirmationEndpoint__mdt
     * @param developerName DeveloperName of the Endpoint record in OrderConfirmationEndpoint__mdt
     *
     * @return the OrderConfirmationEndpoint__mdt record
     */
    public OrderConfirmationEndpoint__mdt getEndpointConfig(String developerName) {
        List<OrderConfirmationEndpoint__mdt> endpointConfig = [SELECT EndPoint__c, MaxDeliveryAttempts__c FROM OrderConfirmationEndpoint__mdt WHERE DeveloperName = :developerName LIMIT 1];

        if (endpointConfig.isEmpty()) {
            throw new IllegalArgumentException('Endpoint config developerName does not exist [' + developerName + ']');
        }
        return endpointConfig[0];
    }
}

