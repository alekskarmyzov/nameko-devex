KUBECONFIG ?= kubeconfig-kubecf
NAMESPACE ?= dev

cf-create-cluster:
	./script.sh

cf-delete-cluster:
	rm -f kubecf-bundle-v*.tgz helm cf-operator.tgz kubecf_release.tgz values.yaml
	kind delete cluster --name kubecf

cf-deploy-app:
	./nex-deploy-local.sh $(NAMESPACE)

cf-undeploy-app:
	./nex-undeploy-local.sh $(NAMESPACE)

cf-run-side-services:
	cd ..
	PREFIX=$(NAMESPACE) docker-compose -f docker-compose-side-services.yml up -d

cf-remove-side-services:
	PREFIX=$(NAMESPACE) docker-compose -f docker-compose-side-services.yml down

cf-auth:
	cf api --skip-ssl-validation $(ENDPOINT)
	admin_pass=$$(kubectl get secret --namespace kubecf var-cf-admin-password -o jsonpath='{.data.password}' | base64 --decode); || \
	cf auth admin "$${admin_pass}"
	