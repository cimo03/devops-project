variable "vswitches_id" {
  description = "交换机 ID 列表"
  type        = list(string)
}

variable "vswitches_zones" {
  description = "交换机可用区列表（对应 vswitches_id）"
  type        = list(string)
}

variable "security_groups" {
  description = "安全组 ID 列表"
  type        = list(string)
}

variable "slb_master_zone" {
  description = "SLB 主可用区"
  type        = string
}

variable "slb_slave_zone" {
  description = "SLB 备可用区"
  type        = string
}

variable "instance_type" {
  description = "ECS 实例规格"
  type        = string
  default     = "ecs.e-c1m1.large"
}

variable "image_id" {
  description = "ECS 镜像 ID"
  type        = string
  default     = "centos_7_06_64_20G_alibase_20190711.vhd"
}

variable "instance_names" {
  description = "ECS 实例名称列表"
  type        = list(string)
  default     = ["server1", "server2", "server3", "server4"]
}