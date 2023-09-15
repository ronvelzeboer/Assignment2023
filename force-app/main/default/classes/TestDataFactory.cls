/**
 * Created by user on 9/15/23.
 */

@IsTest
public class TestDataFactory {
    public static List<Account> getAccountRecords(Integer numRecords) {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < numRecords; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        return accounts;
    }

    public static List<Contract> getContractTestRecords(Account account, Integer numRecords) {
        List<Contract> contracts = new List<Contract>();

        for (Integer i = 0; i < numRecords; i++) {
            contracts.add(new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                Status = 'Draft'
            ));
        }
        return contracts;
    }

    public static List<Order> getOrderTestRecords(Account account, Contract contract, Integer numRecords) {
        List<Order> orders = new List<Order>();

        for (Integer i = 0; i < numRecords; i++) {
            orders.add(new Order(
                Status = KPNConstants.ORDER_STATUS_DRAFT,
                EffectiveDate = Date.today(),
                AccountId = account.Id,
                ContractId = contract.Id
            ));
        }
        return orders;
    }

    public static List<OrderItem> getOrderItemsTestRecords(Id orderId, Integer numRecords, List<PricebookEntry> pricebookEntryPool) {
        List<OrderItem> orderItems = new List<OrderItem>();

        if (pricebookEntryPool.size() < numRecords) {
            throw new IllegalArgumentException('pricebookEntryPool: list must have at least ' + numRecords + ' records.');
        }
        for (Integer i = 0; i < numRecords; i++) {
            orderItems.add(new OrderItem(
                OrderId = orderId,
                PricebookEntryId = pricebookEntryPool[i].Id,
                Status__c = KPNConstants.ORDER_ITEM_STATUS_DRAFT,
                UnitPrice = pricebookEntryPool[i].UnitPrice,
                Quantity = 1
            ));
        }
        return orderItems;
    }

    public static Pricebook2 getPricebookTestRecord() {
        return new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            Description = 'The Hitchhikers Price Guide to the Galaxy'
        );
    }

    public static List<PricebookEntry> getPricebookEntryTestRecords(Id pricebookId, Integer numRecords, List<Product2> productPool) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        if (productPool.size() < numRecords) {
            throw new IllegalArgumentException('productPool: list must have at least ' + numRecords + ' records.');
        }
        for (Integer i = 0; i < numRecords; i++) {
            pricebookEntries.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                UnitPrice = 42.00 + (i * 13),
                Product2Id = productPool[i].Id
            ));
        }
        return pricebookEntries;
    }

    public static List<Product2> getProductTestRecords(Integer numRecords) {
        List<Product2> products = new List<Product2>();

        for (Integer i = 0; i < numRecords; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                IsActive = true,
                ProductCode = 'TestProductCode' + i
            ));
        }
        return products;
    }
}
