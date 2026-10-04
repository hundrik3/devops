# Local lab validation

Date: October 4, 2026. Validation ran on Linux x86_64 with Docker Engine 28.4.0 using the vfs storage driver.

| Check | Result | Evidence |
|---|---|---|
| Maven build and WAR packaging | PASS | Jenkins builds #6, #8, #9 |
| JUnit | 4 tests, 0 failures, 0 errors, 0 skipped | evidence/junit.xml |
| Docker build and containerd local import | PASS | evidence/jenkins-console.txt |
| Kubernetes rollout | PASS, 2 available replicas | evidence/deployment.txt, evidence/pods.txt |
| HTTP smoke tests | All 6 checks passed | evidence/jenkins-console.txt |
| Request through the actual ClusterIP Service from the Kind node | Hello, Service! | evidence/service-response.txt |
| Repeated delivery | PASS | Successful builds #6 and #8 |
| WAR and JUnit XML archiving | PASS | Finished: SUCCESS; WAR verified in the Jenkins archive |
| Unchanged-source optimization | PASS, build #7; tests and rollout were skipped | evidence/unchanged-console.txt |
| Rollback from build #8 to image #6, followed by HTTP smoke tests | PASS | evidence/rollback.txt |
| Restoration of image #8 after rollback | PASS | evidence/rollback.txt |
| Jenkins and Kubernetes restart | PASS; followed by full successful build #9 | evidence/restart.txt, evidence/jenkins-build.json |
| Repeated bootstrap without rebuilding Jenkins | PASS | evidence/repeated-bootstrap.txt |
| Jenkins authentication | Authenticated job access works; anonymous access is denied | scripts/check-jenkins.py completed successfully |
| Kubernetes server-side dry-run and Pod Security policy | PASS | API server accepted the Deployment, Service, and Namespace |
| Bash/Python syntax and Compose configuration | PASS | Checked with local commands |

Versions: Jenkins 2.541.3 / JDK 21, Maven 3.9.9, application compiled with Java release 17 and served by Tomcat 10.1.34 / JDK 17, Kind 0.27.0, and Kubernetes/kubectl 1.32.2. Docker images are pinned by digest, and CLI binaries are verified with SHA-256.

## Resolved setup issues

- The nested Docker environment did not support IPv6 iptables or overlayfs inside Kind. An IPv4 network and the native snapshotter were used.
- The containerd 2 transfer import API could not unpack the selected snapshotter. Local `ctr images import --local --snapshotter=native` resolved the issue.
- The missing kernel log device was restored inside the lab's own Kind node.
- Maven was configured to use the existing HTTPS proxy and trusted CA certificates without disabling TLS verification.
- Read permissions for the init script and execute permissions for the CLI binaries were corrected in the Jenkins container.
- Initial builds exhausted disk space with vfs: functional checks passed, but archiving failed. Intermediate setup artifacts were removed, the Dockerfile was reduced to a single application layer, Jenkins image rebuilding was made conditional on input hashes and image identity, and unchanged healthy deployments were excluded from rebuilding. Final builds #6, #8, and #9 succeeded completely.

## Not performed

AWS EC2 deployment, image registry publishing, GitHub webhooks, remote GitHub source mode after publication, security scanning, load testing, and continuous availability measurement during rolling updates were not performed. Screenshots were not generated; take them from your own lab following docs/portfolio.md.

This evidence covers the current local environment. Restoration in a new cloud task after snapshot publication was not independently tested. The install_script and start_skill configuration fields were saved as an environment draft; cloud environment publication was not independently verified. Application checks refer to the local lab, not GitHub-hosted infrastructure.
