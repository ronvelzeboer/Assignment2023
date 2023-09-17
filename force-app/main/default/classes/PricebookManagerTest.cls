/**
 * @author Ron Velzeboer
 * @date 15/09/2023
 * @description Test class of the PricebookManager class
 */
@IsTest(SeeAllData=false)
private class PricebookManagerTest {

    /**
     * Setup shared test data
     */
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

    /**
     * @description Test the getEntriesByPricebookId method. Verifies if the correct number of records are returned
     */
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

