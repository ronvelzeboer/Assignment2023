/**
 * Created by user on 9/12/23.
 */

public with sharing class PricebookManager {
    public class ProductListItem {
        @AuraEnabled
        public String pricebookEntryId;

        @AuraEnabled
        public String productId;

        @AuraEnabled
        public String productName;

        @AuraEnabled
        public Decimal unitPrice;
    }

    public static Integer getNumberOfEntriesByPricebookId(Id pricebookId) {
        // TODO: implement
        return 200;
    }

    public static List<PricebookEntry> getEntriesByPricebookId(Id pricebookId, Integer recordLimit) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        try {
            pricebookEntries = [
                SELECT Id, Product2.Name, UnitPrice, Product2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebookId
                LIMIT :recordLimit
            ];
        } catch (Exception e) {
            // TODO: implement error handling code
        }
        return pricebookEntries;
    }

    @AuraEnabled(Cacheable=true)
    public static List<ProductListItem> getProductListItemsByPricebookId(Id pricebookId, Integer recordLimit) {
        List<PricebookEntry> pricebookEntries = getEntriesByPricebookId(pricebookId, recordLimit);
        List<ProductListItem> listItems = new List<ProductListItem>();

        for (PricebookEntry entry : pricebookEntries) {
            ProductListItem pli = new ProductListItem();
            pli.pricebookEntryId = entry.Id;
            pli.productId = entry.Product2Id;
            pli.unitPrice = entry.UnitPrice;
            pli.productName = entry.Product2.Name;
            listItems.add(pli);
        }
        return listItems;
    }
}
