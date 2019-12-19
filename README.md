## kubernetes下prometheus对springcloud的监控简单实现

### 说明：

利用micrometer来实现springcloud的metrics暴露

所有内容部署在kubernetes中

采用springcloud2.0来配置micrometer

这里不演示在kubernetes下部署prometheus，只演示springcloud的数据采集

### 工具介绍

Micrometer: 是一款监控指标的度量类库，主要用来对应用的jvm来进行监控 https://micrometer.io/

prometheus：目前容器监控方案的首选，是一个开源的系统监视和警报工具包https://prometheus.io/

grafana: 是一款采用 go 语言编写的开源应用，主要用于大规模指标数据的可视化展现，是网络架构和应用分析中最流行的**时序数据展示**工具.

### 实现过程：

我们拿一个简单的eureka应用来操作
This is an [example link](https://github.com/cwdgit/eureka-micrometer/ "With a Title"). 

在pom.xml文件中添加micrometer的依赖

```xml
		<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>

```



springcloud的启动文件中添加metrics内容

```yaml
spring.application.name=spring-cloud-eureka
eureka.instance.hostname=eureka-server
server.port=8761
eureka.client.register-with-eureka=false
eureka.client.fetch-registry=false
eureka.client.serviceUrl.defaultZone=http://${eureka.instance.hostname}:${server.port}/eureka/
# 通过HTTP暴露Actuator endpoints
# Use "*" to expose all endpoints, or a comma-separated list to expose selected ones
#management.endpoints.web.exposure.include=health,info,metrics
#management.endpoints.web.exposure.exclude=
management.endpoints.web.exposure.include=*
management.metrics.tags.application=${spring.application.name}

```

修改之后，maven编译成jar包，dockerfile做成镜像

```yaml
  
FROM 192.168.16.104:31104/dev/openjdk:8-jre-alpine

ADD target/*.jar /app.jar

#ADD entrypoint.sh entrypoint.sh
#RUN chmod 755 entrypoint.sh 
ENV SPRING_OUTPUT_ANSI_ENABLED=ALWAYS \
    JHIPSTER_SLEEP=0 \
    JAVA_OPTS=""


#ENTRYPOINT ["./entrypoint.sh"]
ENTRYPOINT  ["java","-jar","/app.jar"]

EXPOSE 8761
```

部署到k8s环境中,通过clusterip加端口访问监控项，我们可以访问到暴露的metrics

![image-20191218195249385](https://github.com/cwdgit/eureka-micrometer/blob/master/image/image-20191218195249385.png)

prometheus抽取数据，因为prometheus部署在k8s中，prometheus 的operator会提供对应的crd资源，他会去创建`Prometheus`、`ServiceMonitor`、`AlertManage`r以及`PrometheusRule`4个CRD资源对象，然后会一直监控并维持这4个资源对象的状态。

ServiceMonitor就可以把各种服务通过expoter暴露的metrics数据接口的内容pull到prometheus中。我们在k8s环境中创建servimonitor就可以把metrics集中在prometheus了。

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  annotations:
  labels:
    prometheus: kube-prometheus   # 要被对应的Prometheus resource的serviceMonitorSelector匹配到
    release: kube-prometheus
  name: eureka
  namespace: alauda-system
spec:
  endpoints:
  - honorLabels: true
    interval: 15s
    path: /actuator/prometheus
    port: tcp-8761-8761 # 匹配service的port name
  namespaceSelector:   # SM根据namespaceSelector的配置去匹配Service的NS
    matchNames:
    - project1-dev     
  selector:
    matchLabels:
      app.alauda.io/name: eureka-micrometers.project1-dev   #匹配service的label
```

创建完成，在prometheus内就能发现对应的targets

![image-20191218200323220](https://github.com/cwdgit/eureka-micrometer/blob/master/image/WX20191219-112555%402x.png)

在console的地方也能搜到对应的metrics![image-20191218200425976](https://github.com/cwdgit/eureka-micrometer/blob/master/image/image-20191218200425976.png)

prometheus能抽取到数据，展示就很容易了，在grafana中导入，展示指标

![image-20191218200616148](https://github.com/cwdgit/eureka-micrometer/blob/master/image/image-20191218200616148.png)

可以自己创建图形展示或者用官方提供的模板

![image-20191218200808017](https://github.com/cwdgit/eureka-micrometer/blob/master/image/image-20191218200808017.png)

官方模板效果

![image-20191218200921722](https://github.com/cwdgit/eureka-micrometer/blob/master/image/image-20191218200906083.png)

![image-20191218200906083](https://github.com/cwdgit/eureka-micrometer/blob/master/image/image-20191218200921722.png)

