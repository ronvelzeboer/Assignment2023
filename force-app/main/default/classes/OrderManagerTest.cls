/**
 * Created by user on 9/15/23.
 */

@IsTest(SeeAllData=false)
private class OrderManagerTest {

    @TestSetup
    static void setup() {
        // get standardPriceBookId
        Id standardPricebookId = Test.getStandardPricebookId();

        // create test Pricebook Entries
        List<Product2> productRecords = TestDataFactory.getProductTestRecords(5);
        insert productRecords;

        List<PricebookEntry> pricebookEntries = TestDataFactory.getPricebookEntryTestRecords(
            standardPricebookId, productRecords, 5
        );
        insert pricebookEntries;

        // create test Account
        Account testAccount = TestDataFactory.getAccountRecords(1)[0];
        insert testAccount;

        // create test Contract and active
        Contract testContract = TestDataFactory.getContractTestRecords(testAccount, 1)[0];
        insert testContract;

        testContract.Status = KPNConstants.CONTRACT_STATUS_ACTIVATED;
        update testContract;

        // create test Order
        Order testOrderRecord = TestDataFactory.getOrderTestRecords(testAccount, testContract, standardPricebookId, 1)[0];
        insert testOrderRecord;

        // create test OrderItems
        List<OrderItem> orderItemRecords = TestDataFactory.getOrderItemTestRecords(testOrderRecord.Id, pricebookEntries, 3);
        insert orderItemRecords;
    }

    @IsTest
    public static void testActivateOrderByOrderId() {
        // get test data
        Order testOrder = [SELECT Id, Status FROM Order LIMIT 1];

        // verify order is not yet activated
        System.assertNotEquals(KPNConstants.ORDER_STATUS_ACTIVATED, testOrder.Status);

        // activate the order
        Test.startTest();
        OrderManager.activateOrderByOrderId(testOrder.Id);
        Test.stopTest();

        // verify order is activated
        testOrder = [SELECT Id, Status FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals(KPNConstants.ORDER_STATUS_ACTIVATED, testOrder.Status);
    }
}

