// The entrypoint for the **server** environment.
//
// The [main] method will only be executed on the server during pre-rendering.
// To run code on the client, use the @client annotation.

// Server-specific jaspr import.
import 'package:jaspr/server.dart';

import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/components/github_button.dart';
import 'package:jaspr_content/components/header.dart';
import 'package:jaspr_content/components/image.dart';
import 'package:jaspr_content/components/sidebar.dart';
import 'package:jaspr_content/components/theme_toggle.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

void main() async {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // Starts the app.
  //
  // [ContentApp] spins up the content rendering pipeline from jaspr_content to render
  // your markdown files in the content/ directory to a beautiful documentation site.
  runApp(
    ContentApp(
      // Enables mustache templating inside the markdown files.
      templateEngine: MustacheTemplateEngine(),
      parsers: [
        MarkdownParser(),
      ],
      extensions: [
        // Adds heading anchors to each heading.
        HeadingAnchorsExtension(),
        // Generates a table of contents for each page.
        TableOfContentsExtension(),
      ],
      components: [
        // The <Info> block and other callouts.
        Callout(),
        // // Adds syntax highlighting to code blocks.
        CodeBlock(
          defaultLanguage: 'dart',
        ),

        // Adds zooming and caption support to images.
        Image(zoom: true),
      ],
      layouts: [
        // Out-of-the-box layout for documentation sites.
        DocsLayout(
          header: Header(
            title: 'ContainerPub',
            logo: '/images/logo.svg',

            items: [
              // Enables switching between light and dark mode.
              ThemeToggle(),
              // Shows github stats.
              GitHubButton(repo: 'liodali/ContainerPub'),
            ],
          ),
          sidebar: Sidebar(
            groups: [
              // Main navigation
              SidebarGroup(
                links: [
                  SidebarLink(text: "Home", href: '/'),
                  SidebarLink(text: "About", href: '/about'),
                ],
              ),
              // General Documentation
              SidebarGroup(
                title: 'General',
                links: [
                  SidebarLink(text: "Development", href: '/docs/development'),
                  SidebarLink(text: "Roadmap", href: '/docs/roadmap'),
                ],
              ),
              // CLI Documentation
              SidebarGroup(
                title: 'CLI',
                links: [
                  SidebarLink(text: "CLI Overview", href: '/docs/cli'),
                  SidebarLink(text: "dart_cloud CLI", href: '/docs/cli/dart-cloud-cli'),
                  SidebarLink(text: "dart_cloud_function", href: '/docs/cli/dart-cloud-function'),
                  SidebarLink(text: "Analyzer Rules", href: '/docs/cli/analyzer-rules'),
                  SidebarLink(text: "Deployment Config", href: '/docs/cli/deployment-config'),
                ],
              ),
              // Backend Documentation
              SidebarGroup(
                title: 'Backend',
                links: [
                  SidebarLink(text: "Backend Overview", href: '/docs/backend'),
                  SidebarLink(text: "Authentication", href: '/docs/backend/authentication'),
                  SidebarLink(text: "API Keys & Signing", href: '/docs/backend/api-keys'),
                  SidebarLink(text: "Architecture", href: '/docs/backend/architecture'),
                  SidebarLink(text: "Function Execution", href: '/docs/backend/function-execution'),
                  SidebarLink(text: "Python Podman Client", href: '/docs/backend/python-podman-client'),
                  SidebarLink(text: "Statistics & Monitoring", href: '/docs/backend/statistics'),
                  SidebarLink(text: "API Reference", href: '/docs/backend/api-reference'),
                ],
              ),
              // Database & Backup Documentation
              SidebarGroup(
                title: 'Database & Backup',
                links: [
                  SidebarLink(text: "Database Overview", href: '/docs/database'),
                  SidebarLink(text: "Database System", href: '/docs/database/database-system'),
                  SidebarLink(text: "Database Reference", href: '/docs/database/database-quick-reference'),
                  SidebarLink(text: "Implementation History", href: '/docs/database/database-implementation-tracking'),
                  SidebarLink(text: "Backup Strategy", href: '/docs/database/backup-strategy'),
                  SidebarLink(text: "Backup Workflows", href: '/docs/database/backup-workflows'),
                  SidebarLink(text: "Backup Reference", href: '/docs/database/backup-quick-reference'),
                ],
              ),
              // Migration Documentation
              SidebarGroup(
                title: 'Migration',
                links: [
                  SidebarLink(text: "Podman Migration", href: '/docs/podman-migration'),
                ],
              ),
            ],
          ),
        ),
      ],
      theme: ContentTheme(
        // Customizes the default theme colors.
        primary: ThemeColor(
          ThemeColors.blue.$500,
          dark: ThemeColors.blue.$300,
        ),
        background: ThemeColor(
          ThemeColors.slate.$50,
          dark: ThemeColors.zinc.$950,
        ),
        colors: [
          ContentColors.quoteBorders.apply(ThemeColors.blue.$400),
        ],
      ),
    ),
  );
}
