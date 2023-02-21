# ldc2-rpi-build

To build and get result inside /tmp/deploy:

```bash
docker build -t ldc-build .
docker run --rm -ti -v /tmp/deploy:/deploy ldc-build
```
