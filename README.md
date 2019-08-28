# bp7 evaluation setup

## Directory Layout

- `bp7-go-v0.1/` - *DEPRECATED* go+wasm version 0.1
- `bp7-go-v0.2/` - go+wasm version 0.2
- `bp7wasm/` - rust+wasm version and chrome runner script
- `eval/` - scripts for evaluating results
- `results/` - output folder for results

## Build Instructions

```
./docker-build.sh
```

## Running

For interactive container: 
```
./docker-run.sh
```

For automated evaluation runs: 
```
./docker-run.sh /eval.sh
```

Output gets written to `./results`

## Evaluation

Preprocessing output

```
./eval/output2csv.sh results
```