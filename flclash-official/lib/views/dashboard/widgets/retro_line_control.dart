import 'package:fl_clash/common/common.dart';
import 'package:flutter/material.dart';

class RetroLineControl extends StatelessWidget {
  final String line;
  final VoidCallback onChange;

  const RetroLineControl({
    super.key,
    required this.line,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7901);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final change = OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: orange,
            backgroundColor: Colors.white,
            side: const BorderSide(color: orange),
            minimumSize: const Size(72, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed: onChange,
          child: Text(context.appLocalizations.classicChange),
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x88A1A9AA)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    context.appLocalizations.classicLine,
                    style: const TextStyle(color: orange, fontSize: 14),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: orange),
                    ),
                    child: const Icon(Icons.public, color: orange, size: 23),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: line,
                      child: Text(
                        line,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3C3C3C),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (!stacked) ...[const SizedBox(width: 10), change],
                ],
              ),
              if (stacked)
                Align(alignment: Alignment.centerRight, child: change),
            ],
          ),
        );
      },
    );
  }
}
