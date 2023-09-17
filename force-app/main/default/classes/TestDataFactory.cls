/**
 * @author Ron Velzeboer
 * @date 15/09/2023
 * @description Class to create test data to avoid bloated test classes
 */
@IsTest
public class TestDataFactory {
    /**
     * @description Generates a number of unsaved test Accounts
     * @param numRecords Number a test Account records to create
     *
     * @return a list of test Account
     */
    public static List<Account> getAccountRecords(Integer numRecords) {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < numRecords; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        return accounts;
    }

    /**
     * @description Generates a number of unsaved test Contracts
     * @param account Account to link contract to
     * @param numRecords Number a test Contract records to create
     *
     * @return a list of test Contracts
     */
    public static List<Contract> getContractTestRecords(Account account, Integer numRecords) {
        List<Contract> contracts = new List<Contract>();

        for (Integer i = 0; i < numRecords; i++) {
            contracts.add(new Contract(
                AccountId = account.Id,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = KPNConstants.CONTRACT_STATUS_DRAFT
            ));
        }
        return contracts;
    }

    /**
     * @description Generates a number of unsaved test Orders
     * @param account Account to link order to
     * @param contract Contract to link order to
     * @param pricebookId Pricebook to link order to
     * @param numRecords Number a test Order records to create
     *
     * @return a list of test Orders
     */
    public static List<Order> getOrderTestRecords(Account account, Contract contract, Id pricebookId, Integer numRecords) {
        List<Order> orders = new List<Order>();

        for (Integer i = 0; i < numRecords; i++) {
            orders.add(new Order(
                Status = KPNConstants.ORDER_STATUS_DRAFT,
                EffectiveDate = Date.today(),
                AccountId = account.Id,
                ContractId = contract.Id,
                Pricebook2Id = pricebookId
            ));
        }
        return orders;
    }

    /**
     * @description Generates a number of unsaved test OrderItems
     * @param orderId order to link OrderItems to
     * @param pricebookEntryPool List of PricebookEntries as data input for the OrderItems
     * @param numRecords Number a test OrderItem records to create
     *
     * @return a list of test OrderItems
     */
    public static List<OrderItem> getOrderItemTestRecords(Id orderId, List<PricebookEntry> pricebookEntryPool, Integer numRecords) {
        List<OrderItem> orderItems = new List<OrderItem>();

        if (pricebookEntryPool.size() < numRecords) {
            throw new IllegalArgumentException('pricebookEntryPool: list must have at least ' + numRecords + ' records.');
        }
        for (Integer i = 0; i < numRecords; i++) {
            orderItems.add(new OrderItem(
                OrderId = orderId,
                PricebookEntryId = pricebookEntryPool[i].Id,
                UnitPrice = pricebookEntryPool[i].UnitPrice,
                Status__c = KPNConstants.ORDER_ITEM_STATUS_DRAFT,
                Quantity = 1
            ));
        }
        return orderItems;
    }

    /**
     * @description Generates a number of unsaved test PricebookEntries
     * @param pricebookId Account to link PricebookEntry to
     * @param productPool List of Products as data input for the PricebookEntries
     * @param numRecords Number a test PricebookEntry records to create
     *
     * @return a list of test PricebookEntries
     */
    public static List<PricebookEntry> getPricebookEntryTestRecords(Id pricebookId, List<Product2> productPool, Integer numRecords) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        if (productPool.size() < numRecords) {
            throw new IllegalArgumentException('productPool: list must have at least ' + numRecords + ' records.');
        }
        for (Integer i = 0; i < numRecords; i++) {
            pricebookEntries.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = productPool[i].Id,
                UnitPrice = 42.00 + (i * 13),
                IsActive = true
            ));
        }
        return pricebookEntries;
    }

    /**
     * @description Generates a number of unsaved test Product2 records
     * @param numRecords Number a test Product2 records to create
     *
     * @return a list of test Product2
     */
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

    /**
     * @description Generates a OrderConfirmationQueue__c record
     * @param order Order to use
     * @param orderItems OrderItem to use
     *
     * @return a OrderConfirmationQueue__c record
     */
    public static OrderConfirmationQueue__c getOrderConfirmationQueueTestRecord(Order order, List<OrderItem> orderItems) {
        OrderConfirmation data = new OrderConfirmation();
        data.accountNumber = order.Account.AccountNumber;
        data.orderNumber = order.OrderNumber;
        data.type = order.Type;
        data.status = order.Status;
        data.orderProducts = new List<OrderConfirmation.OrderProduct>();

        for (OrderItem orderItem : orderItems) {
            OrderConfirmation.OrderProduct orderProduct = new OrderConfirmation.OrderProduct();
            orderProduct.name = orderItem.Product2.Name;
            orderProduct.code = orderItem.Product2.ProductCode;
            orderProduct.unitPrice = orderItem.UnitPrice;
            orderProduct.quantity = Integer.valueOf(orderItem.Quantity);
            data.orderProducts.add(orderProduct);
        }
        String payload = OrderConfirmation.serialize(data);

        return new OrderConfirmationQueue__c(
            Order__c = order.Id,
            Status__c = KPNConstants.ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW,
            Data__c = payload
        );
    }
}
