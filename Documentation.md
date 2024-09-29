# 1. Introduction

My task is with designing, implementing, and optimizing a scalable web application deployment in AWS cloud environment. The application is a simple nginx web service that is containerized deployed in EKS, and manage using DevOps best practices.

# 2. Deployment files creation

**Steps:**

- Created a simple index.html page of nginx.

- Created Dockerfile.

- Created YAML files for deployment and service.

- Created Jenkinsfile.

  

  I created all these files in my GitHub repository. 
  Github link: https://github.com/ajmal-up/nginx/tree/main

  

# 3. Infrastructure provisioning

In this step I provisioned a fully managed, scalable and protected EKS cluster using Terraform.
After installation of terraform, created resource wise files.
Reference : Official Hashicorp documentation.

Terraform script is uploaded in GitHub.
Github link : https://github.com/ajmal-up/application_deployment_end_to_end.git

**Steps to execute terraform actions:**

- terraform workspace new prod - Created a new workspace 'prod' for isolated workspace.

- terraform init - Initialize terraform and download reuired plugins
- terraform plan -var-file=terraform-prod.tfvars  - Provide an outline what resources are going to provision.
- terraform apply -var-file=terraform-prod.tfvars - Apply the resources as per the plan.

**Note:**

- This cluster is scalable and protected with IAM policies and roles. Only admins have escalated access in the cluster level.

- I created this cluster by assuming it as a production environment for provisioning more security measures. Hence I have used capacity type as ON-DEMAND instances for not to interrupt workloads. 

  **<u>Security practices</u>**

  - Created a separate role for developers for their limited resource verification
  - Created S3 bucket to store state file remotely and DynamoDB table to lock simultaneous modifications.
  - Using IAM roles and RBAC (Role based access control) I have assigned minimal required access for members other than admin.
  - Deployed worker node in private subnet, thereby restricting external access to workloads in the node.

  Verify cluster is created as per the specifications from console or CLI.

  ![](C:\Users\HP\Desktop\assesment\EKS.PNG)
  



# 4. CI/CD Pipeline creation

In this step, I have created CI/CD pipeline using Jenkins.
For Jenkins, I have launched an Ubuntu 22.04 free tier ec2 instance in AWS and installed jenkins there.

In this server, I installed docker, AWS cli and kubectl also.

**Commands for installation:**

- sudo apt-get update      # update the default Ubuntu packages lists

- sudo apt-get install openjdk-11-jdk     # For installing  JDK 11

- curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null                                   

- echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

  (Above two commands will add Jenkins' official package repository to our system and secure the repository with a GPG key)

- sudo apt-get update && sudo apt-get install jenkins                   #update the repo and install jenkins
- sudo systemctl start jenkins.service                 # Start jenkins
- sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io       # Docker installation
- sudo systemctl start docker
  sudo systemctl enable docker                           # Start docker
- sudo usermod -aG docker jenkins                    # Add jenkins user to docker group
- curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install                                                 # Install AWS CLI
- curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl         # Install kubectl



After installation, login to jenkins server and install all required plugins from manage Jenkins.



**Steps for CI/CD:**

* Create new pipeline job and provide source code repository.

* Setup Github, AWS and Kubernetes credentials in global credentials of jenkins.

* Provide branch name in configuration. After Apply and Save, pipeline will start as per the stages mentioned in jenkinsfile.

  ![](C:\Users\HP\Desktop\assesment\pipeee.PNG)

**Note:**

As application is a simple web app, main stages are:

- Build image from Dockerfile and Push to ECR (ECR is already created in AWS)

- I used rolling update deployment. Image name in deployment.yaml file is kept as a variable. It will update the image name and tag as the build number in Jenkins. So this stage will update the variable in deployment file with build number.

- Jenkins will login to our cluster with CREDENTIAL ID (Added in Manage Jenins --> Credentials) and deploy all K8S manifest files.

  <u>**Security practices:**</u>

  - No credentials were exposed. Everything is stored in manage jenkins.

  - Rolling update deployment will help to roll back to previous successful image.

  - If this is a multi branch pipeline, we can add more security measures like adding approval stage before production deployment, Role based access control etc...

    

# 5. Deployment Verification

After successful completion of pipeline, let's verify the status of deployment.
From terminal, login to kubernetes cluster with this command:

**aws eks update-kubeconfig --name app-cluster-prod --region us-east-1**

- Check status of pods in our namespace

  ![image-20240929205550734](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20240929205550734.png)
  

- Service type mentioned is LoadBalancer. Check the external ip for output
  ![image-20240929205819157](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20240929205819157.png)

​      external ip : http://ab81d226f2e22491bb78d3d99280970e-658126442.us-east-1.elb.amazonaws.com/
We can map this external ip in route53 with our own domain name.

![image-20240929210026627](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20240929210026627.png)
Deployment is successful.



# 6. Monitoring the Deployment

After successful deployment, we need to monitor our workloads and resources. For that I am using Prometheus and Grafana.

**Steps for installing prometheus and grafana**

- Install prometheus and grafana with helm chart in our EKS cluster. 

- helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
  (This will add prometheus helm repo)

- helm repo update      # Update helm repo

- helm install my-kube-prometheus-stack prometheus-community/kube-prometheus-stack 
  (This will install both prometheus and grafana in our cluster)

  ![image-20240929212258366](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20240929212258366.png)



- Expose prometheus and grafana externally

  - kubectl expose service kube-prometheus-stack-prometheus --type=LoadBalancer --target-port=9090 --name=prometheus-service-ext
  - kubectl expose service my-kube-prometheus-stack-grafana --type=LoadBalancer --name=grafana-server-ext

  (These commands will expose prometheus and grafana eternally in 9090 and 80 ports respectievely. We can do port forwarding also. But that will remain for short time only. Once terminal is closed, connection will interrupt. Hence I chose to expose externally.)

- We can query metrices from prometheus interface.

  ![image-20240929213315376](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20240929213315376.png)



- For visualizing theses metrices, login to grafana with 'admin' as user name and password obtained from secrets.
  kubectl get secret my-kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' -n default | base64 --decode 

- Add data source as prometheus. Home --> Data Sources --> Add new data source --> Prometheus.

- Create dashboard for required query.

  ![](C:\Users\HP\Desktop\assesment\Grafana.PNG)

  There will be in-built dashboards for general metrices. Above screenshot is CPU usage of nginx pod that i deployed in cluster. 

- We can create our own custom dashboards also.

  ![](C:\Users\HP\Desktop\assesment\Dashboard.PNG)

- Now for logging, I have used Loki. Loki can be installed by helm chart.
  Search for loki chart:
  helm search repo loki

- Configurations of loki can be append to a values.yaml file.
  helm show values grafana/loki-stack > values.yaml.
  Edit required configurations like promtail in this file.

- Install loki with modified values.yaml file
  helm install --values values.yaml loki grafana/loki-stack

  ![image-20240930003927888](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20240930003927888.png)

  

- Go to grafana and add loki as data source. Now we can query logs for our cluster and the application which we deployed in the cluster.
  ![](C:\Users\HP\Desktop\assesment\Loki.PNG)



Here loki along with promtail is used to fetch logs from containers in the cluster. 
Values.yaml have uploaded in the GitHub repository.

- For alert mechanism, we can use alert manager in the grafana itself.

  - Home --> Alerting --> Alert rules --> New alert rule.

  - Define query and alert condition.

  - Set the threshold value of chosen query. (Is above, Is below, Is within range, Is outside range)

  - Set the Contact point. 
    We can integrate alerts with Email, Slack, AWS SNS, Discord, Telegram, Webhook etc...
    For this POC, I have selected my email.

  - After configuring all required fields, click create rules.

    ![](C:\Users\HP\Desktop\assesment\Alerting.PNG)

  Thus we will get a complete monitoring, logging and alerting setup for our deployments

# 7. Cost Optimization 

Here are the cost optimization methods I followed for this POC:

- For EKS, I setup Cluster auto-scaler to ensure nodes scale with the workload demand
- Added tags for all compute resources so that I can explore costs based on tags in AWS Cost explorer and perform required actions
- As this is a rolling update deployment, I enabled life cycle rules for ECR. So that it will delete old images based on days and count of images.
- Enabled auto scheduler for instances so that it will shutdown on evening and restart on morning.
  Thereby I can reduce running cost.

For this setup, these are the possible cost optimization techniques we can follow. For higher production environments we have other several cost optimization methods are there if we are using any other AWS services. 



# 8. Challenges Faced

These are the challenges I faced during this POC:

- While installing jenkins, after installing JDK I was not able to update the repository due to error in signature of packages from repository.

  - Error : W: GPG error: [http://pkg.jenkins-ci.org](http://pkg.jenkins-ci.org/) binary/ Release: The following signatures couldn't be verified

  - Solution : Update Debian compatible operating systems (Debian, Ubuntu, Linux Mint Debian Edition, etc.) with new signing keys.

    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null

- While installing monitoring tools, helm package was not suitable.
  Searching and installing correct and suitable package was little bit challenging.



# 9. Nutshell

Let me summarize the tools I used and required links:

- Cloud provider : AWS
- Infrastructure as code : Terraform
- CI/CD tool: Jenkins
- Monitoring and logging : Prometheus, Grafana and Loki

Github link for sample app and deployment files: https://github.com/ajmal-up/nginx.git

Github link for all other configurations: https://github.com/ajmal-up/application_deployment_end_to_end.git