#!/bin/sh

docker run -it --rm -v `pwd`/results:/output -p 4000:4000 bp7eval $@
