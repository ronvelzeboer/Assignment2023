/**
 * @author Ron Velzeboer
 * @date 16/09/2023
 * @description Data Transfer Object to convert between Order/OrderItems and the JSON structure of the external system
 */
public class OrderConfirmation {
    public String accountNumber;
    public String orderNumber;
    public String type;
    public String status;
    public List<OrderProduct> orderProducts;

    public class OrderProduct {
        public String name;
        public String code;
        public Decimal unitPrice;
        public Integer quantity;
    }

    /**
     * @description Deserialize a JSON into an OrderConfirmation object
     * @param jsonData JSON structure that matches the naming of the OrderConfirmation class variables
     *
     * @return the JSON data deserialized into the object data structure
     */
    public static OrderConfirmation deserialize(String jsonData) {
        return (OrderConfirmation) JSON.deserializeStrict(jsonData, OrderConfirmation.class);
    }

    /**
     * @description Serialize an OrderConfirmation object to JSON
     * @param dataStructure OrderConfirmation object data structure
     *
     * @return serialized into JSON data
     */
    public static String serialize(OrderConfirmation dataStructure) {
        return JSON.serializePretty(dataStructure, false);
    }
}
