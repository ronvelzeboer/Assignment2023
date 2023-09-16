/**
 * Created by user on 9/15/23.
 */

public with sharing class OrderConfirmationGateway {

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

    private static void updateOrderConfirmationStatusOnOrder(Order order) {
        order.OrderConfirmationStatus__c = KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS;
        update order;
    }

    private static String buildOrderConfirmationJson(Order order, List<OrderItem> orderItems) {
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
        return JSON.serializePretty(data, false);
    }

    private static void createAndSaveOrderConfirmationQueueItem(Order order, String confirmationData) {
        OrderConfirmationQueue__c queueItem = new OrderConfirmationQueue__c(
            Order__c = order.Id,
            Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW,
            Data__c = confirmationData
        );
        insert queueItem;
    }

    public class OrderConfirmationGatewayException extends Exception {}
}
