import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/home_motion.dart';
import 'widgets/retro_dashboard.dart';

const _blue = Color(0xFF3E5D9C);
const _footerColor = Color(0xB1FFFFFF);

class ClassicHomeView extends ConsumerWidget {
  final ValueChanged<PageLabel>? onOpenPage;
  final bool originalLayout;

  const ClassicHomeView({
    super.key,
    this.onOpenPage,
    this.originalLayout = true,
  });

  void _openPage(BuildContext context, WidgetRef ref, PageLabel page) {
    if (onOpenPage != null) {
      onOpenPage!(page);
      return;
    }
    ref.read(currentPageLabelProvider.notifier).toPage(page);
    Navigator.of(context).pop();
  }

  Future<void> _openWebsite(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$url')));
  }

  void _showPurchaseInfo(BuildContext context) {
    final strings = context.appLocalizations;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.classicPermanent),
        content: Text(strings.classicPurchaseInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.appLocalizations;
    final running = ref.watch(isStartProvider);
    final profile = ref.watch(currentProfileProvider);
    final groups = ref.watch(currentGroupsStateProvider).value;
    final mode = ref.watch(
      patchClashConfigProvider.select((value) => value.mode),
    );
    final groupName = mode == Mode.global
        ? GroupName.GLOBAL.name
        : profile?.currentGroupName;
    final selected = groupName == null
        ? null
        : ref.watch(selectedProxyNameProvider(groupName));
    final line = profile == null
        ? strings.nullProfileDesc
        : mode == Mode.direct
        ? strings.direct
        : mode == Mode.rule
        ? strings.classicRulesLine
        : selected ?? strings.classicNoLine;
    final proxyPage = profile == null || groups.isEmpty
        ? PageLabel.profiles
        : PageLabel.proxies;

    final lineControl = LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
        final stacked = constraints.maxWidth < 360 || largeText;
        final change = TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(64, 48),
          ),
          onPressed: () => _openPage(context, ref, proxyPage),
          child: Text(strings.classicChange),
        );
        return Padding(
          key: const ValueKey('classic-line'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.public, color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: Text(
                        '${strings.classicLine}$line',
                        key: ValueKey(line),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (!stacked) change,
                ],
              ),
              if (stacked)
                Align(alignment: Alignment.centerRight, child: change),
            ],
          ),
        );
      },
    );

    return HomeMotion(
      running: running,
      child: Scaffold(
        backgroundColor: _blue,
        appBar: AppBar(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('VPN'),
          actions: [
            if (!originalLayout)
              IconButton(
                tooltip: strings.classicHome,
                icon: const Icon(Icons.home_outlined),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (classicContext) => ClassicHomeView(
                      onOpenPage: (page) {
                        Navigator.of(classicContext).pop();
                        _openPage(context, ref, page);
                      },
                    ),
                  ),
                ),
              ),
            PopupMenuButton<Mode>(
              tooltip: strings.outboundMode,
              initialValue: mode,
              icon: const Icon(Icons.settings_outlined),
              onSelected: (value) =>
                  ref.read(setupActionProvider.notifier).changeMode(value),
              itemBuilder: (_) => [
                for (final item in Mode.values)
                  CheckedPopupMenuItem(
                    value: item,
                    checked: item == mode,
                    child: Text(switch (item) {
                      Mode.rule => strings.rule,
                      Mode.global => strings.global,
                      Mode.direct => strings.direct,
                    }),
                  ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          width: math.min(300, MediaQuery.sizeOf(context).width * .85),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 90,
                  color: _blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    originalLayout ? strings.classicHome : 'VPN',
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
                for (final item in [
                  (
                    Icons.dashboard_outlined,
                    strings.dashboard,
                    PageLabel.dashboard,
                  ),
                  (Icons.folder_open, strings.profiles, PageLabel.profiles),
                  if (groups.isNotEmpty)
                    (Icons.public, strings.proxies, PageLabel.proxies),
                  (Icons.link, strings.connections, PageLabel.connections),
                  (Icons.build_outlined, strings.tools, PageLabel.tools),
                ])
                  ListTile(
                    leading: Icon(item.$1),
                    title: Text(item.$2),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openPage(context, ref, item.$3);
                    },
                  ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!originalLayout) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1120,
                        minHeight: constraints.maxHeight,
                      ),
                      child: RetroDashboardPanel(
                        provideMotion: false,
                        onOpenPage: (page) => _openPage(context, ref, page),
                      ),
                    ),
                  ),
                );
              }
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
              final split =
                  constraints.maxWidth >= 700 ||
                  (landscape && constraints.maxWidth >= 560);
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final buttonSize = tablet
                  ? 240.0
                  : landscape
                  ? 160.0
                  : 200.0;
              final button = HomeEntrance(
                child: HomeConnectButton(
                  key: const ValueKey('classic-connect'),
                  size: buttonSize,
                  running: running,
                  onPressed: () {
                    if (!running && profile == null) {
                      _openPage(context, ref, PageLabel.profiles);
                      return;
                    }
                    ref.read(commonActionProvider.notifier).toggleRunning();
                  },
                ),
              );
              return SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: math.min(constraints.maxWidth, 1120),
                    height: math.max(
                      constraints.maxHeight,
                      (split ? (tablet ? 500 : 340) : 520) +
                          math.max(0, textScale - 1) * 170,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: split
                              ? Row(
                                  key: ValueKey(
                                    landscape
                                        ? 'classic-landscape'
                                        : 'classic-tablet',
                                  ),
                                  children: [
                                    Expanded(child: Center(child: button)),
                                    Expanded(
                                      child: HomeEntrance(
                                        start: .15,
                                        child: lineControl,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('classic-portrait'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    button,
                                    HomeEntrance(
                                      start: .15,
                                      child: lineControl,
                                    ),
                                  ],
                                ),
                        ),
                        SizedBox(
                          height: landscape ? 24 : 60,
                          width: double.infinity,
                          child: const HomeWave(color: _footerColor),
                        ),
                        Material(
                          color: _footerColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _ClassicLink(
                                  spacious: tablet,
                                  label: strings.classicGoogle,
                                  asset: 'main_bottom_google.png',
                                  onTap: () => _openWebsite(
                                    context,
                                    Uri.https('www.google.com'),
                                  ),
                                ),
                                _ClassicLink(
                                  spacious: tablet,
                                  label: strings.classicYoutube,
                                  asset: 'youtube.png',
                                  badge: 'jingxi.png',
                                  onTap: () => _openWebsite(
                                    context,
                                    Uri.https('www.youtube.com'),
                                  ),
                                ),
                                _ClassicLink(
                                  spacious: tablet,
                                  label: strings.classicPermanent,
                                  asset: 'shoping.png',
                                  badge: 'tehui.png',
                                  onTap: () => _showPurchaseInfo(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ClassicLink extends StatelessWidget {
  final bool spacious;
  final String label;
  final String asset;
  final String? badge;
  final VoidCallback onTap;

  const _ClassicLink({
    this.spacious = false,
    required this.label,
    required this.asset,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: HomePress(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: spacious ? 76 : 58,
                height: spacious ? 70 : 54,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/retro/$asset',
                        excludeFromSemantics: true,
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Image.asset(
                          'assets/images/retro/$badge',
                          width: 30,
                          excludeFromSemantics: true,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: spacious ? 14 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
