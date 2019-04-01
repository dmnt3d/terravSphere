Create vSphere Environmnet using Terraform

Usage: 
for SWARM:
terraform plan -var-file=Swarm/swarm.tfvars -var-file=DR.tfvars -state=Swarm/swarm.tfstate

for K8S:
terraform plan -var-file=K8S/swarm.tfvars -var-file=DR.tfvars -state=K8S/k8s.tfstate


DR.tfvars = contains taget vCenter variable

SWARM folder
-- Initializes SWARM environment
-- contains tfstate for SWARM
