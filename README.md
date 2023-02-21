# ldc2-rpi-build

To build and put the ldc2 package in /tmp/deploy:

```bash
docker build -t ldc-build .
./deploy.sh
```

To run a command (after a succesfully build), for example dub on your current directory:
```bash
./run.sh dub
```
