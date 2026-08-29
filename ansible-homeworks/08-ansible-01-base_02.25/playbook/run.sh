#!/usr/bin/env bash
set -e

echo "=== Starting Docker containers ==="
# Remove old containers if they already exist
docker rm -f centos7 ubuntu fedora 2>/dev/null || true

docker run -d --name centos7 pycontribs/centos:7 sleep 1d
docker run -d --name ubuntu pycontribs/ubuntu:latest sleep 1d
docker run -d --name fedora pycontribs/fedora:latest sleep 1d

echo "=== Running Ansible Playbook ==="
# Create a temporary Vault password file for non-interactive execution
echo "netology" > .vault_pass
ansible-playbook site.yml -i inventory/prod.yml --vault-password-file .vault_pass
rm -f .vault_pass

echo "=== Stopping and removing Docker containers ==="
docker rm -f centos7 ubuntu fedora

echo "=== Script finished successfully ==="
