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
                throw new OrderManagerException('An error occurred while updating the status of the Order');
            }

            for (Database.SaveResult result : itemsUpdateResults) {
                if (!result.isSuccess()) {
                    throw new OrderManagerException('An error occurred while updating the status of the related OrderItems');
                }
            }
        } catch(Exception e) {
            Database.rollback(sp);

            // TODO: add message to custom application log instead of System.debug
            System.debug('OrderManager:activateOrderByOrderId -> ' + e.getMessage());

        }
    }

    public static List<OrderItem> getOrderItemsByOrderId(Id orderId) {
        List<OrderItem> records = [
                SELECT Id, PricebookEntryId, Product2.Name, Quantity, UnitPrice, TotalPrice, Status__c
                FROM OrderItem
                WHERE OrderId = :orderId
        ];
        return records;
    }

    public class OrderManagerException extends Exception {}
}
