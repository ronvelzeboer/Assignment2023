/**
 * Created by user on 9/12/23.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import AvailableProductRowSelectedChannel from '@salesforce/messageChannel/AvailableProduct_RowSelected__c';

import Label_Title from '@salesforce/label/c.OrderProducts_Title';
import Label_TableHeader_Name from '@salesforce/label/c.OrderProducts_TableHeader_Name';
import Label_TableHeader_UnitPrice from '@salesforce/label/c.OrderProducts_TableHeader_UnitPrice';
import Label_TableHeader_Quantity from '@salesforce/label/c.OrderProducts_TableHeader_Quantity';
import Label_TableHeader_TotalPrice from '@salesforce/label/c.OrderProducts_TableHeader_TotalPrice';

export default class OrderProducts extends LightningElement {
    @api recordId;
    @track orderProducts = [];

    @wire(MessageContext)
    messageContext;

    subscription = null;

    labels = {
        Label_Title,
        Label_TableHeader_Name,
        Label_TableHeader_UnitPrice,
        Label_TableHeader_Quantity,
        Label_TableHeader_TotalPrice,
    }

    columnConfig = [
        {
            type: 'button-icon',
            fixedWidth: 36,
            typeAttributes: {
                iconName: 'utility:remove',
                variant: 'bare'
            }
        },
        { label: this.labels.Label_TableHeader_Name, fieldName: "productName", type: 'text'},
        { label: this.labels.Label_TableHeader_UnitPrice, fieldName: "productListPrice", type: 'currency' },
        { label: this.labels.Label_TableHeader_Quantity, fieldName: "productQuantity", type: 'integer' },
        { label: this.labels.Label_TableHeader_TotalPrice, fieldName: "totalPrice", type: 'currency' },
    ];

    subscribeToAvailableProductChannel() {
        this.subscription = subscribe(this.messageContext, AvailableProductRowSelectedChannel, (message) => this.handleMessage(message));
    }

    handleMessage(message) {
        console.log('OrderProducts => Add product: ', message);
    }

    connectedCallback() {
        this.subscribeToAvailableProductChannel();
    }
}
