# Stage 1: Build the application using Maven
FROM maven:3.8.5-openjdk-17-slim AS builder

# Set working directory inside the container
WORKDIR /app

# Copy only the pom.xml and download dependencies (better caching)
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./
RUN mvn dependency:go-offline -B

# Copy the rest of the project files
COPY src ./src

# Package the application (skip tests to speed up build, can be enabled in production)
RUN mvn clean package -DskipTests

# Stage 2: Create a smaller image for running the application
FROM openjdk:17-jdk-slim

# Create a non-root user and group named 'spring'
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory inside the container
WORKDIR /app

# Copy the packaged JAR file from the builder stage
COPY --from=builder /app/target/spring-petclinic-*.jar app.jar

# Change ownership of the application files to the 'spring' user
RUN chown spring:spring app.jar

# Switch to the 'spring' user
USER spring

# Expose the port the app runs on
EXPOSE 8080

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
