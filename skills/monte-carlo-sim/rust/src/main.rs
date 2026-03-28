use rand::rngs::SmallRng;
use rand::{Rng, SeedableRng};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Serialize, Deserialize)]
struct IntegralResult {
    integral: f64,
    std_error: f64,
    samples: usize,
    ci95: [f64; 2],
}

#[derive(Serialize, Deserialize)]
struct PiResult {
    estimate: f64,
    actual: f64,
    error: f64,
    samples: usize,
}

#[derive(Serialize, Deserialize)]
struct SampleResult {
    samples: Vec<f64>,
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: mc-rust <command> [args...]");
        std::process::exit(1);
    }

    let command = &args[1];
    
    match command.as_str() {
        "integrate" => {
            if args.len() < 5 {
                eprintln!("Usage: mc-rust integrate <a> <b> <samples>");
                std::process::exit(1);
            }
            let a: f64 = args[2].parse().expect("Invalid a");
            let b: f64 = args[3].parse().expect("Invalid b");
            let samples: usize = args[4].parse().expect("Invalid samples");
            estimate_integral(a, b, samples);
        }
        "pi" => {
            if args.len() < 3 {
                eprintln!("Usage: mc-rust pi <samples>");
                std::process::exit(1);
            }
            let samples: usize = args[2].parse().expect("Invalid samples");
            estimate_pi(samples);
        }
        "sample" => {
            if args.len() < 4 {
                eprintln!("Usage: mc-rust sample <distribution> <n>");
                std::process::exit(1);
            }
            let dist = &args[2];
            let n: usize = args[3].parse().expect("Invalid n");
            // Read params from stdin if available
            let params = read_json_params();
            sample_distribution(dist, &params, n);
        }
        _ => {
            eprintln!("Unknown command: {}", command);
            std::process::exit(1);
        }
    }
}

fn estimate_integral(a: f64, b: f64, samples: usize) {
    let width = b - a;
    
    // Parallel sampling with rayon
    let results: Vec<f64> = (0..samples)
        .into_par_iter()
        .map(|_| {
            let mut rng = SmallRng::from_entropy();
            let x = a + rng.gen::<f64>() * width;
            // Simple test function: x^2
            x * x
        })
        .collect();

    let mean = results.iter().sum::<f64>() / samples as f64;
    let integral = width * mean;
    
    let variance = results
        .iter()
        .map(|&v| (v - mean).powi(2))
        .sum::<f64>()
        / samples as f64;
    
    let std_error = (variance / samples as f64).sqrt() * width;

    let result = IntegralResult {
        integral: (integral * 1_000_000.0).round() / 1_000_000.0,
        std_error: (std_error * 1_000_000.0).round() / 1_000_000.0,
        samples,
        ci95: [
            ((integral - 1.96 * std_error) * 1_000_000.0).round() / 1_000_000.0,
            ((integral + 1.96 * std_error) * 1_000_000.0).round() / 1_000_000.0,
        ],
    };

    println!("{}", serde_json::to_string(&result).unwrap());
}

fn estimate_pi(samples: usize) {
    let inside: usize = (0..samples)
        .into_par_iter()
        .filter(|_| {
            let mut rng = SmallRng::from_entropy();
            let x = rng.gen::<f64>();
            let y = rng.gen::<f64>();
            x * x + y * y <= 1.0
        })
        .count();

    let pi_estimate = 4.0 * inside as f64 / samples as f64;
    let actual = std::f64::consts::PI;
    let error = (pi_estimate - actual).abs();

    let result = PiResult {
        estimate: (pi_estimate * 1_000_000.0).round() / 1_000_000.0,
        actual: (actual * 1_000_000.0).round() / 1_000_000.0,
        error: (error * 1_000_000.0).round() / 1_000_000.0,
        samples,
    };

    println!("{}", serde_json::to_string(&result).unwrap());
}

fn sample_distribution(dist: &str, _params: &str, n: usize) {
    let samples: Vec<f64> = (0..n)
        .into_par_iter()
        .map(|_| {
            let mut rng = SmallRng::from_entropy();
            match dist {
                "uniform" => rng.gen::<f64>(),
                "normal" => {
                    // Box-Muller
                    let u1 = rng.gen::<f64>();
                    let u2 = rng.gen::<f64>();
                    (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
                }
                "exponential" => -(1.0 - rng.gen::<f64>()).ln(),
                _ => rng.gen::<f64>(),
            }
        })
        .collect();

    let result = SampleResult { samples };
    println!("{}", serde_json::to_string(&result).unwrap());
}

fn read_json_params() -> String {
    let mut buffer = String::new();
    if io::stdin().read_to_string(&mut buffer).is_ok() && !buffer.is_empty() {
        buffer
    } else {
        "{}".to_string()
    }
}
