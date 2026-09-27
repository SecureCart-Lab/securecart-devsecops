package com.securecart.config;

import com.securecart.order.OrderNotFoundException;
import com.securecart.product.ProductNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class ApiExceptionHandlerTest {

    private final ApiExceptionHandler handler = new ApiExceptionHandler();

    @Test
    void productNotFoundShouldReturn404() {
        ProductNotFoundException exception =
                new ProductNotFoundException(1L);

        ResponseEntity<Map<String, String>> response =
                handler.notFound(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody())
                .containsEntry("error", exception.getMessage());
    }

    @Test
    void orderNotFoundShouldReturn404() {
        OrderNotFoundException exception =
                new OrderNotFoundException(1L);

        ResponseEntity<Map<String, String>> response =
                handler.notFound(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody())
                .containsEntry("error", exception.getMessage());
    }

    @Test
    void illegalArgumentShouldReturn400() {
        IllegalArgumentException exception =
                new IllegalArgumentException("Bad request");

        ResponseEntity<Map<String, String>> response =
                handler.conflict(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody())
                .containsEntry("error", "Bad request");
    }

    @Test
    void illegalStateShouldReturn400() {
        IllegalStateException exception =
                new IllegalStateException("Invalid state");

        ResponseEntity<Map<String, String>> response =
                handler.conflict(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody())
                .containsEntry("error", "Invalid state");
    }

    @Test
    void validationShouldReturn400() {
        MethodArgumentNotValidException exception =
                mock(MethodArgumentNotValidException.class);

        ResponseEntity<Map<String, String>> response =
                handler.validation(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody())
                .containsEntry("error", "Request validation failed");
    }
}