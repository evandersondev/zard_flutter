import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 9 — ZardWatch / ZardWatchAll / useFormState with rebuild counters.
class WatchFormStateScreen extends HookWidget {
  const WatchFormStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'first': z.string(),
        'last': z.string(),
      }),
      defaultValues: const {'first': '', 'last': ''},
      mode: ValidationMode.onChange,
    );
    return ScreenScaffold(
      title: 'Watch & FormState',
      description:
          'ZardWatch subscribes to a single field; ZardWatchAll re-renders on '
          'any form change; useFormState with `listen:` picks slices. The numbers '
          'below count each rebuild — type and see which subscribers re-render.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardField<String>(
              name: 'first',
              child: ZardInput(label: 'First name'),
            ),
            const SizedBox(height: 12),
            const ZardField<String>(
              name: 'last',
              child: ZardInput(label: 'Last name'),
            ),
            const SizedBox(height: 24),
            const _RebuildBadge(
              label: 'ZardWatch<String>(name: "first")',
              child: ZardWatch<String>(
                name: 'first',
                builder: _renderValue,
              ),
            ),
            const _RebuildBadge(
              label: 'ZardWatchAll',
              child: ZardWatchAll(builder: _renderAll),
            ),
            _RebuildBadge(
              label: "useFormState(listen: [s.isValid, s.isDirty])",
              child: HookBuilder(builder: (ctx) {
                final s = useFormState(
                  listen: (snap) => [snap.isValid, snap.isDirty],
                );
                return Text('valid=${s.isValid} dirty=${s.isDirty}');
              }),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _renderValue(BuildContext _, String? v) =>
      Text('value: "${v ?? ''}"');
  static Widget _renderAll(BuildContext _, Map<String, dynamic> v) =>
      Text('all: $v');
}

class _RebuildBadge extends StatefulWidget {
  const _RebuildBadge({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  State<_RebuildBadge> createState() => _RebuildBadgeState();
}

class _RebuildBadgeState extends State<_RebuildBadge> {
  int _count = 0;
  @override
  Widget build(BuildContext context) {
    // Capture rebuild count for THIS wrapper. The child's own rebuild count is
    // observable via DevTools; here we visualize how often a typical
    // subscriber re-renders.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Builder(
            builder: (ctx) {
              _count++;
              return Row(
                children: [
                  Expanded(child: widget.child),
                  Text('renders: $_count',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
