# ContainerPub Documentation Site

A professional documentation site for ContainerPub built with **Jaspr** and **jaspr_content**.

## Features

- 📚 **Markdown-based Content** - Write documentation in markdown
- 🎨 **Beautiful UI** - Professional design with light/dark mode
- 🔍 **Full-text Search** - Find documentation quickly
- 📱 **Responsive Design** - Works on all devices
- 🎯 **Organized Navigation** - Sidebar with documentation structure
- 💻 **Syntax Highlighting** - Code blocks with syntax highlighting
- 📖 **Table of Contents** - Auto-generated for each page

## Project Structure

```
dev_docs/
├── content/
│   ├── _data/
│   │   ├── site.yaml          # Site configuration
│   │   └── links.yaml         # External links
│   ├── index.md               # Home page
│   ├── about.md               # About page
│   └── docs/
│       ├── development.md     # Development guide
│       ├── architecture.md    # Architecture overview
│       ├── podman-migration.md # Podman migration
│       └── api-reference.md   # API reference
├── lib/
│   ├── main.dart              # Application entry point
│   ├── jaspr_options.dart     # Jaspr configuration
│   └── components/            # Custom components
├── web/
│   ├── index.html             # HTML template
│   └── images/                # Static images
├── pubspec.yaml               # Dependencies
└── README.md                  # This file
```

## Running the Project

### Development Server

```bash
# Install dependencies
dart pub get

# Run development server
jaspr serve
```

The development server will be available on `http://localhost:8080`.

### Building for Production

```bash
# Build static site
jaspr build
```

The output will be located in the `build/jaspr/` directory.

## Content Organization

### Adding Documentation

1. Create a markdown file in `content/docs/`
2. Add frontmatter with title and description:
   ```yaml
   ---
   title: Page Title
   description: Page description
   ---
   ```
3. Write markdown content
4. The page will automatically appear in navigation

### Updating Navigation

Edit `lib/main.dart` to add new pages to the sidebar:

```dart
SidebarGroup(title: 'Documentation', links: [
  SidebarLink(text: "Page Title", href: '/docs/page-name'),
]),
```

### Site Configuration

Edit `content/_data/site.yaml` to customize:
- Site title
- Social media links
- Favicon
- Description

## Customization

### Colors and Theme

Edit `lib/main.dart` theme configuration:

```dart
theme: ContentTheme(
  primary: ThemeColor(ThemeColors.blue.$500, dark: ThemeColors.blue.$300),
  background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950),
),
```

### Header and Logo

Update `Header` component in `lib/main.dart`:

```dart
Header(
  title: 'ContainerPub',
  logo: '/images/logo.svg',
  items: [
    ThemeToggle(),
    GitHubButton(repo: 'liodali/ContainerPub'),
  ],
),
```

## Markdown Features

### Headings
```markdown
# H1
## H2
### H3
```

### Lists
```markdown
- Item 1
- Item 2
  - Nested item

1. First
2. Second
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
[Internal link](/docs/page)
```

### Blockquotes
```markdown
> This is a quote
> It can span multiple lines
```

### Tables
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Cell 1   | Cell 2   |
```

## Deployment

### Static Hosting

```bash
# Build the site
jaspr build

# Deploy build/jaspr/ to your hosting service
# (Netlify, Vercel, GitHub Pages, etc.)
```

### Docker

```dockerfile
FROM dart:stable
WORKDIR /app
COPY . .
RUN dart pub get
RUN jaspr build
EXPOSE 8080
CMD ["dart", "run", "bin/server.dart"]
```

## Dependencies

- **jaspr** - Web framework
- **jaspr_content** - Content rendering
- **jaspr_router** - Client-side routing

## Resources

- [Jaspr Documentation](https://jaspr.dev)
- [jaspr_content Documentation](https://docs.jaspr.site/content)
- [Markdown Guide](https://www.markdownguide.org/)

## License

Same as ContainerPub project
