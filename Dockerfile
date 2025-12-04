# Use an OpenJDK base image
FROM eclipse-temurin:21-jre-jammy

ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app.jar"]