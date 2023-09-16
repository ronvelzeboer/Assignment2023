/**
 * Created by user on 9/16/23.
 */

@IsTest(SeeAllData=false)
private class OrderConfirmationGatewayTest {
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

    @IsTest
    static void testRegisterOrder() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MockOrderConfirmationResponse200');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'plain/text');

        Test.setMock(HttpCalloutMock.class, mock);

        // get test Order Id
        Order testOrder = [SELECT Id, Status, OrderNumber, Account.AccountNumber FROM Order LIMIT 1][0];
        testOrder.Status = KPNConstants.ORDER_STATUS_ACTIVATED;
        update testOrder;

        // verify order confirmation queue is empty
        List<OrderConfirmationQueue__c> emptyQueueItems = [SELECT Id FROM OrderConfirmationQueue__c LIMIT 1];
        System.assertEquals(0, emptyQueueItems.size());

        // create product data reduce set to verify against
        List<OrderItem> items = [
                SELECT Id, PricebookEntryId, Product2.Name, Product2.ProductCode, Quantity, UnitPrice, TotalPrice, Status__c
                FROM OrderItem
                WHERE OrderId = :testOrder.Id
        ];
        Set<String> orderProductReduce = new Set<String>();
        for (OrderItem item : items) {
            orderProductReduce.add(
                item.Product2.Name + '|' + item.Product2.ProductCode + '|' + item.UnitPrice + '|' + Integer.valueOf(item.Quantity)
            );
        }

        Test.startTest();
        OrderConfirmationGateway.registerOrder(testOrder.Id);
        Test.stopTest();

        // verify queue item field data
        List<OrderConfirmationQueue__c> queueItems = [SELECT Id, Order__c, Status__c, Data__c FROM OrderConfirmationQueue__c ];
        System.assertEquals(1, queueItems.size());

        System.assert(queueItems[0].Data__c.length() > 0);
        System.assertEquals(testOrder.Id, queueItems[0].Order__c);
        System.assertEquals(KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW, queueItems[0].Status__c);

        // verify json data
        OrderConfirmation dataStructure = OrderConfirmation.deserialize(queueItems[0].Data__c);

        System.assertEquals(testOrder.OrderNumber, dataStructure.orderNumber);
        System.assertEquals(testOrder.Account.AccountNumber, dataStructure.accountNumber);

        System.assertEquals(items.size(), dataStructure.orderProducts.size());
        for (OrderConfirmation.OrderProduct dataProduct : dataStructure.orderProducts) {
            String reduceKey = dataProduct.name + '|' + dataProduct.code + '|' + dataProduct.unitPrice + '|' + dataProduct.quantity;

            System.assert(orderProductReduce.contains(reduceKey));
        }
    }
}
