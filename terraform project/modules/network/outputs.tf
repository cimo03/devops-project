output "vpc01_guangzhou_id" {
  value = alicloud_vpc.vpc01_guangzhou.id
}

output "vswitches_id" {
  value = alicloud_vswitch.vswitches[*].id
}

output "vswitches_zones" {
  value = alicloud_vswitch.vswitches[*].zone_id
}

output "security_groups_id" {
  value = alicloud_security_group.group[*].id
}