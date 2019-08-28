#!/bin/sh

GOOS=js GOARCH=wasm go build -o test.wasm -ldflags='-s -w' ../benchmark.go
