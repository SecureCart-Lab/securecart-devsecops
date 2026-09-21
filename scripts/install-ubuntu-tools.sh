
#!/usr/bin/env bash

set -Eeuo pipefail

# =============================================================================
# SecureCart DevSecOps Workstation Bootstrap
#
# Target:
#   Ubuntu 24.04 LTS
#
# Purpose:
#   Prepare a brand-new EC2 workstation with the engineering tools required
#   for the SecureCart DevSecOps project.
#
# IMPORTANT:
#   Run this script as the normal Ubuntu user:
#
#       ./scripts/install-ubuntu-tools.sh
#
#   DO NOT run the entire script with sudo:
#
#       sudo ./scripts/install-ubuntu-tools.sh
#
#   The script uses sudo internally only where required.
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Safety check: do not run entire script as root
# -----------------------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    echo "ERROR: Do not run this script as root."
    echo
    echo "Run it as your normal Ubuntu user:"
    echo
    echo "  ./scripts/install-ubuntu-tools.sh"
    echo
    exit 1
fi


# -----------------------------------------------------------------------------
# 2. Verify operating system
# -----------------------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID}" != "ubuntu" ]]; then
    echo "ERROR: This installer requires Ubuntu."
    echo "Detected OS: ${ID}"
    exit 1
fi

if [[ "${VERSION_ID}" != "24.04" ]]; then
    echo "ERROR: This installer is designed for Ubuntu 24.04 LTS."
    echo "Detected version: ${VERSION_ID}"
    exit 1
fi

UBUNTU_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"


# -----------------------------------------------------------------------------
# 3. Detect processor architecture
# -----------------------------------------------------------------------------

ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
    amd64)
        KUBECTL_ARCH="amd64"
        ;;
    arm64)
        KUBECTL_ARCH="arm64"
        ;;
    *)
        echo "ERROR: Unsupported CPU architecture: ${ARCH}" >&2
        exit 1
        ;;
esac


# -----------------------------------------------------------------------------
# 4. Temporary-file cleanup
# -----------------------------------------------------------------------------

cleanup() {

    rm -f \
        /tmp/aws-cli-install.sh \
        /tmp/kubectl \
        /tmp/kubectl.sha256 \
        /tmp/get_helm.sh
}

trap cleanup EXIT


# -----------------------------------------------------------------------------
# 5. Display environment
# -----------------------------------------------------------------------------

printf '\n'
printf '============================================================\n'
printf ' SecureCart DevSecOps Workstation Bootstrap\n'
printf '============================================================\n'
printf 'User:               %s\n' "${USER}"
printf 'Operating system:   Ubuntu %s\n' "${VERSION_ID}"
printf 'Ubuntu codename:    %s\n' "${UBUNTU_CODENAME}"
printf 'Architecture:       %s\n' "${ARCH}"
printf 'Home directory:     %s\n' "${HOME}"
printf '============================================================\n'


# =============================================================================
# PHASE 1 - BASE OPERATING SYSTEM PACKAGES
# =============================================================================

printf '\n==> PHASE 1: Updating Ubuntu package index\n'

sudo apt-get update


printf '\n==> Installing base engineering packages\n'

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bash-completion \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    lsb-release \
    make \
    maven \
    openjdk-21-jdk \
    openssl \
    pipx \
    python3 \
    python3-venv \
    rsync \
    unzip \
    wget \
    zip


# =============================================================================
# PHASE 2 - DOCKER ENGINE
# =============================================================================

printf '\n==> PHASE 2: Configuring Docker official repository\n'


# Create directory for repository signing keys.

sudo install -m 0755 -d /etc/apt/keyrings


# Download Docker's official signing key.

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc


# Make the signing key readable by APT.

sudo chmod a+r /etc/apt/keyrings/docker.asc


# Configure Docker's official Ubuntu repository.

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF


printf '\n==> Updating package index with Docker repository\n'

sudo apt-get update


printf '\n==> Installing Docker Engine\n'

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


printf '\n==> Enabling Docker service\n'

sudo systemctl enable --now docker


printf '\n==> Adding %s to Docker group\n' "${USER}"

sudo usermod -aG docker "${USER}"

printf '\n==> Verifying Docker group configuration\n'

