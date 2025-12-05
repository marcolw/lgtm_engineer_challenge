# LGTM Engineering Challenge — Marco Liao

Demonstrate skills in building a full-stack Observability platform (LGTM Stack) on Kubernetes using GitOps principles.

**Domain:** observability.xeniumsolution.space (Example)

## Highlights

* **Full Stack Observability (LGTM):** Integrated deployment of **L**oki (Logs), **G**rafana (Visuals), **T**empo (Tracing), and **M**etrics (Prometheus/Alertmanager).
* **OpenTelemetry Integration:** Polyglot microservices (Go, Java, Python, .NET, Node) instrumented via OpenTelemetry SDKs feeding a central OTel Collector.
* **GitOps Workflow:** Complete cluster management using **ArgoCD**. Application and Infrastructure configuration drift management.
* **Infrastructure as Code:** Terraform for provisioning AWS EKS clusters and managing state in S3.
* **Automated CI/CD:** GitHub Actions for building app Docker images and updating Helm versions/tags.
* **Service Mesh Ready:** Architecture supports sidecar injection (demonstrated via OTel Operator or manual collector sidecars).

## Repository Architecture

This is a monorepo containing Infrastructure, Application Code, and Kubernetes Manifests.

* `infra/`: Terraform code for AWS EKS provisioning (split by `dev`/`prod`).
* `apps/`: Source code for 5 microservices (Go, Python, .NET, Node, Java).
* `k8s/`: The GitOps source of truth.
    * `apps/`: Helm values and manifests for the demo applications.
    * `observability/`: Configuration for Prometheus Stack, Loki, Tempo, and OTel.
    * `platform/`: ArgoCD configuration and root "App of Apps".
* `.github/`: CI/CD pipelines for Infrastructure planning and App publishing.

## The Tech Stack

### Infrastructure
* **AWS EKS:** Managed Kubernetes.
* **Terraform:** IaC with S3 Backend and DynamoDB locking.

### Observability Platform
* **Prometheus Operator:** For declarative management of Metrics and AlertManager.
* **Grafana:** Pre-provisioned dashboards via Code (ConfigMaps).
* **Loki + Promtail:** Log aggregation and shipping.
* **Tempo:** Distributed tracing backend.
* **OpenTelemetry:** Central collector gateway for processing telemetry data.

### Applications (The "Signal Generators")
* **Polyglot Microservices:** A chain of services calling each other to generate distributed traces, logs (INFO/ERROR), and custom RED metrics (Rate, Errors, Duration).

## How to Reproduce

### 1. Infrastructure Provisioning
1.  Navigate to `infra/live/dev`.
2.  Run `terraform init` and `terraform apply` to provision the EKS cluster and VPC.
3.  Update your `~/.kube/config` with the new cluster context.

### 2. Bootstrap GitOps (ArgoCD)
1.  Run `scripts/bootstrap-argocd.sh`. This installs ArgoCD via Helm on the new cluster.
2.  Apply the Root App: `kubectl apply -f k8s/platform/bootstrap.yaml`.
3.  **Magic happens:** ArgoCD will now fetch this repo and recursively deploy the Observability Stack and Demo Apps.

### 3. Verification
1.  **Grafana:** Access via LoadBalancer/Ingress. View the "Application Overview" dashboard.
2.  **Generate Traffic:** The provided `load-gen` script triggers the entry point (NodeJS app).
3.  **Observe:**
    * See the Trace propagate from Node -> Go -> Java.
    * Correlate Logs with Traces using the TraceID injected into logs.
    * View Metrics for error rates in AlertManager.

## Future Enhancements
* Implement Service Level Objectives (SLOs) using Sloth.
* Add Synthetic Monitoring (Blackbox exporter).
* Integrate PagerDuty for critical alerts.