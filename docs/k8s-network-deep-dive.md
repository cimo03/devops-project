# Kubernetes 集群内部流量链路与服务发现机制 · 深度梳理

> **背景**：在实操Kubernetes过程中，围绕 LoadBalancer Service、Ingress、ClusterIP 以及不同命名空间下资源间的调用关系，提出了一系列层层递进的疑问。对这些问题及其背后的核心原理进行归档，理清整个 K8s 网络流量的真实流转逻辑。

---

## 1. 核心代理链：一个 LoadBalancer Service 内部发生了什么？

这是理解一切的基础。一个 `type: LoadBalancer` 的 Service，本身就是一条完整的代理链。

**核心问题**：流量路径里那个 `Service (ClusterIP)`，到底是指自己创建的 ClusterIP Service，还是 LoadBalancer Service 自带的？

**结论**：它就是 **LoadBalancer Service 自身所拥有的 ClusterIP**，完全不涉及其他 Service。

**完整链路**：
`用户` → `公网 CLB` → `NodePort（任意 Worker 节点）` → `kube-proxy (DNAT)` → `ClusterIP（该 LoadBalancer Service 自身的虚拟 IP）` → `kube-proxy (再次 DNAT)` → `目标 Pod`

**关键认知**：
-   **ClusterIP 没有物理载体**：它不是任何网卡上的真实 IP，你在节点上执行 `ip addr` 绝对看不到它。
-   **它本质上是 Linux 内核中的 iptables/ipvs 规则**：Kube-proxy 通过这些规则，拦截目标是 ClusterIP 的流量，并将其 DNAT（目标地址转换）为真实 Pod IP。

---

## 2. Ingress 体系中的两个 Service：组件角色拆解

这是最容易混淆的地方。Ingress Controller 的 Service 和你的业务 Service 没有任何配置上的引用关系，它们是两个完全独立的组件。

| 对比维度     | Ingress Controller 的 Service        | 业务应用的 Service                                   |
| ------------ | ------------------------------------ | ---------------------------------------------------- |
| **服务对象** | Ingress Controller Pod               | 你的业务 Pod                                         |
| **类型**     | 通常为 `LoadBalancer`                | 通常为 `ClusterIP`                                   |
| **作用**     | 提供**唯一公网入口**，引入流量到集群 | 提供**内部固定入口**（ClusterIP），做 Pod 间负载均衡 |
| **位置**     | 专用命名空间（如 `ingress-nginx`）   | 业务命名空间                                         |
| **协作关系** | 只负责接客                           | 只负责引路                                           |

**流量链路串联**：
`公网 CLB` → `Ingress Controller 的 Service` → `Ingress Controller Pod` → **（Pod 内部根据 Ingress 规则转发）** → `业务 Service (ClusterIP)` → `业务 Pod`

**结论**：Ingress Controller Pod 是唯一的“中间人”，它主动连接业务 Service 的 ClusterIP，把两个独立的 Service 串联起来。

---

## 3. Ingress 资源与 Ingress Controller：定义、部署与更新机制

**核心问题**：Ingress Controller 的部署文件和 `ingress.yaml` 是同一个文件吗？更新 Ingress 规则后，Controller 如何感知？

**结论**：它们是完全不同的两样东西。

-   **Ingress Controller 部署文件**：装软件。定义的是 Deployment（Pod 怎么跑）、Service（创建公网 CLB）、RBAC（授予监听权限）。
-   **Ingress 资源文件 (`ingress.yaml`)**：写规则。定义的是具体的路由规则（域名、路径转发到哪个 Service）。

**协作关系**：
`[Ingress Controller Pod (执行者)]` --(全集群监听 Ingress 资源变化)--> `[Ingress 资源 A] [Ingress 资源 B]`
-   **更新机制**：更新业务命名空间的 Ingress 资源后，API Server 触发通知，Controller 拉取全集群最新 Ingress 规则，热重载自身配置（如 `nginx.conf`），立即生效。**无需重启 Pod**。

**命名空间**：Ingress Controller 部署在 `ingress-nginx` 等专用命名空间，Ingress 资源与业务应用在同一业务命名空间。

---

## 4. 命名空间的隔离性与跨命名空间通信

**核心问题**：不同命名空间下的 Service，到底能不能跨命名空间发现并转发流量到另一个命名空间的 Pod？

**结论**：
-   **服务发现隔离（不能）**：Service 是**命名空间作用域**的资源。它只会在自己所在的命名空间内，通过 Label Selector 查找 Pod 来填充 Endpoints 列表。**B 的 Service 的 Endpoints 里，永远不会出现 A 的 Pod IP。**
-   **物理网络连通（能）**：网络层是通的。你可以通过 DNS 全称 `<service-name>.<namespace>.svc.cluster.local` 跨命名空间访问。

**一句话总结**：逻辑上找不着，物理上去得了。

---

## 5. 总结：Kubernetes 流量一页纸速查

| 场景                    | 执行者                 | 依赖机制           | 核心原则                                                     |
| ----------------------- | ---------------------- | ------------------ | ------------------------------------------------------------ |
| **单 Service 内部流量** | kube-proxy             | iptables/ipvs 规则 | Service 用自己的 ClusterIP 代理流量，ClusterIP 无实体，只是内核规则 |
| **Ingress 公网接入**    | Ingress Controller Pod | Ingress 资源规则   | Controller Service 负责接客，业务 Service 负责引路，两者解耦 |
| **跨命名空间访问**      | 源 Pod                 | DNS 解析           | 逻辑隔离（Service 选择器看不见），网络不隔离（通过域名可访问） |
| **配置更新生效**        | Ingress Controller     | Watch API Server   | 动态监听，热重载，无需重启                                   |
