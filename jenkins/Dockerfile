FROM maven:3.9.9-eclipse-temurin-17@sha256:f58d59b6273e785ac0a4477f6e9b5ba1d7731c75b906c0f7b34076f1851318cc AS maven
FROM jenkins/jenkins:2.541.3-jdk21@sha256:c4098086090ca98491d4bf66182f5e3b015a8232f2acf2df209a212a5801aa8e
USER root
COPY --from=maven /usr/share/maven /opt/maven
COPY --chmod=755 tools/ /usr/local/bin/
COPY --chown=jenkins:jenkins init.groovy.d/setup.groovy /usr/share/jenkins/ref/init.groovy.d/setup.groovy.override
ENV PATH="/opt/maven/bin:${PATH}" JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
USER jenkins
