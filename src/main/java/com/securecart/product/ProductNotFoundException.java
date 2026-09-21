package com.securecart.product;
public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(Long id) { super("Product " + id + " was not found"); }
}
