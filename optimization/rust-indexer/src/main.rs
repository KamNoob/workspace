use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::sync::Arc;
use dashmap::DashMap;
use lru::LruCache;
use std::num::NonZeroUsize;
use regex::Regex;
use std::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ApiEntry {
    name: String,
    description: String,
    url: String,
    auth: String,
    category: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SearchQuery {
    keyword: Option<String>,
    category: Option<String>,
    free_only: Option<bool>,
    limit: Option<usize>,
}

#[derive(Debug)]
struct ApiIndex {
    // Category -> Vec<ApiEntry>
    by_category: DashMap<String, Vec<ApiEntry>>,
    // Name prefix -> Vec<ApiEntry> (for fast prefix matching)
    by_prefix: DashMap<String, Vec<ApiEntry>>,
    // Full text search cache
    search_cache: Arc<tokio::sync::Mutex<LruCache<String, Vec<ApiEntry>>>>,
    // Metadata
    total_apis: usize,
    free_apis: usize,
}

impl ApiIndex {
    fn new(capacity: usize) -> Self {
        ApiIndex {
            by_category: DashMap::new(),
            by_prefix: DashMap::new(),
            search_cache: Arc::new(tokio::sync::Mutex::new(
                LruCache::new(NonZeroUsize::new(1000).unwrap())
            )),
            total_apis: 0,
            free_apis: 0,
        }
    }

    async fn load_from_json(&mut self, file_path: &str) -> Result<(), Box<dyn std::error::Error>> {
        let content = fs::read_to_string(file_path)?;
        let data: Value = serde_json::from_str(&content)?;

        if let Some(categories) = data.get("categories").and_then(|c| c.as_object()) {
            for (category_name, apis_value) in categories {
                if let Some(apis_array) = apis_value.as_array() {
                    let mut category_apis = Vec::new();

                    for api_value in apis_array {
                        if let (
                            Some(name),
                            Some(description),
                            Some(url),
                            Some(auth),
                        ) = (
                            api_value.get("name").and_then(|v| v.as_str()),
                            api_value.get("description").and_then(|v| v.as_str()),
                            api_value.get("url").and_then(|v| v.as_str()),
                            api_value.get("auth").and_then(|v| v.as_str()),
                        ) {
                            let entry = ApiEntry {
                                name: name.to_string(),
                                description: description.to_string(),
                                url: url.to_string(),
                                auth: auth.to_string(),
                                category: category_name.clone(),
                            };

                            // Index by prefix
                            let prefix = name.chars().take(3).collect::<String>().to_lowercase();
                            self.by_prefix
                                .entry(prefix)
                                .or_insert_with(Vec::new)
                                .push(entry.clone());

                            category_apis.push(entry);
                            self.total_apis += 1;

                            if auth == "No" {
                                self.free_apis += 1;
                            }
                        }
                    }

                    if !category_apis.is_empty() {
                        self.by_category.insert(category_name.clone(), category_apis);
                    }
                }
            }
        }

        Ok(())
    }

    fn search(&self, keyword: &str, category: Option<&str>, free_only: bool) -> Vec<ApiEntry> {
        let keyword_lower = keyword.to_lowercase();
        let mut results = Vec::new();

        // Search by category first if specified
        if let Some(cat) = category {
            if let Some(apis) = self.by_category.get(cat) {
                for api in apis.iter() {
                    if (free_only && api.auth != "No") {
                        continue;
                    }
                    if api.name.to_lowercase().contains(&keyword_lower)
                        || api.description.to_lowercase().contains(&keyword_lower)
                    {
                        results.push(api.clone());
                    }
                }
            }
        } else {
            // Full search across all categories
            for entry in self.by_category.iter() {
                let apis = entry.value();
                for api in apis {
                    if (free_only && api.auth != "No") {
                        continue;
                    }
                    if api.name.to_lowercase().contains(&keyword_lower)
                        || api.description.to_lowercase().contains(&keyword_lower)
                    {
                        results.push(api.clone());
                    }
                }
            }
        }

        results
    }

    fn get_category(&self, category: &str) -> Option<Vec<ApiEntry>> {
        self.by_category.get(category).map(|r| r.value().clone())
    }

    fn list_categories(&self) -> Vec<String> {
        self.by_category
            .iter()
            .map(|entry| entry.key().clone())
            .collect()
    }
}

// Global index
lazy_static::lazy_static! {
    static ref INDEX: Arc<tokio::sync::Mutex<Option<ApiIndex>>> = Arc::new(tokio::sync::Mutex::new(None));
}

// Routes
async fn search(
    query: web::Query<SearchQuery>,
) -> HttpResponse {
    let index = INDEX.lock().await;

    if let Some(idx) = index.as_ref() {
        let keyword = query.keyword.as_ref().unwrap_or(&"*".to_string());
        let category = query.category.as_deref();
        let free_only = query.free_only.unwrap_or(false);
        let limit = query.limit.unwrap_or(50);

        let results = idx.search(keyword, category, free_only);
        let limited: Vec<_> = results.into_iter().take(limit).collect();

        return HttpResponse::Ok().json(json!({
            "count": limited.len(),
            "results": limited,
        }));
    }

    HttpResponse::ServiceUnavailable().json(json!({
        "error": "Index not loaded"
    }))
}

async fn category(
    path: web::Path<String>,
) -> HttpResponse {
    let category_name = path.into_inner();
    let index = INDEX.lock().await;

    if let Some(idx) = index.as_ref() {
        if let Some(apis) = idx.get_category(&category_name) {
            return HttpResponse::Ok().json(json!({
                "category": category_name,
                "count": apis.len(),
                "apis": apis,
            }));
        }
    }

    HttpResponse::NotFound().json(json!({
        "error": format!("Category '{}' not found", category_name)
    }))
}

async fn categories() -> HttpResponse {
    let index = INDEX.lock().await;

    if let Some(idx) = index.as_ref() {
        let cats = idx.list_categories();
        return HttpResponse::Ok().json(json!({
            "count": cats.len(),
            "categories": cats,
        }));
    }

    HttpResponse::ServiceUnavailable().json(json!({
        "error": "Index not loaded"
    }))
}

async fn health() -> HttpResponse {
    let index = INDEX.lock().await;

    if let Some(idx) = index.as_ref() {
        return HttpResponse::Ok().json(json!({
            "status": "healthy",
            "total_apis": idx.total_apis,
            "free_apis": idx.free_apis,
        }));
    }

    HttpResponse::Ok().json(json!({
        "status": "loading"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("🚀 API Indexer Server Starting...");

    // Load both index files
    let mut index = ApiIndex::new(37918);
    
    match index.load_from_json("/home/art/.openclaw/workspace/public-apis/api-index-free-only.json").await {
        Ok(_) => println!("✅ Loaded free-only index ({} APIs)", index.total_apis),
        Err(e) => eprintln!("❌ Failed to load index: {}", e),
    }

    let mut index_full = ApiIndex::new(37918);
    match index_full.load_from_json("/home/art/.openclaw/workspace/public-apis/api-index.json").await {
        Ok(_) => println!("✅ Loaded full index ({} APIs)", index_full.total_apis),
        Err(e) => eprintln!("❌ Failed to load full index: {}", e),
    }

    *INDEX.lock().await = Some(index_full); // Use full index by default

    println!("📡 Starting HTTP server on 0.0.0.0:18790");
    println!("   Search: GET /search?keyword=test&category=Development&free_only=true");
    println!("   Category: GET /category/Development");
    println!("   Categories: GET /categories");
    println!("   Health: GET /health");

    HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default())
            .route("/search", web::get().to(search))
            .route("/category/{name}", web::get().to(category))
            .route("/categories", web::get().to(categories))
            .route("/health", web::get().to(health))
    })
    .bind("0.0.0.0:18790")?
    .run()
    .await
}
