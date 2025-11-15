terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Variables
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for your domain"
  type        = string
}

variable "domain_name" {
  description = "Main domain name (e.g., example.com)"
  type        = string
}

variable "vps_ip_address" {
  description = "VPS IP address where backend is hosted"
  type        = string
}

variable "backend_subdomain" {
  description = "Subdomain for backend API (e.g., api)"
  type        = string
  default     = "api"
}

# Main backend subdomain
resource "cloudflare_record" "backend_api" {
  zone_id = var.cloudflare_zone_id
  name    = var.backend_subdomain
  value   = var.vps_ip_address
  type    = "A"
  ttl     = 1
  proxied = true
  comment = "Dart Cloud Backend API"
}

# Wildcard subdomain for dynamic function endpoints (optional)
resource "cloudflare_record" "wildcard_functions" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.backend_subdomain}"
  value   = var.vps_ip_address
  type    = "A"
  ttl     = 1
  proxied = true
  comment = "Wildcard for function-specific subdomains"
}

# SSL/TLS settings
resource "cloudflare_zone_settings_override" "ssl_settings" {
  zone_id = var.cloudflare_zone_id

  settings {
    ssl                      = "full"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    automatic_https_rewrites = "on"
    tls_1_3                  = "on"
  }
}

# Firewall rule to rate limit API requests
resource "cloudflare_rate_limit" "api_rate_limit" {
  zone_id = var.cloudflare_zone_id
  
  threshold = 100
  period    = 60
  
  match {
    request {
      url_pattern = "${var.backend_subdomain}.${var.domain_name}/api/*"
    }
  }
  
  action {
    mode    = "challenge"
    timeout = 86400
  }
  
  description = "Rate limit for API endpoints"
}

# Page rule for API caching
resource "cloudflare_page_rule" "api_cache_rule" {
  zone_id  = var.cloudflare_zone_id
  target   = "${var.backend_subdomain}.${var.domain_name}/api/*"
  priority = 1

  actions {
    cache_level = "bypass"
  }
}

# Outputs
output "backend_url" {
  value       = "https://${var.backend_subdomain}.${var.domain_name}"
  description = "Backend API URL"
}

output "backend_record_id" {
  value       = cloudflare_record.backend_api.id
  description = "Cloudflare DNS record ID for backend"
}
