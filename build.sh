#!/bin/bash

echo "## building rust versions"
source $HOME/.cargo/env
cd /src/bp7wasm
cargo build --release
strip /src/bp7wasm/target/release/bp7eval
./wasm-build.sh

echo "## building go versions"
cd /src/dtn7-go-v0.1/tests
go build 
strip /src/dtn7-go-v0.1/tests/tests
cd wasm
./build-wasm.sh


cd /src/dtn7-go-v0.2/tests
go build
strip /src/dtn7-go-v0.2/tests/tests
cd wasm
./build-wasm.sh


#cd /src/dtn7-go/tests
#go build
#cd wasm
#./build-wasm.sh