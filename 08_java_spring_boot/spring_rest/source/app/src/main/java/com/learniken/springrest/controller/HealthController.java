package com.learniken.springrest.controller;

import com.learniken.springrest.RequestCounter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping
public class HealthController {

    @Autowired
    private RequestCounter requestCounter;

    @GetMapping("/")
    public String root() {
        return "Spring Boot sier \"Hello Learniken Fordypning!\n";
    }

    @GetMapping("/healthz")
    public ResponseEntity<Map<String, Object>> healthz() {
        long count = requestCounter.getCount();
        long delay = count * 100;
        
        // Simulate delay like the Rust version
        try {
            TimeUnit.MILLISECONDS.sleep(delay);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("timestamp", Instant.now().toString());
        response.put("Requestcount", count);
        response.put("Delay", delay);
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/readyz")
    public ResponseEntity<Map<String, String>> readyz() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/slow")
    public ResponseEntity<String> slow(@RequestParam(defaultValue = "100") long n) {
        long count = requestCounter.incrementAndGet();
        long delay = count * n;
        
        // Simulate delay
        try {
            TimeUnit.MILLISECONDS.sleep(delay);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        return ResponseEntity.ok(String.format("Request #%d, delayed by %dms\n", count, delay));
    }
}
