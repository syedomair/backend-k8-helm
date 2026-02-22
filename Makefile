.PHONY : 

ENV ?= dev
ENV_FILE := .env.$(ENV)

# Load the file if it exists
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export # Exports all variables in the included file to the shell
endif

deploy:
	@echo "Deploying to $(ENV) using $(ENV_FILE)..."
	helm upgrade --install $(ENV)-point-service helm/point-service -f helm/point-service/values-$(ENV).yaml --set secret.DATABASE_URL=$(DATABASE_URL) --set image.registry=$(ECR_URL) --set image.tag=$(TAG)
	helm upgrade --install $(ENV)-user-service helm/user-service -f helm/user-service/values-$(ENV).yaml --set secret.DATABASE_URL=$(DATABASE_URL)  --set image.registry=$(ECR_URL) --set image.tag=$(TAG)
	helm upgrade --install $(ENV)-department-service helm/department-service -f helm/department-service/values-$(ENV).yaml --set secret.DATABASE_URL=$(DATABASE_URL)  --set image.registry=$(ECR_URL) --set image.tag=$(TAG)
ifeq ($(ENV),dev) 
	helm upgrade --install $(ENV)-postgres helm/postgres-service -f helm/postgres-service/values.yaml 
	helm upgrade --install $(ENV)-ingress helm/ingress-service -f helm/ingress-service/values.yaml 
else 
	@echo "Unknown ENV=$(ENV). Please set ENV=dev or ENV=stage or ENV=prod." 
endif

build: 
ifeq ($(ENV),stage) 
	$(MAKE) build_stage 
else ifeq ($(ENV),prod) 
	$(MAKE) build_prod 
else ifeq ($(ENV),dev) 
	$(MAKE) build_dev 
else 
	@echo "Unknown ENV=$(ENV). Please set ENV=dev or ENV=stage or ENV=prod." 
endif

build_stage: build_stage_user build_stage_dept build_stage_point

build_prod: build_prod_user build_prod_dept build_prod_point

build_dev:
	eval "$$(minikube docker-env)" && \
	docker build -t dev/user-service:latest -f src/service/user_service/Dockerfile . && \
	docker build -t dev/department-service:latest -f src/service/department_service/Dockerfile . && \
	docker build -t dev/point-service:latest -f src/service/point_service/Dockerfile .

build_stage_user:
	docker build -t stage/user-service:latest -f src/service/user_service/Dockerfile . 
	aws --profile $(AWS_PROFILE) ecr get-login-password
	aws --profile $(AWS_PROFILE) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker tag stage/user-service:latest $(ECR_URL)/stage/user-service:latest
	docker push $(ECR_URL)/stage/user-service:latest

build_stage_dept:
	docker build -t stage/department-service:latest -f src/service/department_service/Dockerfile . 
	aws --profile $(AWS_PROFILE) ecr get-login-password
	aws --profile $(AWS_PROFILE) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker tag stage/department-service:latest $(ECR_URL)/stage/department-service:latest
	docker push $(ECR_URL)/stage/department-service:latest

build_stage_point:
	docker build -t stage/point-service:latest -f src/service/point_service/Dockerfile . 
	aws --profile $(AWS_PROFILE) ecr get-login-password
	aws --profile $(AWS_PROFILE) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker tag stage/point-service:latest $(ECR_URL)/stage/point-service:latest
	docker push $(ECR_URL)/stage/point-service:latest

build_prod_user:
	docker build -t prod/user-service:latest -f src/service/user_service/Dockerfile . 
	aws --profile $(AWS_PROFILE) ecr get-login-password
	aws --profile $(AWS_PROFILE) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker tag prod/user-service:latest $(ECR_URL)/prod/user-service:latest
	docker push $(ECR_URL)/prod/user-service:latest

build_prod_dept:
	docker build -t prod/department-service:latest -f src/service/department_service/Dockerfile . 
	aws --profile $(AWS_PROFILE) ecr get-login-password
	aws --profile $(AWS_PROFILE) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker tag prod/department-service:latest $(ECR_URL)/prod/department-service:latest
	docker push $(ECR_URL)/prod/department-service:latest

build_prod_point:
	docker build -t prod/point-service:latest -f src/service/point_service/Dockerfile . 
	aws --profile $(AWS_PROFILE) ecr get-login-password
	aws --profile $(AWS_PROFILE) ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_URL)
	docker tag prod/point-service:latest $(ECR_URL)/prod/point-service:latest
	docker push $(ECR_URL)/prod/point-service:latest

minikube-build: minikube-delete minikube-start build

minikube-delete:
	minikube delete

minikube-start:
	minikube start --driver=docker
	minikube addons enable ingress

set-eks-context:
	aws eks --region $(AWS_REGION) --profile $(AWS_PROFILE) update-kubeconfig --name $(EKS_CLUSTER_NAME)

