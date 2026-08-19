# Short North Studio Homepage

Static homepage for Short North Studio — no build step, no framework. Three files (`index.html`, `styles.css`, `script.js`) plus `assets/`.

## Deploying with Cloudflare Pages

The live site (short-north-studio.xyz) currently resolves through Cloudflare, so Cloudflare Pages is the simplest path to get this repo live under the same domain.

1. In the [Cloudflare dashboard](https://dash.cloudflare.com/), go to **Workers & Pages → Create → Pages → Connect to Git**.
2. Select this repository (`info-beep/short-north-studio`).
3. Build settings: framework preset **None**, build command **(empty)**, build output directory **`/`**.
4. Click **Save and Deploy**. Cloudflare gives you a temporary URL like `short-north-studio.pages.dev` — confirm the site looks right there first.
5. Go to the new Pages project's **Custom domains** tab and add `short-north-studio.xyz` (and `www` if you use it).
6. Cloudflare will show you the DNS record it needs (usually a `CNAME` to `short-north-studio.pages.dev`). Add that record wherever short-north-studio.xyz's DNS is currently managed (check your registrar/DNS panel — as of this write-up that's Porkbun).
7. Once DNS propagates and Cloudflare issues a certificate, the new site replaces whatever is currently live at the domain.

No environment variables or secrets are needed — everything is static.

## Local preview

```
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

## Structure

- `index.html` — full homepage markup
- `styles.css` — all styling (design tokens at the top of the file)
- `script.js` — hero letter-split animation, ambient particles, scroll parallax, sticky header state
- `assets/hero.mp4` — looping hero background video
- `assets/logo-light.svg`, `assets/logo-dark.svg` — wordmark, cream and ink variants for use over dark/light backgrounds

## Notes

- The old GitHub Pages deployment (CNAME-based) has been removed from this repo — the domain moved to a different host since this repo was last active, so Cloudflare Pages (above) is the current recommended path.
- The three "How booking works" steps previously had duplicated placeholder copy on the live site; this version has distinct copy for each step.
