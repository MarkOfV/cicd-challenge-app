package com.vladanm.cicdchallenge;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class App {

    @GetMapping("/")
    public String home() {
        return "CI/CD Challenge App deployed successfully!";
    }

    @GetMapping("/health")
    public String health() {
        return "{\"status\":\"UP\"}";
    }
    
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }


}