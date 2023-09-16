/**
 * Created by user on 9/15/23.
 */

public with sharing class OrderManager {

    public static void activateOrderByOrderId(Id orderId) {
        Savepoint sp = Database.setSavepoint();

        try {
            Order orderRecord = new Order(Id = orderId, Status = KPNConstants.ORDER_STATUS_ACTIVATED);

            List<OrderItem> relatedOrderItems = getOrderItemsByOrderId(orderId);

            for (OrderItem item : relatedOrderItems) {
                item.Status__c = KPNConstants.ORDER_ITEM_STATUS_ACTIVATED;
            }
            Database.SaveResult orderUpdateResults = Database.update(orderRecord, false);
            Database.SaveResult[] itemsUpdateResults = Database.update(relatedOrderItems, false);

            if (!orderUpdateResults.isSuccess()) {
                throw new OrderManagerException('An error occurred while updating the status of the Order: ' + orderUpdateResults.getErrors());
            }

            for (Database.SaveResult result : itemsUpdateResults) {
                if (!result.isSuccess()) {
                    throw new OrderManagerException('An error occurred while updating the status of the related OrderItems: ' + result.getErrors());
                }
            }
        } catch(Exception e) {
            Database.rollback(sp);

            // TODO: add message to custom application log instead of System.debug
            System.debug('OrderManager:activateOrderByOrderId -> ' + e.getMessage());
        }
    }

    public static Order getOrderById(Id orderId) {
        List<Order> record = [
            SELECT Id, Status, Account.Name, Account.AccountNumber, Type, OrderNumber, OrderConfirmationStatus__c FROM Order WHERE Id = :orderId
        ];
        if (record.isEmpty()) {
            throw new IllegalArgumentException('No order found with Id: ' + orderId);
        }
        return record[0];
    }

    public static List<OrderItem> getOrderItemsByOrderId(Id orderId) {
        List<OrderItem> records = [
                SELECT Id, PricebookEntryId, Product2.Name, Product2.ProductCode, Quantity, UnitPrice, TotalPrice, Status__c
                FROM OrderItem
                WHERE OrderId = :orderId
        ];
        return records;
    }

    public class OrderManagerException extends Exception {}
}
