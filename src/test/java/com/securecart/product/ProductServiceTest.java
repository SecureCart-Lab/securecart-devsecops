package com.securecart.product;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class ProductServiceTest {
    @Test void returnsProductById(){
        ProductRepository repo = mock(ProductRepository.class);
        Product p = new Product("SKU","Name","Desc", BigDecimal.TEN, 3);
        when(repo.findById(1L)).thenReturn(Optional.of(p));
        assertEquals("SKU", new ProductService(repo).findById(1L).getSku());
    }
    @Test void throwsWhenProductMissing(){
        ProductRepository repo = mock(ProductRepository.class);
        when(repo.findById(99L)).thenReturn(Optional.empty());
        assertThrows(ProductNotFoundException.class, () -> new ProductService(repo).findById(99L));
    }
}
