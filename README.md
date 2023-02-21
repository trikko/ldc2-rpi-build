# ldc2-rpi-build

To build and get result inside /tmp/deploy:

```bash
docker build -t ldc-build .
./deploy.sh
```

To run a command (after a succesfully build), for example dub on current directory:
```bash
./run.sh dub
```
