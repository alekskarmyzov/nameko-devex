#!/bin/bash


KUBECONFIG='kubeconfig-kubecf'

echo -e "\n[INFO] CREATING K8S Cluster...\n"

kind create cluster --name kubecf
kubectl cluster-info --context kind-kubecf

echo -e "\n[INFO] DOWNLOADING KubeCF...\n"

curl -s https://api.github.com/repos/cloudfoundry-incubator/kubecf/releases/latest \
		| grep -oP '"browser_download_url": "\K(.*)kubecf-bundle(.*)(?=")' \
		| wget -qi -
	
tar xf kubecf-bundle-v*.tgz

echo -e "\n[INFO] CREATING NAMESPACE...\n"

kubectl create ns cfo

echo -e "\n[INFO] INSTALLING CF-OPERATOR...\n"

helm install cf-operator \
    --namespace cfo \
    --set "global.singleNamespace.name=kubecf" \
    ./cf-operator.tgz

echo -e "\n[INFO] WAITING 120 SECONDS FOR PODS...\n"

sleep 120

kubectl get pods -n cfo


echo -e "\nGETTING NODE IP...\n"

node_ip=$(kubectl get node kubecf-control-plane \
  		--output jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')


echo -e "\n[INFO] MAKING VALUES.YAML...\n"

cat << _EOF_  > values.yaml
system_domain: ${node_ip}.nip.io

services:
  router:
    externalIPs:
    - ${node_ip}
_EOF_

docker exec -it "kubecf-control-plane" bash -c 'cp /etc/kubernetes/pki/ca.crt /etc/ssl/certs/ && \
    update-ca-certificates && \
    (systemctl list-units | grep containerd > /dev/null && systemctl restart containerd)'

echo -e "\n[INFO] INSTALLING KubeCF...\n"

helm install kubecf \
    --namespace kubecf \
    --values values.yaml \
    ./kubecf_release.tgz

watch kubectl get pods -n kubecf