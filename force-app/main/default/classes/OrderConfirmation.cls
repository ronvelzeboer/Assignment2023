/**
 * Created by user on 9/16/23.
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
}
