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
                ContractTerm = 12,
                Status = KPNConstants.CONTRACT_STATUS_DRAFT
            ));
        }
        return contracts;
    }

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
