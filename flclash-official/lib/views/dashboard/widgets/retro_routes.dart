import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showRetroRoutes(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<PageLabel> onOpenPage,
) async {
  if (ref.read(currentProfileProvider) == null) {
    onOpenPage(PageLabel.profiles);
    return;
  }
  if (ref.read(patchClashConfigProvider).mode == Mode.direct) {
    final strings = context.appLocalizations;
    final mode = await showDialog<Mode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.direct),
        content: Text(strings.retroDirectHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, Mode.rule),
            child: Text(strings.rule),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, Mode.global),
            child: Text(strings.global),
          ),
        ],
      ),
    );
    if (!context.mounted || mode == null) return;
    ref.read(setupActionProvider.notifier).changeMode(mode);
  }
  if (ref.read(currentGroupsStateProvider).value.isEmpty) {
    onOpenPage(PageLabel.proxies);
    return;
  }
  final advanced = await showDialog<bool>(
    context: context,
    builder: (_) => const RetroRoutesDialog(),
  );
  if (context.mounted && advanced == true) onOpenPage(PageLabel.proxies);
}

class RetroRoutesDialog extends ConsumerStatefulWidget {
  const RetroRoutesDialog({super.key});

  @override
  ConsumerState<RetroRoutesDialog> createState() => _RetroRoutesDialogState();
}

class _RetroRoutesDialogState extends ConsumerState<RetroRoutesDialog> {
  String? _group;
  bool _selecting = false;
  Object? _error;

  Future<void> _select(String group, String proxy) async {
    if (_selecting) return;
    final profileId = ref.read(currentProfileProvider)?.id;
    setState(() {
      _selecting = true;
      _error = null;
    });
    try {
      await ref
          .read(proxiesActionProvider.notifier)
          .changeProxy(groupName: group, proxyName: proxy);
      if (!mounted || ref.read(currentProfileProvider)?.id != profileId) return;
      ref
          .read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(group, proxy);
      ref.read(proxiesActionProvider.notifier).updateGroupsDebounce();
      Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.appLocalizations;
    final groups = ref.watch(currentGroupsStateProvider).value;
    final profile = ref.watch(currentProfileProvider);
    final preferred = _group ?? profile?.currentGroupName;
    final group =
        groups.where((item) => item.name == preferred).firstOrNull ??
        groups.firstOrNull;
    final selected = group == null
        ? null
        : ref.watch(selectedProxyNameProvider(group.name));
    final canSelect = group?.type == GroupType.Selector;
    const orange = Color(0xFFFF7901);
    return Dialog(
      backgroundColor: const Color(0xFFF1F9FF),
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: SizedBox(
        width: 560,
        height: math.min(560, MediaQuery.sizeOf(context).height - 48),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.retroChooseRoute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF3C3C3C),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.cancel,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (group != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: group.name,
                  isExpanded: true,
                  items: [
                    for (final item in groups)
                      DropdownMenuItem(
                        value: item.name,
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _selecting
                      ? null
                      : (value) => setState(() {
                          _group = value;
                          _error = null;
                        }),
                ),
              ),
            if (_selecting) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _error != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        '${strings.retroRequestFailed}\n$_error',
                      ),
                    )
                  : group == null || group.all.isEmpty
                  ? Center(child: Text(strings.noData))
                  : ListView.separated(
                      itemCount: group.all.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFDDE3E8)),
                      itemBuilder: (context, index) {
                        final proxy = group.all[index];
                        final delay = ref.watch(
                          delayProvider(
                            proxyName: proxy.name,
                            testUrl: group.testUrl,
                          ),
                        );
                        final chosen = selected == proxy.name;
                        return Semantics(
                          selected: chosen,
                          child: ListTile(
                            enabled: canSelect && !_selecting,
                            selected: chosen,
                            selectedTileColor: const Color(0x1AFF7901),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFF7901),
                              foregroundColor: Colors.white,
                              child: Icon(Icons.public),
                            ),
                            title: Text(
                              proxy.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF3C3C3C)),
                            ),
                            subtitle: Text(
                              canSelect
                                  ? '${strings.delay} · ${delay == null
                                        ? '—'
                                        : delay < 0
                                        ? strings.timeout
                                        : delay == 0
                                        ? '…'
                                        : '${delay}ms'}'
                                  : strings.retroAutomaticGroup,
                              style: TextStyle(
                                color: delay != null && delay < 0
                                    ? const Color(0xFFA83232)
                                    : const Color(0xFF5B6470),
                              ),
                            ),
                            trailing: Icon(
                              chosen
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: chosen ? orange : Colors.grey,
                            ),
                            onTap: canSelect && !_selecting
                                ? () => _select(group.name, proxy.name)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            if (_error != null)
              TextButton(
                onPressed: () => setState(() => _error = null),
                child: Text(strings.retroRetry),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.retroAllProxies, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
