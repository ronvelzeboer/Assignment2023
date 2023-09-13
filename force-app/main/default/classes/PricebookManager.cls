/**
 * Created by user on 9/12/23.
 */

public with sharing class PricebookManager {
    public class ProductListItem {
        @AuraEnabled
        public String productId;

        @AuraEnabled
        public String productName;

        @AuraEnabled
        public Decimal productListPrice;
    }

    public static Integer getNumberOfEntriesByPricebookId(Id pricebookId) {
        // TODO: implement
        return 200;
    }

    public static List<PricebookEntry> getEntriesByPricebookId(Id pricebookId, Integer recordLimit) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        try {
            pricebookEntries = [
                SELECT UnitPrice, Product2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebookId
                LIMIT :recordLimit
            ];
        } catch (Exception e) {
            // TODO: implement error handling code
        }
        return pricebookEntries;
    }

    public static List<Product2> getProductsByProductIds(List<Id> productIds) {
        List<Product2> products = new List<Product2>();

        try {
            products = [
                SELECT Id, Name
                FROM Product2
                WHERE Id IN :productIds
            ];
        } catch (Exception e) {
            // TODO: implement error handling code
        }
        return products;
    }

    @AuraEnabled(Cacheable=true)
    public static List<ProductListItem> getProductListItemsByPricebookId(Id pricebookId, Integer recordLimit) {
        List<PricebookEntry> pricebookEntries = getEntriesByPricebookId(pricebookId, recordLimit);
        List<Id> productIds = new List<Id>();
        Map<Id, ProductListItem> listItems = new Map<Id, ProductListItem>();

        for (PricebookEntry entry : pricebookEntries) {
            productIds.add(entry.Product2Id);

            ProductListItem pli = new ProductListItem();
            pli.productId = entry.Product2Id;
            pli.productListPrice = entry.UnitPrice;
            listItems.put(pli.productId, pli);
        }
        List<Product2> products = getProductsByProductIds(productIds);

        for (Product2 product : products) {
            listItems.get(product.Id).productName = product.Name;
        }
        return listItems.values();
    }
}
