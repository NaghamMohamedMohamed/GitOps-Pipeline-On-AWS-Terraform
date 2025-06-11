# 🚀 ITI Capstone Project : Full GitOps Pipeline on AWS with Terraform, and Secrets Management


## 📌 Project Overview

This project showcases a complete GitOps-based CI/CD pipeline using Terraform, Amazon EKS, and modern DevOps tooling ( Jenkins , ArgoCD ). It demonstrates how to provision infrastructure as code, deploy a Node.js web application backed by MySQL and Redis, manage secrets securely, and enable fully automated deployments using GitOps principles.

---

## 🧰 Tech Stack

☁️  **Terraform** for provisioning infrastructure (VPC, subnets, NAT, IGW, EKS , ECR , EBS , IAM Roles & Policies , IRSA)  
☸️ **Amazon EKS** for running Kubernetes workloads ( coupled with EBS CSI Driver )
📦 **Helm** for CI/CD tools installation package management of Kubernetes applications  
⚙️ **Jenkins** for automated Docker build & Terraform deployment  
🚀 **ArgoCD** for GitOps-based CD  
🔁 **Argo Image Updater** for auto-updating images  
🔐 **External Secrets Operator** for syncing secrets from AWS Secrets Manager   
🐳 **Dockerized Application** Build & Deployment using **ECR**  
📦 Stateful Services ( **MySQL** & **Redis** ) managed inside Kubernetes  
📈 **Auto Sync & Deployments** based on Git updates and image changes  

🛡️ **cert-manager** + Let’s Encrypt for automated HTTPS  
🌐 **NGINX Ingress Controller** for external traffic routing 

---

## 🏗️ Architecture Diagrams

---

## 📂 Project Structure



---

## 🛠️ Key Features

### A. Infrastructure Provisioning – Terraform

- VPC with 3 public 3 private subnets across 3 AZs
- Internet & NAT Gateways, route tables
- Amazon EKS with private worker nodes and EBS CSI driver
- TLS Certificate for OIDC Thumbprint : 
    > - **Description** :  This is a data block that retrieves the TLS certificate from the OIDC issuer URL (associated with the EKS cluster).  
    > - **Usage** : Extracts the certificate’s SHA1 thumbprint, which is required by AWS when creating an OIDC provider.  
    > - **Benefit** : Ensures secure integration with EKS's identity system (OIDC).  
    > - **Integration Role** : Uses the issuer URL exposed by the EKS cluster to retrieve TLS data, which is later used to configure IAM roles for service accounts.  

- OIDC Provider Setup : Enables IAM with OIDC federation ( Secure pod-based IAM )
    > - **Description** : Creates an OIDC identity provider in IAM for the EKS cluster.  
    > - **Usage** : Allows Kubernetes service accounts to assume IAM roles via web identity federation.  
    > - **Benefit** : Enables fine-grained IAM permissions for Kubernetes workloads & Avoids long-lived credentials or mounting secrets.  
    > - **Integration Role** : Uses the TLS thumbprint from the previous block & References the same issuer URL from the EKS cluster.

### B. Continuous Integration – Jenkins via Helm

- Clones Node.js repo, builds Docker image
- Pushes to ECR and triggers app dir using webhook

### C. Continuous Deployment – ArgoCD via Helm

- Syncs Kubernetes manifests from Git
- Auto-updates with **Argo Image Updater** on new ECR images

### D. Secrets Management

- External Secrets Operator pulls from AWS Secrets Manager
- Injects MySQL and Redis credentials as K8s secrets

### E. Application Deployment

- Deploys app to EKS using Helm or Kustomize
- MySQL and Redis run in-cluster with secrets injection
    

---

## 🔧 Infrastructure Deployment

### 1. Clone Repository

```sh
git clone https://github.com/NaghamMohamedMohamed/GitOps-Pipeline-On-AWS-Terraform.git

cd GitOps-Pipeline-On-AWS-Terraform
```

> [!NOTE]
> This repository contains the full source code for the Node.js application. So, no need to clone the app repo
---

### 2. Infrastructure Provisioning – With Terraform

```sh 
cd terraform

terraform init
terraform plan -auto-approve
terraform apply -var-file="terraform.tfvars" -auto-approve
```

---

### 3. CI Tool – Jenkins

#### A. Connect to the EKS Cluster :

```sh
# aws eks update-kubeconfig --region '[region]' --name '[clustername]'

aws eks update-kubeconfig --region us-east-1 --name gitops-gp-eks-cluster

```

