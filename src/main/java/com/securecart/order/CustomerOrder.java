package com.securecart.order;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "customer_orders")
public class CustomerOrder {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name="customer_email", nullable=false, length=254) private String customerEmail;
    @Column(nullable=false, length=32) private String status;
    @Column(name="total_amount", nullable=false, precision=12, scale=2) private BigDecimal totalAmount;
    @Column(name="created_at", nullable=false) private Instant createdAt;
    @OneToMany(mappedBy="order", cascade=CascadeType.ALL, orphanRemoval=true, fetch=FetchType.EAGER)
    private List<OrderItem> items = new ArrayList<>();
    protected CustomerOrder() {}
    public CustomerOrder(String customerEmail) {
        this.customerEmail = customerEmail; this.status = "CREATED"; this.totalAmount = BigDecimal.ZERO; this.createdAt = Instant.now();
    }
    public void addItem(OrderItem item) { item.attachTo(this); items.add(item); totalAmount = totalAmount.add(item.lineTotal()); }
    public Long getId(){return id;} public String getCustomerEmail(){return customerEmail;} public String getStatus(){return status;}
    public BigDecimal getTotalAmount(){return totalAmount;} public Instant getCreatedAt(){return createdAt;} public List<OrderItem> getItems(){return List.copyOf(items);}
}
