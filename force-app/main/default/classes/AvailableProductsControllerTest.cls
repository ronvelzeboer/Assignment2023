/**
 * Created by user on 9/15/23.
 */

@IsTest(SeeAllData=false)
private class AvailableProductsControllerTest {

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
