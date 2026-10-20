use chrono::Utc;
use http::StatusCode;
use hyper::service::{make_service_fn, service_fn};
use hyper::{Body, Request, Response, Server};
use std::convert::Infallible;
use std::env;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicUsize, Ordering};

static REQUEST_COUNT: AtomicUsize = AtomicUsize::new(0);

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    let path = req.uri().path();
    let query = req.uri().query().unwrap_or("");

    let response = match (path, query) {
        ("/", _) => root_handler().await,
        ("/healthz", _) => healthz_handler().await,
        ("/readyz", _) => readyz_handler().await,
        ("/slow", n_param) => slow_handler(n_param).await,
        _ => not_found_handler().await,
    };

    Ok(response)
}

async fn root_handler() -> Response<Body> {
    Response::new(Body::from("Rust sier \"Hello Learniken Fordypning! Does it restart correctly?\\n"))
}

async fn healthz_handler() -> Response<Body> {
    // Only read the counter: /slow drives it up. Incrementing here would make
    // the liveness probe slow itself down and restart the pod with no traffic.
    let count = REQUEST_COUNT.load(Ordering::SeqCst);
    let delay = count as u64 * 100;

    // Simulate delay
    if delay > 0 {
        tokio::time::sleep(std::time::Duration::from_millis(delay)).await;
    }

    let response = format!(
        "{{\"status\":\"UP\",\"timestamp\":\"{} \",\"Requestcount\":{}, \"Delay\":{}}}",
        Utc::now().to_rfc3339(),
        count,
        delay
    );

    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "application/json")
        .body(Body::from(response))
        .unwrap()
}

async fn readyz_handler() -> Response<Body> {
    let response = r#"{"status":"UP"}"#;
    Response::builder()
        .status(StatusCode::OK)
        .header("Content-Type", "application/json")
        .body(Body::from(response))
        .unwrap()
}

async fn slow_handler(query: &str) -> Response<Body> {
    // Read the n value from a query string such as "n=50"; fall back to 100 ms.
    let n = query
        .split('&')
        .find_map(|pair| pair.strip_prefix("n="))
        .and_then(|value| value.parse::<u64>().ok())
        .unwrap_or(100);

    let count = REQUEST_COUNT.fetch_add(1, Ordering::SeqCst) + 1;
    let delay = count as u64 * n;

    // Simulate delay
    if delay > 0 {
        tokio::time::sleep(std::time::Duration::from_millis(delay)).await;
    }

    let response = format!("Request # {}, delayed by {} ms\\n", count, delay);
    Response::new(Body::from(response))
}

async fn not_found_handler() -> Response<Body> {
    Response::builder()
        .status(StatusCode::NOT_FOUND)
        .body(Body::from("404 Not Found"))
        .unwrap()
}

#[tokio::main]
async fn main() {
    let port = env::var("PORT").unwrap_or_else(|_| "80".to_string());
    let port: u16 = port.parse().unwrap_or(80);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));

    let make_svc = make_service_fn(|_conn| async {
        Ok::<_, Infallible>(service_fn(handle_request))
    });

    let server = Server::bind(&addr).serve(make_svc);

    println!("Starting server on port {}", port);

    if let Err(e) = server.await {
        eprintln!("server error: {}", e);
    }
}
