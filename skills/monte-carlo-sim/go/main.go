package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"math"
	"math/rand"
	"os"
	"sync"
)

type Asset struct {
	Weight         float64 `json:"weight"`
	ExpectedReturn float64 `json:"expectedReturn"`
	Volatility     float64 `json:"volatility"`
}

type Input struct {
	Assets       []Asset   `json:"assets"`
	Correlations [][]float64 `json:"correlations"`
}

type PortfolioResult struct {
	Mean       float64 `json:"mean"`
	Std        float64 `json:"std"`
	Min        float64 `json:"min"`
	Max        float64 `json:"max"`
	VaR95      float64 `json:"var95"`
	CVaR95     float64 `json:"cvar95"`
	Iterations int     `json:"iterations"`
	Backend    string  `json:"backend"`
}

type SampleResult struct {
	Samples []float64 `json:"samples"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: mc-go <command> [args...]\n")
		os.Exit(1)
	}

	cmd := os.Args[1]

	switch cmd {
	case "portfolio":
		if len(os.Args) < 4 {
			fmt.Fprintf(os.Stderr, "Usage: mc-go portfolio <periods> <iterations>\n")
			os.Exit(1)
		}
		periods := 0
		iterations := 0
		fmt.Sscanf(os.Args[2], "%d", &periods)
		fmt.Sscanf(os.Args[3], "%d", &iterations)

		data, _ := io.ReadAll(os.Stdin)
		var input Input
		json.Unmarshal(data, &input)

		result := simulatePortfolio(input.Assets, periods, iterations)
		out, _ := json.Marshal(result)
		fmt.Println(string(out))

	case "sample":
		if len(os.Args) < 4 {
			fmt.Fprintf(os.Stderr, "Usage: mc-go sample <distribution> <n>\n")
			os.Exit(1)
		}
		dist := os.Args[2]
		n := 0
		fmt.Sscanf(os.Args[3], "%d", &n)

		samples := sampleDistribution(dist, n)
		result := SampleResult{Samples: samples}
		out, _ := json.Marshal(result)
		fmt.Println(string(out))

	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", cmd)
		os.Exit(1)
	}
}

func simulatePortfolio(assets []Asset, periods int, iterations int) PortfolioResult {
	results := make([]float64, iterations)
	var mu sync.Mutex
	var wg sync.WaitGroup

	// Parallel iterations with goroutines
	numWorkers := 8
	batchSize := (iterations + numWorkers - 1) / numWorkers

	for w := 0; w < numWorkers; w++ {
		wg.Add(1)
		go func(worker int) {
			defer wg.Done()

			start := worker * batchSize
			end := start + batchSize
			if end > iterations {
				end = iterations
			}

			for iter := start; iter < end; iter++ {
				portfolioValue := 100.0

				for t := 0; t < periods; t++ {
					periodReturn := 0.0

					for i, asset := range assets {
						assetReturn := asset.ExpectedReturn/252.0 +
							asset.Volatility/math.Sqrt(252) *
								boxMullerNormal()
						periodReturn += asset.Weight * assetReturn
					}

					portfolioValue *= (1.0 + periodReturn)
				}

				mu.Lock()
				results[iter] = portfolioValue
				mu.Unlock()
			}
		}(w)
	}

	wg.Wait()

	// Sort results for percentile calculations
	quickSort(results, 0, len(results)-1)

	mean := 0.0
	for _, v := range results {
		mean += v
	}
	mean /= float64(len(results))

	variance := 0.0
	for _, v := range results {
		variance += (v - mean) * (v - mean)
	}
	variance /= float64(len(results))
	std := math.Sqrt(variance)

	var95Idx := int(0.05 * float64(len(results)))
	if var95Idx >= len(results) {
		var95Idx = len(results) - 1
	}

	cvar95Sum := 0.0
	for i := 0; i <= var95Idx; i++ {
		cvar95Sum += results[i]
	}
	cvar95 := cvar95Sum / float64(var95Idx+1)

	return PortfolioResult{
		Mean:       math.Round(mean*100) / 100,
		Std:        math.Round(std*100) / 100,
		Min:        math.Round(results[0]*100) / 100,
		Max:        math.Round(results[len(results)-1]*100) / 100,
		VaR95:      math.Round(results[var95Idx]*100) / 100,
		CVaR95:     math.Round(cvar95*100) / 100,
		Iterations: iterations,
		Backend:    "go",
	}
}

func sampleDistribution(dist string, n int) []float64 {
	samples := make([]float64, n)
	
	for i := 0; i < n; i++ {
		switch dist {
		case "uniform":
			samples[i] = rand.Float64()
		case "normal":
			samples[i] = boxMullerNormal()
		case "exponential":
			samples[i] = -math.Log(1 - rand.Float64())
		default:
			samples[i] = rand.Float64()
		}
	}

	return samples
}

func boxMullerNormal() float64 {
	u1 := rand.Float64()
	u2 := rand.Float64()
	z0 := math.Sqrt(-2*math.Log(u1)) * math.Cos(2*math.Pi*u2)
	return z0
}

func quickSort(arr []float64, low, high int) {
	if low < high {
		pivot := partition(arr, low, high)
		quickSort(arr, low, pivot-1)
		quickSort(arr, pivot+1, high)
	}
}

func partition(arr []float64, low, high int) int {
	pivot := arr[high]
	i := low - 1

	for j := low; j < high; j++ {
		if arr[j] < pivot {
			i++
			arr[i], arr[j] = arr[j], arr[i]
		}
	}
	arr[i+1], arr[high] = arr[high], arr[i+1]
	return i + 1
}
