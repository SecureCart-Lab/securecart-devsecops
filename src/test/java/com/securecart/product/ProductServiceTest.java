package com.securecart.product;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ProductServiceTest {

    @Test
    void returnsProductById() {
        ProductRepository repo = mock(ProductRepository.class);
        Product p = new Product(
                "SKU",
                "Name",
                "Desc",
                BigDecimal.TEN,
                3
        );

        when(repo.findById(1L)).thenReturn(Optional.of(p));

        ProductService service = new ProductService(repo);

        assertEquals("SKU", service.findById(1L).getSku());
    }

    @Test
    void throwsWhenProductMissing() {
        ProductRepository repo = mock(ProductRepository.class);
        when(repo.findById(99L)).thenReturn(Optional.empty());

        ProductService service = new ProductService(repo);

        assertThrows(
                ProductNotFoundException.class,
                () -> service.findById(99L)
        );
    }
}