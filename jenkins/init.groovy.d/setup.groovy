import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.model.FreeStyleProject
import hudson.model.ParametersDefinitionProperty
import hudson.model.StringParameterDefinition
import hudson.model.BooleanParameterDefinition
import hudson.triggers.TimerTrigger
import hudson.tasks.Shell
import hudson.tasks.ArtifactArchiver

Jenkins j = Jenkins.get()
String password = System.getenv('JENKINS_ADMIN_PASSWORD')
if (!password) throw new IllegalStateException('JENKINS_ADMIN_PASSWORD must be supplied locally')
if (!(j.securityRealm instanceof HudsonPrivateSecurityRealm)) {
    def realm = new HudsonPrivateSecurityRealm(false)
    realm.createAccount('hundrik', password)
    j.securityRealm = realm
}
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
j.authorizationStrategy = strategy
j.setNumExecutors(1)
if (j.getItem('delivery-lab') == null) {
    def job = j.createProject(FreeStyleProject, 'delivery-lab')
    job.description = 'Java → Maven tests → WAR → Docker → local Kind → HTTP smoke. Configuration and stages live in Git; no external Jenkins plugins required.'
    job.addProperty(new ParametersDefinitionProperty(
        new StringParameterDefinition('SOURCE_REPOSITORY', '', 'Optional: your published HTTPS GitHub repository. Empty uses the local mounted snapshot.'),
        new StringParameterDefinition('SOURCE_BRANCH', 'main', 'Branch for the published repository')
    ))
    job.addTrigger(new TimerTrigger('H/5 * * * *'))
    job.buildersList.add(new Shell('''#!/usr/bin/env bash
set -euo pipefail
bash /opt/lab/scripts/job.sh
'''))
    def archive = new ArtifactArchiver('source/target/ROOT.war,source/target/surefire-reports/*.xml,source/target/evidence/*')
    archive.setAllowEmptyArchive(false)
    job.publishersList.add(archive)
    job.save()
}
def existingJob = j.getItem('delivery-lab')
def existingParameters = existingJob.getProperty(ParametersDefinitionProperty)
if (!existingParameters.parameterDefinitions.any { it.name == 'FORCE_REBUILD' }) {
    existingJob.addProperty(new ParametersDefinitionProperty(existingParameters.parameterDefinitions + [new BooleanParameterDefinition('FORCE_REBUILD', false, 'Rebuild even if source and deployment are unchanged')]))
    existingJob.save()
}
j.save()
