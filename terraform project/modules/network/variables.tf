variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "vpc01-guangzhou"
}

variable "vswitches" {
  type = list(object({
    name = string
    cidr = string
    zone = string
  }))
}

variable "security_groups" {
  type = list(object({
    name = string
  }))
}

variable "security_group_rules" {
  type = list(object({
    port     = string
    cidr     = string
    sg_index = number
  }))
  default = []
}

variable "security_group_rule_type" {
  description = "安全组规则方向"
  type        = string
  default     = "ingress"
}

variable "security_group_rule_policy" {
  description = "安全组规则策略"
  type        = string
  default     = "accept"
}