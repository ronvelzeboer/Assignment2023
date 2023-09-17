/**
 * @author Ron Velzeboer
 * @date 12/09/2023
 * @description Class which handles the database interactions for the PricebookEntry
 */
public with sharing class PricebookManager {

    /**
     * @description Get a limited number of PricebookEntries linked to a specific Pricebook
     * @param pricebookId Pricebook to get the PricebookEntries of
     * @param recordLimit Maximum number of records returned
     *
     * @return a list of PricebookEntries
     */
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
