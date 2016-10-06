# K8s the hard way - terraform+AWS

These scripts reproduce the steps from [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) with [Terraform](https://terraform.io).

The resulting setup is not production ready anyhow. Its just used to play around with Terraform, Kubernetes and AWS.


## Usage

In order to run the scripts open up a terminal and run (on Linux or Mac OSX):

    export TF_VAR_access_key=XXXXXXXXXXXXXX
    export TF_VAR_secret_key=XXXXXXXXXXXXXX
    export TF_VAR_region=eu-central-1
    terraform plan
    ... check check ...
    terraform apply
    ... test test ...
    terraform destroy
    
    
Be aware that some of the steps are executed on your local machine. These are not cleaned up through terraform.

## License 
 
 MIT License