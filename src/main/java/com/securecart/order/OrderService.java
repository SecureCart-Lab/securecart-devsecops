package com.securecart.order;

import com.securecart.product.Product;
import com.securecart.product.ProductService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final ProductService productService;
    public OrderService(OrderRepository orderRepository, ProductService productService) { this.orderRepository=orderRepository; this.productService=productService; }

    @Transactional
    public CustomerOrder create(CreateOrderRequest request) {
        CustomerOrder order = new CustomerOrder(request.customerEmail());
        for (CreateOrderRequest.LineItemRequest requested : request.items()) {
            Product product = productService.findById(requested.productId());
            product.reduceInventory(requested.quantity());
            order.addItem(new OrderItem(product.getId(), product.getName(), requested.quantity(), product.getPrice()));
        }
        return orderRepository.save(order);
    }

    @Transactional(readOnly = true)
    public CustomerOrder get(Long id) { return orderRepository.findById(id).orElseThrow(() -> new OrderNotFoundException(id)); }
}
