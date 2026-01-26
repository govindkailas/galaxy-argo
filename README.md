# Galaxy ArgoCD

This repository contains the configuration for deploying Galaxy and ClusterDOS applications using ArgoCD on a Kubernetes cluster.

## Directory Structure

- **`clusterdos.yaml`** - ArgoCD Application manifest for ClusterDOS deployment
- **`galaxy-app.yaml`** - ArgoCD Application manifest for Galaxy deployment
- **`.devcontainer/`** - Development container configuration and setup scripts
- **`LICENSE`** - Repository license

## Getting Started

### Development Environment

To set up a complete development environment with Kubernetes (k3s), ArgoCD, and pre-configured applications, refer to the [Dev Container Setup Guide](.devcontainer/README.md).

The dev container provides:
- A lightweight Kubernetes cluster (k3s)
- ArgoCD pre-installed and configured
- ClusterDOS and Galaxy applications ready to deploy
- All necessary tools and utilities

### Quick Links

- [Dev Container Setup](.devcontainer/README.md) - Complete guide for setting up the development environment
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/) - Official ArgoCD documentation
- [k3s Documentation](https://docs.k3s.io/) - Lightweight Kubernetes distribution documentation

## Applications

### ClusterDOS
Application deployment configuration for ClusterDOS. See `clusterdos.yaml` for details.

### Galaxy
Application deployment configuration for Galaxy. See `galaxy-app.yaml` for details.

## License

See [LICENSE](LICENSE) for details.
