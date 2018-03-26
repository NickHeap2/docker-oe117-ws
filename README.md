# docker-oe117-ws

## Port details

<https://knowledgebase.progress.com/articles/Article/20622?q=webspeed+ports&l=en_US&fs=Search&pn=1>

## Docker commands

### Build the docker image

```bash
docker build -t oe117-ws:0.1 -t oe117-ws:latest .
```

### Run the container

```bash
docker run -it --rm --name oe117-ws -p 5162:5162/udp -p 20931:20931 -p 3055:3055 -p 3202-3502:3202-3502 oe117-ws:latest
```

### Run the container with a mapped volume

```bash
docker run -it --rm --name oe117-ws -p 3055:3055 -p 3202-3388:3202-3388 -p 3390-3502:3390-3502 -v S:/workspaces/docker-volumes/webspeed:/var/lib/openedge/code -v S:/workspaces/docker-volumes/webspeed/logs:/usr/wrk oe117-ws:latest
```

### Run bash in the container

```bash
docker run -it --rm --name oe117-ws -p 5162:5162/udp -p 20931:20931 -p 3055:3055 -p 3202-3502:3202-3502 oe117-ws:latest bash
```

### Exec bash in the running container

```bash
docker exec -it oe117-ws bash
```

### Stop the container

```bash
docker stop oe117-ws
```

### Clean the container

```bash
docker rm oe117-ws
```
