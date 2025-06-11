variable "db_name" {
  description = "Ім'я бази даних WordPress"
  type        = string
  default     = "wordpress"
}

variable "db_user" {
  description = "Ім'я користувача бази даних"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Пароль користувача бази даних"
  type        = string
  default     = "password123"
}

variable "key_name" {
  description = "Назва SSH ключа AWS EC2"
  type        = string
}
