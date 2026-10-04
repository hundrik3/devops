# Publishing to GitHub

The project archive contains source code, documentation, and validation evidence. The local Jenkins password, kubeconfig, Maven cache, and Docker tools are excluded.

After extracting the archive, publish the project to an empty repository from the `devops` directory:

```bash
git init -b main
git add .
git status --short
# Confirm that .env, .local, and kubeconfig are not staged.
git commit -m "Add Java delivery lab with Jenkins, Docker and Kubernetes"
git remote add origin https://github.com/hundrik3/devops.git
git push -u origin main
```

These commands assume an extracted archive without a `.git` directory. In an existing checkout, do not add `origin` again. If the remote already contains commits, fetch them and reconcile the history first; do not force push.

For a demonstration, start the lab using the README and take your own screenshots of a successful Jenkins build, two pods, and the application page. Portfolio presentation guidance is in `docs/portfolio.md`; validation results are in `docs/validation.md`.

Configure the Jenkins `SOURCE_REPOSITORY` parameter to use your published URL. The primary repository is https://github.com/hundrik3/devops. You can also adapt these commands to publish an extracted archive to another repository you own.
