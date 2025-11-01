# Go API Project with Nginx & MySQL (Kubernetes Ready)

This is a **full-stack web application** project consisting of a **Go backend API**, a **MySQL database**, and an **Nginx reverse proxy**.
The project is fully containerized with configurations for both **local development (Docker Compose)** and **production deployment (Kubernetes)**
Nginx secures all traffic via **HTTPS** using self-signed certificates and serves as the front-end gateway for the application.

---

## 🧱 Technology Stack

- **Go (Golang):** Backend API  
- **Nginx:** Reverse Proxy & HTTPS termination  
- **MySQL:** Database  
- **Docker & Docker Compose:** Local development environment  
- **Kubernetes (K8s):** Production orchestration  

---

## 🏗️ System Architecture
[User] --- (HTTPS) ---> [Nginx Proxy] --- (HTTP) ---> [Go Backend API] <---> [MySQL Database]

---

## ✨ Features

- Simple Go REST API that reads data from a MySQL database  
- Nginx configured as a secure HTTPS reverse proxy  
- Self-signed SSL certificates for encrypted communication  
- Complete **Docker Compose** configuration for local development  
- **Kubernetes manifests** for production deployment (Deployments, Services, Secrets, PV/PVC)  
- Secure password management with **Docker Secrets** and **Kubernetes Secrets**

---

## ⚙️ Prerequisites

Before you begin, ensure you have the following tools installed:

- [Docker](https://www.docker.com/)  
- [Docker Compose](https://docs.docker.com/compose/) (usually included with Docker Desktop)  
- [kubectl](https://kubernetes.io/docs/tasks/tools/)  
- [Minikube](https://minikube.sigs.k8s.io/docs/) *(or any Kubernetes cluster)*  
- [Git](https://git-scm.com/)

---

## 🚀 How to Run (Method 1: Docker Compose - Local Dev)

This method is ideal for rapid development and testing on your local machine.

### 1. Prepare the Project

```bash
# Clone the project
git clone git@github.com:Omarh4700/Projects.git
cd Projects
```

# Create the database password file
echo "password" > db_password.txt
|| or simply you can create it using any text editor

# Generate the SSL certificate
```bash
cd nginx
chmod +x generate-ssl.sh
./generate-ssl.sh
cd ..
```

### 2. Run the Application
```bash
docker-compose up --build -d
```

3. Access the Application
Open your browser and navigate to: https://localhost
> ⚠️ Because the SSL certificate is self-signed, you will see a browser security warning.
  - Chrome / Firefox: Click Advanced → Accept the Risk and Continue
<img width="572" height="84" alt="image" src="https://github.com/user-attachments/assets/1e766b11-7f36-460d-af59-fb04feb82783" />

**Or you can use curl command**
```curl -k https://192.168.187.128/```

<img width="991" height="68" alt="image" src="https://github.com/user-attachments/assets/1239c2a1-fa4d-4380-896a-1e7c6d7d3b83" />

---

## ☸️ How to Run (Method 2: Kubernetes - Production)
Deploy the application on a Kubernetes cluster (e.g., Minikube).

### 1. Build and Push Docker Images
Kubernetes requires images to be available in a registry (like Docker Hub).
```bash
# Log in to Docker Hub
docker login

# Build and push the Go backend
cd backend
docker build -t omar4700/api:v1.0 .
docker push omar4700/api:v1.0
cd ..

# Build and push the Nginx image
cd nginx
docker build -t omar4700/nginx_proxy:v1.2 .
docker push omar4700/nginx_proxy:v1.2
cd ..
```
Then update the image names in:
  - ``K8s/backend_deployment.yaml``
  - ``K8s/proxy_deployment.yaml``

### 2. Prepare Cluster Configurations (Secrets & ConfigMaps)
(a) Generate SSL Certificate or you can use the one you created before
```bash
cd nginx && ./generate-ssl.sh && cd ..
```
(b) Create Nginx TLS Secret
```bash
kubectl create secret tls nginx-tls-secret --cert=nginx/ssl/nginx.crt --key=nginx/ssl/nginx.key
```

(c) Create Nginx ConfigMap
```bash
kubectl create configmap nginx-config --from-file=nginx/nginx.conf
```

### 3. Deploy the Application to Kubernetes
```bash
cd K8s

# Apply the database secret
kubectl apply -f db-secret.yaml

# Apply storage and services
kubectl apply -f db-data-pv.yaml
kubectl apply -f db-data-pvc.yaml
kubectl apply -f db-service.yaml
kubectl apply -f database_deployment.yaml
kubectl apply -f backend_service.yaml
kubectl apply -f backend_deployment.yaml
kubectl apply -f proxy_nodeport.yaml
kubectl apply -f proxy_deployment.yaml
```
### 4. Access the Application (Minikube)
You have to know what is ur endpoints for u minikube and serviceport
```bash
kubectl get svc,ep -o wide
curl -k https://192.168.49.2:32274
```

<img width="1263" height="403" alt="image" src="https://github.com/user-attachments/assets/09a0a5a9-a2fe-4d36-9084-8a711915508b" />
