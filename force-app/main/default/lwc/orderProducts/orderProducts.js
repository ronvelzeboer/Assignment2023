/**
 * @author Ron Velzeboer
 * @date 12/09/2023
 */
 /** Standard **/
import { LightningElement, wire, api, track } from 'lwc';
import { subscribe, publish, MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';

/** MessageChannels **/
import RowDeletedChannel from '@salesforce/messageChannel/OrderProduct_RowDeleted__c';
import AvailableProductRowSelectedChannel from '@salesforce/messageChannel/AvailableProduct_RowSelected__c';

/** RPC **/
import saveOrderProduct from '@salesforce/apex/OrderProductsController.saveOrderProduct';
import deleteOrderProduct from '@salesforce/apex/OrderProductsController.deleteOrderProduct';
import activateOrder from '@salesforce/apex/OrderProductsController.activateOrder';
import getOrderProductListItems from '@salesforce/apex/OrderProductsController.getOrderProductListItemsByOrderId';

/** Labels **/
import Label_Title from '@salesforce/label/c.OrderProducts_Title';
import Label_Button_Activate from '@salesforce/label/c.OrderProducts_Button_Activate';
import Label_TableHeader_Name from '@salesforce/label/c.OrderProducts_TableHeader_Name';
import Label_TableHeader_UnitPrice from '@salesforce/label/c.OrderProducts_TableHeader_UnitPrice';
import Label_TableHeader_Quantity from '@salesforce/label/c.OrderProducts_TableHeader_Quantity';
import Label_TableHeader_TotalPrice from '@salesforce/label/c.OrderProducts_TableHeader_TotalPrice';
import Label_TableHeader_Status from '@salesforce/label/c.OrderProducts_TableHeader_Status';
import Label_Toast_Error_Unexpected_Error from '@salesforce/label/c.Generic_Toast_Error_Unexpected_Error';
import Label_Toast_Order_Product_Deleted from '@salesforce/label/c.OrderProducts_Toast_Order_Product_Deleted';
import Label_Toast_Order_Product_Saved from '@salesforce/label/c.OrderProducts_Toast_Order_Product_Saved';
import Label_Toast_Error_Order_Product_Not_Deleted from '@salesforce/label/c.OrderProducts_Toast_Error_Order_Product_Not_Deleted';
import Label_Toast_Error_Order_Product_Not_Saved from '@salesforce/label/c.OrderProducts_Toast_Error_Order_Product_Not_Saved';
import Label_Toast_Error_ReadOnly_Mode from '@salesforce/label/c.OrderProducts_Toast_Error_ReadOnly_Mode';
import Label_Toast_Order_Activated from '@salesforce/label/c.OrderProducts_Toast_Order_Activated';
import Label_Toast_Error_Unable_To_Activate_Order from '@salesforce/label/c.OrderProducts_Toast_Error_Unable_To_Activate_Order';
import Label_Dialog_Confirm_Activate_Order from '@salesforce/label/c.OrderProducts_Dialog_Confirm_Activate_Order';

export default class OrderProducts extends LightningElement {
    @api recordId;
    @track orderStatus;
    @track orderProducts = [];

    subscription = null;

    labels = {
        Label_Button_Activate,
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
    ];

    @wire(MessageContext)
    messageContext;

    @wire(getOrderProductListItems, { orderId: '$recordId' })
    wiredOrderProducts({ data, error }) {
        if (data) {
            this.orderProducts = data;
        } else if (error) {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log('Error:' + JSON.stringify(error));
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Order.Status' ] })
    wiredOrder({ data, error }) {
        if (data) {
            this.orderStatus = getFieldValue(data, 'Order.Status');

        } else if (error) {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log(error);
        }
    }

    get isActivateBtnDisabled() {
        return this.orderProducts.length === 0 || this.isActivatedOrder();
    }

   isActivatedOrder() {
        return this.orderStatus === 'Activated';
    }

    subscribeToAvailableProductChannel() {
        this.subscription = subscribe(this.messageContext, AvailableProductRowSelectedChannel, (message) => this.handleMessage(message));
    }

    handleMessage(message) {
        if (this.isActivatedOrder()) { this.showToastMessage(Label_Toast_Error_ReadOnly_Mode, 'info'); return; }

        if (!message.pricebookEntryId || !message.productName || !message.unitPrice) {
            console.log('Missing required keys in message format' + JSON.stringify(message, null, 4));
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            return;
        }
        this.addOrderProduct(message);
    }

    handleActivateBtnClick(event) {
        if (this.isActivatedOrder()) { return; }

        LightningConfirm.open({
            message: Label_Dialog_Confirm_Activate_Order,
            variant: 'header',
            label: '',
            theme: 'warning',
        }).then((result) => {
            if (result) {
                this.doActivateOrder();
            }
        });
    }

    doActivateOrder() {
        activateOrder({ orderId: this.recordId }).then((result) => {
            this.orderStatus = 'Activated';
            this.showToastMessage(Label_Toast_Order_Activated, 'success');
            this.dispatchEvent(new RefreshEvent());
        }).catch((error) => {
            this.showToastMessage(Label_Toast_Error_Unable_To_Activate_Order, 'error');
            console.log('Activation failed: ' + JSON.stringify(error, null, 4));
        });
    }

    handleRowAction(event) {
        if (this.isActivatedOrder()) { this.showToastMessage(Label_Toast_Error_ReadOnly_Mode, 'info'); return; }

        try {
            const eventAction = event.detail.action.name;

            if (eventAction == 'delete') {
                this.deleteRowAction(event);
            }
        } catch (error) {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log('An error occurred while processing the row action event. Error: ' + error.message);
        }
    }

    deleteRowAction(event) {
        const selectedOrderProduct = event.detail.row;

        if (selectedOrderProduct) {
            deleteOrderProduct( { orderProductId : selectedOrderProduct.orderItemId }).then((result) => {
                this.deleteOrderProductFromListData(selectedOrderProduct);
                this.publishToRowDeletedChannel(selectedOrderProduct);

                this.showToastMessage(Label_Toast_Order_Product_Deleted.replace('%ProductName%', selectedOrderProduct.productName), 'success');
            }).catch((error) => {
                this.showToastMessage(Label_Toast_Error_Order_Product_Not_Deleted.replace('%ProductName%', selectedOrderProduct.productName), 'error');
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

    addOrderProduct(data) {
        this.addOrderProductToList(data);
        this.handleSaveOrderProduct(data.pricebookEntryId);
    }

    addOrderProductToList(data) {
        const recordIndex = this.orderProducts.findIndex((obj) => obj.pricebookEntryId == data.pricebookEntryId);

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
            // clone record to avoid readonly issues
            const existingRecord = Object.assign({}, this.orderProducts[recordIndex]);

            existingRecord.quantity += data.quantity;
            existingRecord.totalPrice = existingRecord.quantity * existingRecord.unitPrice;

            this.orderProducts = this.orderProducts.map((obj, index) => {
                if (index == recordIndex) {
                    obj = existingRecord;
                }
                return obj;
            })
        }
    }

    handleSaveOrderProduct(pricebookEntryId) {
        const orderProductListItem = this.orderProducts.find((obj) => obj.pricebookEntryId == pricebookEntryId);
        const isNewListItem = orderProductListItem.orderItemId.startsWith('TMP-') ? true : false;

        const orderProductRecord = {
            orderItemId: (isNewListItem ? null : orderProductListItem.orderItemId),
            orderId: this.recordId,
            pricebookEntryId: orderProductListItem.pricebookEntryId,
            unitPrice: orderProductListItem.unitPrice,
            quantity: orderProductListItem.quantity,
        }
        saveOrderProduct( { record: orderProductRecord }).then((result) => {
            this.orderProducts = this.orderProducts.map((obj) => {
                if (obj.pricebookEntryId === pricebookEntryId) {
                    obj.orderItemId = result.orderItemId;
                }
                return obj;
            });
            if (isNewListItem) {
                this.showToastMessage(Label_Toast_Order_Product_Saved.replace('%ProductName%', orderProductListItem.productName), 'success');
            }
        }).catch((error) => {
           this.showToastMessage(Label_Toast_Error_Order_Product_Not_Saved.replace('%ProductName%', orderProductListItem.productName), 'error');
        });

    }

    showToastMessage(message, variant='info', title='') {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        })
        this.dispatchEvent(evt);
    }

    connectedCallback() {
        this.subscribeToAvailableProductChannel();
    }
}
