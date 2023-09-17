/**
 * @author Ron Velzeboer
 * @data 15/09/2023
 * @description Test class for the OrderProductController class
 */
@IsTest(SeeAllData=false)
private class OrderProductsControllerTest {

    /**
     * @description Setup shared test data
     */
    @TestSetup
    static void setup() {
        // get standardPriceBookId
        Id standardPricebookId = Test.getStandardPricebookId();

        // create test Pricebook Entries
        List<Product2> productRecords = TestDataFactory.getProductTestRecords(10);
        insert productRecords;

        List<PricebookEntry> pricebookEntryRecords = TestDataFactory.getPricebookEntryTestRecords(
            standardPricebookId, productRecords, 10
        );
        insert pricebookEntryRecords;

        // create test Account
        Account testAccount = TestDataFactory.getAccountRecords(1)[0];
        insert testAccount;

        // create test Contract and activate
        Contract testContract = TestDataFactory.getContractTestRecords(testAccount, 1)[0];
        insert testContract;

        testContract.Status = KPNConstants.CONTRACT_STATUS_ACTIVATED;
        update testContract;

        // create test Order
        Order testOrder = TestDataFactory.getOrderTestRecords(testAccount, testContract, standardPricebookId, 1)[0];
        insert testOrder;

        // create test OrderItems
        List<OrderItem> orderItemRecords = TestDataFactory.getOrderItemTestRecords(testOrder.Id, pricebookEntryRecords, 5);
        insert orderItemRecords;
    }

    /**
     * @description Tests the activateOrder method. Verifies if Order status is set correctly
     */
    @IsTest
    public static void testActivateOrder() {
        // get test Order Id
        Id testOrderId = [SELECT Id FROM Order LIMIT 1].Id;

        // activate order
        Test.startTest();
        OrderProductsController.activateOrder(testOrderId);
        Test.stopTest();

        // verify order is activated
        Order activatedOrder = [SELECT Status FROM Order WHERE Id = :testOrderId LIMIT 1];
        System.assertEquals(KPNConstants.ORDER_STATUS_ACTIVATED, activatedOrder.Status);
    }

    /**
     * @description Test the deleteOrderProduct method and verifies if records get deleted successfully
     */
    @IsTest
    public static void testDeleteOrderProduct() {
        // get test Order Id
        Id testOrderId = [SELECT Id FROM Order LIMIT 1].Id;

        OrderItem testOrderItem = [SELECT Id FROM OrderItem WHERE OrderId = :testOrderId LIMIT 1][0];

        // delete order
        Test.startTest();
        OrderProductsController.deleteOrderProduct(testOrderItem.Id);
        Test.stopTest();

        // verify record is deleted
        List<OrderItem> deletedOrderItem = [SELECT Id FROM OrderItem WHERE Id = :testOrderItem.Id];
        System.assertEquals(0, deletedOrderItem.size());
    }

    /**
     * @description Tests the saveOrderProduct method. Verifies created OrderItem data
     */
    @IsTest
    public static void testSaveOrderProduct() {
        // get test Order Id
        Id testOrderId = [SELECT Id FROM Order LIMIT 1].Id;

        // get order
        List<OrderItem> testOrderItems = [SELECT PricebookEntryId FROM OrderItem WHERE OrderId = :testOrderId];

        // get used pricebookEntryIds for order
        Set<Id> usedPricebookEntryIds = new Set<Id>();
        for (OrderItem item : testOrderItems) {
            usedPricebookEntryIds.add(item.PricebookEntryId);
        }
        // get unused pricebookEntry
        PricebookEntry testPricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Id NOT IN :usedPricebookEntryIds LIMIT 1][0];

        // double verify chosen pricebookEntry is not linked to order
        List<OrderItem> nonExistingOrderItem = [SELECT Id FROM OrderItem WHERE PricebookEntryId = :testPricebookEntry.Id AND OrderId = :testOrderId];
        System.assertEquals(0, nonExistingOrderItem.size());

        // create order product list item
        OrderProductsController.OrderProductListItem listItem = new OrderProductsController.OrderProductListItem();
        listItem.orderItemId = null;
        listItem.orderId = testOrderId;
        listItem.pricebookEntryId = testPricebookEntry.Id;
        listItem.unitPrice = testPricebookEntry.UnitPrice;
        listItem.quantity = 3;

        // save order product
        Test.startTest();
        OrderProductsController.saveOrderProduct(listItem);
        Test.stopTest();

        // retrieve order item
        List<OrderItem> existingOrderItem = [
            SELECT Id, UnitPrice, Quantity FROM OrderItem WHERE PricebookEntryId = :testPricebookEntry.Id AND OrderId = :testOrderId
        ];

        // verify existence and values
        System.assertEquals(1, existingOrderItem.size());
        System.assertEquals(listItem.unitPrice, existingOrderItem[0].UnitPrice);
        System.assertEquals(listItem.quantity, existingOrderItem[0].Quantity);
    }

    /**
     * @description Tests the getOrderProductListItemsByOrderId method. Verifies if it retrieves the correct number of records
     */
    @IsTest
    public static void testGetOrderProductListItemsByOrderId() {
        // get test Order Id
        Id testOrderId = [SELECT Id FROM Order LIMIT 1].Id;

        // get orderProducts
        Test.startTest();
        List<OrderProductsController.OrderProductListItem> orderProducts = OrderProductsController.getOrderProductListItemsByOrderId(testOrderId);
        Test.stopTest();

        // verify retrieved order products count
        System.assertEquals(5, orderProducts.size());
    }
}

