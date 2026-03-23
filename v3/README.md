# Library of Morenita

A digital archive, curriculum curator, and study space for artists, thinkers, and makers rooted in culture.

## Pages

| File | Description |
|------|-------------|
| `index.html` | Main archive, My Issues, Portfolio — the home hub |
| `idea-web.html` | D3.js force-directed idea constellation |
| `academy.html` | Learning tracks + ambient study space with WebAudio |
| `builder.html` | Magazine builder / issue creator |

## Getting Started in VS Code

1. Open this folder in VS Code: `File → Open Folder`
2. Install recommended extensions when prompted (Live Server, Prettier)
3. Right-click `index.html` → **Open with Live Server**
4. Navigate between pages using the top nav

## Navigation Map

```
index.html  ──┬──→  idea-web.html
              ├──→  academy.html
              ├──→  builder.html
              └──→  index.html#collections (My Issues)
                    index.html#profile (Portfolio)
```

## Shared Design System

All pages share:
- **CSS variables** defined in `:root` — edit colors in one place
- **Grid-aware energy banner** — adapts imagery/animations to grid load
- **Typography**: Cormorant Garamond (display) · EB Garamond (body) · Figtree (UI)
- **Color palette**: Cream · Sienna · Sage · Gold · Ink

## Adding Articles to the Idea Web

In `idea-web.html`, find the `ARTICLES` array and add:
```js
{
  id: 'a15',
  type: 'article',
  title: 'Your article title',
  excerpt: 'One sentence description.',
  tags: ['philosophy', 'africa', 'resistance'],  // use taxonomy tags
  readTime: '10 min'
}
```

## Tag Taxonomy

`philosophy` · `africa` · `diaspora` · `fashion-history` · `textiles` · `herbalism` · `beauty-ritual` · `art-history` · `music` · `literature` · `architecture` · `spirituality` · `science` · `resistance` · `feminism` · `nature`

## Roadmap

- [ ] Article writing interface (write directly in-app)
- [ ] Persistent save state (localStorage / backend)
- [ ] Mobile responsive nav
- [ ] Print-ready PDF export from builder
- [ ] Real drag-and-drop in magazine builder
- [ ] User auth + profile backend
