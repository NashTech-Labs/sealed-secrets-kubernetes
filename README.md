# Sealed Secrets

This directory serves as a workbench from which to create
[sealed secrets](https://github.com/bitnami-labs/sealed-secrets).

## Setup

### Kubeseal

`kubeseal` is a CLI client for sealing/encrypting k8s secrets.

```
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/kubeseal-0.18.0-linux-amd64.tar.gz
tar -xvf kubeseal-0.18.0-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/kubeseal
```

### Sealed Secret Operator

Current deployment process is done via traditional good old ways of manual helm install commamnd on targeted cluster kubecontext.

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm dependency update sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --version 2.2.0 # LATEST VERSION (02/06/2022)
```

## Usage

Use the [`sealedsecretsh`](./sealedsecretsh) script in order to create a `SealedSecret` resource using the public key `sealedsecret.<cluster>.cert.pem`, which can only be decrypted by the on-cluster `sealed-secrets` controller.

*NOTE: Must execute on target k8s cluster's bastion host

### Encryption

Make sure to run this script from the appropriate k8s cluster controllers as it needs corresponding controller public certs

Store secret key value pairs in a `<secret>.yaml` file on this working directory.

```bash
# populate <secret>.yaml with secrets you'd like to encrypt
$ cat <<EOF > <secret>.yaml
key1: value1
key2: value2
...
EOF

# sealedsecret script takes in multiple input to generate sealed secret from raw secret value file
# For more details run a help command to see the input details
./sealedsecretsh
./sealedsecretsh -h
./sealedsecretsh --help

# Example
./sealedsecretsh secret.yaml eks-test dev secret-test
```

### Decryption

Decryption for secrets works like any other k8s secrets:

```bash
kubectl get secrets <secret-name> \
  --namespace <namespace> \
  -ojsonpath="{.data.<data-field-key>}" | \
  base64 --decode >> decrypted.secrets.yaml
```


### To create docker registry secret using sealed secret pem certificate

Once you have the certificate on your controller node, you can just add the parameters in the below command and run the command from the controller where you have kubeseal installed:

    kubectl create secret docker-registry docker-regcred -n "" --docker-server="" --docker-username="" --docker-password="" --docker-email="" --output json | kubeseal --cert=sealedsecret.test-eks.cert.pem --format=yaml
