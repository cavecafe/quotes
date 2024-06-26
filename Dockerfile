FROM eclipse-temurin:17-jre-alpine
VOLUME /tmp
ARG REPO_NAME
ARG JAR_FILE
ARG BUILD_VERSION
ARG AUTHOR

RUN echo "REPO_NAME: ${REPO_NAME}"
RUN echo "JAR_FILE: ${JAR_FILE}"
RUN echo "BUILD_VERSION: ${BUILD_VERSION}"
RUN echo "AUTHOR: ${AUTHOR}"

LABEL REPO_NAME=${REPO_NAME}
LABEL JAR_FILE=${JAR_FILE}
LABEL version=${BUILD_VERSION}
LABEL authors=${AUTHOR}

EXPOSE 8080

COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
