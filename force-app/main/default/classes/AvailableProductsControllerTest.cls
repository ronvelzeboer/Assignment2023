/**
 * @author Ron Velzeboer
 * @date 15/09/2023
 * @description Test class for the AvailableProductsController class
 */
@IsTest(SeeAllData=false)
private class AvailableProductsControllerTest {

    /**
     * @description Setup shared test data using the TestDataFactory
     */
    @TestSetup
    static void setup() {
        // get standardPriceBookId
        Id standardPricebookId = Test.getStandardPricebookId();

        // create products
        List<Product2> productRecords = TestDataFactory.getProductTestRecords(10);
        insert productRecords;

        // create test pricebook entries
        List<PricebookEntry> pricebookEntryRecords = TestDataFactory.getPricebookEntryTestRecords(
            standardPricebookId, productRecords, 5
        );
        insert pricebookEntryRecords;
    }


    /**
     * @description Tests the getProductListItemsByPricebookId method if it returns the desired number of records
     */
    @IsTest
    public static void testGetProductListItemsByPricebookId() {
        // get standardPriceBookId
        Id standardPricebookId = Test.getStandardPricebookId();

        // get product list items
        List<AvailableProductsController.ProductListItem> productListItems = AvailableProductsController.getProductListItemsByPricebookId(standardPricebookId, 5);

        // Verify expected count
        System.assertEquals(5, productListItems.size());
    }
}
