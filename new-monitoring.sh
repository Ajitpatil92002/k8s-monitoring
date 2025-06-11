#!/bin/bash

set -euo pipefail

# Define the directory to store configuration files
INSTALL_DIR="/k8s-monitoring-configs"

echo "📁 Creating directory: $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"

# Define URLs for the configuration files
BASE_URL="https://raw.githubusercontent.com/Ajitpatil92002/k8s-monitoring/refs/heads/main"
declare -A CONFIG_FILES=(
  [loki-values.yml]="$BASE_URL/loki-values.yml"
  [k8s-monitoring-values.yml]="$BASE_URL/k8s-monitoring-values.yml"
  [grafana-values.yml]="$BASE_URL/grafana-values.yml"
)

# Download configuration files
echo "⬇️  Downloading configuration files..."
for file in "${!CONFIG_FILES[@]}"; do
  url="${CONFIG_FILES[$file]}"
  dest="$INSTALL_DIR/$file"
  echo " - $file"
  sudo curl -sSfL -o "$dest" "$url"
done

# Add Helm repositories
echo "📦 Adding and updating Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create the 'monitoring' namespace if it doesn't exist
echo "🧱 Ensuring namespace 'monitoring' exists..."
kubectl get namespace monitoring >/dev/null 2>&1 || kubectl create namespace monitoring

# Create the Grafana admin secret if it doesn't exist
SECRET_NAME="grafana-admin-secret"
if ! kubectl get secret "$SECRET_NAME" -n monitoring >/dev/null 2>&1; then
  echo "🔐 Creating Grafana admin secret..."
  kubectl create secret generic "$SECRET_NAME" -n monitoring \
    --from-literal=admin-user=admin \
    --from-literal=admin-password=Cyberark1
else
  echo "🔐 Grafana admin secret already exists. Skipping."
fi

# Helm installations
echo "🚀 Installing components..."

echo " - Loki"
helm upgrade --install loki grafana/loki \
  --values "$INSTALL_DIR/loki-values.yml" \
  -n monitoring

echo " - Prometheus"
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring

echo " - Grafana"
helm upgrade --install grafana grafana/grafana \
  --values "$INSTALL_DIR/grafana-values.yml" \
  -n monitoring

echo " - k8s-monitoring"
helm upgrade --install k8s grafana/k8s-monitoring \
  --values "$INSTALL_DIR/k8s-monitoring-values.yml" \
  -n monitoring

echo "✅ Installation complete."
