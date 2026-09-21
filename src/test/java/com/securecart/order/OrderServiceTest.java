package com.securecart.order;
import com.securecart.product.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
class OrderServiceTest {
    @Test void createsOrderAndReducesInventory(){
        OrderRepository orders = mock(OrderRepository.class);
        ProductService products = mock(ProductService.class);
        Product product = new Product("SKU","Name","Desc", new BigDecimal("12.50"), 5);
        when(products.findById(1L)).thenReturn(product);
        when(orders.save(any(CustomerOrder.class))).thenAnswer(inv -> inv.getArgument(0));
        CustomerOrder result = new OrderService(orders, products).create(
            new CreateOrderRequest("student@example.com", List.of(new CreateOrderRequest.LineItemRequest(1L,2))));
        assertEquals(new BigDecimal("25.00"), result.getTotalAmount());
        assertEquals(3, product.getInventoryQuantity());
    }
}
