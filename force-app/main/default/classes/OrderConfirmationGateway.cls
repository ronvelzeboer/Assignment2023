/**
 * @author Ron Velzeboer
 * @date 15/09/2023
 * @description Creates Order Confirmation data and adds queue records to send to an external system
 */

public with sharing class OrderConfirmationGateway {

    /**
     * @description Tests if order is 'Activated' and calls methods to create the OrderConfirmationStatus__c record and
     * updates the OrderConfirmationStatus__c of the order
     * @param orderId the order for which an order confirmation needs to be send
     *
     * @throws OrderConfirmationGatewayException in case the order status is not 'Activated'
     */
    public static void registerOrder(Id orderId) {
        try {
            Order order = OrderManager.getOrderById(orderId);

            if (order.Status != KPNConstants.ORDER_STATUS_ACTIVATED) {
                throw new OrderConfirmationGatewayException('Error: Only orders with status "Activated" will be accepted');
            }
            List<OrderItem> orderItems = OrderManager.getOrderItemsByOrderId(orderId);

            String confirmationData = buildOrderConfirmationJson(order, orderItems);
            updateOrderConfirmationStatusOnOrder(order);
            createAndSaveOrderConfirmationQueueItem(order, confirmationData);
        } catch (Exception e) {
            throw e;
        }
    }

    /**
     * @description Updates the OrderConfirmationStatus__c of the order to 'In Progress'
     * @param order Order to be processed
     */
    private static void updateOrderConfirmationStatusOnOrder(Order order) {
        order.OrderConfirmationStatus__c = KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS;
        update order;
    }

    /**
     * @description Manage the creation of the Order Confirmation JSON data
     * @param order Order to be processed
     * @param orderItems OrderItems to be processed
     *
     * @return
     */
    private static String buildOrderConfirmationJson(Order order, List<OrderItem> orderItems) {
        OrderConfirmation dataStructure = buildOrderConfirmationObjectStructure(order, orderItems);
        return OrderConfirmation.serialize(dataStructure);
    }

    /**
     * @description Builds an OrderConfirmation object based on the Order and OrderItems
     * @param order Order to be processed
     * @param orderItems OrderItems to be processed
     *
     * @return OrderConfirmation object based on input
     */
    private static OrderConfirmation buildOrderConfirmationObjectStructure(Order order, List<OrderItem> orderItems) {
        OrderConfirmation data = new OrderConfirmation();
        data.accountNumber = order.Account.AccountNumber;
        data.orderNumber = order.OrderNumber;
        data.type = order.Type;
        data.status = order.Status;
        data.orderProducts = new List<OrderConfirmation.OrderProduct>();

        for (OrderItem orderItem : orderItems) {
            OrderConfirmation.OrderProduct orderProduct = new OrderConfirmation.OrderProduct();
            orderProduct.name = orderItem.Product2.Name;
            orderProduct.code = orderItem.Product2.ProductCode;
            orderProduct.unitPrice = orderItem.UnitPrice;
            orderProduct.quantity = Integer.valueOf(orderItem.Quantity);
            data.orderProducts.add(orderProduct);
        }
        return data;
    }

    /**
     * @description Creates a OrderConfirmationQueue__c record (with the JSON data to send) for the order confirmation
     * of the Order which is picked up by a Batch Job.
     * @param order Order to be processed
     * @param confirmationData Order Confirmation JSON data structure
     */
    private static void createAndSaveOrderConfirmationQueueItem(Order order, String confirmationData) {
        OrderConfirmationQueue__c queueItem = new OrderConfirmationQueue__c(
            Order__c = order.Id,
            Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW,
            Data__c = confirmationData
        );
        insert queueItem;
    }

    /**
     * @description Custom Exception class
     */
    public class OrderConfirmationGatewayException extends Exception {}
}
