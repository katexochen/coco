#!/usr/bin/env bash

decryptConfigPath="conf/decrypt_config.json"
ocicryptConfigPath="conf/ocicrypt_config.json"

export decryptConfig=$(cat $decryptConfigPath | base64 -w 0)
yq e -i '.spec.config.environmentVariables[2].value = env(decryptConfig)' crd.yml

export ocicryptConfig=$(cat $ocicryptConfigPath | base64 -w 0)
yq e -i '.spec.config.environmentVariables[3].value = env(ocicryptConfig)' crd.yml
