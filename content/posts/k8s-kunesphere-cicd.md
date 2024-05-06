---
title: 【k8s学习笔记】 Kunesphere CI/CD流谁线自动化部署
date: 2024-05-06T18:26:14+08:00
slug: a9d96f7
tags:
  - k8s
categories:
  - devops

---

<!--more-->

## 准备一个 springboot 项目

项目如下，是一个简单的springboot项目

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506222151.png)

定义一个简单接口, 返回 helloworld

```java
package com.example.demo;

import org.springframework.boot.*;
import org.springframework.boot.autoconfigure.*;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class DemoApplication {

	@GetMapping("/")
	public String home() {
		return "hello world!!!";
	}

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}
}

```

单元测试类 DemoApplicationTests.java 

```java
package com.example.demo;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.junit4.SpringRunner;
import static org.assertj.core.api.Assertions.assertThat;

@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
public class DemoApplicationTests {

	@Test
	public void contextLoads() {
	}

	@Autowired
	private TestRestTemplate restTemplate;

	@Test
	public void homeResponse() {
		String body = this.restTemplate.getForObject("/", String.class);
		assertThat(body).isNotBlank();
	}
}

```



## 开启devops功能

登录 KubeSphere ，找到定制资源，搜索config

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506222844.png)

点击 ClusterConfiguration，然后点击三个点编辑YAML

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506223036.png)

编辑配置，将devops 的 enabled 改为true

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506223307.png) 

## 流水线部署

创建流水线项目

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230107.png)

进入项目创建流水线

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230210.png)

编辑流水线

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230257.png)

全局代理选择 maven

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230346.png)

第一步拉取代码

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230638.png)

第二部单元测试

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230512.png)

第三部打包并构建镜像

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230715.png)

部署到指定k8s集群

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506230750.png)

搞定！

运行流水线

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506231244.png)

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506231313.png)

运行日志

![](https://raw.gitmirror.com/telzhou618/images/main/img03/20240506231341.png)

## 所需配置文件

完整的 jenkinsfile 文件内容

```jenkins
pipeline {
  agent {
    node {
      label 'maven'
    }

  }
  stages {
    stage('拉取代码') {
      agent none
      steps {
        git(url: 'http://192.168.1.4/root/java-web-demo.git', credentialsId: 'gitlab', branch: 'master', changelog: true, poll: false)
      }
    }

    stage('单元测试') {
      agent none
      steps {
        container('maven') {
          sh 'mvn clean test'
        }

      }
    }

    stage('构建镜像') {
      agent none
      steps {
        container('maven') {
          sh 'mvn -Dmaven.test.skip=true clean package'
          sh 'docker build -f deploy/Dockerfile -t $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:SNAPSHOT-$BUILD_NUMBER .'
          withCredentials([usernamePassword(credentialsId: 'dockerhub-id', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
            sh 'echo "$DOCKER_PASSWORD" | docker login $REGISTRY -u "$DOCKER_USERNAME" --password-stdin'
            sh 'docker push $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:SNAPSHOT-$BUILD_NUMBER'
          }

        }

      }
    }

    stage('发布到test环境') {
      agent none
      steps {
        container('maven') {
          withCredentials([kubeconfigContent(credentialsId: 'demo-kubeconfig', variable: 'KUBECONFIG_CONTENT')]) {
            sh '''mkdir ~/.kube
echo "$KUBECONFIG_CONTENT" > ~/.kube/config
envsubst < deploy/k8s-deploy-test.yaml | kubectl apply -f -'''
          }

        }

      }
    }

  }
  environment {
    DOCKER_CREDENTIAL_ID = 'dockerhub-id'
    GITHUB_CREDENTIAL_ID = 'github-id'
    KUBECONFIG_CREDENTIAL_ID = 'demo-kubeconfig'
    REGISTRY = 'docker.io'
    DOCKERHUB_NAMESPACE = 'telzhou618'
    GITHUB_ACCOUNT = 'kubesphere'
    APP_NAME = 'java-web-demo-test'
  }
}
```

Dockerfile 文件

```dockerfile
FROM java:8u92-jre-alpine
MAINTAINER "telzhou618"
ADD target/java-web-demo-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

k8s-deploy.yaml 文件, 一个 Deployment, 一个service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: java-web-demo-test
  name: java-web-demo-test
  namespace: bbs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-web-demo-test
  template:
    metadata:
      labels:
        app: java-web-demo-test
    spec:
      containers:
        - name: java-web-demo-test
          image: $REGISTRY/$DOCKERHUB_NAMESPACE/$APP_NAME:SNAPSHOT-$BUILD_NUMBER
          ports:
            - containerPort: 8080
              protocol: TCP
          resources:
            limits:
              cpu: "1"
            requests:
              cpu: 500m
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: java-web-demo-test
  name: java-web-demo-test
  namespace: bbs
spec:
  ports:
    - name: http
      port: 8080
      protocol: TCP
      targetPort: 8080
      nodePort: 30963
  selector:
    app: java-web-demo-test
  type: NodePort

```
