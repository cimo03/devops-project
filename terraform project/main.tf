# 网络模块
module "network" {
  source = "./modules/network"

   providers = {
    alicloud = alicloud
  }

  vpc_cidr  = var.vpc_cidr
  vpc_name  = var.vpc_name

  vswitches = [
    { name = var.vswitch01_name, cidr = var.vswitch01_cidr, zone = var.vswitch01_zone },
    { name = var.vswitch02_name, cidr = var.vswitch02_cidr, zone = var.vswitch02_zone },
  ]

  security_groups = [
    { name = var.security_group01_name },
    { name = var.security_group02_name },
  ]

  security_group_rules = [
    { port = "22/22",   cidr = "0.0.0.0/0", sg_index = 0 },
    { port = "8080/8080",   cidr = "0.0.0.0/0", sg_index = 0 },
    { port = "80/80",   cidr = "0.0.0.0/0", sg_index = 0 },
    { port = "443/443", cidr = "0.0.0.0/0", sg_index = 0 },
    { port = "22/22",   cidr = "0.0.0.0/0", sg_index = 1 },
    { port = "8080/8080",   cidr = "0.0.0.0/0", sg_index = 1 },
    { port = "80/80",   cidr = "0.0.0.0/0", sg_index = 1 },
    { port = "443/443", cidr = "0.0.0.0/0", sg_index = 1 },
  ]
}

# 计算模块
module "compute" {
  source = "./modules/compute"

   providers = {
    alicloud = alicloud
  }

  vswitches_id    = module.network.vswitches_id
  vswitches_zones = module.network.vswitches_zones
  security_groups = module.network.security_groups_id
  slb_master_zone = var.vswitch01_zone
  slb_slave_zone  = var.vswitch02_zone
  instance_names  = ["server1", "server2"]
}

# 存储模块
module "storage" {
  source = "./modules/storage"

   providers = {
    alicloud = alicloud
  }

  vpc_id             = module.network.vpc01_guangzhou_id
  security_group_ids = module.network.security_groups_id
  db_name            = var.db_name
  db_account_name    = var.db_account_name
  db_account_password = var.db_account_password
}