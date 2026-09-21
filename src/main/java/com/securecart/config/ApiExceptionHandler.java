package com.securecart.config;
import com.securecart.order.OrderNotFoundException;
import com.securecart.product.ProductNotFoundException;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler({ProductNotFoundException.class, OrderNotFoundException.class})
    ResponseEntity<Map<String,String>> notFound(RuntimeException ex){ return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", ex.getMessage())); }
    @ExceptionHandler({IllegalStateException.class, IllegalArgumentException.class})
    ResponseEntity<Map<String,String>> conflict(RuntimeException ex){ return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage())); }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Map<String,String>> validation(MethodArgumentNotValidException ex){ return ResponseEntity.badRequest().body(Map.of("error", "Request validation failed")); }
}
