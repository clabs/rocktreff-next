# rocktreff.de

Hugo site with PostCSS (autoprefixer + PurgeCSS). Deploys to GitHub Pages on push to `main`.

## Prerequisites

| Tool        | Version         | Notes                                                                          |
| ----------- | --------------- | ------------------------------------------------------------------------------ |
| Hugo        | 0.162.0         | [github.com/gohugoio/hugo/releases](https://github.com/gohugoio/hugo/releases) |
| Node.js     | 24+             | required for PostCSS pipeline                                                  |
| ImageMagick | 7+ with libheif | only needed for image scripts                                                  |

**Install Hugo (macOS):**

```bash
brew install hugo
# or pin the exact version:
brew install hugo@0.162.0
```

**Install Hugo (Linux):**

```bash
wget https://github.com/gohugoio/hugo/releases/download/v0.162.0/hugo_0.162.0_linux-amd64.tar.gz
tar -xzf hugo_0.162.0_linux-amd64.tar.gz
sudo mv hugo /usr/local/bin/
```

## Local dev setup

```bash
npm install          # install PostCSS plugins (autoprefixer, PurgeCSS)
hugo server          # start dev server at http://localhost:1313
```

Hugo watches for changes and reloads automatically. PostCSS runs as part of the Hugo pipeline — `node_modules/` must exist.

## Production build

```bash
hugo --minify        # output to ./public/
```

## Image scripts

Both scripts require ImageMagick. Install with AVIF support:

```bash
# macOS
brew install imagemagick

# Ubuntu/Debian
sudo apt install imagemagick libheif-dev
```

### `scripts/create-webp-avif.sh` — batch convert a folder

Converts all JPEGs and PNGs in a directory to WebP and AVIF. JPEGs use lossy encoding; PNGs with fewer than 256 unique colors use lossless encoding automatically.

```bash
./scripts/create-webp-avif.sh [input_dir] [quality]
```

| Argument    | Default           | Description                     |
| ----------- | ----------------- | ------------------------------- |
| `input_dir` | `.` (current dir) | folder containing source images |
| `quality`   | `80`              | lossy quality 1–100 for photos  |

**Examples:**

```bash
# convert all images in current directory at default quality
./scripts/create-webp-avif.sh

# convert images in static/img/ at quality 85
./scripts/create-webp-avif.sh static/img 85
```

Output files are written next to the originals (`hero.jpg` → `hero.webp`, `hero.avif`).
