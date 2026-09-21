package com.securecart.product;

import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    private final ProductService service;
    public ProductController(ProductService service) { this.service = service; }
    @GetMapping public List<ProductResponse> list() { return service.findAll().stream().map(ProductResponse::from).toList(); }
    @GetMapping("/{id}") public ProductResponse get(@PathVariable Long id) { return ProductResponse.from(service.findById(id)); }
}
