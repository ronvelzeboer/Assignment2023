/**
 * @author Ron Velzeboer
 * @date 12/09/2023
 */
 /** Standard **/
import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex'
import stylesheets from '@salesforce/resourceUrl/stylesheets';

/** MessageChannels **/
import RowSelectedChannel from '@salesforce/messageChannel/AvailableProduct_RowSelected__c';
import OrderProductRowDeletedChannel from '@salesforce/messageChannel/OrderProduct_RowDeleted__c';

/** RPC **/
import getProductListItems from '@salesforce/apex/AvailableProductsController.getProductListItemsByPricebookId';
import getOrderProductListItems from '@salesforce/apex/OrderProductsController.getOrderProductListItemsByOrderId';

/** Labels **/
import Label_Title from '@salesforce/label/c.AvailableProducts_Title';
import Label_TableHeader_Name from '@salesforce/label/c.AvailableProducts_TableHeader_Name';
import Label_TableHeader_ListPrice from '@salesforce/label/c.AvailableProducts_TableHeader_ListPrice';
import Label_Toast_Error_Unexpected_Error from '@salesforce/label/c.Generic_Toast_Error_Unexpected_Error';


export default class AvailableProducts extends LightningElement {
    @api recordId;
    @track selectedPricebookId;
    @track productListItems = [];
    @track sortedBy = 'productName';
    @track sortedDirection = 'asc';

    // TODO: implement search functionality in case there are more then 500 records.
    maxRecordLimit = 500;
    cssLoaded = false;
    subscription = null;
    assignedOrderProductMap = {};

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
                variant: 'bare',
                name: 'add',
            },
            cellAttributes: { class: { fieldName: 'backgroundStyle' } }
        },
        { label: this.labels.Label_TableHeader_Name, fieldName: "productName", type: 'text', sortable: 'true', cellAttributes: { class: { fieldName: 'backgroundStyle' } } },
        { label: this.labels.Label_TableHeader_ListPrice, fieldName: "unitPrice", type: 'currency', sortable: 'true', fixedWidth: 125, cellAttributes: { class: { fieldName: 'backgroundStyle' } } },
    ];

    @wire(MessageContext)
    messageContext;

    @wire(getOrderProductListItems, { orderId: '$recordId' })
    wiredOrderProducts({ data, error } ) {
        if (data) {
            data.forEach((obj) => {
                this.assignedOrderProductMap[obj.pricebookEntryId] = {
                    pricebookEntryId: obj.pricebookEntryId,
                    productName: obj.productName,
                    unitPrice: obj.unitPrice,
                };
            });
        } else if (error) {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log('Error:' + JSON.stringify(error));
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ 'Order.Pricebook2Id' ] })
    wiredOrder({ data, error }) {
        if (data) {
            this.selectedPricebookId = getFieldValue(data, 'Order.Pricebook2Id');

        } else if (error) {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log(error);
        }
    }

    @wire(getProductListItems, { pricebookId: '$selectedPricebookId', recordLimit: '$maxRecordLimit' })
    wiredProductListItems({ error, data }) {
        if (data) {
            this.productListItems = data;
            this.doSortProducts();
        } else if (error) {
            console.log(error);
            this.productListItems = [];
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
        }
    }

    handleRowAction(event) {
        try {
            const eventAction = event.detail.action.name;

            if (eventAction == 'add') {
                this.addRowAction(event);
            }
        } catch (error) {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log('An error occurred while processing the row action event. Error: ' + error.message);
        }
    }

    addRowAction(event) {
       const selectedProduct = event.detail.row;

        if (selectedProduct) {
            let pricebookEntryId = selectedProduct.pricebookEntryId;

            if (!this.assignedOrderProductMap[pricebookEntryId]) {
                this.assignedOrderProductMap[pricebookEntryId] = {
                    pricebookEntryId: pricebookEntryId,
                    productName: selectedProduct.productName,
                    unitPrice: selectedProduct.unitPrice
                };
                this.doSortProducts();
            }
            const messagePayload = {
                pricebookEntryId: pricebookEntryId,
                productName: selectedProduct.productName,
                unitPrice: selectedProduct.unitPrice,
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
            return x[this.sortedBy];
        };
        let isReverseSort = this.sortedDirection === 'asc' ? 1 : -1;

        // Do sort as normal
        parseData.sort((a, b) => {
            return isReverseSort * ((keyValue(a) > keyValue(b)) - (keyValue(b) > keyValue(a)));
        });

        // Add weighted sort to product assigned to the order so they appear on top while incorporating the normal sort functionality
        parseData.map((e, index) => {
            e.sortWeight = (numberOfListProducts - index);

            if (this.assignedOrderProductMap[e.pricebookEntryId]) {
                e.sortWeight += numberOfListProducts;
                e.backgroundStyle = 'datatable-assigned-row';
            } else {
                e.backgroundStyle = '';
            }
        });

        // Re-sort based on weighted sort, descending order, so highest weighted product is on top
        parseData.sort((a, b) => {
            return -1 * ((a['sortWeight'] > b['sortWeight']) - (b['sortWeight'] > a['sortWeight']));
        });

        this.productListItems = parseData;
        console.log(JSON.stringify(this.productListItems, null, 4));
    }

    subscribeToOrderProductDeleteChannel() {
        this.subscription = subscribe(this.messageContext, OrderProductRowDeletedChannel, (message) => this.handleOrderProductDeleteMessage(message));
    }

    handleOrderProductDeleteMessage(message) {
        if (message.pricebookEntryId) {
            delete this.assignedOrderProductMap[message.pricebookEntryId];
            this.doSortProducts();
        }
    }

    connectedCallback() {
        this.subscribeToOrderProductDeleteChannel();
    }

    renderedCallback() {
        if (this.cssLoaded) {
            return;
        }
        this.cssLoaded = true;

        loadStyle(this, stylesheets + '/global.css').then(() => {
            console.log("Styles loaded");
        }).catch(error => {
            this.showToastMessage(Label_Toast_Error_Unexpected_Error, 'error');
            console.log(error);
        });
    }
}
