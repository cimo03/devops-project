# K8s 常见故障排错案例

项目中共排查解决 14 个生产级 K8s 故障，以下为完整记录。

---

### 案例 1：容器启动崩溃（CrashLoopBackOff）

**现象**：Pod 状态为 `CrashLoopBackOff`，容器反复重启。`kubectl logs` 显示 `/bin/sh: php-fpm7: not found`。

**根因**：镜像中 PHP-FPM 可执行文件名为 `/usr/local/sbin/php-fpm`，而非 `php-fpm7`。容器启动时找不到可执行文件，进程立即退出，Kubernetes 检测到容器终止，触发反复重启。

**解决方案**：将 Deployment 中 `command` 改为 `["/usr/local/sbin/php-fpm", "-F"]`，使用正确的二进制路径。

---

### 案例 2：无法通过公网访问应用（连接拒绝）

**现象**：Pod 状态为 `Running`，但通过 LoadBalancer 公网 IP 访问时，浏览器显示“拒绝连接”或 `curl` 返回 `Failed to connect`。

**根因**：PHP-FPM 使用 FastCGI 协议监听 9000 端口，不能直接处理 HTTP 请求。容器内没有进程监听 80 端口，Service 的 `targetPort` 指向 80，导致连接请求无法被接收。

**解决方案**：引入 Nginx 作为 Sidecar 容器，监听 80 端口接收 HTTP 请求，通过 `fastcgi_pass 127.0.0.1:9000` 转发给同 Pod 内的 PHP-FPM。

---

### 案例 3：Prometheus Agent 因内存不足无法调度

**现象**：集群 Pod 监控无任何数据。执行 `kubectl get pods --all-namespaces | grep prometheus` 发现 Agent Pod 状态为 `Pending`。`kubectl describe pod` 显示 `0/1 nodes are available: 1 Insufficient memory`。

**根因**：Prometheus Agent 请求的内存（Requests: 256Mi）在单节点 4GB 集群上无法满足，调度器找不到可用内存。

**解决方案**：增加一个 Worker 节点扩容集群。新节点加入后，Agent 成功调度并变为 `Running`。

---

### 案例 4：告警规则不触发（资源请求缺失）

**现象**：Prometheus Agent 正常运行，压测时 CPU 使用率很高（648m/658m），但告警规则始终为 Normal。

**根因**：Deployment 中 `resources: {}`，未设置 `requests.cpu`。`pod_cpu_utilization` 计算公式为 `(Pod 实际 CPU 用量 / Pod 请求的 CPU) × 100%`，分母为 0 时指标无法计算。

**解决方案**：在 Helm Chart 的 Deployment 模板中为 `php-fpm` 和 `nginx` 容器添加资源请求（`cpu: 100m, memory: 128Mi` 和 `cpu: 50m, memory: 64Mi`），执行 `helm upgrade`。

---

### 案例 5：添加资源请求后告警仍不触发

**现象**：已添加 `resources.requests`，但告警规则依然 Normal。

**根因**：`pod_cpu_utilization` 指标依赖 `kube-state-metrics` 正确暴露资源请求信息，存在采集延迟或数据缺失。

