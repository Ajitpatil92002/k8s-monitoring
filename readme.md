helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

````

### loki-values.yml
```yaml
loki:
    auth_enabled: false
    commonConfig:
        replication_factor: 1
    schemaConfig:
        configs:
            - from: 2024-04-01
              store: tsdb
              object_store: s3
              schema: v13
              index:
                  prefix: loki_index_
                  period: 24h
    ingester:
        chunk_encoding: snappy
    tracing:
        enabled: true
    pattern_ingester:
        enabled: true
    limits_config:
        allow_structured_metadata: true
        volume_enabled: true
    ruler:
        enable_api: true
    querier:
        max_concurrent: 4

minio:
    enabled: true

deploymentMode: SingleBinary
singleBinary:
    replicas: 1
    resources:
        limits:
            cpu: 0.1
            memory: 900Mi
        requests:
            cpu: 0.1
            memory: 700Mi
    extraEnv:
        - name: GOMEMLIMIT
          value: 400MiB

chunksCache:
    writebackSizeLimit: 10MB
    resources:
        requests:
            cpu: 100m
            memory: 500Mi
        limits:
            cpu: 100m
            memory: 500Mi

resultsCache:
    resources:
        requests:
            cpu: 100m
            memory: 128Mi
        limits:
            cpu: 100m
            memory: 256Mi

backend:
    replicas: 0
read:
    replicas: 0
write:
    replicas: 0
ingester:
    replicas: 0
querier:
    replicas: 0
queryFrontend:
    replicas: 0
queryScheduler:
    replicas: 0
distributor:
    replicas: 0
compactor:
    replicas: 0
indexGateway:
    replicas: 0
bloomCompactor:
    replicas: 0
bloomGateway:
    replicas: 0

````

```sh
helm install --values loki-values.yml loki grafana/loki -n monitoring
```

```sh
helm install prometheus prometheus-community/prometheus -n monitoring
```

### grafana-values.yml

```yaml
persistence:
    type: pvc
    enabled: true

adminUser: admin
adminPassword: Cyberark1

service:
    enabled: true
    type: ClusterIP

datasources:
    datasources.yaml:
        apiVersion: 1
        datasources:
            - name: Loki
              type: loki
              access: proxy
              orgId: 1
              url: http://loki-gateway.monitoring.svc.cluster.local:80
              basicAuth: false
              isDefault: true
              version: 1
              editable: true
            - name: Prometheus
              type: prometheus
              access: proxy
              orgId: 1
              url: http://prometheus-server.monitoring.svc.cluster.local:80
              basicAuth: false
              isDefault: false
              version: 1
              editable: true
```

```sh
helm install --values grafana-values.yml grafana grafana/grafana --namespace monitoring
```

### k8s-monitoring-values.yml

```yaml
cluster:
    name: meta-monitoring-tutorial

destinations:
    - name: loki
      type: loki
      url: http://loki-gateway.meta.svc.cluster.local/loki/api/v1/push
    - name: prometheus
      type: prometheus
      url: http://prometheus-server.meta.svc.cluster.local/api/v1/write

clusterEvents:
    enabled: true
    collector: alloy-logs
    namespaces:
        - meta
        - prod

nodeLogs:
    enabled: false

podLogs:
    enabled: true
    gatherMethod: kubernetesApi
    collector: alloy-logs
    labelsToKeep:
        [
            'app_kubernetes_io_name',
            'container',
            'instance',
            'job',
            'level',
            'namespace',
            'service_name',
            'service_namespace',
            'deployment_environment',
            'deployment_environment_name',
        ]
    structuredMetadata:
        pod: pod
    namespaces:
        - meta
        - prod

alloy-singleton:
    enabled: false

alloy-metrics:
    enabled: true

alloy-logs:
    enabled: true
    alloy:
        mounts:
            varlog: false
        clustering:
            enabled: true

alloy-profiles:
    enabled: false

alloy-receiver:
    enabled: false
```

```sh
helm install --values ./k8s-monitoring-values.yml k8s grafana/k8s-monitoring -n monitoring
```

Add Dashboards - 15282 and 13639
