# syntax=docker/dockerfile:1.7
FROM maven:3.9.15-eclipse-temurin-26 AS build
WORKDIR /workspace
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -q clean verify -DskipTests=false -Ddependency-check.skip=true

FROM eclipse-temurin:21-jre-jammy
RUN groupadd --system securecart && useradd --system --gid securecart --create-home securecart
WORKDIR /app
COPY --from=build /workspace/target/securecart-*.jar /app/securecart.jar
USER securecart:securecart
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/securecart.jar"]