**解决方案**：修改告警规则，改用绝对 CPU 使用率的 PromQL 替代百分比指标：
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="prod",pod=~"my-release-deploy.*",container="php-fpm"}[2m])) by (pod) > 0.1
```
保存后重新压测，告警状态从 Normal → Pending → Firing。

---

### 案例 6：告警 Firing 但未收到通知

**现象**：告警状态已 Firing，但未收到任何通知。

**根因**：阿里云 Prometheus 托管服务已全面接入 ARMS 告警管理，通知对象为联系人 `ack_aliyun0786342958`。需在 ARMS 告警管理中心配置通知策略，才能将告警事件推送到通知渠道。

**解决方案**：采用替代验证方案——在告警规则页面直接观察状态变化，当状态变为 Firing 时截图作为告警触发的证据。

---

### 案例 7：Deployment Selector 不可变导致升级失败

**现象**：尝试修改 Deployment 的 `spec.selector.matchLabels` 添加 `version: v2` 标签时，API Server 直接拒绝，报错 `field is immutable`。

**根因**：Deployment 的 Selector 创建后不可修改，这是 Kubernetes 的设计约束，目的是保证 Deployment 对 Pod 的绝对控制权，防止两个 Deployment 争夺同一批 Pod。

**解决方案**：引入 `track` 标签方案——Deployment Selector 使用固定不变的 `track: stable` 或 `track: canary`，版本信息只打在 Pod 模板标签上，不在 Selector 中。升级时 Selector 不变，永远不会触发此错误。

---

### 案例 8：全量发布时卸载 v1 Release 导致 Ingress 丢失

**现象**：全量发布到 v2 后，卸载 v1 Release（`helm uninstall my-release-v1`）时，主 Ingress 也随之被删除，导致所有外部流量无法进入集群。

**根因**：主 Ingress 是由 v1 Release 通过 Helm 创建和管理的。卸载 v1 Release 会级联删除其管理的所有资源，包括 Deployment、Service 和 Ingress。由于没有其他 Ingress 接替，服务入口彻底丢失。

**解决方案**：采用原地升级策略——保持 Release 名称固定（如 `my-release`），全量发布时直接 `helm upgrade` 更新镜像和版本标签，而不是新建一个 Release 再删旧的。主 Ingress 始终由同一个 Release 管理，不会被意外删除。金丝雀 Ingress 独立于 Helm Release 之外，灰度结束后单独清理，不影响主入口。

---

### 案例 9：Release 名称带版本号导致命名混乱

**现象**：Release 名称 `my-release-v1` 但内部运行的是 v2 镜像和标签，名称与实际内容不匹配，后续维护和排错容易误解。

**根因**：将版本号嵌入了 Release 名称本身，但全量发布时直接原地升级了 v1 Release，导致名称失去意义。

**解决方案**：采用固定 Release 名称策略——Release 始终叫 `my-release`，不包含版本号。版本信息完全由镜像 Tag 和 Pod 的 `version` 标签承载。灰度发布时临时部署独立的 Canary Release（`my-release-canary`），验证完后直接删除。

---

### 案例 10：HPA 始终显示 `<unknown>/60%`

**现象**：压测时 Pod CPU 已很高，但 HPA 的 TARGETS 始终显示 `<unknown>/60%`，无法触发扩容。

**根因**：HPA 是在添加资源请求**之前**创建的，它缓存了旧 Pod（无 `resources.requests`）的状态。虽然 Deployment 已更新，但旧 Pod 还未被替换，HPA 仍然看到没有资源请求的旧 Pod，导致无法计算 CPU 使用率百分比。

**解决方案**：执行 `kubectl rollout restart deployment my-release-deploy -n prod` 强制重建所有 Pod。重建完成后 HPA 成功显示 `cpu: 1%/60%`。

---

### 案例 11：滚动更新时新 Pod Pending（内存不足）

**现象**：执行 `kubectl rollout restart` 后，新 Pod 处于 Pending 状态，提示 `Insufficient memory`。

**根因**：Prometheus Agent 占用了大量内存，剩余内存不够新 Pod 调度。

**解决方案**：临时停掉 Prometheus 监控组件释放内存：
```bash
kubectl scale deployment -n arms-prom arms-prometheus-ack-arms-prometheus --replicas=0
kubectl scale deployment -n arms-prom kube-state-metrics --replicas=0
kubectl scale deployment -n arms-prom o11y-addon-controller --replicas=0
kubectl delete daemonset -n arms-prom node-exporter
```
内存释放后，新 Pod 成功调度，滚动更新完成。

---

### 案例 12：HPA 扩容后大量 Pod Pending

**现象**：压测时 HPA 将副本数从 2 扩到 8，但新 Pod 全部因内存不足而 Pending，无法实际运行。

**根因**：HPA 只负责计算期望副本数并修改 Deployment，不关心集群是否有足够资源运行新 Pod。当节点内存被现有 Pod 占满时，新 Pod 无法调度。

**解决方案**：压测结束后，CPU 使用率降至 1%，HPA 等待稳定窗口（约 5 分钟）后自动缩容，所有 Pending Pod 被优先终止，副本数恢复为 2。生产环境应配合 Cluster Autoscaler 自动增加节点。

---

### 案例 13：构建流水线变量语法错误导致镜像 Tag 无效

**现象**：云效 Flow 构建流水线报错 `invalid tag "...{{CI_COMMIT_SHA}}": invalid reference format`。

**根因**：`{{}}` 是 Go 模板语法（Helm 使用），云效 Docker 构建任务使用 Shell 风格环境变量 `${}`。两种语法混用导致变量未被替换。

**解决方案**：将镜像 Tag 从 `{{CI_COMMIT_SHA}}` 改为 `${CI_COMMIT_SHA}`。

---

### 案例 14：流水线代码推送后未自动触发

**现象**：`git push` 到 Codeup 成功，但云效 Flow 流水线没有自动运行。

**根因**：Codeup Webhook 负责“通知”云效有代码推送，云效“代码源触发”开关负责“开门”允许自动运行。两者缺一不可，而代码源触发开关默认关闭。

**解决方案**：在流水线编辑页面 → 源代码卡片 → 开启“代码源触发”开关。

---

### 排错心得

1. **Events 是第一手线索**：`kubectl describe pod` 和 `kubectl describe hpa` 中的 Events 是排错的第一入口，大多数问题的根因都在其中。
2. **层级依赖要理清**：HPA 依赖 Metrics Server，告警指标依赖 `resources.requests`，Agent 依赖节点资源。上游故障会导致下游异常，排查时要追溯依赖链。
3. **缓存状态是常见坑点**：HPA 缓存旧 Pod 状态、`kube-state-metrics` 采集延迟，这类“明明配置是对的但就是不生效”的问题，往往是缓存导致的，`kubectl rollout restart` 是快速验证手段。
4. **资源配置是生产底线**：容器必须设置 `resources.requests` 和 `resources.limits`，否则监控、告警、HPA 均无法正常工作。
5. **环境差异要隔离**：通过 `track` 标签实现版本隔离，通过命名空间实现环境隔离，通过 `values-{env}.yaml` 实现配置隔离——隔离是生产稳定性的基石。