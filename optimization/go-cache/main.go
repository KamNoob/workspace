package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// CacheEntry holds cached API search results
type CacheEntry struct {
	Data      interface{}
	ExpiresAt time.Time
}

// APICache provides response caching with TTL
type APICache struct {
	mu    sync.RWMutex
	cache map[string]CacheEntry
}

// NewAPICache creates a new cache instance
func NewAPICache() *APICache {
	cache := &APICache{
		cache: make(map[string]CacheEntry),
	}

	// Cleanup goroutine - remove expired entries every minute
	go func() {
		ticker := time.NewTicker(1 * time.Minute)
		defer ticker.Stop()

		for range ticker.C {
			cache.cleanup()
		}
	}()

	return cache
}

// Get retrieves a cached value if it exists and hasn't expired
func (c *APICache) Get(key string) (interface{}, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.cache[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(entry.ExpiresAt) {
		return nil, false
	}

	return entry.Data, true
}

// Set stores a value in cache with TTL
func (c *APICache) Set(key string, value interface{}, ttl time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.cache[key] = CacheEntry{
		Data:      value,
		ExpiresAt: time.Now().Add(ttl),
	}
}

// cleanup removes expired entries
func (c *APICache) cleanup() {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	for key, entry := range c.cache {
		if now.After(entry.ExpiresAt) {
			delete(c.cache, key)
		}
	}
}

// Stats returns cache statistics
func (c *APICache) Stats() map[string]int {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return map[string]int{
		"entries": len(c.cache),
	}
}

// Global instances
var (
	cache           = NewAPICache()
	indexerURL      = "http://localhost:18790"
	defaultCacheTTL = 5 * time.Minute
)

// Search proxies to Rust indexer with caching
func Search(c *gin.Context) {
	keyword := c.DefaultQuery("keyword", "*")
	category := c.Query("category")
	freeOnly := c.DefaultQuery("free_only", "false")
	limit := c.DefaultQuery("limit", "50")

	// Create cache key
	cacheKey := fmt.Sprintf("search:%s:%s:%s:%s", keyword, category, freeOnly, limit)

	// Check cache first
	if cached, found := cache.Get(cacheKey); found {
		c.JSON(200, gin.H{
			"source": "cache",
			"data":   cached,
		})
		return
	}

	// Query Rust indexer
	url := fmt.Sprintf(
		"%s/search?keyword=%s&category=%s&free_only=%s&limit=%s",
		indexerURL, keyword, category, freeOnly, limit,
	)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(503, gin.H{"error": fmt.Sprintf("Indexer unavailable: %v", err)})
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result interface{}
	json.Unmarshal(body, &result)

	// Cache the result
	cache.Set(cacheKey, result, defaultCacheTTL)

	c.JSON(resp.StatusCode, gin.H{
		"source": "indexer",
		"data":   result,
	})
}

// Category proxies to Rust indexer
func Category(c *gin.Context) {
	name := c.Param("name")

	cacheKey := fmt.Sprintf("category:%s", name)

	if cached, found := cache.Get(cacheKey); found {
		c.JSON(200, gin.H{
			"source": "cache",
			"data":   cached,
		})
		return
	}

	url := fmt.Sprintf("%s/category/%s", indexerURL, name)
	resp, err := http.Get(url)
	if err != nil {
		c.JSON(503, gin.H{"error": fmt.Sprintf("Indexer unavailable: %v", err)})
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result interface{}
	json.Unmarshal(body, &result)

	cache.Set(cacheKey, result, 10*time.Minute) // Category cache longer

	c.JSON(resp.StatusCode, gin.H{
		"source": "indexer",
		"data":   result,
	})
}

// Categories lists all categories
func Categories(c *gin.Context) {
	const cacheKey = "categories"

	if cached, found := cache.Get(cacheKey); found {
		c.JSON(200, gin.H{
			"source": "cache",
			"data":   cached,
		})
		return
	}

	url := fmt.Sprintf("%s/categories", indexerURL)
	resp, err := http.Get(url)
	if err != nil {
		c.JSON(503, gin.H{"error": fmt.Sprintf("Indexer unavailable: %v", err)})
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result interface{}
	json.Unmarshal(body, &result)

	cache.Set(cacheKey, result, 1*time.Hour) // Categories rarely change

	c.JSON(resp.StatusCode, gin.H{
		"source": "indexer",
		"data":   result,
	})
}

// Health checks both cache and indexer
func Health(c *gin.Context) {
	resp, err := http.Get(fmt.Sprintf("%s/health", indexerURL))
	indexerHealthy := err == nil && resp.StatusCode == 200

	stats := cache.Stats()

	c.JSON(200, gin.H{
		"status":       "healthy",
		"cache_entries": stats["entries"],
		"indexer":      map[string]bool{"healthy": indexerHealthy},
	})
}

// CacheClear clears all cached entries
func CacheClear(c *gin.Context) {
	cache.cache = make(map[string]CacheEntry)
	c.JSON(200, gin.H{"message": "Cache cleared"})
}

// CacheStats returns cache statistics
func CacheStats(c *gin.Context) {
	stats := cache.Stats()
	c.JSON(200, gin.H{
		"cache_entries": stats["entries"],
		"ttl_seconds":   int(defaultCacheTTL.Seconds()),
	})
}

func main() {
	gin.SetMode(gin.ReleaseMode)
	router := gin.Default()

	// API Routes
	router.GET("/search", Search)
	router.GET("/category/:name", Category)
	router.GET("/categories", Categories)
	router.GET("/health", Health)

	// Cache Management
	router.POST("/cache/clear", CacheClear)
	router.GET("/cache/stats", CacheStats)

	log.Println("🚀 API Cache Layer Starting...")
	log.Println("📡 Listening on :18791")
	log.Printf("🔗 Forwarding to Rust indexer on %s\n", indexerURL)
	log.Println("   Endpoints:")
	log.Println("   GET  /search?keyword=test&category=Development&free_only=true")
	log.Println("   GET  /category/Development")
	log.Println("   GET  /categories")
	log.Println("   GET  /health")
	log.Println("   POST /cache/clear")
	log.Println("   GET  /cache/stats")

	if err := router.Run(":18791"); err != nil {
		log.Fatal(err)
	}
}
