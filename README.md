# Assignment Notes

Welcome!

## Deploy Salesforce DX Project

Authorize ORG
```
sfdx org login web --instance-url http://MyDomainName-SandboxName.sandbox.my.salesforce.com --alias ORGALIAS
```

Deploy metadata
```
sfdx project deploy start --target-org ORGALIAS --source-dir force-app --ignore-conflicts --wait 90 --test-level RunAllTestsInOrg
```
In case the deployment is failing, I record a video which can be found here: [ADD LINK]

## Trigger Order Confirmation Batch (Anonymous Apex)

```
OrderConfirmationQueueJob job = new OrderConfirmationQueueJob();
Database.executeBatch(job, 10);
```

## Design choices

### Generic choices
- loosely coupled data structures, made use of data transfer objects
-

### Available Products Module
- Hardcoded limit of 500 records for now. Desired solution for dealing with large data volumes should be discussed with the customer. TODO: Create a separate userstory for this to keep current userstory small. 
- Weighted sorting mechanism implement to have the benefits of sorting while selected products are "locked" at the top
-

### Order Products
- Implemented missing Acceptance Criteria: Remove option (required in case of mistake). Need to discuss this in our next meeting with the customer (when the customer is back from holiday), but this definitively needs to be added in my opinion. 
-

### Order Confirmation functionality
- Build in Retry mechanism in case Order Confirmation could not be delivered
- 

## Improvement List

- Search bar in Available Products LWC component
- Maybe add a scrollbar for Order Products List 
-
