#!/bin/sh

#cargo build --release --target wasm32-unknown-unknown --lib
#wasm-bindgen target/wasm32-unknown-unknown/release/bp7wasm.wasm --out-dir wasm --target web

cargo web deploy --release