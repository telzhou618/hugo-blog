---
title: MongoDB Docker 安装和使用
subtitle:
date: 2024-05-28T13:57:05+08:00
slug: 359bede
draft: true
tags:
  - mongodb
categories:
  - db

---

## docker 安装 mongodb

1.拉取mongodb镜像

```shell
docker pull mongo

```

2.创建文件夹

```shell
mkdir -p /home/mongo/conf/
mkdir -p /home/mongo/data/
mkdir -p /home/mongo/logs/

```

3.新增mongod.conf文件

```shell
cd /home/mongo/conf && vi mongod.conf

```

mongod.conf文件内容：

```shell
# 数据库文件存储位置
dbpath = /data/db
# log文件存储位置
logpath = /data/log/mongod.log
# 使用追加的方式写日志
logappend = true
# 是否以守护进程方式运行
# fork = true
# 全部ip可以访问
bind_ip = 0.0.0.0
# 端口号
port = 27017
# 是否启用认证
auth = true
# 设置oplog的大小(MB)
oplogSize=2048

```

4.新增mongod.log文件

```shell
cd /home/mongo/logs/ && vi mongod.log

##log文件不需要内容##
chmod  777 mongod.log 

```

5.docker容器构建以及启动mongodb

```shell
cd /
docker run -it \
	--name mongodb \
	--restart=always \
    --privileged \
    -p 27017:27017 \
    -v /home/mongo/data:/data/db \
    -v /home/mongo/conf:/data/configdb \
    -v /home/mongo/logs:/data/log/  \
    -d mongo:latest \
    -f /data/configdb/mongod.conf

```

6.进入容器创建管理员

```shell
##进入容器##
docker exec -it mongodb /bin/bash

##进入mongodb shell##
mongosh

##切换到admin库##
> use admin

##创建账号/密码##
db.createUser({ user: 'admin', pwd: 'admin', roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] });

```

7.使用 Mongodb-compass工具连接 URL 如下所示

```shell
mongodb://admin:*****@127.0.0.1:27017/
```

## 创建账号和数据库

1.使用管理员账号密码登录，然后创建新的数据库，再给新库创建用户
```shell
mongosh -u admin -p admin

use poetry-app

# 创建账号, 授予读写权限
db.createUser(
{
    user:"poetry",
    pwd:"123456",
    roles:[{role:"readWrite",db:"poetry-app"}]
    }
);

```
2.用新账号连接使用
```shell
mongosh -u poetry -p 123456 --authenticationDatabase poetry-app

```

## 账号管理
例子1：在lijiamandb数据库中，创建用户lijiaman，对该库具有读写权限。
```shell
use lijiamandb

db.createUser(
{
    user:"lijiaman",
    pwd:passwordPrompt(),
    roles:[{role:"readWrite",db:"lijiamandb"}]
    }
)
```
例子2：在reportdb数据库中，创建用户report，对reportdb数据库具有读写权限，对lijiamandb具有读的权限。
```shell
use reportdb

db.createUser(
    {
        user:"report",
        pwd:passwordPrompt(),
        roles:[
            {role:"readWrite",db:"reportdb"},
            {role:"read",db:"lijiamandb"}
        ]
    }
)
```
删除用户
```shell
db.dropUser("user_name")
```
修改密码，例如，把lijiamandb数据库中的user1用户的密码改为123456。
```shell
use lijiamandb
db.changeUserPassword("user1", "123456")
```
查看所有用户
```shell
use admin
db.system.users.find().pretty()
```
