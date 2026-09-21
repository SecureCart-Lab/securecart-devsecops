package com.securecart.order;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name="order_items")
public class OrderItem {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY, optional=false) @JoinColumn(name="order_id", nullable=false) private CustomerOrder order;
    @Column(name="product_id", nullable=false) private Long productId;
    @Column(name="product_name", nullable=false, length=160) private String productName;
    @Column(nullable=false) private Integer quantity;
    @Column(name="unit_price", nullable=false, precision=12, scale=2) private BigDecimal unitPrice;
    protected OrderItem() {}
    public OrderItem(Long productId, String productName, Integer quantity, BigDecimal unitPrice) {
        this.productId=productId; this.productName=productName; this.quantity=quantity; this.unitPrice=unitPrice;
    }
    void attachTo(CustomerOrder order){this.order=order;} public BigDecimal lineTotal(){return unitPrice.multiply(BigDecimal.valueOf(quantity));}
    public Long getProductId(){return productId;} public String getProductName(){return productName;} public Integer getQuantity(){return quantity;} public BigDecimal getUnitPrice(){return unitPrice;}
}
