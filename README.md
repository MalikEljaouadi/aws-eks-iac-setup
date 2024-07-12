# aws-eks-iac-setup
This repo aims to create a state of the art AWS EKS cluster using Terraform as an IAC

## TODO: 
- [ ] Add diagrams
- [ ] Add guided explanation
- [ ] Reconsidere structuring the project
- [ ] For each one of the deployed apps explain what the app does and what are the deployment carcteristics of this app
- [ ] Explain that we need to allow for our cluster to run the stateful apps in EKS: So we need to install the CSI driver to allocate the EBS volumes and mount them to the pods with ReadWriteOnce access mode