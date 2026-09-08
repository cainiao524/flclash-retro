import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_motion.dart';

const retroBlue = Color(0xFF3E5D9C);
const _orange = Color(0xFFFF7901);

class RetroDashboardPanel extends ConsumerWidget {
  final ValueChanged<PageLabel>? onOpenPage;
  final bool provideMotion;

  const RetroDashboardPanel({
    super.key,
    this.onOpenPage,
    this.provideMotion = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.appLocalizations;
    final running = ref.watch(isStartProvider);
    final profile = ref.watch(currentProfileProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final groupName = mode == Mode.global
        ? GroupName.GLOBAL.name
        : profile?.currentGroupName;
    final selected = groupName == null
        ? null
        : ref.watch(selectedProxyNameProvider(groupName));
    final hasGroups = ref.watch(currentGroupsStateProvider).value.isNotEmpty;
    void toPage(PageLabel page) {
      final target =
          page == PageLabel.proxies && (!hasGroups || profile == null)
          ? PageLabel.profiles
          : page;
      if (onOpenPage != null) {
        onOpenPage!(target);
      } else {
        ref.read(currentPageLabelProvider.notifier).toPage(target);
      }
    }

    final content = Material(
      color: retroBlue,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.sizeOf(context);
          final tablet = size.shortestSide >= 600;
          final landscape = size.width > size.height;
          final split =
              constraints.maxWidth >= 650 ||
              (landscape && constraints.maxWidth >= 520);
          final button = HomeEntrance(
            child: HomeConnectButton(
              size: tablet
                  ? 240
                  : landscape
                  ? 160
                  : 200,
              running: running,
              onPressed: () {
                if (!running && profile == null) {
                  toPage(PageLabel.profiles);
                  return;
                }
                ref.read(commonActionProvider.notifier).toggleRunning();
              },
            ),
          );
          final controls = HomeEntrance(
            start: .15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => toPage(PageLabel.proxies),
                    icon: const Icon(Icons.public),
                    label: Text(
                      '${strings.proxies} · ${profile == null
                          ? strings.classicNoLine
                          : mode == Mode.direct
                          ? strings.direct
                          : mode == Mode.rule
                          ? strings.classicRulesLine
                          : selected ?? strings.classicNoLine}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  onPressed: () => toPage(PageLabel.profiles),
                  child: Text(
                    '${strings.profiles} · ${profile?.label ?? strings.nullProfileDesc}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final item in Mode.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: mode == item
                                    ? retroBlue
                                    : Colors.white,
                                backgroundColor: mode == item
                                    ? Colors.white
                                    : Colors.white12,
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: () => ref
                                  .read(setupActionProvider.notifier)
                                  .changeMode(item),
                              child: Text(switch (item) {
                                Mode.rule => strings.rule,
                                Mode.global => strings.global,
                                Mode.direct => strings.direct,
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: split
                    ? Row(
                        key: const ValueKey('retro-functional-wide'),
                        children: [
                          Expanded(child: Center(child: button)),
                          Expanded(child: controls),
                        ],
                      )
                    : Column(
                        key: const ValueKey('retro-functional-phone'),
                        children: [
                          button,
                          const SizedBox(height: 24),
                          controls,
                        ],
                      ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: HomeWave(color: Color(0xFFEDF1F8)),
                  ),
                  Container(
                    color: const Color(0xFFEDF1F8),
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: Row(
                      children: [
                        for (final link in [
                          (Icons.public, strings.proxies, PageLabel.proxies),
                          (
                            Icons.folder_open,
                            strings.profiles,
                            PageLabel.profiles,
                          ),
                          (
                            Icons.build_outlined,
                            strings.tools,
                            PageLabel.tools,
                          ),
                        ])
                          Expanded(
                            child: HomePress(
                              onTap: () => toPage(link.$3),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _orange,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        link.$1,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      link.$2,
                                      style: const TextStyle(color: retroBlue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return provideMotion
        ? HomeMotion(running: running, child: content)
        : content;
  }
}
