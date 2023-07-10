---
title: "Java SPI 应用"
date: 2023-07-05T16:15:58+08:00
draft: true
---
Java SPI（Service Provider Interface）是Java平台提供的一种机制，用于实现服务发现和扩展的功能。它允许开发人员定义一组接口，然后允许其他开发人员在应用程序中提供不同的实现。
## 举个例子
某应该需要外部提供数据，具体使用USB接口传输还是Typec接口传输并不关心，官方只需定义接口，USB厂商和typec厂商各自去实现接口即可，具体如下。
创建 maven 项目 data-trans-api 为接口项目, xml 配置如下
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>spi-demo</artifactId>
        <groupId>org.example</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>data-trans-api</artifactId>

    <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
    </properties>
</project>
```
定义接口
```java
package com.example;

public interface DataProvider {
    String getData();
}

```
### usb实现项目
创建一个名称为 usb 的 maven 项目，引入前面提供的 data-trans-api 包，完整的XML如下
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>spi-demo</artifactId>
        <groupId>org.example</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>usb</artifactId>

    <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>data-trans-api</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>
</project>
```
创建类 UsbDataProvider，实现 DataProvider 接口，编写提供数据的逻辑，这里简单返回一个字符串。
```java
package com.example;

public class UsbDataProvider implements DataProvider {
    @Override
    public String getData() {
        return "从Usb接口获取数据...";
    }
}

```
然后在 resources 目录下依次创建目录 META-INF/services/
在 services 目录创建配置文件，名称为接口类的完全限定名，这里是 com.example.DataProvider
在文件内添加实现类的完全限定名，这里是 com.example.UsbDataProvider, 如果有多个实现，换行写入，每个实现类单独一行, 完整的结果如下
文件路径：resource/META-INF/services/com.example.DataProvider，文件内容如下
```shell
com.example.UsbDataProvider
```
### 使用 demo
创建 maven 项目，名称为 demo, 引入前面的接口包和实现包
```xml
<dependency>
  <groupId>org.example</groupId>
  <artifactId>data-trans-api</artifactId>
  <version>1.0-SNAPSHOT</version>
</dependency>
<dependency>
  <groupId>org.example</groupId>
  <artifactId>usb</artifactId>
  <version>1.0-SNAPSHOT</version>
</dependency>
```
编写如下代码，ServiceLoader 是 jdk 提供的获取spi对象的方法
```java
public class Main {
    public static void main(String[] args) {
        ServiceLoader<DataProvider> load = ServiceLoader.load(DataProvider.class);
        Iterator<DataProvider> iterator = load.iterator();
        while (iterator.hasNext()) {
            DataProvider provider = iterator.next();
            String data = provider.getData();
            System.out.println(data);
        }
    }
}
```
运行结果
```shell
从Usb接口获取数据...
```
可以看到拿到了 UsbDataProvider 对象实例，并且调用 getData方法成功获取到数据。

原理：ServiceLoader 会扫描所有jar包的 DataProvider 配置文件，加载实现类，并通过反射实例化。

如果有一天要用Typec获取数据，在不修改代码的情况下如何实现？
### typc实现
创建名为 typec 的 maven 项目，引入接口包 data-trans-api, xml 如下
```xml
<dependency>
  <groupId>org.example</groupId>
  <artifactId>data-trans-api</artifactId>
  <version>1.0-SNAPSHOT</version>
</dependency>
```
创建类 TypecDataProvider，实现 DataProvider 接口，编写提供数据的逻辑
```java
package com.example;

public class TypecDataProvider implements DataProvider {
    @Override
    public String getData() {
        return "从Typec接口获取数据...";
    }
}
```
同样创建配置文件 resource/META-INF/services/com.example.DataProvider，内容为TypecDataProvider 的包完全限定名，如下
```shell
com.example.TypecDataProvider
```
编译打包
将前面 demo 中的 usb 依赖改成新写的 typec 包
```xml
<dependency>
  <groupId>org.example</groupId>
  <artifactId>data-trans-api</artifactId>
  <version>1.0-SNAPSHOT</version>
</dependency>
<dependency>
  <groupId>org.example</groupId>
  <artifactId>typec</artifactId>
  <version>1.0-SNAPSHOT</version>
</dependency>
```
再次运行 main 方法
```shell
从Typc接口获取数据...
```
做到了不修改代码，只更换jar包的方式满足项目的扩展。

如果同时引入 usb 和 typec，再次运行 demo
```shell
从Usb接口获取数据...
从typc接口获取数据...
```
两个都成功，spi 允许多实现，通过 ServiceLoader#load 方法获取到的是一个集合 Iterator 对象。
## 优点

- 方便扩展，松耦合
## 缺点

- 不能懒加载，会加载所有的实现类，只能通过 Iterator 迭代才能找到想要的类。




