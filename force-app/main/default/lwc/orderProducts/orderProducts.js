/**
 * Created by user on 9/12/23.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { subscribe, publish, MessageContext } from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';
import AvailableProductRowSelectedChannel from '@salesforce/messageChannel/AvailableProduct_RowSelected__c';
import RowDeletedChannel from '@salesforce/messageChannel/OrderProduct_RowDeleted__c';
import saveOrderProduct from '@salesforce/apex/OrderProductsController.saveOrderProduct';
import deleteOrderProduct from '@salesforce/apex/OrderProductsController.deleteOrderProduct';
import getOrderProductListItems from '@salesforce/apex/OrderProductsController.getOrderProductListItemsByOrderId';

import Label_Title from '@salesforce/label/c.OrderProducts_Title';
import Label_TableHeader_Name from '@salesforce/label/c.OrderProducts_TableHeader_Name';
import Label_TableHeader_UnitPrice from '@salesforce/label/c.OrderProducts_TableHeader_UnitPrice';
import Label_TableHeader_Quantity from '@salesforce/label/c.OrderProducts_TableHeader_Quantity';
import Label_TableHeader_TotalPrice from '@salesforce/label/c.OrderProducts_TableHeader_TotalPrice';
import Label_TableHeader_Status from '@salesforce/label/c.OrderProducts_TableHeader_Status';

export default class OrderProducts extends LightningElement {
    @api recordId;
    @track orderProducts = [];

    subscription = null;

    labels = {
        Label_Title,
        Label_TableHeader_Name,
        Label_TableHeader_UnitPrice,
        Label_TableHeader_Quantity,
        Label_TableHeader_TotalPrice,
        Label_TableHeader_Status,
    }

    columnConfig = [
        {
            type: 'button-icon',
            fixedWidth: 36,
            typeAttributes: {
                iconName: 'utility:delete',
                variant: 'bare',
                name: 'delete'
            }
        },
        { label: this.labels.Label_TableHeader_Name, fieldName: "productName", type: 'text'},
        { label: this.labels.Label_TableHeader_UnitPrice, fieldName: "unitPrice", type: 'currency', fixedWidth: 125 },
        { label: this.labels.Label_TableHeader_Quantity, fieldName: "quantity", type: 'integer', fixedWidth: 100 },
        { label: this.labels.Label_TableHeader_TotalPrice, fieldName: "totalPrice", type: 'currency', fixedWidth: 125 },
        { label: this.labels.Label_TableHeader_Status, fieldName: "status", type: 'text', fixedWidth: 125 },
    ];

    @wire(MessageContext)
    messageContext;

    @wire(getOrderProductListItems, { orderId: '$recordId' })
    wiredOrderProducts({ data, error }) {
        if (data) {
//            console.log('Error:' + JSON.stringify(data, null, 4));
            this.orderProducts = data.map((obj) => {
                obj = {
                    orderItemId: obj.orderItemId,
                    pricebookEntryId: obj.pricebookEntryId,
                    productName: obj.productName,
                    unitPrice: obj.unitPrice,
                    quantity: obj.quantity,
                    totalPrice: obj.totalPrice,
                    status: obj.status,
                };
                return obj;
            })
        } else if (error) {
            console.log('Error:' + JSON.stringify(error));
            // TODO
        }
    }

    get isActivateBtnDisabled() {
        return this.orderProducts.length === 0;
    }

    subscribeToAvailableProductChannel() {
        this.subscription = subscribe(this.messageContext, AvailableProductRowSelectedChannel, (message) => this.handleMessage(message));
    }

    handleActivateBtnClick(event) {
        console.log('Activate Order and Order Products');
    }

    handleRowAction(event) {
        try {
            const eventAction = event.detail.action.name;

            if (eventAction == 'delete') {
                this.deleteRowAction(event);
            }
        } catch (error) {
            console.log('An error occurred while processing the row action event. Error: ' + error.message);
        }
    }

    deleteRowAction(event) {
        const selectedOrderProduct = event.detail.row;

        if (selectedOrderProduct) {
            deleteOrderProduct( { orderProductId : selectedOrderProduct.orderItemId }).then((result) => {
                this.deleteOrderProductFromListData(selectedOrderProduct);
                this.publishToRowDeletedChannel(selectedOrderProduct);
            }).catch((error) => {
                console.log(error);
            });
        }
    }

    deleteOrderProductFromListData(deletedOrderProduct) {
        this.orderProducts = this.orderProducts.filter((obj) => !(obj.orderItemId === deletedOrderProduct.orderItemId) );
    }

    publishToRowDeletedChannel(deletedOrderProduct) {
        const messagePayload = {
            orderItemId: deletedOrderProduct.orderItemId,
            pricebookEntryId: deletedOrderProduct.pricebookEntryId,
        };
        publish(this.messageContext, RowDeletedChannel, messagePayload);
    }

    handleMessage(message) {
        if (!message.pricebookEntryId || !message.productName || !message.unitPrice) {
            console.log('Missing required keys in message format' + JSON.stringify(message, null, 4));
            return;
        }
        this.addOrderProduct(message);
    }

    addOrderProduct(data) {
        this.addOrderProductToList(data);
        this.handleSaveOrderProduct(data.pricebookEntryId)
    }

    addOrderProductToList(data) {
        const recordIndex = this.orderProducts.findIndex((rec) => rec.pricebookEntryId == data.pricebookEntryId);

        if (recordIndex === -1) {
            const newRecord = {
                orderItemId: 'TMP-' + data.recordId,
                pricebookEntryId: data.pricebookEntryId,
                productName: data.productName,
                unitPrice: data.unitPrice,
                quantity: data.quantity,
                totalPrice: (data.unitPrice * data.quantity),
                status: '[Saving]',
            };

           this.orderProducts = [...this.orderProducts, newRecord];
        } else {
            const existingRecord = this.orderProducts[recordIndex];
            existingRecord.quantity += data.quantity;
            existingRecord.totalPrice = existingRecord.quantity * existingRecord.unitPrice;

            this.orderProducts = [...this.orderProducts];
        }
    }

    handleSaveOrderProduct(pricebookEntryId) {
        const orderProductListItem = this.orderProducts.find((obj) => obj.pricebookEntryId == pricebookEntryId);

        // TODO change to other object
        const orderProductRecord = {
            Id: (orderProductListItem.orderItemId.startsWith('TMP-') ? null : orderProductListItem.orderItemId),
            OrderId: this.recordId,
            PricebookEntryId: orderProductListItem.pricebookEntryId,
            ListPrice: orderProductListItem.unitPrice,
            UnitPrice: orderProductListItem.unitPrice,
            Quantity: orderProductListItem.quantity,
        }

        saveOrderProduct( { orderProduct: orderProductRecord }).then((result) => {
            this.orderProducts = this.orderProducts.map((obj) => {
                if (obj.pricebookEntryId === pricebookEntryId) {
                    obj.orderItemId = result.Id;
                    obj.status = result.Status;
                }
                return obj;
            });
        }).catch((error) => {
           console.log(error);
        });

    }

    connectedCallback() {
        this.subscribeToAvailableProductChannel();
    }
}
