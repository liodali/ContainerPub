import 'package:auto_route/auto_route.dart';
import 'package:cloud_panel/providers/auth_provider.dart';
import 'package:cloud_panel/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

@RoutePage()
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoTabsRouter(
      routes: const [
        OverviewRoute(),
        FunctionsRoute(),
        ContainersRoute(),
        WebhooksRoute(),
        SettingsRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return FScaffold(
          sidebar: SideBarDashboard(tabsRouter: tabsRouter),
          child: child,
        );
      },
    );
  }
}

class SideBarDashboard extends StatelessWidget {
  const SideBarDashboard({
    super.key,
    required this.tabsRouter,
  });

  final TabsRouter tabsRouter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: context.theme.colors.border,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Logo Area
            HeaderSideBar(),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard,
                    label: 'Overview',
                    isSelected: tabsRouter.activeIndex == 0,
                    onTap: () => tabsRouter.setActiveIndex(0),
                  ),
                  const SizedBox(height: 8),
                  _SidebarItem(
                    icon: Icons.functions,
                    label: 'Functions',
                    isSelected: tabsRouter.activeIndex == 1,
                    onTap: () => tabsRouter.setActiveIndex(1),
                  ),
                  const SizedBox(height: 8),
                  _SidebarItem(
                    icon: Icons.layers,
                    label: 'Containers',
                    isSelected: tabsRouter.activeIndex == 2,
                    onTap: () => tabsRouter.setActiveIndex(2),
                  ),
                  const SizedBox(height: 8),
                  _SidebarItem(
                    icon: Icons.webhook,
                    label: 'Webhooks',
                    isSelected: tabsRouter.activeIndex == 3,
                    onTap: () => tabsRouter.setActiveIndex(3),
                  ),
                  const SizedBox(height: 8),
                  _SidebarItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    isSelected: tabsRouter.activeIndex == 4,
                    onTap: () => tabsRouter.setActiveIndex(4),
                  ),
                ],
              ),
            ),
            // User / Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, _) {
                  return FButton(
                    style: FButtonStyle.ghost(),
                    onPress: () {
                      ref.read(authProvider.notifier).logout();
                      // Router will handle redirect via AuthGuard or simple check in main.dart
                      // But since we use manual router, main.dart checks authState.
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderSideBar extends StatelessWidget {
  const HeaderSideBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ).copyWith(top: 24, bottom: 32),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.theme.colors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'CP',
                style: TextStyle(
                  color: context.theme.colors.primaryForeground,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'ContainerPub',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onTap,
      child: FTile(
        style: (style) => style.copyWith(
          backgroundColor: FWidgetStateMap.all(
            isSelected
                ? context.theme.colors.primary
                : context.theme.colors.background,
          ),
          decoration: FWidgetStateMap.all(
            BoxDecoration(
              border: Border.all(
                width: 0,
                color: context.theme.colors.background,
              ),
            ),
          ),
        ), //isSelected ? FButtonStyle.primary() : FButtonStyle.ghost(),
        title: Text(
          label,
          style: context.theme.typography.base.copyWith(
            color: isSelected
                ? context.theme.colors.primaryForeground
                : context.theme.colors.secondaryForeground,
          ),
        ),
        prefix: Icon(
          icon,
          size: 18,
          color: isSelected
              ? context.theme.colors.primaryForeground
              : context.theme.colors.secondaryForeground,
        ),
      ),
    );
  }
}
