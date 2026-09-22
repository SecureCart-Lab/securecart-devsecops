
#!/usr/bin/env bash

set -Eeuo pipefail

# =============================================================================
# SecureCart DevSecOps Engineering Workstation Bootstrap
#
# Target:
#   Ubuntu 24.04 LTS
#
# Run as:
#   ./scripts/install-ubuntu-tools.sh
#
# DO NOT run as:
#   sudo ./scripts/install-ubuntu-tools.sh
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Safety checks
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

INSTALL_USER="$(id -un)"
USER_HOME="${HOME}"


# -----------------------------------------------------------------------------
# 2. Verify Ubuntu 24.04
# -----------------------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: /etc/os-release was not found."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID}" != "ubuntu" ]]; then
    echo "ERROR: This installer requires Ubuntu."
    echo "Detected OS: ${ID}"
    exit 1
fi

if [[ "${VERSION_ID}" != "24.04" ]]; then
    echo "ERROR: This installer requires Ubuntu 24.04 LTS."
    echo "Detected version: ${VERSION_ID}"
    exit 1
fi

UBUNTU_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME}}"


# -----------------------------------------------------------------------------
# 3. Detect architecture
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
        echo "ERROR: Unsupported architecture: ${ARCH}" >&2
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
        /tmp/get_helm.sh \
        /tmp/hashicorp-archive-keyring.gpg
}

trap cleanup EXIT


# -----------------------------------------------------------------------------
# 5. Error reporting
# -----------------------------------------------------------------------------

trap 'echo; echo "ERROR: Installation failed at line ${LINENO}."; exit 1' ERR


# -----------------------------------------------------------------------------
# 6. Display environment
# -----------------------------------------------------------------------------

printf '\n'
printf '============================================================\n'
printf ' SecureCart DevSecOps Workstation Bootstrap\n'
printf '============================================================\n'
printf 'User:               %s\n' "${INSTALL_USER}"
printf 'Operating system:   Ubuntu %s\n' "${VERSION_ID}"
printf 'Ubuntu codename:    %s\n' "${UBUNTU_CODENAME}"
printf 'Architecture:       %s\n' "${ARCH}"
printf 'Home directory:     %s\n' "${USER_HOME}"
printf '============================================================\n'


# -----------------------------------------------------------------------------
# 7. Validate passwordless sudo access
# -----------------------------------------------------------------------------

printf '\n==> Validating passwordless sudo access\n'

if ! sudo -n true 2>/dev/null; then
    echo "ERROR: Passwordless sudo is required for this installer."
    echo
    echo "Verify with:"
    echo
    echo "  sudo -n whoami"
    echo
    exit 1
fi

printf '[OK] Passwordless sudo access is available.\n'


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
# PHASE 2 - DOCKER ENGINE AND DOCKER COMPOSE V2
# =============================================================================

printf '\n==> PHASE 2: Configuring Docker repository\n'

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc


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


printf '\n==> Installing Docker Engine, Buildx, and Compose v2\n'

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


printf '\n==> Enabling and starting Docker\n'

sudo systemctl enable --now docker


printf '\n==> Adding %s to the docker group\n' "${INSTALL_USER}"

sudo usermod -aG docker "${INSTALL_USER}"


printf '\n==> Verifying Docker group configuration\n'

if getent group docker \
    | awk -F: -v user="${INSTALL_USER}" '
        {
            n=split($4,members,",")
            for (i=1; i<=n; i++) {
                if (members[i] == user) {
                    found=1
                }
            }
        }
        END {
            exit(found ? 0 : 1)
        }
    '
then
    printf '[OK] %s is configured as a member of the docker group.\n' \
        "${INSTALL_USER}"
else
    printf 'ERROR: %s was not added to the docker group.\n' \
        "${INSTALL_USER}" >&2
    exit 1
fi


printf '\n==> Verifying Docker daemon\n'

sudo docker info >/dev/null

printf '[OK] Docker daemon is running.\n'


# =============================================================================
# PHASE 3 - AWS CLI V2
# =============================================================================

printf '\n==> PHASE 3: Installing AWS CLI v2\n'

curl -fsSL \
    https://awscli.amazonaws.com/v2/install.sh \
    -o /tmp/aws-cli-install.sh

chmod 700 /tmp/aws-cli-install.sh

