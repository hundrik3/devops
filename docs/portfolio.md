# Portfolio overview

**Java Delivery Lab: CI/CD with Jenkins, Docker, and Kubernetes**

A local lab for automated delivery of a Java web application. Maven compiles the application, runs JUnit tests, and produces a WAR. Jenkins runs the CI/CD script, builds the Tomcat container image, imports it into Kind, and deploys two Kubernetes replicas. Delivery finishes with rollout verification and HTTP smoke tests.

Stack: Java 17, Jakarta Servlet, Maven, JUnit 5, Jenkins, Docker, Kubernetes, Kind, and Bash.

Implemented capabilities:

- Jenkins job configuration stored in code, with no additional plugins required.
- Image tags linked to the source revision and build number.
- Startup, readiness, and liveness probes, with explicit resource limits.
- An unprivileged application container with a read-only root filesystem.
- WAR files, test reports, and delivery evidence archived by Jenkins.
- Repeatable startup and cleanup commands.

Inspired by DevCloudNinjas project #5, with AWS EC2 replaced by local Kind. Results refer to the local lab. Supporting evidence is available in `evidence/` and `docs/validation.md`.

## Suggested demonstration

1. Explain the delivery architecture and Jenkins job configuration.
2. Show a successful Jenkins build, the test count, and the archived WAR.
3. Show two Ready pods and the image tag containing the build number.
4. Access the application and health endpoints through port forwarding.
5. Change the page, run a new build, and inspect the new Deployment revision.
6. Roll back to the previous version and repeat the smoke test.

Take screenshots from your own running lab: a Jenkins build, pod status, and the application page. Screenshots from the original tutorial are not included.

## Topics to understand

- Why the Java application is packaged as a WAR and served by Tomcat.
- How readiness differs from liveness and why a startup probe is useful.
- How a Service selects pods through labels.
- Why image tags include a revision instead of using `latest`.
- How failed tests or HTTP checks stop delivery.
- How local image import into Kind differs from pushing to a registry.
- What privileges the Docker socket gives Jenkins.
- Why two replicas on a single node do not protect against node failure.
