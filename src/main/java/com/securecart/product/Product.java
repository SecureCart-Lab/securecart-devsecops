package com.securecart.product;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "products", uniqueConstraints = @UniqueConstraint(name = "uk_products_sku", columnNames = "sku"))
public class Product {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 64) private String sku;
    @Column(nullable = false, length = 160) private String name;
    @Column(length = 500) private String description;
    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal price;
    @Column(name = "inventory_quantity", nullable = false) private Integer inventoryQuantity;

    protected Product() {}
    public Product(String sku, String name, String description, BigDecimal price, Integer inventoryQuantity) {
        this.sku = sku; this.name = name; this.description = description; this.price = price; this.inventoryQuantity = inventoryQuantity;
    }
    public Long getId() { return id; }
    public String getSku() { return sku; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public BigDecimal getPrice() { return price; }
    public Integer getInventoryQuantity() { return inventoryQuantity; }
    public void reduceInventory(int quantity) {
        if (quantity < 1) throw new IllegalArgumentException("quantity must be positive");
        if (inventoryQuantity < quantity) throw new IllegalStateException("insufficient inventory");
        inventoryQuantity -= quantity;
    }
}
