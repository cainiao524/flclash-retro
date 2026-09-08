import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dashboard/classic_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home.dart';

class RetroHomePage extends ConsumerStatefulWidget {
  const RetroHomePage({super.key});

  @override
  ConsumerState<RetroHomePage> createState() => _RetroHomePageState();
}

class _RetroHomePageState extends ConsumerState<RetroHomePage> {
  bool _opening = false;

  Future<void> _openAdvanced(PageLabel page) async {
    if (_opening) return;
    _opening = true;
    ref.read(currentPageLabelProvider.notifier).toPage(page);
    try {
      final navigator = Navigator.of(context);
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => HomePage(
            onOpenHome: () => navigator.popUntil((route) => route.isFirst),
          ),
        ),
      );
    } finally {
      _opening = false;
      if (mounted) {
        ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) => HomeBackScopeContainer(
    child: ClassicHomeView(originalLayout: false, onOpenPage: _openAdvanced),
  );
}
