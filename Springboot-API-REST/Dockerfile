# Multistage
# Stage 1
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2
FROM eclipse-temurin:21-jdk AS runner
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/target/*.jar app.jar
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
