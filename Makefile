.PHONY: all common bootstrap servers clients deploy

SED_I_FLAG = $(shell if [ "$$(uname)" = "Darwin" ]; then echo "-i ''"; else echo "-i"; fi)
BUTANE_IMAGE = quay.io/coreos/butane:latest


all: bootstrap servers clients

common:
	rm -rf ./config
	rm -rf ./ignition
	cp -a templates config
	mkdir ignition
	find config -type f -print0 | xargs -0 sed $(SED_I_FLAG) "s|%%DATACENTER%%|${DATACENTER}|g"

bootstrap: common
	sed 's|%%SSH_PUBKEY%%|${SSH_PUBKEY}|' nomad-common-clc.yaml | cat - nomad-bootstrap-systemd-clc.yaml | cat - nomad-common-storage-clc.yaml | cat - nomad-bootstrap-storage-clc.yaml | sed 's|%%DATACENTER%%|${DATACENTER}|g;s|%%BOOTSTRAP_IP%%|${BOOTSTRAP_IP}|g' > config/server-1.yaml 
	#docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config --output server-1.ign
	docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config < config/server-1.yaml > ignition/server-1.json

servers: common
	find config/ -type f -print0 | xargs -0 sed $(SED_I_FLAG) 's/%%BOOTSTRAP_IP%%/${BOOTSTRAP_IP}/g'
	sed 's|%%SSH_PUBKEY%%|${SSH_PUBKEY}|' nomad-common-clc.yaml | cat - nomad-server-systemd-clc.yaml | cat - nomad-common-storage-clc.yaml | cat - nomad-server-storage-clc.yaml | sed 's|%%NUMBER%%|2|;s|%%DATACENTER%%|${DATACENTER}|g;s|%%BOOTSTRAP_IP%%|${BOOTSTRAP_IP}|g' > config/server-2.yaml
	#| ct --files-dir config --strict --out-file server-2.ign
	docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config  < config/server-2.yaml > ignition/server-2.json
	sed 's|%%SSH_PUBKEY%%|${SSH_PUBKEY}|' nomad-common-clc.yaml | cat - nomad-server-systemd-clc.yaml | cat - nomad-common-storage-clc.yaml | cat - nomad-server-storage-clc.yaml | sed 's|%%NUMBER%%|3|;s|%%DATACENTER%%|${DATACENTER}|g;s|%%BOOTSTRAP_IP%%|${BOOTSTRAP_IP}|g' > config/server-3.yaml
	#| ct --files-dir config --strict --out-file server-3.ign
	docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config  < config/server-3.yaml > ignition/server-3.json


clients: common
	find config/ -type f -print0 | xargs -0 sed $(SED_I_FLAG) 's/%%BOOTSTRAP_IP%%/${BOOTSTRAP_IP}/g'
	sed 's|%%SSH_PUBKEY%%|${SSH_PUBKEY}|' nomad-common-clc.yaml | cat - nomad-client-systemd-clc.yaml | cat - nomad-common-storage-clc.yaml | cat - nomad-client-storage-clc.yaml | sed 's|%%NUMBER%%|1|;s|%%DATACENTER%%|${DATACENTER}|g;s|%%BOOTSTRAP_IP%%|${BOOTSTRAP_IP}|g' > config/client-1.yaml
	#ct --files-dir config --strict --out-file client-1.ign
	docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config < config/client-1.yaml > ignition/client-1.json
	sed 's|%%SSH_PUBKEY%%|${SSH_PUBKEY}|' nomad-common-clc.yaml | cat - nomad-client-systemd-clc.yaml | cat - nomad-common-storage-clc.yaml | cat - nomad-client-storage-clc.yaml | sed 's|%%NUMBER%%|2|;s|%%DATACENTER%%|${DATACENTER}|g;s|%%BOOTSTRAP_IP%%|${BOOTSTRAP_IP}|g' > config/client-2.yaml
	#ct --files-dir config --strict --out-file client-2.ign
	docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config < config/client-2.yaml > ignition/client-2.json
	sed 's|%%SSH_PUBKEY%%|${SSH_PUBKEY}|' nomad-common-clc.yaml | cat - nomad-client-systemd-clc.yaml | cat - nomad-common-storage-clc.yaml | cat - nomad-client-storage-clc.yaml | sed 's|%%NUMBER%%|3|;s|%%DATACENTER%%|${DATACENTER}|g;s|%%BOOTSTRAP_IP%%|${BOOTSTRAP_IP}|g' > config/client-3.yaml
	#ct --files-dir config --strict --out-file client-3.ign
	docker run --rm -i -v "$(PWD)/config:/config" $(BUTANE_IMAGE) --files-dir /config < config/client-3.yaml > ignition/client-3.json

deploy:
	./azure-deploy.sh ${RESOURCE_GROUP}
