/**
 * @author Ron Velzeboer
 * @date 16/09/2023
 * @description Test class for the OrderConfirmationQueueJob class
 */
@IsTest(SeeAllData=false)
private class OrderConfirmationQueueJobTest {

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

        for (OrderItem orderItem : orderItemRecords) {
            orderItem.Status__c = KPNConstants.ORDER_ITEM_STATUS_ACTIVATED;
        }
        update orderItemRecords;

        // activate order and set OrderConfirmationStatus
        testOrder.Status = KPNConstants.ORDER_STATUS_ACTIVATED;
        testOrder.OrderConfirmationStatus__c = KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS;
        update testOrder;

        // create OrderConfirmationQueue__c, query order and orderItems related data
        Order orderWithRelatedData = [SELECT Id, Status, Account.AccountNumber, OrderNumber, Type FROM Order WHERE Id = :testOrder.Id LIMIT 1][0];

        List<OrderItem> orderItemsWithRelatedData = [
            SELECT Id, PricebookEntryId, Product2.Name, Product2.ProductCode, Quantity, UnitPrice, TotalPrice, Status__c
            FROM OrderItem
            WHERE OrderId = :testOrder.Id
        ];
        OrderConfirmationQueue__c queueItem = TestDataFactory.getOrderConfirmationQueueTestRecord(orderWithRelatedData, orderItemsWithRelatedData);
        insert queueItem;
    }

    /**
     * @description Tests scenario the order confirmation is send
     */
    @IsTest
    static void testOrderConfirmationDelivered() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockOrderConfirmationResponse' + KPNConstants.HTTP_STATUS_CODE_OK);
        mock.setStatusCode(KPNConstants.HTTP_STATUS_CODE_OK);
        mock.setHeader('Content-Type', 'plain/text');

        Test.setMock(HttpCalloutMock.class, mock);

        // get test Order Id
        Order testOrder = [SELECT Id, Status, OrderConfirmationStatus__c FROM Order LIMIT 1][0];

        // verify initial order state
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS, testOrder.OrderConfirmationStatus__c);

        // verify initial state of OrderConfirmationQueue__c record
        OrderConfirmationQueue__c queueItem = [SELECT Id, Status__c FROM OrderConfirmationQueue__c WHERE Order__c = :testOrder.Id][0];
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW, queueItem.Status__c);

        Test.startTest();
        OrderConfirmationQueueJob job = new OrderConfirmationQueueJob();
        Database.executeBatch(job, 10);
        Test.stopTest();

        // get test Order Id after batch job
        Order testOrderResultState = [SELECT Id, Status, OrderConfirmationStatus__c FROM Order LIMIT 1][0];

        // verify order confirmation status on order
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_STATUS_DELIVERED, testOrderResultState.OrderConfirmationStatus__c);

        // verify result state of OrderConfirmationQueue__c record
        OrderConfirmationQueue__c queueItemResultState = [SELECT Id, Status__c FROM OrderConfirmationQueue__c WHERE Order__c = :testOrder.Id][0];

        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_COMPLETED, queueItemResultState.Status__c);
    }

    @IsTest
    static void testOrderConfirmationRetry() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockOrderConfirmationResponse' + KPNConstants.HTTP_STATUS_CODE_INTERNAL_SERVER_ERROR);
        mock.setStatusCode(KPNConstants.HTTP_STATUS_CODE_INTERNAL_SERVER_ERROR);
        mock.setHeader('Content-Type', 'plain/text');

        Test.setMock(HttpCalloutMock.class, mock);

        // get test Order Id
        Order testOrder = [SELECT Id, Status, OrderConfirmationStatus__c FROM Order LIMIT 1][0];

        // verify initial order state
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS, testOrder.OrderConfirmationStatus__c);

        // verify initial state of OrderConfirmationQueue__c record
        OrderConfirmationQueue__c queueItem = [SELECT Id, Status__c, DeliveryAttemptCount__c FROM OrderConfirmationQueue__c WHERE Order__c = :testOrder.Id][0];
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW, queueItem.Status__c);
        System.assertEquals(0, queueItem.DeliveryAttemptCount__c);

        Test.startTest();
        OrderConfirmationQueueJob job = new OrderConfirmationQueueJob();
        Database.executeBatch(job, 10);
        Test.stopTest();

        // get test Order Id after batch job
        Order testOrderResultState = [SELECT Id, Status, OrderConfirmationStatus__c FROM Order LIMIT 1][0];

        // verify order confirmation status on order
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS, testOrderResultState.OrderConfirmationStatus__c);

        // verify result state of OrderConfirmationQueue__c record
        OrderConfirmationQueue__c queueItemResultState = [SELECT Id, Status__c, DeliveryAttemptCount__c FROM OrderConfirmationQueue__c WHERE Order__c = :testOrder.Id][0];

        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_RETRY, queueItemResultState.Status__c);
        System.assertEquals(1, queueItemResultState.DeliveryAttemptCount__c);
    }

    @IsTest
    static void testOrderConfirmationFailed() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockOrderConfirmationResponse500');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'plain/text');

        Test.setMock(HttpCalloutMock.class, mock);

        // get test Order Id
        Order testOrder = [SELECT Id, Status, OrderConfirmationStatus__c FROM Order LIMIT 1][0];

        // verify initial order state
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_STATUS_IN_PROGRESS, testOrder.OrderConfirmationStatus__c);

        // verify initial state of OrderConfirmationQueue__c record
        OrderConfirmationQueue__c queueItem = [SELECT Id, Status__c, DeliveryAttemptCount__c FROM OrderConfirmationQueue__c WHERE Order__c = :testOrder.Id][0];
        queueItem.DeliveryAttemptCount__c = 5; // TODO: do not hardcode limit
        queueItem.Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_RETRY;
        update queueItem;

        Test.startTest();
        OrderConfirmationQueueJob job = new OrderConfirmationQueueJob();
        Database.executeBatch(job, 10);
        Test.stopTest();

        // get test Order Id after batch job
        Order testOrderResultState = [SELECT Id, Status, OrderConfirmationStatus__c FROM Order LIMIT 1][0];

        // verify order confirmation status on order
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_STATUS_FAILED, testOrderResultState.OrderConfirmationStatus__c);

        // verify result state of OrderConfirmationQueue__c record
        OrderConfirmationQueue__c queueItemResultState = [SELECT Id, Status__c, DeliveryAttemptCount__c FROM OrderConfirmationQueue__c WHERE Order__c = :testOrder.Id][0];

        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_FAILED, queueItemResultState.Status__c);
    }
}
