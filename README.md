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

## Improvement List

- Search bar in Available Products LWC component

