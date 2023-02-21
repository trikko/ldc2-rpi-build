#!/bin/bash
docker run --rm -ti -v $PWD:/source ldc-build /bin/bash -c 'ulimit -n 2048' && $@
