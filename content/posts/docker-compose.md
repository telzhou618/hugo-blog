---
title: "Docker-Compose 容器编排"
date: 2023-06-28T14:21:07+08:00
tags:
  - docker
categories:
  - devops
---

## Docker-Compose

可以批量管理多个容器。

### 编写 docker-compose 文件

- 以Redis为例，执行 vi docker-compose-redis.yml。

```dockerfile
version: '3'
services:
  # redis
  redis:
    image: redis
    volumes:
      - /var/volumes/redis_data:/data
    restart: always
    ports:
      - "6379:6379"
```

### 启动容器

```sh
docker-compose -f docker-compose-redis.yml up -d
docker-compose -f docker-compose-redis.yml up -d --build // 每次重新打包新的镜像
```

- -f 指定compose 文件，默认查找docker-compose.yml.
- -d 后台启动。

### 配置文件常用参数

- image 指定镜像名称或ID

```yaml
image：java
```

- build 指定Dockerfile文件的路径

```yaml
 build: ./dir
```

- command 覆盖容器启动后默认执行的命令。
- links 连接其他容器

```yaml
web:
	links:
		- db
		- redis
```

- external_links 连接外部容器，格式和links一样。

- ports 暴露端口信息，格式：宿主主机端口：容器端口,只指定容器端口时宿主主机端口随机

```yaml
ports:
  - "8081"
	- "8080:8080"
```

- expose 只保留容器端口

```yaml
expose:
	- "8000"
	- "9000"
```

- volumes 卷挂在路径，格式：宿主主机路径:容器路径

```yaml
volumes:
	- /opt/data:/var/lib/mysql
```

- environment 设置环境变量

```yaml
environment:
	RACK_ENV dev
	SHOW: false
```

- net 设置网络

```yaml
net: "bridge" 
net: "host"
net: "none"
net: "container:[service name or container name/id]"
```

- dns 设置dns,可以一个，也可以是多个

```yaml
dns: 8.8.8.8
dns:
	- 8.8.8.8
	- 9.9.9.9
```

### docker-compose 常用操作命令

- 查看容器

```bash
docker-compose -f docker-compose.yml ps
```

- 关闭/启动/重启某个容器

```bash
docker-compose -f docker-compose.yml stop/start/restart <服务名称> // 不加服务名则会操作所有容器
```

- 查看容器日志

```bash
docker-compose -f docker-compose.yml logs -f 						 	// 查看所有容器日志
docker-compose -f docker-compose.yml logs -f	<服务名> 		// 查看指定容器日志
docker-compose -f docker-compose.yml logs -f >> app.log & // 把日志输出到文件
```

- 重新构建镜像并启动

```bash
docker-compose -f docker-compose.yml up --build -d
```

- 重新构建 cokder-compose.yml 有变化的容器并启动

```bash
docker-compose -f docker-compose.yml up --fore-recreate -d
```

- 停掉容器并删除

```bash
docker-compose -f docker-compose.yml down
```

## prometheus + grafana 搭建监控

### 安装 redis-exporter
```sh
docker run -d \
	--name redis_exporter \
	-p 9121:9121 \
	-v /etc/localtime:/etc/localtime:ro \
	oliver006/redis_exporter \
	--redis.addr redis://192.168.202.101:6379 \ # redis 地址
```

### 安装 prometheus

```sh
cd /opt
mkdir prometheus
cd /opt/prometheus
vi prometheus.yml
```

prometheus.yml

```yaml
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: prometheus
 
  - job_name: redis
    static_configs:
      - targets: ['192.168.202.101:9121'] # redis_exporter 地址
        labels:
          instance: redis
```

docker 启动 prometheus

```sh
docker run  -d \
  -p 9090:9090 \
  --name=prometheus \
  -v /etc/localtime:/etc/localtime:ro \
  -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml  \
  prom/prometheus
```

### 安装grafana

```sh
cd /opt
mkdir grafana-storage
chmod 777 grafana-storage
```

```sh
# grafana
docker run -d \
  -p 3000:3000 \
  --name=grafana \
  -v /opt/grafana-storage:/var/lib/grafana \
  -v /etc/localtime:/etc/localtime:ro \
  grafana/grafana
```





```sh
docker run -d --name node_exporter \
	-p 9100:9100 \
	--restart=always \
	--net="host" \
	--pid="host" \
	-v "/proc:/host/proc:ro" \
	-v "/sys:/host/sys:ro" \
	-v "/:/rootfs:ro" \
	prom/node-exporter \
	--path.procfs=/host/proc \
	--path.rootfs=/rootfs \
	--path.sysfs=/host/sys \
	--collector.filesystem.ignored-mount-points='^/(sys|proc|dev|host|etc)($$|/)'
```

