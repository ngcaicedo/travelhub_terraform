.PHONY: help init plan apply destroy fmt validate validate-modules up down up-stack down-stack clean

ENV ?= development
STACK ?= networking

STACK_DIR = stacks/$(STACK)
ENV_DIR = environments/$(ENV)/$(STACK)

# Stack order for bringing infra up (dependencies first)
UP_ORDER   = networking registry data compute frontend cicd
# Reverse order for tear down (dependents first)
DOWN_ORDER = cicd frontend compute data registry networking

# Modules that generate local artifacts (used by validate-modules and clean)
MODULES_WITH_ARTIFACTS = lambda

help:
	@echo "=== TravelHub Terraform ==="
	@echo ""
	@echo "Usage: make <target> ENV=<environment> STACK=<stack>"
	@echo ""
	@echo "Environments: development, production"
  @echo "Stacks:       networking, registry, data, compute, frontend, cicd"
	@echo "Modules:      alb, codebuild, codepipeline, ecr, ecs_cluster, ecs_service,"
	@echo "              elasticache, lambda, rds, secrets_manager, security_groups"
	@echo ""
	@echo "Targets:"
	@echo "  make init             - Initialize terraform backend"
	@echo "  make plan             - Show execution plan"
	@echo "  make apply            - Apply changes"
	@echo "  make destroy          - Destroy resources"
	@echo "  make fmt              - Format all terraform files"
	@echo "  make validate         - Validate all stacks (needs init first)"
	@echo "  make validate-modules - Validate all reusable modules"
	@echo "  make up               - Init+apply ALL stacks in order (networking->registry->data->compute->frontend->cicd)"
	@echo "  make down             - Destroy ALL stacks in reverse order (cicd->frontend->compute->data->registry->networking)"
	@echo "  make clean            - Remove generated artifacts (lambda zip, .terraform.lock.hcl overrides, etc.)"
	@echo ""
	@echo "Examples:"
	@echo "  make init ENV=development STACK=networking"
	@echo "  make plan ENV=development STACK=networking"
	@echo "  make apply ENV=development STACK=networking"
	@echo "  make up ENV=development"
	@echo "  make down ENV=development"
	@echo "  make validate-modules"
	@echo ""
	@echo "Stack dependency map:"
	@echo "  networking -> registry -> data (RDS + ElastiCache + Secrets) -> compute (ECS + Lambda) -> cicd"
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
	@for stack in networking registry data compute frontend cicd; do \
		echo "Validating stack: $$stack..."; \
		cd stacks/$$stack && terraform validate 2>/dev/null || echo "  (needs init first)"; \
		cd ../..; \
	done

validate-modules:
	@for mod in alb codebuild codepipeline ecr ecs_cluster ecs_service elasticache lambda rds secrets_manager security_groups; do \
		echo "Validating module: $$mod..."; \
		cd modules/$$mod && terraform validate 2>/dev/null || echo "  (needs init first)"; \
		cd ../..; \
	done

clean:
	@echo "Removing generated artifacts..."
	@find modules/lambda -name "lambda_payload.zip" -delete && echo "  Removed lambda_payload.zip" || true
	@find . -name ".terraform" -type d -prune -exec echo "  Skipping .terraform dir: {}" \; 2>/dev/null || true
	@echo "Done."

# --- Orchestrated lifecycle targets -----------------------------------------
# Bring the whole environment up, honoring inter-stack dependencies.
up:
	@echo ">>> Bringing up ENV=$(ENV) in order: $(UP_ORDER)"
	@for stack in $(UP_ORDER); do \
		echo ""; \
		echo "=== [UP] $$stack ($(ENV)) ==="; \
		$(MAKE) --no-print-directory up-stack ENV=$(ENV) STACK=$$stack || exit $$?; \
	done
	@echo ""
	@echo ">>> Infra UP complete for ENV=$(ENV)"

# Tear the whole environment down in reverse dependency order.
# Uses -auto-approve because the whole point is to stop burning resources fast.
down:
	@echo ">>> Destroying ENV=$(ENV) in reverse order: $(DOWN_ORDER)"
	@for stack in $(DOWN_ORDER); do \
		echo ""; \
		echo "=== [DOWN] $$stack ($(ENV)) ==="; \
		$(MAKE) --no-print-directory down-stack ENV=$(ENV) STACK=$$stack || exit $$?; \
	done
	@echo ""
	@echo ">>> Infra DOWN complete for ENV=$(ENV)"

# Internal: init + apply a single stack non-interactively.
up-stack:
	cd $(STACK_DIR) && terraform init -reconfigure -backend-config=../../$(ENV_DIR)/backend.tfvars
	cd $(STACK_DIR) && terraform apply -auto-approve -var-file=../../$(ENV_DIR)/terraform.tfvars

# Internal: init + destroy a single stack non-interactively.
# init is required so destroy can read the remote state / providers.
down-stack:
	cd $(STACK_DIR) && terraform init -reconfigure -backend-config=../../$(ENV_DIR)/backend.tfvars
	cd $(STACK_DIR) && terraform destroy -auto-approve -var-file=../../$(ENV_DIR)/terraform.tfvars