#### B. Verify Cluster Connection :

```sh
kubectl get nodes
```

#### C. Install Helm on the EKS Cluster :

```sh
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify the Installation
helm version
```

#### D. Install Jenkins Repo via Helm :

```sh
# Add jenkinsci repo ( official repo )
helm repo add jenkinsci https://charts.jenkins.io/

# Update helm repos
helm repo update

# Create jenkins namespace
kubectl create namespace jenkins
```

> [!Note]  
> Why used jenkinsci : This chart installs a Jenkins server which spawns agents on kubernetes utilizing the jenkins kubernetes plugins.

#### E. Create the resources needed for jenkins :

```sh
# Create a Storage Class for the Jenkins pods PV ( Persistent Volume ), PVC ( persistent Volume Claim )
kubectl apply -f ../Manifests/storage-class.yaml

# Create the needed Service Accounts for the EBS , Kaniko ( Used in Jenkins Pipeline )
kubectl apply -f ../Manifests/ebs-service-account.yaml
kubectl apply -f ../Manifests/kaniko-service-account.yaml 
```

#### F. Install Jenkins Chart via Helm :

> [!NOTE]  
> Create the jenkins-values.yaml file ( Hem Values used for installing Jenkins chart ).
> But it is already created and found in this repo.


```sh
# Install Jenkins chart with new helm values file
helm install jenkins jenkinsci/jenkins --version 5.8.56 -f ../Jenkins/jenkins-values.yaml --namespace jenkins

# Verify Jenkins Pods are running ( After the two replicas are running, press Ctrl+C )
kubectl get pods -n jenkins -w
```

#### G. Access Jenkins Dashboard :

```sh
# Get the dashboard url
kubectl get svc jenkins -n jenkins

# Look for the EXTERNAL-IP. Open "EXTERNAL-IP:8080" in a browser ( Jenkins Dashboard URL : http://EXTERNAL-IP:port )


# Get the admin password for accessing jenkins dashboard
kubectl get secret jenkins -n jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --d
```

> [!NOTE]  
> Update Plugins in jenkins dashboard ( if needed ) : Plugins ➔ Updates ➔ Select the plugins found in this tab ➔ Press Update ➔ Check the box beside this option ( Restart Jenkins when installation is complete and no jobs are running )

--- 

#### H. Create Webhook in your repo : 
> - Open GitHub ➔ Open Your Clonned Repo ➔ Settings ➔ Webhooks ( at the left panel ) ➔ Add webhook
> - **Payload URL** ➔ `http://<Jenkins_Dashboard_URL>/github-webhook/`
> - **Content type** ➔ Choose **application/json**
> - **Which events would you like to trigger this webhook?** ➔ Choose **Just the push event.** 

---
#### I. Create the cloud & pipeline using dashboard :

- Kubernetes Cloud Creation : 
  > - Manage Jenkins ➔ Clouds ➔ New Cloud ➔ **Cloud Name** : **kubernetes** & **Type** : **Kubernetes** ➔ Create  
  > - **Kubernetes Namespace** : jenkins  
  > - **Jenkins URL** : `http://jenkins.jenkins.svc.cluster.local:8080`  
  > - **Jenkins Tunnel** : `jenkins-agent.jenkins.svc.cluster.local:50000` 

- Pipeline Creation : 
  > - Manage Jenkins ➔ New Item ➔ Enter pipleine name & choose **pipeline**  
  > - In Triggers Section : Check this option ( **GitHub hook trigger for GITScm polling** )  
  > - In Pipleine Section : Definition ➔ Choose **Pipeline script from SCM**
  > - In SCM Section inside previous section : Choose **git** ➔ **Repository URL** : `https://github.com/<Your-GitHub_USERNAME>/<YOUR_REPO_NAME>.git` ➔ **Branch Specifier** : ***/main** ➔ **Script Path** : **Jenkins/Jenkinsfile**

- Then the pipleine will automatically trigger any change on the repo and will build new image and push to ECR upon any change in **Nodeapp Dir.**


---

## 🔗 References
- [AWS Docs](https://docs.aws.amazon.com/)
- [Terraform Docs](https://developer.hashicorp.com/terraform/docs)  
- [Helm Docs](https://helm.sh/docs/)
- [Helm Charts](https://artifacthub.io/)
- [Jenkins Docs](https://www.jenkins.io/doc/)
- [Kaniko Build For for Container Building](https://www.youtube.com/watch?v=qSK3HNirASU)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/en/stable/)