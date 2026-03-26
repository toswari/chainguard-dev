#!/usr/bin/env bash
set -euo pipefail

echo "======================================================"
echo "Chainguard SE Challenge - Go Implementation"
echo "Installing required tools for container security"
echo "and supply chain implementation"
echo "======================================================"

echo "[1/14] Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo "[2/14] Installing essential build tools..."
sudo apt install -y curl wget git jq make gcc g++ ca-certificates gnupg lsb-release unzip tree

echo "[3/14] Installing Go 1.22..."
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version

echo "[4/14] Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

echo "[5/14] Installing nerdctl..."
NERDCTL_VERSION=1.7.6
wget https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local/bin nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz

echo "[6/14] Installing k3s (Kubernetes)..."
curl -sfL https://get.k3s.io | sh -
sudo kubectl get nodes

echo "[7/14] Installing local registry (registry:2)..."
sudo mkdir -p /opt/registry/data
# Remove existing registry if any
docker rm -f registry 2>/dev/null || true
sudo docker run -d --restart=always -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  --name registry registry:2

echo "[8/14] Installing Cosign..."
COSIGN_VERSION=2.2.4
wget https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

echo "[9/14] Installing Syft..."
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin

echo "[10/14] Installing Grype..."
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin

echo "[11/14] Installing apko..."
APKO_VERSION=0.13.2
wget https://github.com/chainguard-dev/apko/releases/download/v${APKO_VERSION}/apko_${APKO_VERSION}_linux_amd64.tar.gz
sudo tar -C /usr/local/bin -xzf apko_${APKO_VERSION}_linux_amd64.tar.gz

echo "[12/14] Installing melange..."
MELANGE_VERSION=0.8.0
wget https://github.com/chainguard-dev/melange/releases/download/v${MELANGE_VERSION}/melange_${MELANGE_VERSION}_linux_amd64.tar.gz
sudo tar -C /usr/local/bin -xzf melange_${MELANGE_VERSION}_linux_amd64.tar.gz

echo "[13/14] Creating project directories..."
mkdir -p reports
mkdir -p sbom
mkdir -p docs
mkdir -p keys
mkdir -p k8s
mkdir -p scripts

echo "[14/14] Verifying installations..."
echo "  - Go: $(go version)"
echo "  - Docker: $(docker --version)"
echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "  - cosign: $(cosign version)"
echo "  - syft: $(syft --version)"
echo "  - grype: $(grype --version)"
echo "  - apko: $(apko version)"
echo "  - melange: $(melange version)"

echo "======================================================"
echo "Chainguard SE Challenge environment installation DONE."
echo "Tools installed: Docker, nerdctl, k3s, registry, Go,"
echo "cosign, syft, grype, apko, melange."
echo "======================================================"
echo "Project directories created:"
echo "  - reports/  (CVE scan reports)"
echo "  - sbom/     (Software Bill of Materials)"
echo "  - docs/     (Documentation)"
echo "  - keys/     (Cosign signing keys)"
echo "  - k8s/      (Kubernetes manifests)"
echo "  - scripts/  (Utility scripts)"
echo "======================================================"
echo "NOTE: You may need to log out and log back in for"
echo "Docker group permissions to take effect, or run:"
echo "  newgrp docker"
echo "======================================================"