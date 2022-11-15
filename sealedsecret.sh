#!/usr/bin/env bash

## sealedsecret is a program that creates a generic "sealed secret" using the same
## command-line interface as `kubectl create secret generic`.

AWS_ACCOUNT_ID=""

if ! command -v kubectl > /dev/null; then
  echo "'kubectl' is not installed" >&2 && \
  exit 1
fi

if ! command -v kubeseal > /dev/null; then
  echo "'kubeseal' is not installed" >&2 && \
  exit 1
fi

if [[ $# -lt 2 ]] || [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
  echo "Usage: sealedsecret.sh <secret.source.yaml>" >&2 && \
  echo "                   <cluster>" >&2 && \
  echo "                   <namespace>" >&2 && \
  echo "                   <secret-name>" >&2 && \
  exit 2
fi

SECRET_INPUT_YAML=$1
EKS_CLUSTER=$2
EKS_NAMESPACE=$3
SECRET_NAME=$4

# K8S CONFIG
echo "K8S: CONFIG SETUP START"
aws eks --region us-east-1 update-kubeconfig --name ${EKS_CLUSTER} 
kubectl config use-context arn:aws:eks:us-east-1:${AWS_ACCOUNT_ID}:cluster/${EKS_CLUSTER}
echo "=============== DONE ==============="

cd ./pipeline/secrets/scripts/sealedsecrets

# K8S: Generate K8S Secret (sealing target)
echo -e "kubectl: Generate k8s secret to seal"
KUBECTL_COMMAND="kubectl create secret generic $SECRET_NAME "
echo -e "YAML: Extract secrets <key>-<value> pair"
while IFS=:" " read -r key value
do
  # do something on $line
  KUBECTL_COMMAND+=" --from-literal=$key=$value"
  # echo -e "KEY: $key | VALUE: $value"
done < "$SECRET_INPUT_YAML"

KUBECTL_COMMAND+=" -n $EKS_NAMESPACE -o yaml --dry-run=client > $SECRET_NAME.tmp.yaml"
eval "$KUBECTL_COMMAND"

kubectl config current-context

# Kubeseal: Fetch certificate
echo -e "kubeseal: Fetch public cert to encrypt secrets with"
kubeseal \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=test \
  --fetch-cert > ./sealedsecret.$EKS_CLUSTER.cert.pem

echo -e "kubeseal: Seal the secrets and generate sealedsecrets"
echo -e "=============== SealedSecret CRD ==============="
kubeseal --cert=./sealedsecret.$EKS_CLUSTER.cert.pem --format=yaml < $SECRET_NAME.tmp.yaml

echo -e "=====DONE====="


