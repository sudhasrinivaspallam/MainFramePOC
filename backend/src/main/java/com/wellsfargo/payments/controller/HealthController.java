package com.wellsfargo.payments.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/")
    public Map<String, String> root() {
        return Map.of(
            "app", "Plastic Issuance & Settlement System",
            "version", "1.0.0",
            "stack", "Java 21 + Spring Boot 3 + PostgreSQL 16"
        );
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }
}
