package com.securecart.config;

import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;

class SecurityConfigTest {

    private final SecurityConfig config = new SecurityConfig();

    @Test
    void passwordEncoderShouldCreateBcryptEncoder() {
        PasswordEncoder encoder = config.passwordEncoder();

        String encoded = encoder.encode("test-password");

        assertThat(encoded).isNotEqualTo("test-password");
        assertThat(encoder.matches("test-password", encoded)).isTrue();
    }

    @Test
    void usersShouldCreateNormalUser() {
        PasswordEncoder encoder = config.passwordEncoder();

        UserDetailsService service = config.users(
                encoder,
                "user",
                "user-password",
                "admin",
                "admin-password"
        );

        UserDetails user = service.loadUserByUsername("user");

        assertThat(user.getUsername()).isEqualTo("user");
        assertThat(
                encoder.matches("user-password", user.getPassword())
        ).isTrue();

        assertThat(user.getAuthorities())
                .extracting("authority")
                .containsExactly("ROLE_USER");
    }

    @Test
    void usersShouldCreateAdminWithUserAndAdminRoles() {
        PasswordEncoder encoder = config.passwordEncoder();

        UserDetailsService service = config.users(
                encoder,
                "user",
                "user-password",
                "admin",
                "admin-password"
        );

        UserDetails admin = service.loadUserByUsername("admin");

        assertThat(admin.getUsername()).isEqualTo("admin");
        assertThat(
                encoder.matches("admin-password", admin.getPassword())
        ).isTrue();

        assertThat(admin.getAuthorities())
                .extracting("authority")
                .containsExactlyInAnyOrder(
                        "ROLE_USER",
                        "ROLE_ADMIN"
                );
    }
}