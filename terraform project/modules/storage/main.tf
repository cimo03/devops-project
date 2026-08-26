# OSS Bucket
resource "alicloud_oss_bucket" "bucket" {
  bucket = "bucket01-gz-20260606-001"
  referer_config {
    allow_empty = true
    referers    = ["http://www.aliyun.com", "https://www.aliyun.com"]
  }
}

resource "alicloud_oss_bucket_acl" "bucket-acl" {
  bucket = alicloud_oss_bucket.bucket.bucket
  acl    = "private"
}

# RDS 交换机
resource "alicloud_vswitch" "db_vswitch" {
  vpc_id        = var.vpc_id
  cidr_block    = "172.16.3.0/24"
  zone_id       = "cn-guangzhou-a"
  vswitch_name  = "vswitch_03"
}

# RDS 实例
resource "alicloud_db_instance" "db_instance" {
  engine                 = "MySQL"
  engine_version         = "8.0"
  instance_type          = "rds.mysql.t1.small"
  instance_storage       = 20
  instance_charge_type   = "Postpaid"
  vswitch_id             = alicloud_vswitch.db_vswitch.id
  monitoring_period      = "60"
  security_group_ids     = var.security_group_ids
}

# 数据库
resource "alicloud_db_database" "liuyan_db" {
  instance_id   = alicloud_db_instance.db_instance.id
  name          = var.db_name
  character_set = "utf8mb4"
}

# 账号
resource "alicloud_db_account" "app_account" {
  instance_id      = alicloud_db_instance.db_instance.id
  account_name     = var.db_account_name
  account_password = var.db_account_password
}

# 权限
resource "alicloud_db_account_privilege" "app_privilege" {
  instance_id  = alicloud_db_instance.db_instance.id
  account_name = alicloud_db_account.app_account.account_name
  db_names     = [alicloud_db_database.liuyan_db.name]
  privilege    = "ReadWrite"
}