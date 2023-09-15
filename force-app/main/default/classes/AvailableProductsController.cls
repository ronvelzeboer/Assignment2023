/**
 * Created by user on 9/15/23.
 */

public with sharing class AvailableProductsController {
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

    public static ProductListItem getMappedProductListItem(PricebookEntry record) {
        ProductListItem listItem = new ProductListItem();
        listItem.pricebookEntryId = record.Id;
        listItem.productId = record.Product2Id;
        listItem.unitPrice = record.UnitPrice;
        listItem.productName = record.Product2.Name;
        return listItem;
    }
}
