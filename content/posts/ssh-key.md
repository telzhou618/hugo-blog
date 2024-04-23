---
title: SSK key 免密访问 gitlab 配置
subtitle:
date: 2023-04-23T09:34:26+08:00
tags:
  - ssh
  - git
categories:
  - devops
---

## 安装最新 git
安装在最新yum源,ius源官方：https://ius.io/setup
```shell
yum install \
https://repo.ius.io/ius-release-el7.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```
安装 git
```shell
 yum remove git
 yum install -y git236
 git --version

```

## linux 配置
生成rsa公钥和秘钥,运行ssk-keygen 一路回车，注意，如果秘钥已存在会覆盖
```shell
ssh-keygen -t rsa -b 4096 -C "telzhou618@qq.com"
cat ~/.ssh/id_rsa.pub

```
![](https://raw.githubusercontent.com/telzhou618/images/main/img03/20240423100359.png)

复制公钥填写在gitlab中

![](https://raw.githubusercontent.com/telzhou618/images/main/img03/20240423095344.png)

然后在 git clone, 即可成功。

## windows 配置

生成秘钥
```shell
ssh-keygen -t rsa -b 4096 -C "telzhou618@qq.com"
cat /c/Users/Administrator/.ssh/id_rsa.pub
```

![](https://raw.githubusercontent.com/telzhou618/images/main/img03/20240423100106.png)

设置到 gitlab, 和前面linux一样。

