/**
 * Created by user on 9/12/23.
 */

public with sharing class PricebookManager {


//    public static Integer getNumberOfEntriesByPricebookId(Id pricebookId) {
//        // TODO: implement
//        return 200;
//    }

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


}
