/**
 * Created by user on 9/15/23.
 */

public with sharing class KPNConstants {

    /** Contract Related Picklist Values **/
    public static final String CONTRACT_STATUS_DRAFT = 'Draft';
    public static final String CONTRACT_STATUS_ACTIVATED = 'Activated';
    public static final String CONTRACT_STATUS_IN_APPROVAL_PROCESS = 'In Approval Process';

    /** Order Related Picklist Values **/
    public static final String ORDER_STATUS_DRAFT = 'Draft';
    public static final String ORDER_STATUS_ACTIVATED = 'Activated';
    public static final String ORDER_ITEM_STATUS_DRAFT = 'Draft';
    public static final String ORDER_ITEM_STATUS_ACTIVATED = 'Activated';
    public static final String ORDER_CONFIRMATION_STATUS_PENDING_ACTIVATION = 'Pending Activation';
    public static final String ORDER_CONFIRMATION_STATUS_IN_PROGRESS = 'In Progress';
    public static final String ORDER_CONFIRMATION_STATUS_FAILED = 'Failed';
    public static final String ORDER_CONFIRMATION_STATUS_DELIVERED = 'Delivered';

    /** Order Confirmation Queue Related Picklist Values **/
    public static final String ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_NEW  = 'New';
    public static final String ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_RETRY = 'Retry';
    public static final String ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_FAILED = 'Failed';
    public static final String ORDER_CONFIRMATION_QUEUE_ITEM_STATUS_COMPLETED = 'Completed';
}
