# Dev Container Setup Guide

This directory contains the configuration for the Galaxy ArgoCD development environment. The dev container provides a complete Kubernetes cluster (k3s) with ArgoCD, clusterdos, and Galaxy pre-configured as separate applications.

## Prerequisites

- **Docker Desktop** or **Docker Engine** (with Docker CLI available)
- **VS Code** with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- **4GB+ RAM** available for the container
- **10GB+ disk space** for k3s and application deployments

## Quick Start

### Option 1: VS Code (Recommended)

1. Open the workspace in VS Code:
   ```bash
   code /path/to/galaxy-argo
   ```

2. When prompted, click **"Reopen in Container"** or use the command palette:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Dev Containers: Reopen in Container"
   - Press Enter

3. Wait for the container to build and the setup script to complete (this may take 5-10 minutes on first run)

4. Once complete, you'll see:
   ```
   === Setup Complete ===
   ArgoCD is available at: http://localhost:8080
   ```

### Option 2: Command Line

```bash
# Navigate to the workspace
cd /path/to/galaxy-argo

# Build and start the dev container
docker build -f .devcontainer/Dockerfile -t galaxy-argocd-dev .
docker run -it --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v galaxy-k3s-data:/var/lib/rancher/k3s \
  -p 6443:6443 \
  -p 8080:8080 \
  -p 8081:8081 \
  -v "$(pwd)":/workspace \
  galaxy-argocd-dev

# Inside the container, run the setup
/workspace/.devcontainer/setup.sh
```

## What Gets Set Up

The `setup.sh` script automatically:

1. **Starts k3s** - A lightweight Kubernetes cluster
2. **Waits for the cluster** - Ensures all nodes are ready
3. **Installs ArgoCD** - Via Helm with external access enabled
4. **Waits for ArgoCD CRDs** - Ensures Application resource is available
5. **Deploys clusterdos** - Via ArgoCD Application manifest
6. **Deploys Galaxy** - As a separate ArgoCD Application (optional, can be disabled)
7. **Sets up port forwarding** - ArgoCD available on `localhost:8080`

## Accessing ArgoCD

### Web UI

Open your browser and navigate to: **http://localhost:8080**

### Credentials

The default credentials are printed at the end of the setup script:
- **Username**: `admin`
- **Password**: Check the setup output or run:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

### CLI Access

Install the ArgoCD CLI locally and login:

```bash
# Login to ArgoCD
argocd login localhost:8080 --insecure --username admin

# View applications
argocd app list

# Get clusterdos status
argocd app get clusterdos

# Sync clusterdos manually
argocd app sync clusterdos
```

## Useful Kubernetes Commands

```bash
# View all nodes and their status
kubectl get nodes

# View all pods
kubectl get pods -A

# View ArgoCD deployment
kubectl get pods -n argocd

# View clusterdos resources
kubectl get all -n argocd

# Watch clusterdos deployment progress
kubectl get applications -n argocd -w

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Port forward to ArgoCD (if not already running)
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

## Monitoring Deployments

### Check clusterdos status in ArgoCD

```bash
# Via CLI
argocd app get clusterdos

# Via kubectl
kubectl get application clusterdos -n argocd
```

### View Helm release status

```bash
helm list -n argocd
```

### Check deployed resources

```bash
# List all resources
kubectl get all -A

# Check specific namespaces
kubectl get pods -n argocd
```

## Configuration

### Customizing clusterdos

The clusterdos deployment is defined in `/workspace/clusterdos.yaml`. Edit this file to:

- Adjust resource requests/limits
- Modify Helm values
- Enable/disable clusterdos components

After editing, ArgoCD will detect the changes and sync automatically (or manually run `argocd app sync clusterdos`).

### Customizing Galaxy

The Galaxy deployment is defined in `/workspace/galaxy-app.yaml`. Edit this file to:

- Adjust resource requests/limits
- Modify persistence settings
- Configure Helm values

After editing, ArgoCD will detect the changes and sync automatically (or manually run `argocd app sync galaxy`).

### Adding more applications

Create new ArgoCD Application manifests in the workspace and apply them:

```bash
kubectl apply -f /path/to/app-manifest.yaml
```

## Troubleshooting

### Container won't start

**Issue**: Docker daemon not accessible
```bash
# Solution: Ensure Docker is running and /var/run/docker.sock is mounted
docker ps  # Test Docker access
```

### k3s not starting

**Issue**: Check if k3s process is running
```bash
ps aux | grep k3s
kubectl cluster-info  # Verify cluster is ready
```

### ArgoCD not accessible

**Issue**: Port 8080 in use or forwarding not active
```bash
# Check if port is in use
lsof -i :8080

# Manually set up port forwarding
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### Clusterdos not deploying

**Issue**: Check ArgoCD Application status
```bash
argocd app get clusterdos
kubectl describe application clusterdos -n argocd
kubectl logs -n argocd deployment/argocd-application-controller
```

### Insufficient disk space

**Issue**: k3s requires space for images and persistent volumes
```bash
# Check available space
df -h

# Clean up unused resources
kubectl delete pvc --all
# Or remove the k3s-data volume and restart
```

## Environment Variables

The setup script uses these environment variables:

- `KUBECONFIG` - Set to `/etc/rancher/k3s/k3s.yaml`
- `K3S_KUBECONFIG_MODE` - Set to `644` for accessibility

## File Structure

```
.devcontainer/
├── Dockerfile          # Container image definition with k3s, Helm, kubectl
├── devcontainer.json   # VS Code dev container configuration
├── setup.sh           # Initialization script for k3s, ArgoCD, clusterdos, and Galaxy
└── README.md          # This file

../clusterdos.yaml     # ArgoCD Application manifest for clusterdos deployment
../galaxy-app.yaml    # ArgoCD Application manifest for Galaxy deployment
```

## Next Steps

1. **Access ArgoCD** at http://localhost:8080
2. **Monitor deployments** - Check both clusterdos and Galaxy applications in ArgoCD UI
3. **Access Galaxy** - Once deployed and healthy, Galaxy will be available (port depends on service configuration)
4. **Explore clusterdos** - Use the clusterdOS features for cluster orchestration
5. **Deploy additional applications** using ArgoCD or Helm

## Support

For issues or questions:
- Check the troubleshooting section above
- Review logs: `kubectl logs -f -n argocd <pod-name>`
- Inspect the ArgoCD UI for sync status and error messages

## Cleanup

To remove the dev container and related resources:

```bash
# Stop the container (VS Code: Close Remote Window)
# Or from CLI:
docker stop galaxy-argocd-dev
docker rm galaxy-argocd-dev

# Remove the volume (if desired)
docker volume rm galaxy-k3s-data
```

To restart: Simply reopen the dev container and the setup will run again.
