variable "db_password" {
  description = "Password for the PostgreSQL application user"
  type        = string
  sensitive   = true
}

variable "admin_source_ip" {
  description = "Public IP/CIDR allowed to SSH to the web tier"
  type        = string
}