sudo bash /tmp/aws-cli-install.sh --system


printf '\n==> Verifying AWS CLI\n'

aws --version


# =============================================================================
# PHASE 4 - TERRAFORM
# =============================================================================

printf '\n==> PHASE 4: Configuring HashiCorp repository\n'

curl -fsSL \
    https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    > /tmp/hashicorp-archive-keyring.gpg

sudo install \
    -o root \
    -g root \
    -m 0644 \
    /tmp/hashicorp-archive-keyring.gpg \
    /usr/share/keyrings/hashicorp-archive-keyring.gpg


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

KUBECTL_VERSION="v1.36.2"

printf '\n==> PHASE 5: Installing kubectl %s\n' "${KUBECTL_VERSION}"


curl -fsSLo /tmp/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"


curl -fsSLo /tmp/kubectl.sha256 \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256"


printf '\n==> Verifying kubectl checksum\n'

echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" \
    | sha256sum --check


printf '\n==> Installing kubectl\n'

sudo install \
    -o root \
    -g root \
    -m 0755 \
    /tmp/kubectl \
    /usr/local/bin/kubectl


# =============================================================================
# PHASE 6 - HELM 3
# =============================================================================

printf '\n==> PHASE 6: Installing Helm 3\n'

curl -fsSL \
    https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    -o /tmp/get_helm.sh

chmod 700 /tmp/get_helm.sh

bash /tmp/get_helm.sh


# =============================================================================
# PHASE 7 - USER-LOCAL PATH FOR PIPX APPLICATIONS
# =============================================================================

printf '\n==> PHASE 7: Configuring ~/.local/bin\n'

LOCAL_BIN="${USER_HOME}/.local/bin"

mkdir -p "${LOCAL_BIN}"

export PATH="${LOCAL_BIN}:${PATH}"

PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'


# -----------------------------------------------------------------------------
# ~/.profile
# -----------------------------------------------------------------------------

touch "${USER_HOME}/.profile"

if ! grep -Fqx "${PATH_EXPORT}" "${USER_HOME}/.profile"; then
    cat >> "${USER_HOME}/.profile" <<'EOF'

# User-local command-line applications
export PATH="$HOME/.local/bin:$PATH"
EOF
fi


# -----------------------------------------------------------------------------
# ~/.bashrc
# -----------------------------------------------------------------------------

touch "${USER_HOME}/.bashrc"

if ! grep -Fqx "${PATH_EXPORT}" "${USER_HOME}/.bashrc"; then
    cat >> "${USER_HOME}/.bashrc" <<'EOF'

# User-local command-line applications
# Includes applications installed by pipx.
export PATH="$HOME/.local/bin:$PATH"
EOF
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


# Refresh Bash command cache.
hash -r


# =============================================================================
# PHASE 10 - VERIFY REQUIRED COMMAND PATHS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' Verifying Installed Commands\n'
printf '============================================================\n'


