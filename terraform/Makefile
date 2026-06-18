.PHONY: fmt fmt-check lint validate/dev init/dev plan/dev apply/dev secrets/set/dev secrets/set/prod

OP_VAULT ?= Private

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check

lint:
	tflint --recursive --config="$(CURDIR)/.tflint.hcl"
	trivy config .

validate/dev:
	terraform -chdir=projects/dev init -backend=false
	terraform -chdir=projects/dev validate

init/dev:
	terraform -chdir=projects/dev init \
		-backend-config="bucket=$(TF_STATE_BUCKET)" \
		-backend-config="prefix=$(GCP_PROJECT_ID_PREFIX)-dev"

plan/dev:
	terraform -chdir=projects/dev plan -out=tfplan

apply/dev:
	terraform -chdir=projects/dev apply tfplan

secrets/set/dev:
	op read "op://$(OP_VAULT)/$(GCP_PROJECT_ID_PREFIX)-dev/google-api-key" | gcloud secrets versions add google-api-key --project=$(GCP_PROJECT_ID_PREFIX)-dev --data-file=-
	op read "op://$(OP_VAULT)/$(GCP_PROJECT_ID_PREFIX)-dev/google-oauth-client-id" | gcloud secrets versions add google-oauth-client-id --project=$(GCP_PROJECT_ID_PREFIX)-dev --data-file=-
	op read "op://$(OP_VAULT)/$(GCP_PROJECT_ID_PREFIX)-dev/google-oauth-client-secret" | gcloud secrets versions add google-oauth-client-secret --project=$(GCP_PROJECT_ID_PREFIX)-dev --data-file=-

secrets/set/prod:
	op read "op://$(OP_VAULT)/$(GCP_PROJECT_ID_PREFIX)-prod/google-api-key" | gcloud secrets versions add google-api-key --project=$(GCP_PROJECT_ID_PREFIX)-prod --data-file=-
	op read "op://$(OP_VAULT)/$(GCP_PROJECT_ID_PREFIX)-prod/google-oauth-client-id" | gcloud secrets versions add google-oauth-client-id --project=$(GCP_PROJECT_ID_PREFIX)-prod --data-file=-
	op read "op://$(OP_VAULT)/$(GCP_PROJECT_ID_PREFIX)-prod/google-oauth-client-secret" | gcloud secrets versions add google-oauth-client-secret --project=$(GCP_PROJECT_ID_PREFIX)-prod --data-file=-
