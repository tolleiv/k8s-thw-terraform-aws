# Makefile to kick of the terraform for this project
#
# You should set the following environment variable to authenticate
# with AWS so you can store and retrieve the remote state befor you run this Makefile.
#
# export AWS_ACCESS_KEY_ID= <your key>
# export AWS_SECRET_ACCESS_KEY= <your secret>
# export AWS_DEFAULT_REGION= <your bucket region eg ap-southeast-2>
# export TF_VAR_access_key=$AWS_ACCESS_KEY # exposed as access_key in the terraform scripts
# export TF_VAR_secret_key=$AWS_SECRET_ACCESS_KEY
#
# Reference: http://karlcode.owtelse.com/blog/2015/09/01/working-with-terraform-remote-statefile/
# ####################################################
#
STATEBUCKET=aoe-test-terraform-state

# # Before we start test that we have the manditory executables avilable
 EXECUTABLES = git terraform
 K := $(foreach exec,$(EXECUTABLES),\
  $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH, consider apt-get install $(exec)")))
#
#     .PHONY: all s3bucket plan


.PHONY: all plan apply

all: init.txt keydir key plan
	echo "All"

keydir:
	mkdir ssh

key: keydir
	ssh-keygen -t rsa -C "kubernetes_the_hard_way" -P '' -f ssh/kubernetes_the_hard_way

plan:
	@echo "running terraform plan"
	terraform plan

apply:
	@echo "running terraform apply"
	terraform apply -refresh=true

detroy:
	@echo "running terraform destroy"
	terraform destroy

# little hack target to prevent it running again without need
# for second nested Makefile
init.txt:
	@echo "initialise remote statefile"
	terraform remote config -backend=s3 -backend-config="bucket=$(STATEBUCKET)" -backend-config="key=terraform.tfstate"
	echo "ran terraform remote config -backend=s3 -backend-config=\"bucket=$(STATEBUCKET)\" -backend-config=\"key=terraform.tfstate\"" > ./init.txt
