#!/bin/bash

source $HOME/.cargo/env

mkdir /output

echo "## getting binary sizes"

stdbuf -oL ls -la /src/bp7wasm/target/release/bp7eval | awk '{print $5,$9}' 2>&1 > /output/binary.sizes.txt
stdbuf -oL ls -la /src/bp7wasm/target/deploy/bp7eval.wasm | awk '{print $5,$9}' 2>&1 >> /output/binary.sizes.txt
stdbuf -oL ls -la /src/dtn7-go-v0.1/tests/tests | awk '{print $5,$9}' 2>&1 >> /output/binary.sizes.txt
stdbuf -oL ls -la /src/dtn7-go-v0.1/tests/wasm/test.wasm | awk '{print $5,$9}' 2>&1 >> /output/binary.sizes.txt
stdbuf -oL ls -la /src/dtn7-go-v0.2/tests/tests | awk '{print $5,$9}' 2>&1 >> /output/binary.sizes.txt
stdbuf -oL ls -la /src/dtn7-go-v0.2/tests/wasm/test.wasm | awk '{print $5,$9}' 2>&1 >> /output/binary.sizes.txt

echo "## running rust(native)"

stdbuf -oL /src/bp7wasm/target/release/bp7eval 2>&1 > /output/bp7-rs.native.out

echo "## running rust(wasm)"
cd /src/bp7wasm/target/deploy
basic-http-server >/dev/null &
cd ../..
stdbuf -oL ./run_bench.sh 2>&1 > /output/bp7-rs.wasm.out
killall basic-http-server

echo "## running go(native) v0.1"
stdbuf -oL /src/dtn7-go-v0.1/tests/tests 2>&1 > /output/bp7-go-v0.1.native.out

echo "## running go(native) v0.2"
stdbuf -oL /src/dtn7-go-v0.2/tests/tests 2>&1 > /output/bp7-go-v0.2.native.out

echo "## running go(wasm) v0.2"
cd /src/dtn7-go-v0.2/tests/wasm
basic-http-server >/dev/null &
stdbuf -oL /src/bp7wasm/run_bench.sh 2>&1 > /output/bp7-go-v0.2.wasm.out
killall basic-http-server
