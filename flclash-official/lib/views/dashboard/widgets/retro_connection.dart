import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_motion.dart';

class RetroConnectionControl extends ConsumerStatefulWidget {
  final double size;
  final VoidCallback onOpenProfiles;

  const RetroConnectionControl({
    super.key,
    required this.size,
    required this.onOpenProfiles,
  });

  @override
  ConsumerState<RetroConnectionControl> createState() =>
      _RetroConnectionControlState();
}

class _RetroConnectionControlState
    extends ConsumerState<RetroConnectionControl> {
  int _revision = 0;
  bool _pending = false;
  Object? _error;

  Future<void> _toggle() async {
    final running = ref.read(isStartProvider);
    if (!running && ref.read(currentProfileProvider) == null) {
      widget.onOpenProfiles();
      return;
    }
    final revision = ++_revision;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await ref
          .read(setupActionProvider.notifier)
          .setRunning(
            !running,
            initialize: !running && !ref.read(initProvider),
          );
    } catch (error) {
      if (mounted && revision == _revision) setState(() => _error = error);
    } finally {
      if (mounted && revision == _revision) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.appLocalizations;
    final running = ref.watch(isStartProvider);
    final hasProfile = ref.watch(currentProfileProvider) != null;
    final status = _error != null
        ? strings.retroRequestFailed
        : _pending
        ? strings.retroRequestPending
        : running
        ? strings.retroRunRequested
        : hasProfile
        ? strings.retroStopped
        : strings.retroImportFirst;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeConnectButton(
          size: widget.size,
          running: running,
          onPressed: _toggle,
        ),
        SizedBox(height: widget.size <= 160 ? 12 : 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Semantics(
            liveRegion: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        if (_error != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.retroRequestFailed),
                content: SingleChildScrollView(
                  child: SelectableText('$_error'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings.confirm),
                  ),
                ],
              ),
            ),
            child: Text(strings.details('')),
          ),
      ],
    );
  }
}
