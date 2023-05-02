#!/usr/bin/env bash

# image="xynnn007/verdictd:cc0.5.0-rc0"
image="ghcr.io/katexochen/inclavare-containers/verdictd:1ad3027"

docker run \
    -it \
    --rm \
    -p 12345:12345 \
    --env RUST_LOG=debug \
    $image \
    verdictd \
    --listen=0.0.0.0:12345 \
    --client-api=127.0.0.1:50000 \
    --verifier=sgx_ecdsa \
    --attester=nullattester \
    --mutual
