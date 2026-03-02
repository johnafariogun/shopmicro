package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"time"
)

// ANSI color codes for pretty terminal output
const (
	ColorReset  = "\033[0m"
	ColorRed    = "\033[31m"
	ColorGreen  = "\033[32m"
	ColorYellow = "\033[33m"
	ColorCyan   = "\033[36m"
)

type Service struct {
	Name string
	Path string
}

func main() {
	// 1. Define CLI Flags
	envFlag := flag.String("env", "local", "Environment to check (local, staging, prod)")
	timeoutFlag := flag.Int("timeout", 5, "Timeout in seconds for each HTTP request")
	flag.Parse()

	fmt.Printf("%s=== ShopMicro Environment Health Validator ===%s\n", ColorCyan, ColorReset)
	fmt.Printf("Target Environment: %s%s%s\n", ColorYellow, *envFlag, ColorReset)

	// 2. Define Base URLs based on environment
	var baseURL string
	switch *envFlag {
	case "local":
		// Matches your local Kubernetes NodePort/Ingress setup
		baseURL = "http://shopmicro.local:31332" 
	case "staging":
		baseURL = "https://shopmicro.local:31332"
	case "prod":
		baseURL = "https://shopmicro.production.com"
	default:
		fmt.Printf("%sError: Unknown environment '%s'. Use local, staging, or prod.%s\n", ColorRed, *envFlag, ColorReset)
		os.Exit(1)
	}

	// 3. Define the critical user journey endpoints to check
	services := []Service{
		{Name: "Frontend (React)", Path: "/"},
		{Name: "Backend API (Products)", Path: "/api/products"},
		{Name: "ML-Service (Recommendations)", Path: "/ml/recommendations/32"},
	}

	// Configure HTTP client with the specified timeout
	client := http.Client{
		Timeout: time.Duration(*timeoutFlag) * time.Second,
	}

	allHealthy := true

	// 4. Execute the Health Checks
	fmt.Println("Running checks...")
	for _, svc := range services {
		targetURL := baseURL + svc.Path
		
		start := time.Now()
		resp, err := client.Get(targetURL)
		duration := time.Since(start).Milliseconds()

		if err != nil {
			fmt.Printf("  [%sFAIL%s] %-30s -> Error: %v\n", ColorRed, ColorReset, svc.Name, err)
			allHealthy = false
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode <= 299 {
			fmt.Printf("  [%s OK %s] %-30s -> HTTP %d (%dms)\n", ColorGreen, ColorReset, svc.Name, resp.StatusCode, duration)
		} else {
			fmt.Printf("  [%sFAIL%s] %-30s -> HTTP %d (Expected 2xx)\n", ColorRed, ColorReset, svc.Name, resp.StatusCode)
			allHealthy = false
		}
	}

	// 5. Finalize and Exit
	fmt.Println("----------------------------------------------")
	if allHealthy {
		fmt.Printf("%sSUCCESS: All ShopMicro services are healthy in %s!%s\n", ColorGreen, *envFlag, ColorReset)
		os.Exit(0) // Exit 0 means success in CI/CD pipelines
	} else {
		fmt.Printf("%sFAILURE: One or more services are degraded. Check logs!%s\n", ColorRed, ColorReset)
		os.Exit(1) // Exit 1 instantly fails a CI/CD pipeline
	}
}
