# Momo-infrastructure
## Repo contains:
1) steps to deploy hosted k8s cluster.

├── ansible

│   ├── ansible.cfg

│   ├── playbook.yml

│   └── roles

├── README.md

├── rke_config

│   ├── certificate.yml

│   ├── cert-manager-issuer.yml

│   ├── cluster_certs

│   ├── cluster-issuer.yml

│   ├── cluster.yml

│   ├── encoded.txt

│   ├── ingress-nginx.yml

│   ├── load-balancer.yml

│   ├── loadbalancer.yml

│   ├── metallb

│   ├── momo-ca-cert.yml

│   ├── nginx-ingress-controller.yml

│   ├── terraform.tfstate

│   ├── tls-cert-manager.yml

│   ├── tls.crt

│   ├── tls.csr

│   ├── tls.key

│   └── yandex-ccm-values.yml

└── terraform

    ├── hosts.tpl

    ├── main.tf

    ├── meta.txt

    ├── terraform.tfstate

    ├── terraform.tfstate.backup

    └── variables.tf

2) pictures uploaded to S3 Object Storage in YC

3) steps to deploy application in kubernetes cluster

├── backend

│   ├── configmap.yml

│   ├── deployment.yml

│   ├── secrets.yml

│   ├── service.yml

│   └── vpa.yml

├── frontend

│   ├── configmap.yml

│   ├── deployment.yml

│   ├── ingress.yml

│   ├── secrets.yml

│   └── service.yml

4) helm chart to deploy application in k8s cluster via helm

├── charts

│   ├── backend

│   │   ├── Chart.yaml

│   │   └── templates

│   │       ├── configmap.yaml

│   │       ├── deployment.yaml

│   │       ├── secrets.yaml

│   │       ├── service.yaml

│   │       └── vpa.yaml

│   └── frontend

│       ├── Chart.yaml

│       └── templates

│           ├── configmap.yaml

│           ├── deployment.yaml

│           ├── ingress.yaml

│           ├── secrets.yaml

│           └── service.yaml

├── Chart.yaml

└── values.yaml

Charts are stored in Nexus repo: http://nexus.praktikum-services.tech/repository/alexlevashov-helm-026/
Index of /momo-store
Name	Last Modified	Size	Description
Parent Directory
0.0.1
0.1.0
0.1.1

## Deploy

# Pipeline to deploy application in Kubernetes via manifests:

  stage: deploy

  image: docker:24.0.7-alpine3.19

  before_script:

    - apk update && apk add --no-cache docker-cli-compose openssh-client bash curl gettext

    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    - install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    - eval $(ssh-agent -s)

    - echo "$SSH_PRIVATE_KEY"| tr -d '\r' | ssh-add -

    - mkdir -p ~/.ssh

    - chmod 600 ~/.ssh

    - echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts

    - chmod 644 ~/.ssh/known_hosts

    - mkdir -p ~/.kube

    - echo "$KUBECONFIG_BASE64" | base64 -d >> ~/.kube/config

    - kubectl config use-context momo-store-context

  script:

    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

    - kubectl apply -f kubernetes/backend/service.yml --namespace default

    - kubectl apply -f kubernetes/backend/vpa.yml --namespace default

    - kubectl apply -f kubernetes/backend/deployment.yml --namespace default

    - kubectl apply -f kubernetes/backend/secrets.yml --namespace default

    - kubectl wait --for=condition=available --timeout=60s deployment/backend --namespace default

    - kubectl apply -f kubernetes/frontend/configmap.yml --namespace default

    - kubectl apply -f kubernetes/frontend/service.yml --namespace default

    - kubectl apply -f kubernetes/frontend/deployment.yml --namespace default

    - kubectl wait --for=condition=available --timeout=60s deployment/frontend --namespace default

    - kubectl apply -f kubernetes/frontend/ingress.yml --namespace default

    - kubectl wait --for=condition=available --timeout=60s deployment/backend --namespace default

  after_script:

    - rm ~/.kube/config

  rules:

    - changes:

      - kubernetes/**/*

  environment:

    name: production/backend

    url: http://momo-store.devops-practicum.ru:80

    auto_stop_in: 1h
    
  rules:

    - when: manual

# Pipeline to deploy via helm chart:

deploy-helm:

  stage: deploy

  image: alpine/helm:3.9.4

  before_script:

    #Установка репозитория Helm из Nexus

    - helm repo add my-repo ${HELM_REPO} --username ${NEXUS_USER} --password ${NEXUS_PASS}

    - helm repo update

    #Kubectl install

    - apk update && apk add --no-cache curl

    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    - install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    - mkdir -p ~/.kube

    - echo "$KUBECONFIG_BASE64" | base64 -d >> ~/.kube/config

    - chmod 600 ~/.kube/config

    - kubectl config use-context momo-store-context

    #Убедитесь, что Helm может взаимодействовать с кластером

    - helm repo update

  script:

    #Delete the existing docker-config-secret

    - kubectl delete secret docker-config-secret --namespace default

    #Create docker-config-secret from CICD variable

    - kubectl create secret generic docker-config-secret --namespace default  --from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" --type=kubernetes.io/dockerconfigjson

    - helm upgrade --install momo-store-chart my-repo/momo-store --atomic --namespace default

  after_script:

    - rm ~/.kube/config

  environment:

    name: production

    url: http://momo-store.devops-practicum.ru:80

    auto_stop_in: 1h

  rules:

    - when: manual

## Project status
Project completed. Application is successfully deployed via Helm chart via CICD pipeline.

-------------------------
cd existing_repo
git remote add origin https://gitlab.praktikum-services.ru/std-026-53/momo-infrastructure.git
git branch -M main
git push -uf origin main
