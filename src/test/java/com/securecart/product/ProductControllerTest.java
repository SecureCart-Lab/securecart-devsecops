package com.securecart.product;
import com.securecart.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import java.math.BigDecimal;
import java.util.List;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@WebMvcTest(ProductController.class)
@Import(SecurityConfig.class)
@TestPropertySource(properties={
 "securecart.security.user.username=student","securecart.security.user.password=test-password",
 "securecart.security.admin.username=admin","securecart.security.admin.password=test-admin-password"})
class ProductControllerTest {
    @Autowired MockMvc mvc;
    @MockitoBean ProductService service;
    @Test void productListIsPublic() throws Exception {
        when(service.findAll()).thenReturn(List.of(new Product("SKU","Name","Desc", BigDecimal.TEN, 2)));
        mvc.perform(get("/api/products")).andExpect(status().isOk()).andExpect(jsonPath("$[0].sku").value("SKU"));
    }
}
