# rocktreff.de

Hugo site with PostCSS (autoprefixer + PurgeCSS). Deploys to GitHub Pages on push to `main`.

## Prerequisites

| Tool        | Version         | Notes                                                                          |
| ----------- | --------------- | ------------------------------------------------------------------------------ |
| Hugo        | 0.162.0         | [github.com/gohugoio/hugo/releases](https://github.com/gohugoio/hugo/releases) |
| Node.js     | 24+             | required for PostCSS pipeline                                                  |

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

## Images

Commit only the original JPG/PNG to `assets/`. Hugo generates WebP variants
(and downscaled sizes) at build time — no local image tools needed.

- **JPG** → lossy WebP. **PNG** → lossless WebP (lossy if much smaller).
  The WebP is only served if it is smaller than the original.
- Generated files are cached in `resources/_gen/` (gitignored). The first build
  after a fresh clone takes a bit longer; later builds reuse the cache. CI caches it too.

**In templates**, render an image from `assets/` with:

```go-html-template
{{ partial "img/picture.html" (dict "src" "sponsors/foo.png" "alt" "Foo Logo") }}

{{/* fluid-width images (CSS width: 100%): responsive srcset */}}
{{ partial "img/picture.html" (dict
    "src" "crew/crew2025.jpg"
    "widths" (slice 480 800 1200 1600 2000)
    "sizes" "(min-width: 768px) 50vw, 100vw") }}
```

Without `widths`, the image is capped at 1200px (`"width"` overrides it).
Only use `widths` when CSS sets the rendered width, as srcset `w` descriptors
change the intrinsic size of `width: auto` images.

**In CSS**, every image in `assets/images/` is published at its own path, with a
generated `.webp` next to it if that is smaller (`images/landing_0.jpg` →
`/images/landing_0.webp`). Reference both in plain CSS:

```css
.foo {
  background-image: image-set(
    url('../images/landing_0.webp') type('image/webp'),
    url('../images/landing_0.jpg') type('image/jpeg')
  );
}
```

Some photos are already so compressed that WebP is not smaller (`bg.jpg`,
`bg_light.jpg`, `landing_2.jpg`, `landing_3.jpg`); no `.webp` is generated for
them, so reference the original only.