if getent group docker | awk -F: -v user="${USER}" '{ n=split($4,a,","); for (i=1;i<=n;i++) if (a[i]==user) found=1 } END { exit(found ? 0 : 1) }'; then
    printf '[OK] User %s is configured as a member of the docker group.\n' "${USER}"
else
    printf 'ERROR: User %s was not added to the docker group.\n' "${USER}" >&2
    exit 1
fi


printf '\n==> Verifying Docker daemon\n'

sudo docker info >/dev/null

printf 'Docker daemon is running successfully.\n'


# =============================================================================
# PHASE 3 - AWS CLI V2
# =============================================================================

printf '\n==> PHASE 3: Installing AWS CLI v2\n'


# Download AWS's official AWS CLI installation script.

curl -fsSL \
    https://awscli.amazonaws.com/v2/install.sh \
    -o /tmp/aws-cli-install.sh


chmod 700 /tmp/aws-cli-install.sh


# Install system-wide under /usr/local.

sudo bash /tmp/aws-cli-install.sh --system


printf '\n==> Verifying AWS CLI installation\n'

aws --version


# =============================================================================
# PHASE 4 - TERRAFORM
# =============================================================================

printf '\n==> PHASE 4: Configuring HashiCorp repository\n'


# Download and install HashiCorp repository signing key.

wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    | sudo tee \
        /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        >/dev/null


sudo chmod 0644 \
    /usr/share/keyrings/hashicorp-archive-keyring.gpg


# Configure HashiCorp's official APT repository.

echo \
"deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME} main" \
    | sudo tee \
        /etc/apt/sources.list.d/hashicorp.list \
        >/dev/null


printf '\n==> Updating package index with HashiCorp repository\n'

sudo apt-get update


printf '\n==> Installing Terraform\n'

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y terraform


# =============================================================================
# PHASE 5 - KUBECTL
# =============================================================================

#
# SecureCart EKS target:
#
#     Kubernetes 1.36
#
# kubectl should remain within one minor version of the EKS control plane.
#

KUBECTL_VERSION="v1.36.2"


printf '\n==> PHASE 5: Installing kubectl %s\n' "${KUBECTL_VERSION}"


# Download kubectl.

curl -fsSLo /tmp/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"


# Download the official SHA256 checksum.

curl -fsSLo /tmp/kubectl.sha256 \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256"


printf '\n==> Verifying kubectl SHA256 checksum\n'


echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" \
    | sha256sum --check


printf '\n==> Installing kubectl into /usr/local/bin\n'


sudo install \
    -o root \
    -g root \
    -m 0755 \
    /tmp/kubectl \
    /usr/local/bin/kubectl


# =============================================================================
# PHASE 6 - HELM
# =============================================================================

printf '\n==> PHASE 6: Installing Helm 3\n'


# Download the official Helm 3 installer.

curl -fsSL \
    https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    -o /tmp/get_helm.sh


chmod 700 /tmp/get_helm.sh


# Execute installer.

bash /tmp/get_helm.sh


# =============================================================================
# PHASE 7 - CONFIGURE USER-LOCAL PATH
# =============================================================================

#
# pipx exposes installed CLI applications under:
#
#     ~/.local/bin
#
# This directory must be on PATH for commands such as:
#
#     ggshield
#     checkov
#
# This section handles:
#
#   - the current installer process
#   - future SSH sessions
#   - VS Code Remote SSH terminals
#

printf '\n==> PHASE 7: Configuring ~/.local/bin\n'


LOCAL_BIN="${HOME}/.local/bin"

mkdir -p "${LOCAL_BIN}"


# Make ~/.local/bin available immediately while this script is running.

export PATH="${LOCAL_BIN}:${PATH}"


PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'


# -----------------------------------------------------------------------------
# Add PATH to ~/.profile for login shells
# -----------------------------------------------------------------------------

touch "${HOME}/.profile"


if ! grep -Fqx "${PATH_EXPORT}" "${HOME}/.profile"; then

    cat >> "${HOME}/.profile" <<'EOF'

# User-local command-line applications
export PATH="$HOME/.local/bin:$PATH"
EOF

    printf 'Added ~/.local/bin to ~/.profile\n'

else

    printf '~/.local/bin already exists in ~/.profile\n'

fi


# -----------------------------------------------------------------------------
# Add PATH to ~/.bashrc for interactive / VS Code Remote SSH terminals
# -----------------------------------------------------------------------------

