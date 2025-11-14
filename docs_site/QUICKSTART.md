# Jaspr Documentation Site - Quick Start

Get the ContainerPub documentation site up and running in minutes.

## 🚀 Quick Start

### 1. Navigate to the project
```bash
cd docs_site/dev_docs
```

### 2. Install dependencies
```bash
dart pub get
```

### 3. Run development server
```bash
jaspr serve
```

Visit `http://localhost:8080`

## 📚 Documentation Structure

```
content/
├── index.md                    # Home page
├── about.md                    # About page
└── docs/
    ├── development.md          # Development guide
    ├── architecture.md         # Architecture overview
    ├── podman-migration.md     # Podman migration
    └── api-reference.md        # API reference
```

## ✏️ Adding New Pages

### 1. Create markdown file
```bash
touch content/docs/my-page.md
```

### 2. Add frontmatter
```yaml
---
title: My Page Title
description: Page description
---

# My Page Title

Content here...
```

### 3. Update navigation
Edit `lib/main.dart`:
```dart
SidebarLink(text: "My Page", href: '/docs/my-page'),
```

## 🎨 Customization

### Change Site Title
Edit `content/_data/site.yaml`:
```yaml
titleBase: My Site Title
```

### Change Colors
Edit `lib/main.dart`:
```dart
primary: ThemeColor(ThemeColors.blue.$500, dark: ThemeColors.blue.$300),
```

### Update GitHub Link
Edit `lib/main.dart`:
```dart
GitHubButton(repo: 'your-org/your-repo'),
```

## 🏗️ Building for Production

```bash
jaspr build
```

Output: `build/jaspr/`

## 📖 Markdown Features

### Headings
```markdown
# H1
## H2
### H3
```

### Code Blocks
```markdown
```dart
void main() {
  print('Hello');
}
```
```

### Links
```markdown
[Link text](https://example.com)
[Internal](/docs/page)
```

### Lists
```markdown
- Item 1
- Item 2
  - Nested

1. First
2. Second
```

### Tables
```markdown
| Col 1 | Col 2 |
|-------|-------|
| Cell  | Cell  |
```

## 🔗 Important Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Site configuration |
| `content/_data/site.yaml` | Site metadata |
| `content/index.md` | Home page |
| `content/docs/*.md` | Documentation pages |

## 🚀 Deployment

### Netlify
```bash
jaspr build
# Deploy build/jaspr/ to Netlify
```

### Vercel
```bash
jaspr build
# Deploy build/jaspr/ to Vercel
```

### GitHub Pages
```bash
jaspr build
# Deploy build/jaspr/ to gh-pages branch
```

## 📚 Documentation Pages

1. **Home** (`/`) - Welcome and overview
2. **About** (`/about`) - Project information
3. **Development** (`/docs/development`) - Getting started
4. **Architecture** (`/docs/architecture`) - System design
5. **Podman** (`/docs/podman-migration`) - Container runtime
6. **API** (`/docs/api-reference`) - API documentation

## 🆘 Troubleshooting

### Port already in use
```bash
jaspr serve --port 8081
```

### Build fails
```bash
dart pub get
dart pub upgrade
jaspr build
```

### Changes not showing
1. Stop development server
2. Run `dart pub get`
3. Run `jaspr serve` again

## 📝 Next Steps

1. ✅ Run `jaspr serve`
2. ✅ View the site at `http://localhost:8080`
3. ✅ Add your documentation
4. ✅ Customize colors and title
5. ✅ Deploy to production

## 🔗 Resources

- [Jaspr Docs](https://jaspr.dev)
- [jaspr_content Docs](https://docs.jaspr.site/content)
- [Markdown Guide](https://www.markdownguide.org/)

---

**Ready to go!** 🎉
