package com.securecart.product;
import java.math.BigDecimal;
public record ProductResponse(Long id, String sku, String name, String description, BigDecimal price, Integer inventoryQuantity) {
    public static ProductResponse from(Product p) {
        return new ProductResponse(p.getId(), p.getSku(), p.getName(), p.getDescription(), p.getPrice(), p.getInventoryQuantity());
    }
}
