---
title: "Docker & Docker-compose"
date: 2023-06-28T14:21:07+08:00
tags:
  - docker
categories:
  - devops
---
##  Docker 架构

{{< figure src="https://raw.githubusercontent.com/telzhou618/images/main/img/image-20210810154908558.png" title="Docker架构" >}}


Docker 主要组件包括 Client、Daemon、Images、Container、Registry。

- Client ： docker客户端
- Daemon：docker服务端守护进程。
- Images：docker镜像，有点像jar包。
- Container：运行docker镜像的容器，像Tomcat。
- Registry：docker镜像仓库，像maven仓库。

## Docker 常用命令

### 镜像相关的命令

#### 搜索镜像

```sh
docker search java  // 搜索镜像
```

#### 下载镜像

```sh
docker pull java:8  // 下载镜像
```

#### 查看镜像

```sh
docker images  // 查看镜像
```

#### 删除镜像

```sh
docker rmi java  // 删除镜像，加-f强制删除
docker rmi $(docker images ‐q) // 删除所有镜像
```

### 容器相关的命令

#### 运行Docker镜像

```sh
docker run -d -p 8080:80 nginx:least
```

- -d 后台运行
- -p 指定端口
  - 如：8080:8080，宿主主机端口：容器端口
- -m 指定容器的内存大小
  - 如 ：-m 500M
- -e 指定环境变量
  - 如：-e  JAVA_OPTS='‐Xms1028M ‐Xmx1028M ‐Xmn512M ‐Xss512K ‐XX:MetaspaceSize=256M ‐XX:MaxMetaspaceSize= 256M' 
- -net 设置网络
  - --net=bridge 桥接，默认
  - --net=host 容器使用宿主网络，不安全。
  - --net=container=容器ID，使用和其他容器一样的网络
- -v 指定挂在目录
  - 如: /var/nginx/logs : /nginx/logs , 宿主主机：容器主机。

#### 列出容器列表

```sh
docker ps  // 加 -a 可列出所有的容器，包含停止的容器
```

#### 停止容器

```sh
docker stop [容器ID]  // 停止容器
docker kill [容器ID]  // 强制停止容器
```

#### 启动容器

```sh
docker start [容器ID]
```

#### 查看日志

```sh
docker container logs [容器ID]
```

#### 查看容器信息

```sh
docker inspect [容器ID]
```

#### 查看容器里的进程

```
docker top [容器ID]
```

#### 文件传输

```
docker cp [容器ID]:/容器文件路径 宿主主机文件路径	// 从容器cp到主机
docker cp 宿主主机文件路径 [容器ID]:/容器文件路径	// 从主机cp到容器
```

#### 进入到容器的 shell

```sh
docker exec -it [容器ID] /bin/bash
```

#### 删除容器

```sh
docker rm [容器ID] // 删除已停止的容器
docker rm -f [容器ID] // 强制删除正在运行的容器
docker rm ‐f $(docker ps ‐a ‐q) // 强制删除所有容器
```

## Docker 构建镜像

### Dockerfile 命令

- FROM 指定基础镜像，如 java:8
- RUN 构建镜像执行的命令。
- ADD 文件复制
- COPY 文件复制，不支持URL和压缩。
- CMD 容器启动命令。
- EXPOSE 容器暴露端口。
- WORKID 容器工作路径。
- ENV 环境变量。
- ENTRPINT 和CMD类似。
- VOLUME 指定存储目录，如：VOLUME["/data"]。

### 编写Dockerfile

执行 vi Dockerfile编写镜像文件

```dockerfile
# 基础镜像
FROM java:8
# 复制文件
ADD java-demo.jar /app.jar
# 暴露端口
EXPOSE 8080
# 运行程序
CMD java -jar /app.jar
```

### 构建镜像

在Dockerfile 文件所在的目录执行以下命令构建镜像。

```
docker build -t java-demo:0.0.1 .
```

- -t 指定镜像的名称和版本，不指定版本默认为latest
- '.' 点代表Dockerfile文件的位置

### 上传到Docker镜像仓库

- 在docker hub 注册账号
- 在控制台使用 docker login 命令登录
- 给镜像打一个tag分组名称, 如： docker tag java-demo.jar:0.0.1  zhangsan/java-demo.jar:0.0.1
- push到远程仓库, 如：docker push zhangsan/java-demo.jar

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

