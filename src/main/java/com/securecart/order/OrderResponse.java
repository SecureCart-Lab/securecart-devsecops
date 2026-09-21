package com.securecart.order;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
public record OrderResponse(Long id, String customerEmail, String status, BigDecimal totalAmount, Instant createdAt, List<LineItem> items) {
    public record LineItem(Long productId, String productName, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {}
    public static OrderResponse from(CustomerOrder order) {
        return new OrderResponse(order.getId(), order.getCustomerEmail(), order.getStatus(), order.getTotalAmount(), order.getCreatedAt(),
            order.getItems().stream().map(i -> new LineItem(i.getProductId(), i.getProductName(), i.getQuantity(), i.getUnitPrice(), i.lineTotal())).toList());
    }
}
