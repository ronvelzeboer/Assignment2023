/**
 * @author Ron Velzeboer
 * @date 15/09/2023
 * @description Class with constants to keep hardcoding limited to one place. This class would also be used to implement
 * Schema definitions for Records Types etc.
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

    /** Endpoint custom meta data developerNames **/
    public static final String ENDPOINT_DEVELOPERNAME_ORDER_CONFIRMATION_GENERIC = 'B2B_Generic';

    /** HTTP Status codes **/
    public static final Integer HTTP_STATUS_CODE_OK = 200;
    public static final Integer HTTP_STATUS_CODE_BAD_REQUEST= 400;
    public static final Integer HTTP_STATUS_CODE_UNAUTHORIZED= 401;
    public static final Integer HTTP_STATUS_CODE_NOT_FOUND = 404;
    public static final Integer HTTP_STATUS_CODE_INTERNAL_SERVER_ERROR = 500;
}
