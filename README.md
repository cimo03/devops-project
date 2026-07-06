# ACK DevOps 项目实践

基于阿里云 ACK 的留言板应用全链路部署、CI/CD、灰度发布、监控告警与弹性伸缩实践。

## 项目背景

独立完成，将 PHP 留言板应用容器化并部署到阿里云 ACK 集群，搭建完整的 CI/CD 流水线，实现灰度发布、健康检查、监控告警和 HPA 弹性伸缩。项目中独立排查并解决 14 个 K8s 生产级故障。

## 技术栈

- **云平台**：阿里云 ACK、ACR、ECS、VPC、RDS、OSS
- **容器编排**：Docker、Kubernetes（Deployment/Service/Ingress/HPA/Helm）
- **CI/CD**：云效 Flow（构建与部署分离）、Codeup
- **监控**：Prometheus 托管版、ARMS 告警管理
- **脚本工具**：Shell、Helm Chart 模板化
- **应用源码**：PHP（源码见src/目录）

## 项目架构

> ![image](D:\devops-project\images\image.png)

## 核心成果

- 使用 Helm Chart 实现一键部署，支持staging/prod 两套环境参数化配置
- 搭建云效 Flow 构建与部署分离的 CI/CD 流水线，镜像 Tag 使用 Git 提交哈希
- 基于 Nginx Ingress Canary 实现灰度发布（10%→100% 流量切换）
- 配置 Prometheus 监控告警规则，解决因资源请求缺失导致的指标采集失败
- 配置 HPA 弹性伸缩，压测验证副本数从 2 自动扩至 8，5分钟后副本数恢复至 2

## 文档索引

- [Kubernetes 网络与服务发现深度梳理](docs/k8s-network-deep-dive.md)
- [Prometheus 监控告警与 HPA 弹性伸缩](docs/prometheus-and-hpa.md)
- [健康检查探针、灰度发布、全量发布与回滚联动](docs/canary-rollout-and-rollback.md)
- [流水线构建与部署分离、参数化、带审批、多环境隔离](docs/ci-cd-pipeline.md)
- [云效 Flow 构建流水线](docs/yunxiao-build-pipeline.md)
- [使用 Helm 模板化管理留言板应用](docs/helm-chart-practice.md)

## 排错记录

项目中共排查解决 14 个 K8s 生产级故障，详见 [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。