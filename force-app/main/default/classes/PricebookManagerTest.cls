/**
 * Created by user on 9/15/23.
 */

@IsTest(SeeAllData=false)
private class PricebookManagerTest {

    @TestSetup
    static void setup() {
        // get standardPriceBookId
        Id standardPricebookId = Test.getStandardPricebookId();

        // create test Products
        List<Product2> productRecords = TestDataFactory.getProductTestRecords(5);
        insert productRecords;

        // create test Pricebook Entries
        List<PricebookEntry> pricebookEntryRecords = TestDataFactory.getPricebookEntryTestRecords(
            standardPricebookId, productRecords, 5
        );
        insert pricebookEntryRecords;
    }

    @IsTest
    public static void testGetEntriesByPricebookId() {
        // get standardPriceBookId
        Id standardPricebookId = Test.getStandardPricebookId();

        // retrieve Pricebook Entries
        Test.startTest();
        List<PricebookEntry> entries = PricebookManager.getEntriesByPricebookId(standardPricebookId, 3);
        Test.stopTest();

        // verify retrieved entries match expected count
        System.assertEquals(3, entries.size());
    }
}

