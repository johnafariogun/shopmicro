#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/johnafariogun/shopmicro"
RUNNER_VERSION="2.332.0"
RUNNER_DIR="actions-runner"

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <RUNNER_TOKEN>"
  exit 1
fi

TOKEN=$1

echo "Creating runner directory..."
mkdir -p $RUNNER_DIR
cd $RUNNER_DIR

echo "Downloading GitHub Actions runner..."
curl -L -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "Verifying checksum..."
echo "f2094522a6b9afeab07ffb586d1eb3f190b6457074282796c497ce7dce9e0f2a  actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | sha256sum -c

echo "Extracting..."
tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "Configuring runner..."
./config.sh --url $REPO_URL --token $TOKEN --unattended

echo "Installing service..."
sudo ./svc.sh install

echo "Starting service..."
sudo ./svc.sh start

echo "Runner installed and running as a service."