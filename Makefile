SHELL := /bin/bash

KUBE_DEFS = $(shell find cluster -name '*.pkl')

PKL_TMP_DIR = ./storage/tmp/pkl-output
CLUSTER_STAMP := ./storage/.cluster_ready
PULL_STAMP := ./storage/.images_pulled

all: pkl PklProject.deps.json Settings.pkl releases create-cluster pull apply

pkl:
	@curl -L -o pkl 'https://github.com/apple/pkl/releases/download/0.28.2/pkl-linux-amd64'
	@chmod +x pkl
	@./pkl --version

PklProject.deps.json: pkl
	@./pkl project resolve

Settings.pkl: pkl
	@cp templates/Settings.demo.pkl ./Settings.pkl
	@echo ">>>> MAKE SURE YOU EDITED THE SETTINGS FILE CORRECTLY <<<<"

releases: Settings.pkl
	@./scripts/fetch-releases.sh
	@touch releases/

update:
	rm -rf releases
	@./scripts/fetch-releases.sh
	@touch releases/

pull:
	make $(PULL_STAMP)
$(PULL_STAMP): releases $(CLUSTER_STAMP)
	@echo "Loading image DEMOBACKEND..."
	@output="$$(docker load -i $$(ls releases/demo-backend/latest/demo-backend-*.tar | tail -n 1))"; \
	echo "$$output"; \
	image_tag="$$(echo "$$output" | grep 'Loaded image:' | awk -F': ' '{print $$2}')"; \
	name="$$(echo $$image_tag | cut -d':' -f1)"; \
	tag="$$(echo $$image_tag | cut -d':' -f2)"; \
	echo "Tagging $$name:$$tag as $$name:latest"; \
	docker tag "$$name:$$tag" "$$name:latest"; \
	echo "Importing $$name:latest into k3d..."; \
	k3d image import "$$name:latest" -c demo
	@echo "Loading image DEMOFRONTEND..."
	@rm -rf storage/demo/nginx/public/
	@mkdir -p storage/demo/nginx/public/
	@touch $(PULL_STAMP)
	@unzip -o $$(ls releases/demo-frontend/latest/*.zip | tail -n 1) -d storage/demo/nginx/public/
	@echo "Loading image DEMOPRO FRONTEND..."
	@rm -rf storage/pro/nginx/public/
	@mkdir -p storage/pro/nginx/public/
	@touch $(PULL_STAMP)
	@unzip -o $$(ls releases/demo-pro-frontend/latest/*.zip | tail -n 1) -d storage/pro/nginx/public/
apply: releases pull
	@rm -rf $(PKL_TMP_DIR)
	@mkdir -p $(PKL_TMP_DIR)
	for pkl_file in $(KUBE_DEFS); do \
	  rel_path=$${pkl_file#cluster/}; \
	  out_path=$(PKL_TMP_DIR)/$${rel_path%.pkl}.yaml; \
	  ./pkl eval $$pkl_file -f yaml -o $$out_path; \
	done;
	@kubectl apply -k $(PKL_TMP_DIR);
	@domain=$$(./pkl eval Settings.pkl -f json | jq -r '.ingresses.demo.domain');\
	echo "API_BASE_URL=\"https://$$domain\"" > storage/demo/nginx/public/api.js
	@domain=$$(./pkl eval Settings.pkl -f json | jq -r '.ingresses.pro.domain');\
	echo "API_BASE_URL=\"https://$$domain\"" > storage/pro/nginx/public/api.js

create-cluster:
	make $(CLUSTER_STAMP)
$(CLUSTER_STAMP):
	@./scripts/create-cluster.sh;
	@./scripts/install-helms.sh;
	@touch $(CLUSTER_STAMP)
delete-cluster:
	@./scripts/delete-cluster.sh;
	@rm -f $(CLUSTER_STAMP)

clean: delete-cluster 

fclean:  clean
	@rm -rf ./releases
	@rm ./pkl

re: clean all

.PHONY: all clean fclean re create-cluster delete-cluster apply pull