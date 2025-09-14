use reqwest::Client;
use serde_json::json;
use std::env;
use std::fs;
use std::process;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Load .env file if it exists
    dotenv::dotenv().ok();
    
    // Try to read the API key from environment variable first (if loaded by dotenv)
    let cairo_coder_api = match env::var("CAIRO_CODER_API_KEY") {
        Ok(key) => key,
        Err(_) => {
            // If not in environment, try to read directly from .env file
            match fs::read_to_string(".env") {
                Ok(contents) => {
                    // Parse the .env file manually
                    let mut api_key = None;
                    for line in contents.lines() {
                        let line = line.trim();
                        if line.starts_with("CAIRO_CODER_API_KEY=") {
                            api_key = Some(line.trim_start_matches("CAIRO_CODER_API_KEY=").trim().to_string());
                            break;
                        }
                    }
                    
                    match api_key {
                        Some(key) => key,
                        None => {
                            eprintln!("Error: The .env file does not have an API key.");
                            eprintln!("Please add CAIRO_CODER_API_KEY=your_api_key to the .env file.");
                            process::exit(1);
                        }
                    }
                },
                Err(e) => {
                    eprintln!("Error reading .env file: {}", e);
                    eprintln!("Please ensure .env file exists and contains CAIRO_CODER_API_KEY=your_api_key");
                    process::exit(1);
                }
            }
        }
    };
    
    // Remove quotes if present
    let cairo_coder_api = cairo_coder_api.trim_matches('"').trim_matches('\'');
    
    println!("Using Cairo Coder API...");
    
    let client = Client::new();

    let response = client
        .post("https://api.cairo-coder.com/v1/chat/completions")
        .header("Content-Type", "application/json")
        .header("x-api-key", cairo_coder_api)
        .json(&json!({
            "messages": [
                {
                    "role": "user",
                    "content": "Write a simple Cairo contract that implements a counter"
                }
            ]
        }))
        .send()
        .await?;

    if response.status().is_success() {
        let data: serde_json::Value = response.json().await?;
        if let Some(content) = data["choices"][0]["message"]["content"].as_str() {
            println!("\nResponse from Cairo Coder:\n{}", content);
        } else {
            println!("Response: {}", data);
        }
    } else {
        eprintln!("API request failed with status: {}", response.status());
        let error_text = response.text().await?;
        eprintln!("Error details: {}", error_text);
    }

    Ok(())
}
