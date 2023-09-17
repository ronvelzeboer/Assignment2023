/**
 * @author Ron Velzeboer
 * @date 14/09/2023
 * @description Controller for the LWC 'Order Products' component
 */
public with sharing class OrderProductsController
{
    /**
     * @description OrderProductListItem serves as an object to transfer data between the LWC frontend component and the
     * controller to loosely couple the frontend and the backed structure
     */
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

    /**
     * @description Activates the Order and OrderItem (Order Products) records. Then triggers the order confirmation process to the external system
     * @param orderId Order to activate
     */
    @AuraEnabled
    public static void activateOrder(Id orderId) {
        // activate order in salesforce
        OrderManager.activateOrderByOrderId(orderId);

        // initiate order confirmation to external system
        OrderConfirmationGateway.registerOrder(orderId);
    }

    /**
     * @description Deletes a specific OrderItem (Order Product)
     * @param orderProductId OrderProduct to delete
     * @throws SecurityException in case user has no delete permissions
     */
    @AuraEnabled
    public static void deleteOrderProduct(Id orderProductId) {

        if (!Schema.SObjectType.OrderItem.isDeletable()) {
            throw new SecurityException('Insufficient permissions to delete order products!');
        }
        OrderItem item = new OrderItem(Id = orderProductId);
        delete item;
    }

    /**
     * @description Save Order Product after its transformed into an OrderItem
     * @param record OrderProductListItem data transfer object
     *
     * @return the updated order
     */
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

    /**
     * @description Returns a list of OrderProducts of a specific order
     * @param orderId Order to get the OrderItems (Order Products) from
     *
     * @return a list of OrderProductListItem data transfer objects
     */
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

    /**
     * @description Mapper method to map an OrderItem record to a OrderProductListItem data transfer object
     * @param record OrderItem to map
     *
     * @return a OrderProductListItem data transfer object
     */
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

    /**
     * @description Mapper method to map a OrderProductListItem data transfer object to an OrderItem
     * @param listItem OrderProductListItem to map
     *
     * @return a OrderItem SObject
     */
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
