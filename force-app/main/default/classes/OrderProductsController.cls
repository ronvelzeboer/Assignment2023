/**
 * Created by user on 9/14/23.
 */

public with sharing class OrderProductsController
{
    public class OrderProductListItem {
        @AuraEnabled
        public Id orderItemId;

        @AuraEnabled
        public Id pricebookEntryId;

        @AuraEnabled
        public String productName;

        @AuraEnabled
        public Integer quantity;

        @AuraEnabled
        public Decimal unitPrice;

        @AuraEnabled
        public Decimal totalPrice;

        @AuraEnabled
        public String status;
    }

    @AuraEnabled
    public static OrderItem saveOrderProduct(OrderItem orderProduct) {

        if (orderProduct.Id == null && !Schema.SObjectType.OrderItem.isCreateable() ) {
            throw new SecurityException('Insufficient permissions to insert order products!');
        }
        if (orderProduct.Id != null && !Schema.SObjectType.OrderItem.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update order products!');
        }
        upsert orderProduct;
        return orderProduct;
    }

    @AuraEnabled
    public static void deleteOrderProduct(Id orderProductId) {

        if (!Schema.SObjectType.OrderItem.isDeletable()) {
            throw new SecurityException('Insufficient permissions to delete order products!');
        }
        OrderItem item = new OrderItem(Id = orderProductId);
        delete item;
    }

    @AuraEnabled(Cacheable=true)
    public static List<OrderProductListItem> getOrderProductListItemsByOrderId(Id orderId) {
        List<OrderProductListItem> orderProducts = new List<OrderProductListItem>();

        List<OrderItem> records = [
            SELECT Id, PricebookEntryId, Product2.Name, Quantity, UnitPrice, TotalPrice, Status__c FROM OrderItem WHERE OrderId= :orderId
        ];
        for (OrderItem record : records) {
            OrderProductListItem listItem = new OrderProductListItem();
            listItem.orderItemId = record.Id;
            listItem.productName = record.Product2.Name;
            listItem.pricebookEntryId = record.PricebookEntryId;
            listItem.unitPrice = record.UnitPrice;
            listItem.quantity = Integer.valueOf(record.Quantity);
            listItem.totalPrice = record.TotalPrice;
            listItem.status = record.Status__c;
            orderProducts.add(listItem);
        }
        return orderProducts;
    }
}
