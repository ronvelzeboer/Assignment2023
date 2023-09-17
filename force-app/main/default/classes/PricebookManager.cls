/**
 * Created by user on 9/12/23.
 */

public with sharing class PricebookManager {

    public static List<PricebookEntry> getEntriesByPricebookId(Id pricebookId, Integer recordLimit) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        pricebookEntries = [
            SELECT Id, Product2.Name, UnitPrice, Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
            LIMIT :recordLimit
        ];
        return pricebookEntries;
    }
}
