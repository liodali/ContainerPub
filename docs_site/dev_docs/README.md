# ContainerPub Documentation Site

A professional documentation site for ContainerPub built with **Jaspr 0.22.0** and **jaspr_content 0.4.5**.

## Features

- **Markdown-based Content** - Write documentation in markdown with Mustache templating
- **Beautiful UI** - Professional design with light/dark mode toggle
- **Responsive Design** - Works on all devices
- **Organized Navigation** - Sidebar with hierarchical documentation structure
- **Syntax Highlighting** - Code blocks with Dart as default language
- **Table of Contents** - Auto-generated for each page
- **Heading Anchors** - Deep linking to sections
- **Image Zoom** - Click to zoom images with captions
- **Callouts** - Info, warning, and other callout blocks

## Project Structure

```
dev_docs/
├── content/
│   ├── _data/
│   │   ├── site.yaml              # Site configuration
│   │   └── links.yaml             # External links
│   ├── index.md                   # Home page
│   ├── about.md                   # About page
│   └── docs/
│       ├── development.md         # Development guide
│       ├── architecture.md        # Architecture overview
│       ├── podman-migration.md    # Podman migration
│       ├── cli/                   # CLI documentation (3 pages)
│       │   ├── index.md           # CLI overview
│       │   ├── dart-cloud-cli.md  # dart_cloud CLI reference
│       │   └── dart-cloud-function.md
│       ├── backend/               # Backend documentation (4 pages)
│       │   ├── index.md           # Backend overview
│       │   ├── authentication.md  # Auth system docs
│       │   ├── architecture.md    # System architecture
│       │   └── api-reference.md   # API endpoints
│       └── database/              # Database & Backup (7 pages)
│           ├── index.md           # Database overview
│           ├── database-system.md
│           ├── database-quick-reference.md
│           ├── database-implementation-tracking.md
│           ├── backup-strategy.md
│           ├── backup-workflows.md
│           └── backup-quick-reference.md
├── lib/
│   ├── main.server.dart           # Server entry point
│   ├── main.server.options.dart   # Generated Jaspr options
│   └── components/
│       └── clicker.dart           # Example client component
├── web/
│   ├── index.html                 # HTML template
│   └── images/                    # Static images
├── cloudflare_deploy_site/        # Cloudflare Pages deployment
├── deploy.sh                      # Deployment script
├── pubspec.yaml                   # Dependencies
└── README.md                      # This file
```

## Running the Project

### Development Server

```bash
# Install dependencies
dart pub get

# Run development server
jaspr serve
```

The development server will be available at `http://localhost:8080`.

### Building for Production

```bash
# Build static site with optimization
jaspr build --sitemap-exclude -O 3
```

The output will be located in the `build/jaspr/` directory.

### Deploying to Cloudflare Pages

```bash
# Full build and deploy
./deploy.sh

# Skip build (deploy existing build)
./deploy.sh --skip
```

The deploy script:

1. Cleans previous builds
2. Runs `jaspr build` with optimization level 3
3. Copies output to `cloudflare_deploy_site/public/build`
4. Deploys via Wrangler to Cloudflare Pages

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

Edit `lib/main.server.dart` to add new pages to the sidebar:

```dart
SidebarGroup(
  title: 'Section Name',
  links: [
    SidebarLink(text: "Page Title", href: '/docs/section/page-name'),
  ],
),
```

**Current Navigation Structure:**

- **General** - Development guide
- **CLI** - CLI overview, dart_cloud CLI, dart_cloud_function
- **Backend** - Overview, Authentication, Architecture, API Reference
- **Database & Backup** - 7 pages covering database system and backup strategies
- **Migration** - Podman migration guide

### Site Configuration

Edit `content/_data/site.yaml` to customize:

- Site title
- Social media links
- Favicon
- Description

## Customization

### Colors and Theme

Edit `lib/main.server.dart` theme configuration:

```dart
theme: ContentTheme(
  primary: ThemeColor(ThemeColors.blue.$500, dark: ThemeColors.blue.$300),
  background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950),
  colors: [
    ContentColors.quoteBorders.apply(ThemeColors.blue.$400),
  ],
),
```

### Header and Logo

Update `Header` component in `lib/main.server.dart`:

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

### Custom Components

Client-side components use the `@client` annotation. Example in `lib/components/clicker.dart`:

```dart
@client
class Clicker extends StatefulComponent {
  // Interactive component that runs on the client
}
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

````markdown
```dart
void main() {
  print('Hello');
}
```
````

````

### Links
```markdown
[Link text](https://example.com)
[Internal link](/docs/page)
````

### Blockquotes

```markdown
> This is a quote
> It can span multiple lines
```

### Tables

```markdown
| Column 1 | Column 2 |
| -------- | -------- |
| Cell 1   | Cell 2   |
```

## Deployment

### Cloudflare Pages (Primary)

The project is configured for Cloudflare Pages deployment:

```bash
./deploy.sh
```

### Other Static Hosting

```bash
# Build the site
jaspr build --sitemap-exclude -O 3

# Deploy build/jaspr/ to your hosting service
# (Netlify, Vercel, GitHub Pages, etc.)
```

## Dependencies

| Package       | Version | Purpose                     |
| ------------- | ------- | --------------------------- |
| jaspr         | ^0.22.0 | Web framework               |
| jaspr_content | ^0.4.5  | Content rendering & layouts |
| jaspr_router  | ^0.8.1  | Client-side routing         |

### Dev Dependencies

- **build_runner** - Build system
- **jaspr_builder** - Jaspr code generation
- **jaspr_lints** - Linting rules

## Content Extensions

Configured in `lib/main.server.dart`:

- **HeadingAnchorsExtension** - Adds anchor links to headings
- **TableOfContentsExtension** - Auto-generates TOC
- **MustacheTemplateEngine** - Enables `{{variable}}` templating
- **CodeBlock** - Syntax highlighting (default: Dart)
- **Image** - Zoom support with captions
- **Callout** - Info/warning blocks

## Documentation Stats

| Section           | Pages  | Description                                           |
| ----------------- | ------ | ----------------------------------------------------- |
| General           | 3      | Development, architecture, roadmap                    |
| CLI               | 5      | CLI tools, analyzer rules, deployment config          |
| Backend           | 5      | Authentication, architecture, function execution, API |
| Database & Backup | 7      | Database system and backup strategies                 |
| Migration         | 1      | Podman migration guide                                |
| **Total**         | **21** | Complete documentation coverage                       |

## Resources

- [Jaspr Documentation](https://jaspr.dev)
- [jaspr_content Documentation](https://docs.jaspr.site/content)
- [Markdown Guide](https://www.markdownguide.org/)

## License

Same as ContainerPub project
