EKS_NAME ?= nameko-devex-eks
NAMESPACE ?= dev
AWS_PROFILE ?= leverx
ECR_REPO ?= 397662559378.dkr.ecr.eu-central-1.amazonaws.com
TAG ?= dev

deploy-eks: eks-create-cluster eks-setup-ingress
	$(MAKE) init-helm
	$(MAKE) eks-create-namespace
	$(MAKE) eks-deploy-dependencies
	$(MAKE) eks-install-charts
	$(MAKE) eks-create-balancer

undeploy-eks:
	# eks-delete-namespace:
	eksctl delete cluster --name=$(EKS_NAME) --profile $(AWS_PROFILE)

eks-create-cluster:	
	eksctl create cluster \
	--name $(EKS_NAME) \
	--version 1.21 \
	--region eu-central-1 \
	--nodegroup-name $(EKS_NAME)-ng-1 \
	--node-type t3.medium \
	--node-labels ingress-ready=true \
	--node-volume-size 20 \
	--nodes 4 \
	--vpc-public-subnets subnet-96ac4dfc,subnet-767f230b,subnet-d65c7f9b \
	--profile $(AWS_PROFILE)

eks-setup-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	sleep 15
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

eks-create-namespace:
	kubectl apply -f namespaces/$(NAMESPACE).yaml

eks-delete-namespace:
	kubectl delete -f namespaces/$(NAMESPACE).yamleks-install-charts

eks-create-balancer:
	sleep 30
	kubectl apply -f service.yaml --namespace $(NAMESPACE)
	kubectl get svc nameko-devex-load-balabcer --namespace $(NAMESPACE)

init-helm:
	helm repo add stable https://charts.helm.sh/stable
	helm repo update

eks-deploy-dependencies:
	helm upgrade broker stable/rabbitmq --install \
		--namespace $(NAMESPACE)
	helm upgrade db stable/postgresql --install \
		--set postgresqlDatabase=orders \
		--namespace $(NAMESPACE)
	helm upgrade cache stable/redis --install \
		--namespace $(NAMESPACE)
	kubectl --namespace=$(NAMESPACE) get pods

eks-install-charts:
	cd ..; $(MAKE) build

	aws ecr get-login-password --profile $(AWS_PROFILE) | docker login --username AWS --password-stdin $(ECR_REPO)

	export HELM_EXPERIMENTAL_OCI=1; \
	aws ecr get-login-password \
     --profile $(AWS_PROFILE) | helm registry login \
     --username AWS \
     --password-stdin $(ECR_REPO)

	docker tag nameko/nameko-example-gateway:$(TAG) $(ECR_REPO)/nameko-example-gateway:$(TAG)
	docker push $(ECR_REPO)/nameko-example-gateway:$(TAG)
	docker tag nameko/nameko-example-orders:$(TAG) $(ECR_REPO)/nameko-example-orders:$(TAG)
	docker push $(ECR_REPO)/nameko-example-orders:$(TAG)
	docker tag nameko/nameko-example-products:$(TAG) $(ECR_REPO)/nameko-example-products:$(TAG)
	docker push $(ECR_REPO)/nameko-example-products:$(TAG)
	
	$(MAKE) SERVICE_NAME=gateway eks-install-chart
	$(MAKE) SERVICE_NAME=orders eks-install-chart
	$(MAKE) SERVICE_NAME=products eks-install-chart

eks-install-chart:
	helm upgrade $(SERVICE_NAME) ../k8s/charts/$(SERVICE_NAME) --install \
	--namespace=$(NAMESPACE) \
	--set image.tag=$(TAG) \
	--set image.image=$(ECR_REPO)/nameko-example-$(SERVICE_NAME)


################### TESTS #######################

eks-smoke-test:
	../test/nex-smoketest-eks.sh $(DOMAIN)

eks-perf-test:
	cd ..; ./test/nex-bzt.sh $(DOMAIN)