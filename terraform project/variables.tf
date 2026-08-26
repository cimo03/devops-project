variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_name" {
  description = "VPC 名称"
  type        = string
  default     = "vpc01-guangzhou"
}

variable "vswitch01_name" {
  description = "交换机01名称"
  type        = string
}

variable "vswitch01_cidr" {
  description = "交换机01网段"
  type        = string
}

variable "vswitch01_zone" {
  description = "交换机01可用区"
  type        = string
}

variable "vswitch02_name" {
  description = "交换机02名称"
  type        = string
}

variable "vswitch02_cidr" {
  description = "交换机02网段"
  type        = string
}

variable "vswitch02_zone" {
  description = "交换机02可用区"
  type        = string
}

variable "security_group_name" {
  description = "安全组名称"
  type        = string
}

variable "security_group_rule_ip" {
  description = "安全组规则来源IP"
  type        = string
}

variable "security_group_rule_type" {
  description = "安全组规则方向"
  type        = string
}

variable "security_group_rule_port_range" {
  description = "安全组规则端口范围"
  type        = string
  default     = "80/80"
}

variable "security_group_rule_policy" {
  description = "安全组规则策略"
  type        = string
  default     = "accept"
}

variable "security_group01_name" {
  description = "安全组1名称"
  type        = string
  default     = "sg_01"
}

variable "security_group02_name" {
  description = "安全组2名称"
  type        = string
  default     = "sg_02"
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