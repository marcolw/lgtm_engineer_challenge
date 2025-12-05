#!/bin/bash

# Define the root name
# REPO_NAME="lgtm_engineer_challenge"

# echo "Creating Repository Structure for $REPO_NAME..."

# # Create Root
# mkdir -p $REPO_NAME
# cd $REPO_NAME

# 1. Create Github Workflows
mkdir -p .github/workflows
touch .github/workflows/{infra-plan.yaml,infra-apply.yaml,build-apps.yaml}

# 2. Create Infrastructure (Terraform)
# Structure: Modules for reusability, Live for environment instantiations
mkdir -p infra/modules/{eks,vpc,iam}
mkdir -p infra/live/{dev,prod}
touch infra/live/dev/{main.tf,variables.tf,outputs.tf,backend.conf,terraform.tfvars}
touch infra/live/prod/{main.tf,variables.tf,outputs.tf,backend.conf,terraform.tfvars}

# 3. Create Applications (Polyglot)
# Creating folders for Go, Python, DotNet, Node, Java
APPS=("go-service" "python-service" "dotnet-service" "nodejs-service" "java-service")
for app in "${APPS[@]}"; do
    mkdir -p apps/$app
    touch apps/$app/{Dockerfile,README.md}
    # Create specific entry files for realism
    if [[ "$app" == "go-service" ]]; then touch apps/$app/main.go; fi
    if [[ "$app" == "python-service" ]]; then touch apps/$app/app.py; fi
    if [[ "$app" == "nodejs-service" ]]; then touch apps/$app/index.js; fi
    if [[ "$app" == "java-service" ]]; then mkdir -p apps/$app/src/main/java; fi
    if [[ "$app" == "dotnet-service" ]]; then touch apps/$app/Program.cs; fi
done

# 4. Create Kubernetes / GitOps Manifests
# Platform: ArgoCD configurations
mkdir -p k8s/platform
touch k8s/platform/{bootstrap.yaml,values-argocd.yaml}

# Observability: Configuration for the stack
# We will assume Helm Chart usage, so we mostly need values.yaml files
mkdir -p k8s/observability/{prometheus-stack,loki-stack,tempo,otel-collector}
touch k8s/observability/prometheus-stack/values.yaml
touch k8s/observability/loki-stack/values.yaml
touch k8s/observability/tempo/values.yaml
touch k8s/observability/otel-collector/{values.yaml,collector-config.yaml}

# Demo Apps: Helm releases or K8s Manifests for the apps
mkdir -p k8s/demo-apps
touch k8s/demo-apps/{Chart.yaml,values.yaml}
# Create folders for individual app overrides if necessary
for app in "${APPS[@]}"; do
    mkdir -p k8s/demo-apps/$app
    touch k8s/demo-apps/$app/values.yaml
done

# 5. Scripts
mkdir -p scripts
touch scripts/{bootstrap-argocd.sh,cleanup.sh,load-generator.sh}
chmod +x scripts/*.sh

# 6. README and Misc
touch README.md
touch .gitignore

# Populate a simple .gitignore
cat <<EOT >> .gitignore
.terraform
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
.DS_Store
node_modules/
bin/
obj/
target/
__pycache__/
EOT

echo "----------------------------------------------------------------"
echo "Repository $REPO_NAME created successfully."
echo "----------------------------------------------------------------"
echo "Next Steps:"
echo "1. Initialize git: 'git init'"