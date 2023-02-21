#!/bin/bash
docker run --rm -ti -v /tmp/deploy:/deploy ldc-build /bin/bash -c 'mkdir -p /deploy && tar -czf /deploy/ldc-$LDC_VERSION-armbian.tar.gz /ldc-$LDC_VERSION/*'
