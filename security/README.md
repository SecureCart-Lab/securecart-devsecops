# Security gates
- **ggshield**: secrets in Git history/working tree.
- **SonarQube Community Build**: source-code quality and static analysis on the self-hosted runner.
- **OWASP Dependency-Check**: known-vulnerable Java dependencies; build fails at CVSS 7+.
- **Checkov**: Terraform misconfiguration checks.
- **Trivy**: HIGH/CRITICAL container vulnerability gate.
- **Syft**: SPDX SBOM generation.
- **Cosign**: keyless image signing with GitHub OIDC.
- **OWASP ZAP**: post-deployment DAST.
Runtime controls (Kyverno/Falco) live in the GitOps repository.
