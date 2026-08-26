# VPC
resource "alicloud_vpc" "vpc01_guangzhou" {
  vpc_name   = var.vpc_name
  cidr_block = var.vpc_cidr
}

# 交换机
resource "alicloud_vswitch" "vswitches" {
  count        = length(var.vswitches)
  vswitch_name = var.vswitches[count.index].name
  vpc_id       = alicloud_vpc.vpc01_guangzhou.id
  cidr_block   = var.vswitches[count.index].cidr
  zone_id      = var.vswitches[count.index].zone
}

# 安全组
resource "alicloud_security_group" "group" {
  count               = length(var.security_groups)
  security_group_name = var.security_groups[count.index].name
  vpc_id              = alicloud_vpc.vpc01_guangzhou.id
}

# 安全组规则
resource "alicloud_security_group_rule" "rules" {
  count             = length(var.security_group_rules)
  type              = var.security_group_rule_type
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = var.security_group_rule_policy
  port_range        = var.security_group_rules[count.index].port
  priority          = 1
  security_group_id = alicloud_security_group.group[var.security_group_rules[count.index].sg_index].id
  cidr_ip           = var.security_group_rules[count.index].cidr
}