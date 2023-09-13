/**
 * Created by user on 9/12/23.
 */

import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex'
import getProductListItems from '@salesforce/apex/PricebookManager.getProductListItemsByPricebookId';
import { publish, MessageContext } from 'lightning/messageService';
import RowSelectedChannel from '@salesforce/messageChannel/AvailableProduct_RowSelected__c';
import { loadStyle } from 'lightning/platformResourceLoader';
import stylesheets from '@salesforce/resourceUrl/stylesheets';

import Label_Title from '@salesforce/label/c.AvailableProducts_Title';
import Label_TableHeader_Name from '@salesforce/label/c.AvailableProducts_TableHeader_Name';
import Label_TableHeader_ListPrice from '@salesforce/label/c.AvailableProducts_TableHeader_ListPrice';

export default class AvailableProducts extends LightningElement {
    @api recordId;
    @track selectedPricebookId;
    @track productListItems = [];
    @track sortedBy = 'productName';
    @track sortedDirection = 'asc';
    cssLoaded = false;

    assignedOrderProductMap = {};

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Order.Pricebook2Id' ] })
    wiredOrder({ data, error }) {
        if (data) {
            this.selectedPricebookId = getFieldValue(data, 'Order.Pricebook2Id');

        } else if (error) {
            console.log(error);
        }
    }

    @wire(getProductListItems, { pricebookId: '$selectedPricebookId', recordLimit: '200'})
    wiredProductListItems({ error, data }) {
        console.log('wiredProductListItems => ' + data);
        if (data) {
            this.productListItems = data;
            this.doSortProducts();
        } else if (error) {
            console.log(error);
            this.productListItems = [];
        }
    }

    labels = {
        Label_Title,
        Label_TableHeader_Name,
        Label_TableHeader_ListPrice,
    }

    columnConfig = [
        {
            type: 'button-icon',
            fixedWidth: 36,
            typeAttributes: {
                iconName: 'utility:add',
                variant: 'bare'
            },
            cellAttributes: { class: { fieldName: 'backgroundStyle' } }
        },
        { label: this.labels.Label_TableHeader_Name, fieldName: "productName", type: 'text', sortable: 'true', cellAttributes: { class: { fieldName: 'backgroundStyle' } } },
        { label: this.labels.Label_TableHeader_ListPrice, fieldName: "productListPrice", type: 'currency', sortable: 'true', cellAttributes: { class: { fieldName: 'backgroundStyle' } } },

    ];

    handleClickAction(event) {
       const selectedProduct = event.detail.row;

        if (selectedProduct) {
            let productId = selectedProduct.productId;

            if (!this.assignedOrderProductMap[productId]) {
                this.assignedOrderProductMap[productId] = {
                    productId: productId, productName: selectedProduct.productName, productListPrice: selectedProduct.productListPrice
                };
                this.doSortProducts();
            }
            const messagePayload = {
                recordId: productId,
                productName: selectedProduct.productName,
                productListPrice: selectedProduct.productListPrice,
                quantity: 1
            };
            publish(this.messageContext, RowSelectedChannel, messagePayload);
        }
    }

    sortProducts(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.doSortProducts();
    }

    doSortProducts() {
        let numberOfListProducts = this.productListItems.length;
        let parseData = JSON.parse(JSON.stringify(this.productListItems));

        let keyValue = (x) => {
            return x[this.sortedBy].toLowerCase();
        };
        let isReverseSort = this.sortedDirection === 'asc' ? 1 : -1;

        // Do sort as normal
        parseData.sort((a, b) => {
            return isReverseSort * ((keyValue(a) > keyValue(b)) - (keyValue(b) > keyValue(a)));
        });

        // Add weighted sort to product assigned to the order so they appear on top while incorporating the normal sort functionality
        parseData.map((e, index) => {
            e.sortWeight = (numberOfListProducts - index);

            if (this.assignedOrderProductMap[e.productId]) {
                e.sortWeight += numberOfListProducts;
                e.backgroundStyle = 'datatable-assigned-row';
            }
        });

        // Re-sort based on weighted sort, descending order, so highest weighted product is on top
        parseData.sort((a, b) => {
            return -1 * ((a['sortWeight'] > b['sortWeight']) - (b['sortWeight'] > a['sortWeight']));
        });

        this.productListItems = parseData;
        console.log(JSON.stringify(this.productListItems, null, 4));
    }

    renderedCallback() {
        if (this.cssLoaded) {
            return;
        }
        this.cssLoaded = true;

        loadStyle(this, stylesheets + '/global.css').then(() => {
            console.log("Styles loaded");
        }).catch(error => {
            console.log(error);
        });
    }
}
