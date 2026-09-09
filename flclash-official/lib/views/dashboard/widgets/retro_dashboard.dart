import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_motion.dart';
import 'retro_connection.dart';
import 'retro_line_control.dart';
import 'retro_routes.dart';

const retroBlue = Color(0xFF3E5D9C);
const retroFooter = Color(0xB1FFFFFF);
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
    void toPage(PageLabel page) {
      final hasProfile = ref.read(currentProfileProvider) != null;
      if (page == PageLabel.proxies &&
          hasProfile &&
          ref.read(patchClashConfigProvider).mode == Mode.direct) {
        showRetroRoutes(context, ref, toPage);
        return;
      }
      final hasGroups = ref.read(currentGroupsStateProvider).value.isNotEmpty;
      final target = page == PageLabel.proxies && (!hasGroups || !hasProfile)
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
            child: RetroConnectionControl(
              size: tablet
                  ? 240
                  : landscape
                  ? 160
                  : 200,
              onOpenProfiles: () => toPage(PageLabel.profiles),
            ),
          );
          final controls = HomeEntrance(
            start: .15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RetroLineControl(
                    onChange: () => showRetroRoutes(context, ref, toPage),
                    line: profile == null
                        ? strings.classicNoLine
                        : mode == Mode.direct
                        ? strings.direct
                        : mode == Mode.rule
                        ? '${strings.classicRulesLine}${selected?.isNotEmpty == true ? ' · $selected' : ''}'
                        : selected ?? strings.classicNoLine,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
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
                                    ? _orange
                                    : Colors.white,
                                backgroundColor: mode == item
                                    ? Colors.white
                                    : Colors.transparent,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                side: BorderSide(
                                  color: mode == item
                                      ? _orange
                                      : Colors.white38,
                                ),
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
                padding: EdgeInsets.only(
                  top: tablet
                      ? math.max(48, (constraints.minHeight - 460) / 2)
                      : landscape
                      ? 12
                      : 48,
                  bottom: landscape ? 12 : 24,
                ),
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
                          const SizedBox(height: 32),
                          controls,
                        ],
                      ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: landscape ? 24 : 60,
                    width: double.infinity,
                    child: const HomeWave(color: retroFooter),
                  ),
                  Container(
                    color: retroFooter,
                    padding: EdgeInsets.only(
                      bottom: landscape ? 8 : 16,
                      top: 8,
                    ),
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
                                padding: EdgeInsets.all(
                                  landscape && !tablet ? 4 : 8,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        landscape && !tablet ? 8 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _orange,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        link.$1,
                                        color: Colors.white,
                                        size: tablet
                                            ? 36
                                            : landscape
                                            ? 24
                                            : 32,
                                      ),
                                    ),
                                    SizedBox(height: landscape ? 6 : 8),
                                    Text(
                                      link.$2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF3C3C3C),
                                        fontSize: 14,
                                      ),
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
