#!/usr/bin/env bash

trap ' ' INT

sgxNodes=$(kubectl get nodes | grep sgx | cut -d' ' -f1)
for node in $sgxNodes; do
  kubectl label nodes "${node}" "node-role.kubernetes.io/worker="
done

echo "Deploying the CoCo operator..."

kubectl apply -k "github.com/confidential-containers/operator/config/release?ref=v0.5.0"

kubectl get pods -n confidential-containers-system --watch
echo

./configure.sh

read -n 1 -p "Continue to deploy enclave-cc CRD? (press a key)"

echo "Deploying the enclave-cc CRD..."

kubectl apply -f .

kubectl get runtimeclass --watch
echo

read -n 1 -p "Continue to deploy verdirctd? (press a key)"

echo "Deploying verdirctd..."

kubectl apply -k ../verdictd
