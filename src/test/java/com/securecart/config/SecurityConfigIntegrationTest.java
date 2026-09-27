package com.securecart.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.web.SecurityFilterChain;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(properties = {
        "securecart.security.user.username=user",
        "securecart.security.user.password=user-password",
        "securecart.security.admin.username=admin",
        "securecart.security.admin.password=admin-password"
})
class SecurityConfigIntegrationTest {

    @Autowired
    private SecurityFilterChain securityFilterChain;

    @Test
    void securityFilterChainShouldBeCreated() {
        assertThat(securityFilterChain).isNotNull();
    }
}