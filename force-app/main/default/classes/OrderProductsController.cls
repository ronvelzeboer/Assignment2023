/**
 * Created by user on 9/14/23.
 */

public with sharing class OrderProductsController
{
    public class OrderProductListItem {
        @AuraEnabled
        public Id orderItemId { get; set; }

        @AuraEnabled
        public Id orderId { get; set; }

        @AuraEnabled
        public Id pricebookEntryId { get; set; }

        @AuraEnabled
        public String productName { get; set; }

        @AuraEnabled
        public Integer quantity { get; set; }

        @AuraEnabled
        public Decimal unitPrice { get; set; }

        @AuraEnabled
        public Decimal totalPrice { get; set; }

        @AuraEnabled
        public String status { get; set; }
    }

    @AuraEnabled
    public static void activateOrder(Id orderId) {
        // activate order in salesforce
        OrderManager.activateOrderByOrderId(orderId);

        // initiate order confirmation to external system
        OrderConfirmationGateway.registerOrder(orderId);
    }

    @AuraEnabled
    public static void deleteOrderProduct(Id orderProductId) {

        if (!Schema.SObjectType.OrderItem.isDeletable()) {
            throw new SecurityException('Insufficient permissions to delete order products!');
        }
        OrderItem item = new OrderItem(Id = orderProductId);
        delete item;
    }

    @AuraEnabled
    public static OrderProductListItem saveOrderProduct(OrderProductListItem record) {

        if (record.orderItemId == null && !Schema.SObjectType.OrderItem.isCreateable() ) {
            throw new SecurityException('Insufficient permissions to insert order products!');
        }
        if (record.orderItemId != null && !Schema.SObjectType.OrderItem.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update order products!');
        }
        OrderItem orderItem = getMappedOrderItemInstance(record);
        upsert orderItem;

        record.orderItemId = orderItem.Id;
        return record;
    }

    @AuraEnabled(Cacheable=true)
    public static List<OrderProductListItem> getOrderProductListItemsByOrderId(Id orderId) {
        List<OrderProductListItem> orderProducts = new List<OrderProductListItem>();

        List<OrderItem> records = OrderManager.getOrderItemsByOrderId(orderId);
        for (OrderItem record : records) {
            OrderProductListItem listItem = getMappedOrderProductListItemInstance(record);
            orderProducts.add(listItem);
        }
        return orderProducts;
    }

    public static OrderProductListItem getMappedOrderProductListItemInstance(OrderItem record) {
        OrderProductListItem listItem = new OrderProductListItem();
        listItem.orderItemId = record.Id;
        listItem.productName = record.Product2.Name;
        listItem.pricebookEntryId = record.PricebookEntryId;
        listItem.unitPrice = record.UnitPrice;
        listItem.quantity = Integer.valueOf(record.Quantity);
        listItem.totalPrice = record.TotalPrice;
        listItem.status = record.Status__c;
        return listItem;
    }

    public static OrderItem getMappedOrderItemInstance(OrderProductListItem listItem) {
        OrderItem record = new OrderItem(
            Id = listItem.orderItemId,
            OrderId = listItem.orderId,
            PricebookEntryId = listItem.pricebookEntryId,
            ListPrice = listItem.unitPrice,
            UnitPrice = listItem.unitPrice,
            Quantity = listItem.quantity
        );
        return record;
    }
}
