# Short North Studio

Static site for short-north-studio.com. No build step: plain HTML, CSS and JS with image frames for the scroll-animated hero.

This branch (`netlify-live-site`) is a copy of what was live on Netlify (project `magical-madeleine-b00948`, deploy of Sep 28 2026), plus:

- a 360 tour section (Matterport embed) after "the details you need"
- an "event packages and pricing" section before "book the room"
- nav, dot-nav and footer links to both

## Layout

- `index.html`: home page (all CSS and JS inline)
- `baby-showers/`, `kids-parties/`, `estimate/`, `event-support/`: sub-pages
- `img/`, `frames/`: images and hero animation frames
- `docs/`: PDF package sheets

## Local preview

```
python3 -m http.server 8000
```

## Deploying

Netlify: connect this repo (publish directory `/`, no build command), or drag the folder onto Netlify Drop.
