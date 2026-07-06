# ============ 第一阶段：构建阶段 ============
FROM php:8.0-fpm-alpine AS builder

# 使用阿里云镜像源加速
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装构建工具和依赖
RUN apk add --no-cache \
    autoconf \
    gcc \
    make \
    musl-dev

# 安装 mysqli 扩展
RUN docker-php-ext-install mysqli

# ============ 第二阶段：运行阶段 ============
FROM php:8.0-fpm-alpine

# 使用阿里云镜像源并升级所有系统包（修复已知高危漏洞）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk update && apk upgrade --no-cache

# 安装运行时依赖（nginx）
RUN apk add --no-cache nginx

# 从构建阶段复制 PHP 扩展
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# 创建必要的目录
RUN mkdir -p /run/nginx && \
    mkdir -p /var/www/html

# 复制 Nginx 配置文件（确保 nginx.conf 存在于构建上下文中）
COPY nginx.conf /etc/nginx/http.d/default.conf

# 复制应用代码
COPY . /var/www/html/

# 创建非 root 用户并设置权限
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /var/www/html

# 切换用户
USER appuser

# 暴露端口
EXPOSE 80

# 启动 PHP-FPM 和 Nginx
CMD php-fpm7 -D && nginx -g "pid /run/nginx/nginx.pid; daemon off;"