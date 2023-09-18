# Assignment Notes

Welcome to my assignment implementation! This page describes the installation/deployment and other handy information. I also included a short design decision section and improvement points.

## 1) Deployment / Installation Instructions
(In case the deployment is failing, I recorded a demo video which can be found [here](_demoVideo/AssignmentDemo.mp4))

- Deploy to ORG with SFDX (see instructions below)
- Activate Order Flexi page as ORG Default (see instructions below)
- Assign 'RVAssignment' Permission Set to the user

### 1.1) Deploy Salesforce DX Project

#### Authorize ORG
```
sfdx org login web --instance-url YOURORGURL --alias ORGALIAS
```

#### Deploy metadata
```
sfdx project deploy start --target-org ORGALIAS --source-dir force-app --ignore-conflicts --wait 90 --test-level RunAllTestsInOrg
```

### 1.2) Activate Order Flexi Page as ORG Default
- Goto Setup -> Lightning App Builder
- Click Edit for 'Order_Record_Page'
- Press 'Activation...' and click 'Assign as Org Default'
- Click 'Next' and then 'Save'

## 2) Test Notes


### 2.1) Trigger Order Confirmation Batch (Anonymous Apex)
After the order has been activated a OrderConfirmationQueue__c records is created. Execute below code in Anonymous Apex to process the Order Confirmation Queue Item. 

To view to message deliver to the external system, please go to order confirmation endpoint location: [https://rvkpnassignment.requestcatcher.com](https://rvkpnassignment.requestcatcher.com)

After you opened above endpoint location please execute:

```
OrderConfirmationQueueJob job = new OrderConfirmationQueueJob();
Database.executeBatch(job, 10);
```

## 3) Design choices

### 3.1) Generic choices
- loosely coupled data structures (data transfer objects) to communicate between "components".

### 3.2) Available Products Module
- Hardcoded limit of 500 records for now. Desired solution for dealing with large data volumes should be discussed with the customer. TODO: Create a separate userstory for this to keep current userstory small. 
- Weighted sorting mechanism implement to have the benefits of sorting while selected products are "locked" at the top

### 3.3) Order Products 
- Implemented missing Acceptance Criteria: Remove option (required in case of mistake). Need to discuss this in our next meeting with the customer (when the customer is back from holiday), but this definitively needs to be added in my opinion.


### 3.4) Order Confirmation functionality
- Build in Retry mechanism in case Order Confirmation could not be delivered. It allows for a configurable MaxDeliveryAttempts__c, after this is reached it will set a "FAIL" status on the OrderConfirmationQueue item and on the Order.OrderConfirmationStatus__c. The record stays in the queue but will not be picked up anymore. Normally, It would probably be better to implement an API layer in between Salesforce and the external system, which is better suited for this. In that case Salesforce can do a 'fire-and-forget' approach and gets a callback by the API layer with a status update.
- It was just fun building something like this in Salesforce, as I wanted to ace the extra requirement point 2 :wink:  

## 4) Improvement List

- Search bar in Available Products LWC component
- Maybe add a scrollbar for Order Products List 

