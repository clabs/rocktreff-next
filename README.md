# Rocktreff — Local Development (Linux)

## Prerequisites

- Docker

## Run dev server

```bash
docker run --rm \
  -v "$PWD:/app:Z" \
  -w /app \
  -p 4000:4000 \
  jekyll/builder:4.1.0 \
  /bin/bash -c "chmod -R 777 . && jekyll serve -s source -d dist -c config.yml --host 0.0.0.0"
```

Site available at <http://localhost:4000>.

## Production build

```bash
docker run --rm \
  -v "$PWD:/app:Z" \
  -w /app \
  jekyll/builder:4.1.0 \
  /bin/bash -c "chmod -R 777 . && jekyll build -s source -d dist -c config.yml"
```

Output lands in `dist/`.

## Structure

```text
source/    Jekyll source (templates, content, assets)
dist/      Build output — served by GitHub Pages
config.yml Jekyll config
```
