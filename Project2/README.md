# 3-Tier Web Application: Full CI/CD Pipeline on Kubernetes

This project is a practical implementation of a complete CI/CD pipeline, automating the build, test, and deployment of a 3-tier application (backend, proxy, database) on Kubernetes.

The pipeline uses Jenkins (running as a pod within K8s), builds new Docker images, pushes them to Docker Hub, and then uses Helm to deploy the entire application stack to a dedicated namespace.

---

## Architecture
<img width="674" height="1018" alt="3 teir web app drawio" src="https://github.com/user-attachments/assets/1a327d48-9ae2-4caf-be9a-d094bb63c054" />

---
##  Technology Stack

* **CI/CD:** `Jenkins` (Pipeline as Code)
* **Containerization:** `Docker`
* **Container Registry:** `Docker Hub`
* **Orchestration:** `Kubernetes (K8s)`
* **Package Manager:** `Helm`
* **Application:**
    * **Proxy:** `Nginx`
    * **Backend:** `Go (App)`
    * **Database:** `MySQL`

---

##  The CI/CD Pipeline Explained

The entire pipeline is defined in a `Jenkinsfile` and is divided into 6 stages:

### 1. Source Stage
* Pulls the latest code from the `master` branch of the GitHub repository.

### 2. Build Stage
* Uses a `docker` container (DIND - Docker-in-Docker) to build new images for:
    * The `backend` (from its Dockerfile).
    * The `proxy` (from its Nginx Dockerfile).
* Each new image is tagged with the job's `BUILD_NUMBER`.

### 3. Push Stage
* Logs into Docker Hub using credentials stored in Jenkins.
* Pushes the new `backend` and `proxy` images to the registry.

### 4. Deploy Stage
* Uses a `helm` container to execute the `helm upgrade --install` command.
* Helm deploys the entire application chart (located in `Project2/jenkins-files/k8s-files`) into the `dev` namespace.
* The new `image.tag` (the build number) is passed into the chart using `--set` variables to update the `backend` and `proxy` deployments.
* The `--wait` flag is used to ensure all pods are up and `Ready`.

### 5. Smoke Test
* Waits 20 seconds for the application to stabilize.
* Sends a `curl` request to the proxy's endpoint (`https://proxy.dev.svc.cluster.local`).
* The goal is to confirm the service is "alive" and responding (even a `404` response is considered a success, as it means the proxy is running).

### 6. Notification
* **On Success:** A success email is sent to `hassanomar4700@gmail.com` with a link to the build.
* **On Failure:** (Handled by `post { failure }`) A failure email is sent if any stage fails, ensuring immediate notification.

---

## Prerequisites

To run this project, you will need:
1.  **Kubernetes Cluster:** Any K8s cluster (e.g., Minikube, EKS, GKE).
2.  **Jenkins:** Installed on the cluster (preferably via Helm chart) with the `Kubernetes Plugin `configured & `Docker Pipeline plugin`.
3.  **Docker Hub Account:** To store the Docker images.
4.  **Jenkins Credentials:**
    * `DockerHub-Cred`: A Username/Password (or Access Token) credential for Docker Hub.
5.  **RBAC Permissions:** The most critical part for a successful deployment. (See next section).

---

##  RBAC Configuration (Crucial)

The Jenkins agent pod (running as `system:serviceaccount:jenkins:default`) needs permission to create/modify resources in the `dev` namespace and `PersistentVolumes` at the cluster scope.

The following 3 YAML files must be applied:

-  `dev-role.yaml` (Allows deploying into `dev`)
-  `dev-rolebinding.yaml` (Links Jenkins to the above role)
-  `cluster-role.yaml` (Allows creating `PersistentVolume`) 

---


# Jenkins on Kubernetes: Common Troubleshooting Guide

This table covers the most common errors encountered when setting up a Jenkins CI/CD pipeline on Kubernetes.

| Error Message / Symptom | Stage | Probable Cause & Solution |
| :--- | :--- | :--- |
| `Still waiting for next available executor` | Pipeline Start | **Cause:** Jenkins can't find a valid agent pod template. This usually happens because: <br> 1. The **Built-In Node** (master) has the same label (e.g., `jenkins-agent`) as your pod template, causing the job to queue on the master (which has 0 executors). <br> 2. The `jnlp` container in your pod template has its `Command` set to `sleep infinity`. <br><br> **Solution:** <br> 1. Go to `Manage Jenkins` -> `Nodes` -> `Built-In Node` -> `Configure` and **clear the `Labels` field**. <br> 2. In your `Pod Template` settings, ensure the `jnlp` container has its `Command` and `Arguments` fields **empty**. |
| `Agent pod CrashLoopBackOff` or `Terminating` | Pipeline Start | **Cause:** The agent pod starts but fails to connect back to the Jenkins master. The `Jenkins URL` in your K8s cloud config is likely set to `localhost` or an external IP. <br><br> **Solution:** <br> 1. Go to `Manage Jenkins` -> `Nodes and Clouds` -> `Configure Clouds`. <br> 2. Set **`Jenkins URL`** to the internal service name: `http://jenkins.jenkins.svc.cluster.local:8080` (adjust as needed). <br> 3. **Check (✓) `WebSocket`**. <br> 4. Leave the **`Jenkins tunnel`** field **empty**. <br> 5. **Restart the Jenkins Master pod** (`kubectl delete pod ...`) to apply the new settings. |
| `denied: requested access to the resource is denied` | Stage: Push | **Cause:** `Login Succeeded` but the `docker push` failed. This means the credentials are valid, but permissions are wrong. <br> 1. The Docker Hub repository (e.g., `omar4700/backend`) does not exist. <br> 2. The `docker login` command is wrong. <br><br> **Solution:** <br> 1. Log in to Docker Hub and **manually create** the empty repositories (`backend`, `proxy`). <br> 2. In the `Jenkinsfile`, ensure the login command is: `sh "echo ${DOCKER_PASS} | ... login ... docker.io"` (login to the registry, not the user). |
| `Error: ... forbidden: User "..." cannot ...` | Stage: Deploy | **Cause:** The Jenkins agent's Service Account (e.g., `system:serviceaccount:jenkins:default`) does not have RBAC permissions to create/read resources in other namespaces. <br> 1. **(Namespace error)** `secrets "..." is forbidden ... in namespace "dev"`. <br> 2. **(Cluster error)** `persistentvolumes "..." is forbidden`. <br><br> **Solution:** <br> 1. Create a `Role` and `RoleBinding` in the `dev` namespace that grants `*` permissions to the `jenkins:default` Service Account. <br> 2. Create a `ClusterRole` and `ClusterRoleBinding` that grants permissions for cluster-scoped resources (like `persistentvolumes`) to the `jenkins:default` Service Account. |

---
