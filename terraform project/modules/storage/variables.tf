variable "vpc_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "db_name" {
  description = "数据库名称"
  type        = string
  default     = "liuyan"
}

variable "db_account_name" {
  description = "数据库账号"
  type        = string
  default     = "db_admin"
}

variable "db_account_password" {
  description = "数据库账号密码"
  type        = string
  sensitive   = true
}