touch "${HOME}/.bashrc"


if ! grep -Fqx "${PATH_EXPORT}" "${HOME}/.bashrc"; then

    cat >> "${HOME}/.bashrc" <<'EOF'

# User-local command-line applications
# Includes applications installed using pipx.
export PATH="$HOME/.local/bin:$PATH"
EOF

    printf 'Added ~/.local/bin to ~/.bashrc\n'

else

    printf '~/.local/bin already exists in ~/.bashrc\n'

fi


# =============================================================================
# PHASE 8 - GGSHIELD
# =============================================================================

printf '\n==> PHASE 8: Installing GitGuardian ggshield with pipx\n'


pipx install ggshield


# =============================================================================
# PHASE 9 - CHECKOV
# =============================================================================

printf '\n==> PHASE 9: Installing Checkov with pipx\n'


pipx install checkov


# Refresh Bash command lookup cache.

hash -r


# =============================================================================
# PHASE 10 - VERIFY COMMAND PATHS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' Verifying Installed Commands\n'
printf '============================================================\n'


REQUIRED_COMMANDS=(
    git
    java
    mvn
    docker
    aws
    terraform
    kubectl
    helm
    jq
    pipx
    ggshield
    checkov
)


FAILED=0


for command_name in "${REQUIRED_COMMANDS[@]}"; do

    if command -v "${command_name}" >/dev/null 2>&1; then

        printf '[OK]      %-12s %s\n' \
            "${command_name}" \
            "$(command -v "${command_name}")"

    else

        printf '[MISSING] %-12s\n' "${command_name}"

        FAILED=1

    fi

done


if [[ "${FAILED}" -ne 0 ]]; then

    printf '\n'
    printf 'ERROR: One or more required commands could not be found.\n'
    printf 'Review the installation output above.\n'

    exit 1

fi


# =============================================================================
# PHASE 11 - DISPLAY INSTALLED VERSIONS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' Installed Tool Versions\n'
printf '============================================================\n'


printf '\n--- Git -----------------------------------------\n'
git --version


printf '\n--- Java ----------------------------------------\n'
java -version


printf '\n--- Maven ---------------------------------------\n'
mvn --version


printf '\n--- Docker --------------------------------------\n'
docker --version


printf '\n--- Docker Compose ------------------------------\n'
docker compose version


printf '\n--- AWS CLI -------------------------------------\n'
aws --version


printf '\n--- Terraform -----------------------------------\n'
terraform version


printf '\n--- kubectl -------------------------------------\n'
kubectl version --client


printf '\n--- Helm ----------------------------------------\n'
helm version --short


printf '\n--- jq ------------------------------------------\n'
jq --version


printf '\n--- pipx ----------------------------------------\n'
pipx --version


printf '\n--- ggshield ------------------------------------\n'
ggshield --version


printf '\n--- Checkov -------------------------------------\n'
checkov --version


# =============================================================================
# PHASE 12 - FINAL INSTRUCTIONS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' SecureCart Workstation Bootstrap Complete\n'
printf '============================================================\n'


printf '\n'
printf 'The engineering workstation was initialized successfully.\n'


printf '\nIMPORTANT:\n'
printf '\n'
printf 'Your Ubuntu user was added to the Docker group.\n'
printf 'The CURRENT SSH session does not automatically receive the\n'
printf 'new Docker group membership.\n'


printf '\n'
printf 'Disconnect from this EC2 instance and reconnect using\n'
printf 'VS Code Remote SSH before continuing the project.\n'


printf '\n'
printf 'After reconnecting, run:\n'
printf '\n'

printf '  id\n'
printf '  docker ps\n'
printf '  git --version\n'
printf '  java -version\n'
printf '  mvn --version\n'
printf '  aws --version\n'
printf '  terraform version\n'
printf '  kubectl version --client\n'
printf '  helm version --short\n'
printf '  ggshield --version\n'
printf '  checkov --version\n'


printf '\n'
printf 'AWS CREDENTIALS:\n'
printf '\n'
printf 'AWS CLI has been installed, but this script deliberately\n'
printf 'does NOT run "aws configure".\n'
printf '\n'
printf 'AWS authentication will be configured separately.\n'


printf '\n'
printf '============================================================\n'