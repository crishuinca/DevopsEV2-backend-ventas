# Multistage
# Stage 1
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2
FROM eclipse-temurin:21-jre AS runner
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r spring && useradd -r -g spring spring
COPY --from=builder /build/target/*.jar app.jar
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh \
    && chmod +x /entrypoint.sh \
    && chown -R spring:spring /app /entrypoint.sh
USER spring:spring
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
