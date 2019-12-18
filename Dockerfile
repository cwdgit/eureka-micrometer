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

