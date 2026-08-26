resource "alicloud_instance" "instances" {
  count                 = length(var.instance_names)
  availability_zone     = var.vswitches_zones[count.index % 2]
  security_groups       = [var.security_groups[count.index % 2]]
  instance_type         = var.instance_type
  system_disk_category  = "cloud_essd"
  image_id              = var.image_id
  instance_name         = var.instance_names[count.index]
  vswitch_id            = var.vswitches_id[count.index % 2]
  internet_max_bandwidth_out = 5
}

# 公网 SLB
resource "alicloud_slb_load_balancer" "load_balancer" {
  address_type       = "internet"
  internet_charge_type = "PayByTraffic"
  master_zone_id     = var.slb_master_zone
  slave_zone_id      = var.slb_slave_zone
  vswitch_id         = var.vswitches_id[0]
  load_balancer_spec = "slb.s1.small"
  tags = {
    Purpose     = "Web-Server"
    Environment = "Experiment"
  }
}

resource "alicloud_slb_listener" "listener" {
  load_balancer_id = alicloud_slb_load_balancer.load_balancer.id
  backend_port     = 80
  frontend_port    = 80
  protocol         = "http"
  bandwidth        = 5
}

resource "alicloud_slb_server_group" "slb_server_group" {
  load_balancer_id = alicloud_slb_load_balancer.load_balancer.id
}

resource "alicloud_slb_backend_server" "backend_server" {
  load_balancer_id = alicloud_slb_load_balancer.load_balancer.id

  dynamic "backend_servers" {
    for_each = alicloud_instance.instances[*].id
    content {
      server_id = backend_servers.value
      weight    = 100
    }
  }
}

resource "alicloud_slb_rule" "slb_rule" {
  load_balancer_id     = alicloud_slb_load_balancer.load_balancer.id
  frontend_port        = alicloud_slb_listener.listener.frontend_port
  server_group_id      = alicloud_slb_server_group.slb_server_group.id
  domain               = "*.aliyun.com"
  health_check_interval = 10
  health_check_timeout  = 30
  healthy_threshold    = 3
  unhealthy_threshold  = 5
  listener_sync        = "off"
  scheduler            = "wrr"
  health_check         = "on"
}
