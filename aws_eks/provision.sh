#!/bin/bash 

if [ $# -eq 0 ]
then
    echo " please provide your AWS account id"
    exit 1
fi

for tool in terraform eksctl kubectl curl aws
do 
    which $tool > /dev/null || (echo "please make sure these tool are installed [terraform eksctl kubectl curl aws]" &&  exit 1)
done 

echo "####################################################################"
echo "          deploying eks cluster for development:"
echo "              1- eks cluster in us-east-1 region"
echo "              2- AWS LB controller for ingress"
echo "              3- prometheus-grafana stack for monitoring"
echo "####################################################################"


# infrastructure setup: terraform 
terraform init || (echo "couldn't initalize terraform project\nmake sure you are in the project directory"; exit 1)
terraform plan -out task-paln
terraform apply -auto-approve  task-paln || (echo "couldn't provision AWS infra, please review your terraform code"; terraform destroy -auto-approve;  exit 1 )


# update kubeconfig
aws eks update-kubeconfig --name dev-cluster --region us-east-1
echo "kubeconfig updated.\n"
# Install prometheus stask for monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus -n monitoring --create-namespace prometheus-community/kube-prometheus-stack


# Install Load balancer controller
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json 

eksctl delete iamserviceaccount \
--cluster=dev-cluster \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--region us-east-1

eksctl create iamserviceaccount \
--cluster=dev-cluster \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::$1:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--region us-east-1 \
--approve


helm repo add eks https://aws.github.io/eks-charts
helm repo update

# kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=dev-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller


kubectl patch service prometheus-grafana -n monitoring -p '{"spec":{"type":"NodePort"}}'

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/load-balancer-name: "dev-alb"
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-grafana
            port:
              number: 80
EOF

# finally
echo "\nuse: 'kubectl get ingress grafana -n monitoring' to retrive grafana public url"