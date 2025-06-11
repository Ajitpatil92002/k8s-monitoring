#!/bin/bash

# Define the directory in the root where files will be stored
INSTALL_DIR="/k8s-monitoring-configs"

# Create the directory
echo "Creating directory $INSTALL_DIR..."
sudo mkdir -p $INSTALL_DIR

# Define URLs for the configuration files
LOKI_VALUES_URL="https://raw.githubusercontent.com/Ajitpatil92002/k8s-monitoring/refs/heads/main/loki-values.yml"
K8S_MONITORING_VALUES_URL="https://raw.githubusercontent.com/Ajitpatil92002/k8s-monitoring/refs/heads/main/k8s-monitoring-values.yml"
GRAFANA_VALUES_URL="https://raw.githubusercontent.com/Ajitpatil92002/k8s-monitoring/refs/heads/main/grafana-values.yml"

# Define file names for the downloaded configuration files
LOKI_VALUES_FILE="$INSTALL_DIR/loki-values.yml"
K8S_MONITORING_VALUES_FILE="$INSTALL_DIR/k8s-monitoring-values.yml"
GRAFANA_VALUES_FILE="$INSTALL_DIR/grafana-values.yml"

# Download the configuration files
echo "Downloading configuration files to $INSTALL_DIR..."
sudo curl -o $LOKI_VALUES_FILE $LOKI_VALUES_URL
sudo curl -o $K8S_MONITORING_VALUES_FILE $K8S_MONITORING_VALUES_URL
sudo curl -o $GRAFANA_VALUES_FILE $GRAFANA_VALUES_URL

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create the monitoring namespace
echo "Creating monitoring namespace..."
kubectl create namespace monitoring

# Create a secret for Grafana admin user
echo "Creating Grafana admin secret..."
kubectl create secret generic grafana-admin-secret -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=Cyberark1

# Install Loki
echo "Installing Loki..."
helm install --values $LOKI_VALUES_FILE loki grafana/loki -n monitoring

# Install Prometheus
echo "Installing Prometheus..."
helm install prometheus prometheus-community/prometheus -n monitoring

# Install Grafana
echo "Installing Grafana..."
helm install --values $GRAFANA_VALUES_FILE grafana grafana/grafana --namespace monitoring

# Install k8s-monitoring
echo "Installing k8s-monitoring..."
helm install --values $K8S_MONITORING_VALUES_FILE k8s grafana/k8s-monitoring -n monitoring

echo "Installation complete."