REQUIRED_COMMANDS=(
    git
    java
    javac
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
    rsync
    curl
    wget
    unzip
    openssl
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
    printf 'ERROR: One or more required commands are missing.\n'
    printf 'Review the installation output above.\n'

    exit 1
fi


# =============================================================================
# PHASE 11 - VERIFY DOCKER SERVICE AND GROUP DATABASE
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' Docker Verification\n'
printf '============================================================\n'


printf '\n--- Docker service ------------------------------\n'

if [[ "$(sudo systemctl is-active docker)" != "active" ]]; then
    echo "ERROR: Docker service is not active."
    exit 1
fi

printf '[OK] Docker service is active.\n'


if [[ "$(sudo systemctl is-enabled docker)" != "enabled" ]]; then
    echo "ERROR: Docker service is not enabled."
    exit 1
fi

printf '[OK] Docker service is enabled.\n'


printf '\n--- Docker group --------------------------------\n'

getent group docker


if getent group docker \
    | awk -F: -v user="${INSTALL_USER}" '
        {
            n=split($4,members,",")
            for (i=1; i<=n; i++) {
                if (members[i] == user) {
                    found=1
                }
            }
        }
        END {
            exit(found ? 0 : 1)
        }
    '
then
    printf '[OK] %s is recorded in the docker group.\n' \
        "${INSTALL_USER}"
else
    printf 'ERROR: %s is not recorded in the docker group.\n' \
        "${INSTALL_USER}" >&2
    exit 1
fi


printf '\n--- Docker daemon -------------------------------\n'

sudo docker info >/dev/null

printf '[OK] Docker daemon responds successfully.\n'


# =============================================================================
# PHASE 12 - VERIFY PIPX APPLICATION PATHS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' pipx Application Verification\n'
printf '============================================================\n'


GGSHIELD_PATH="$(command -v ggshield)"
CHECKOV_PATH="$(command -v checkov)"


printf 'ggshield: %s\n' "${GGSHIELD_PATH}"
printf 'checkov:   %s\n' "${CHECKOV_PATH}"


if [[ "${GGSHIELD_PATH}" != "${USER_HOME}/.local/bin/ggshield" ]]; then
    echo "ERROR: ggshield is not resolving from ~/.local/bin."
    exit 1
fi


if [[ "${CHECKOV_PATH}" != "${USER_HOME}/.local/bin/checkov" ]]; then
    echo "ERROR: Checkov is not resolving from ~/.local/bin."
    exit 1
fi


# =============================================================================
# PHASE 13 - DISPLAY INSTALLED VERSIONS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' Installed Tool Versions\n'
printf '============================================================\n'


printf '\n--- Git -----------------------------------------\n'
git --version


printf '\n--- Java runtime --------------------------------\n'
java -version


printf '\n--- Java compiler -------------------------------\n'
javac -version


printf '\n--- Maven ---------------------------------------\n'
mvn --version


printf '\n--- Docker --------------------------------------\n'
docker --version


printf '\n--- Docker Buildx -------------------------------\n'
docker buildx version


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


printf '\n--- rsync ---------------------------------------\n'
rsync --version | sed -n '1p'


# =============================================================================
# PHASE 14 - FINAL INSTRUCTIONS
# =============================================================================

printf '\n'
printf '============================================================\n'
printf ' SecureCart Workstation Bootstrap Complete\n'
printf '============================================================\n'


printf '\n'
printf 'The engineering workstation was initialized successfully.\n'


printf '\nIMPORTANT - DOCKER GROUP ACTIVATION\n'
printf '-----------------------------------\n'
printf '\n'
printf 'The user "%s" has been added to the docker group.\n' \
    "${INSTALL_USER}"
printf '\n'
printf 'Linux does not update supplementary groups inside the\n'
printf 'SSH/VS Code Remote SSH session that was already running\n'
printf 'before this installer changed the group membership.\n'


printf '\n'
printf 'FULLY disconnect the current VS Code Remote SSH session.\n'
printf 'Then reconnect to securecart-workstation and open a NEW\n'
printf 'terminal before continuing.\n'


printf '\n'
printf 'After reconnecting, run:\n'
printf '\n'
printf '  id\n'
printf '  getent group docker\n'
printf '  docker ps\n'
printf '\n'


printf 'The expected conditions are:\n'
printf '\n'
printf '  - id includes the docker group\n'
printf '  - getent group docker lists %s\n' "${INSTALL_USER}"
printf '  - docker ps works WITHOUT sudo\n'


printf '\n'
printf 'Then verify the engineering tools:\n'
printf '\n'
printf '  git --version\n'
printf '  java -version\n'
printf '  javac -version\n'
printf '  mvn -version\n'
printf '  docker --version\n'
printf '  docker compose version\n'
printf '  terraform version\n'
printf '  aws --version\n'
printf '  kubectl version --client\n'
printf '  helm version --short\n'
printf '  ggshield --version\n'
printf '  checkov --version\n'
printf '  rsync --version | sed -n '1p'\n'


printf '\n'
printf 'Verify pipx command locations:\n'
printf '\n'
printf '  command -v ggshield\n'
printf '  command -v checkov\n'
printf '\n'
printf 'Expected:\n'
printf '\n'
printf '  %s/.local/bin/ggshield\n' "${USER_HOME}"
printf '  %s/.local/bin/checkov\n' "${USER_HOME}"


printf '\n'
printf 'AWS CREDENTIALS\n'
printf '---------------\n'
printf '\n'
printf 'AWS CLI is installed, but AWS authentication has NOT been\n'
printf 'configured by this script.\n'
printf '\n'
printf 'Configure AWS authentication separately in the next step.\n'


printf '\n'
printf '============================================================\n'