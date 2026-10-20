package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync/atomic"
	"time"

	"github.com/gorilla/mux"
)

var (
	requestCount int64
)

const (
	// Maximum delay in milliseconds to prevent DoS
	maxDelayMs = 10000
	// Maximum n value to prevent excessive delays
	maxNValue = 1000
	// Default n value
	defaultNValue = 100
	// Request timeout to prevent hanging
	requestTimeout = 30 * time.Second
)

func main() {
	// Get port from environment variable, default to 80
	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}

	// Validate port is a valid number
	if _, err := strconv.Atoi(port); err != nil {
		log.Fatalf("Invalid PORT value: %s. Must be a valid integer.", port)
	}

	// Create router
	router := mux.NewRouter()

	// Add security middleware
	router.Use(securityHeadersMiddleware)

	// Define routes
	router.HandleFunc("/", rootHandler).Methods("GET")
	router.HandleFunc("/healthz", healthzHandler).Methods("GET")
	router.HandleFunc("/readyz", readyzHandler).Methods("GET")
	router.HandleFunc("/slow", slowHandler).Methods("GET")

	// Catch-all for unknown routes
	router.HandleFunc("{path:.*}", unknownHandler).Methods("GET")

	// Create HTTP server with timeout
	server := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("Starting server on port %s", port)
	log.Fatal(server.ListenAndServe())
}

// securityHeadersMiddleware adds security headers to all responses
func securityHeadersMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Prevent MIME type sniffing
		w.Header().Set("X-Content-Type-Options", "nosniff")
		
		// Enable XSS protection
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		
		// Prevent clickjacking
		w.Header().Set("X-Frame-Options", "DENY")
		
		// Content Security Policy
		w.Header().Set("Content-Security-Policy", "default-src 'self'")
		
		// Strict Transport Security (HSTS)
		w.Header().Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
		
		// Referrer Policy
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		
		// Permissions Policy
		w.Header().Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
		
		// Call the next handler
		next.ServeHTTP(w, r)
	})
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	fmt.Fprint(w, "Go sier \"Hello Learniken Fordypning!\\n")
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
	// Only read the counter: /slow drives it up. Incrementing here would make
	// the liveness probe slow itself down and restart the pod with no traffic.
	count := atomic.LoadInt64(&requestCount)

	// Cap delay to prevent DoS - max 10 seconds
	delay := count * 100
	if delay > maxDelayMs {
		delay = maxDelayMs
	}

	// Simulate delay like the Koa and Java versions
	if delay > 0 {
		// Use a context with timeout to prevent hanging forever
		ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
		defer cancel()
		
		select {
		case <-time.After(time.Duration(delay) * time.Millisecond):
			// Delay completed
		case <-ctx.Done():
			// Timeout reached, log and continue
			log.Printf("Healthz delay timed out after %dms", delay)
		}
	}

	// Build response
	response := map[string]interface{}{
		"status":      "UP",
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
		"Requestcount": count,
		"Delay":       delay,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Failed to encode healthz response: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "Internal Server Error")
	}
}

func readyzHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status": "UP",
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("Failed to encode readyz response: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "Internal Server Error")
	}
}

func slowHandler(w http.ResponseWriter, r *http.Request) {
	// Get n parameter from query, default to 100
	nParam := r.URL.Query().Get("n")
	n := int64(defaultNValue)
	
	if nParam != "" {
		var err error
		n, err = strconv.ParseInt(nParam, 10, 64)
		if err != nil {
			// Invalid n parameter, use default
			n = int64(defaultNValue)
		} else if n < 0 {
			// Negative values don't make sense, use default
			n = int64(defaultNValue)
		} else if n > int64(maxNValue) {
			// Cap n to prevent excessive delays (DoS protection)
			n = int64(maxNValue)
		}
	}

	count := atomic.AddInt64(&requestCount, 1)
	
	// Prevent integer overflow and cap total delay
	// Use float64 for intermediate calculation to detect overflow
	delayFloat := float64(count) * float64(n)
	if delayFloat > float64(maxDelayMs) {
		delayFloat = float64(maxDelayMs)
	}
	delay := int64(delayFloat)

	// Simulate delay with timeout protection
	if delay > 0 {
		ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
		defer cancel()
		
		select {
		case <-time.After(time.Duration(delay) * time.Millisecond):
			// Delay completed
		case <-ctx.Done():
			// Timeout reached
			log.Printf("Slow endpoint timed out after %dms", delay)
			delay = maxDelayMs // Report the intended delay
		}
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	fmt.Fprintf(w, "Request #%d, delayed by %dms\\n", count, delay)
}

func unknownHandler(w http.ResponseWriter, r *http.Request) {
	path := mux.Vars(r)["path"]
	if path == "" {
		path = r.URL.Path
	}
	log.Printf("Unknown route accessed: %s", path)
	http.NotFound(w, r)
}
