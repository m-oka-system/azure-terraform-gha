#! /bin/bash

# GitHub Login
gh auth login

# Create Repository
gh repo create azure-terraform-gha --public
git init
git remote add origin https://github.com/m-oka-system/azure-terraform-gha.git

# Register Secrets
gh secret set -f .secrets

# Register Variables
gh variable set -f variables
