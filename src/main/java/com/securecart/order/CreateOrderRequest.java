package com.securecart.order;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
public record CreateOrderRequest(
    @NotBlank @Email String customerEmail,
    @NotEmpty List<@Valid LineItemRequest> items
) {
    public record LineItemRequest(@NotNull Long productId, @NotNull @Min(1) Integer quantity) {}
}
