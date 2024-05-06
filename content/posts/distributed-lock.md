---
title: "Redis 或 Zookeeper 实现分布式锁"
date: 2022-06-28T11:44:07+08:00
tags:
  - lock
  - java
categories:
  - java
---
---
分布式锁是为了解决跨进程、跨服务应用在高并发场景下造成线程不安全的问题的一种同步加锁的技术方案，在互联网公司有广泛的使用场景，如秒杀项目减库存场景，分布式锁可以保证所有参与者按顺序排队访问某一资源，谁排在最前面谁就有资格获得资源的使用权，排在后面的线程必须等到持有锁的线程释放锁才有可能获取资源使用权，后面的线程要么等待要么放弃。

分布式锁是缺点：造型系统 **吞吐量、可用性** 下降。


## Redis 实现分布式锁

- 需要用到redisson包,新建spring-boot项目，导入redisson包
```xml
 <dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson-spring-boot-starter</artifactId>
    <version>3.15.6</version>
</dependency>
```

- 配置Redis连接信息
```yaml
spring:
  redis:
    database: 0
    host: 127.0.0.1
    port: 6379
```

- 锁的具体使用代码
```java
@RestController
@AllArgsConstructor
public class DistributedLockRedissonController {

    private final RedissonClient redissonClient;
    private final StringRedisTemplate stringRedisTemplate;

    /**
     * redisson 分布式锁
     */
    @RequestMapping("/redisson/doReduceStack")
    public String doReduceStack() {
        // 检查库存
        int store = Integer.parseInt(stringRedisTemplate.opsForValue().get("store"));
        if (store <= 0) {
            throw new RuntimeException("库存不足");
        }
        RLock lock = redissonClient.getLock("lock");
        try {
            lock.lock();
            // 双重检查
            store = Integer.parseInt(stringRedisTemplate.opsForValue().get("store"));
            if (store <= 0) {
                throw new RuntimeException("库存不足");
            }
            // 减库存
            stringRedisTemplate.opsForValue().set("store", String.valueOf(store - 1));
            // 生成订单
            System.out.println("下单成功");
            return "下单成功";
        } finally {
            if (lock.isLocked() && lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }
}
```
- 实现原理

待完善


## ZK 实现分布式锁

- 需要用到curator包，新建spring-boot项目，导入curator包
```xml
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-framework</artifactId>
    <version>5.1.0</version>
</dependency>
```


- 配置zookeeper连接信息
```yaml
spring:
      zookeeper:
        address: 127.0.0.1:2181
```

- 注册CuratorFramework客户端
```java
@Configuration
public class CommonConfig {

    @Value("${spring.zookeeper.address}")
    private String zookeeperAddress;

    @Bean
    @ConditionalOnMissingBean({CuratorFramework.class})
    public CuratorFramework curatorFramework() {
        CuratorFramework curatorFramework = CuratorFrameworkFactory.newClient(zookeeperAddress, new RetryNTimes(5, 1000));
        curatorFramework.start();
        return curatorFramework;
    }
}
```


- zookeeper分布式锁使用
```java
@RestController
@AllArgsConstructor
public class DistributedLockZookeeperController {

    private CuratorFramework curatorFramework;

    /**
     * zookeeper 分布式锁
     */
    @RequestMapping("/zookeeper/get-lock")
    public String doReduceStack() throws Exception {
        InterProcessMutex lock = new InterProcessMutex(curatorFramework, "/zookeeper/lockId");

        // zookeeper 加锁的两种方式

        // lock.acquire()
        // 尝试加锁，如果加锁失败，会一致的等到加锁成功。

        // lock.acquire(3, TimeUnit.SECONDS)
        // 尝试加锁，如果加锁失败会在3秒内不断获取所，如果3秒内获取锁失败，则抛异常

        if (lock.acquire(3, TimeUnit.SECONDS)) {
            try {
                // 执行业务
                System.out.println("获得锁成功，执行业务逻辑！");
                TimeUnit.SECONDS.sleep(2);
                return "success";
            } finally {
                if (lock.isOwnedByCurrentThread()) {
                    lock.release();
                }
            }
        } else {
            throw new RuntimeException("操作过于频繁");
        }
    }

}
```
- 实现原理

待完善

## 分布式锁总结
