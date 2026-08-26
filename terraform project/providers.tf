terraform {
  required_version = ">= 0.12"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.280.0"    # 回退到已验证可用的版本
    }
  }
}

provider "alicloud" {
  region = "cn-guangzhou"
}