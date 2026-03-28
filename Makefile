.PHONY: help init plan apply destroy fmt validate

ENV ?= development
STACK ?= networking

STACK_DIR = stacks/$(STACK)
ENV_DIR = environments/$(ENV)/$(STACK)

help:
	@echo "=== TravelHub Terraform ==="
	@echo ""
	@echo "Usage: make <target> ENV=<environment> STACK=<stack>"
	@echo ""
	@echo "Environments: development, production"
	@echo "Stacks:       networking, registry, data, compute, cicd"
	@echo ""
	@echo "Targets:"
	@echo "  make init      - Initialize terraform backend"
	@echo "  make plan      - Show execution plan"
	@echo "  make apply     - Apply changes"
	@echo "  make destroy   - Destroy resources"
	@echo "  make fmt       - Format all terraform files"
	@echo "  make validate  - Validate all stacks"
	@echo ""
	@echo "Examples:"
	@echo "  make init ENV=development STACK=networking"
	@echo "  make plan ENV=development STACK=networking"
	@echo "  make apply ENV=development STACK=networking"
	@echo ""
	@echo "CI only:    registry -> cicd (enable_deploy=false)"
	@echo "CI+CD full: networking -> registry -> data -> compute -> cicd (enable_deploy=true)"

init:
	cd $(STACK_DIR) && terraform init -backend-config=../../$(ENV_DIR)/backend.tfvars

plan:
	cd $(STACK_DIR) && terraform plan -var-file=../../$(ENV_DIR)/terraform.tfvars

apply:
	cd $(STACK_DIR) && terraform apply -var-file=../../$(ENV_DIR)/terraform.tfvars

destroy:
	cd $(STACK_DIR) && terraform destroy -var-file=../../$(ENV_DIR)/terraform.tfvars

fmt:
	terraform fmt -recursive .

validate:
	@for stack in networking registry data compute cicd; do \
		echo "Validating $$stack..."; \
		cd stacks/$$stack && terraform validate 2>/dev/null || echo "  (needs init first)"; \
		cd ../..; \
	done
