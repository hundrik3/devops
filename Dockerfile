FROM tomcat:10.1.34-jdk17-temurin@sha256:6cc7480fb8de7028d1f740704364703c55878564204bbe89186f549eb78e7ee7
# The WAR is expanded during CI, so startup never writes into the read-only webapps directory.
COPY --chown=10001:10001 target/runtime/ /usr/local/tomcat/webapps/ROOT/
ENV CATALINA_TMPDIR=/tmp
USER 10001:10001
EXPOSE 8080
CMD ["catalina.sh", "run"]
