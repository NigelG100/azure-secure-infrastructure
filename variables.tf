variable "db_password" {
  description = "Password for the PostgreSQL application user"
  type        = string
  sensitive   = true
}