Create vSphere Environmnet using Terraform

Usage: 
terraform plan -var-file=Swarm/swarm.tfvars -var-file=DR.tfvars -state=Swarm/swarm.tfstate

DR.tfvars = contains taget vCenter variable

SWARM folder
-- Initializes SWARM environment
-- contains tfstate for SWARM
