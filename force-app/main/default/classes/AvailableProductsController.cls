/**
 * @author Ron Velzeboer
 * @date 15/09/2023
 * @description Controller for the LWC 'Available Products' component
 */
public with sharing class AvailableProductsController {
    /**
     * @description ProductListItem serves as an object to transfer data between the LWC frontend component and the
     * controller to loosely couple the frontend and the backed structure
     */
    public class ProductListItem {
        @AuraEnabled
        public String pricebookEntryId { get; private set; }

        @AuraEnabled
        public String productId { get; private set; }

        @AuraEnabled
        public String productName { get; private set; }

        @AuraEnabled
        public Decimal unitPrice { get; private set; }
    }

    /**
     * @description Returns a list of ProductListItems with a defined record limit
     * @param pricebookId PricebookId to get products from
     * @param recordLimit Maximum number of records returned
     *
     * @return List<ProductListItem>
     */
    @AuraEnabled(Cacheable=true)
    public static List<ProductListItem> getProductListItemsByPricebookId(Id pricebookId, Integer recordLimit) {
        List<PricebookEntry> pricebookEntries = PricebookManager.getEntriesByPricebookId(pricebookId, recordLimit);
        List<ProductListItem> listItems = new List<ProductListItem>();

        for (PricebookEntry record : pricebookEntries) {
            ProductListItem listItem = getMappedProductListItem(record);
            listItems.add(listItem);
        }
        return listItems;
    }

    /**
     * @description Returns a newly created ProductListItem object based on a provided PricebookEntry record
     * @param record PricebookEntry record to map
     *
     * @return ProductListItem
     */
    public static ProductListItem getMappedProductListItem(PricebookEntry record) {
        ProductListItem listItem = new ProductListItem();
        listItem.pricebookEntryId = record.Id;
        listItem.productId = record.Product2Id;
        listItem.unitPrice = record.UnitPrice;
        listItem.productName = record.Product2.Name;
        return listItem;
    }
}
