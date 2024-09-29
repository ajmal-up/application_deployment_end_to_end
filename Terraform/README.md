TERRAFORM
---------

Here with these terraform script, we will provision a fully managed, scalable and protected EKS cluster.
This scripts are modular, reusable and follows best practices

## Note:
  - We are creating an EKS cluster for our application in production environment. 

  - As we assume it is a production env, we are using ON-DEMAND instances for guaranteed computing without interruptions. If this is a test environment we will use SPOT instances, that will save the cost upto 90% compared to ON-DEMAND prices.

     in terraform-prod.tfvars file, change capacity type if we want to use spot instances:
        capacity_type  = "SPOT" 

  - We have created one cluster role with the name 'developer' that will provide only required access to developers to access clusters for checking infos like node, deployment, pod statuses etc...
  This will provide more security to our environment from deletion of cluster resources by other team members.
  
  - We have created s3 bucket for storing state file remotely that will ensure state file security.
  Also DynamoDB table which will lock the state file by preventing simultaneous modifications.
