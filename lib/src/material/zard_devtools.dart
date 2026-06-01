import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/field_state.dart';
import '../core/form_controller.dart';

/// Live introspection panel for a [ZardFormController]. Shows current values,
/// errors, dirty/touched/disabled flags, and a JSON dump. Useful while
/// developing forms or as a debugging aid in the example app.
class ZardDevtools extends StatelessWidget {
  const ZardDevtools({
    required this.form,
    this.collapsed = false,
    super.key,
  });

  final ZardFormController form;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: !collapsed,
        title: AnimatedBuilder(
          animation: form,
          builder: (ctx, _) => Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const Icon(Icons.bug_report_outlined, size: 18),
              const Text('Zard Devtools'),
              const SizedBox(width: 6),
              _badge('valid', form.isValid),
              _badge('dirty', form.isDirty),
              _badge('submitting', form.isSubmitting),
              _badge('validating', form.isValidating),
            ],
          ),
        ),
        children: [
          AnimatedBuilder(
            animation: form,
            builder: (ctx, _) => DefaultTabController(
              length: 2,
              child: SizedBox(
                height: 320,
                child: Column(
                  children: [
                    const TabBar(tabs: [
                      Tab(text: 'Fields'),
                      Tab(text: 'JSON'),
                    ]),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _FieldsTable(form: form),
                          _JsonView(form: form),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, bool on) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: on
                ? const Color(0xFF22C55E).withValues(alpha: 0.18)
                : const Color(0xFF94A3B8).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: on
                  ? const Color(0xFF166534)
                  : const Color(0xFF334155),
            ),
          ),
        ),
      );
}

class _FieldsTable extends StatelessWidget {
  const _FieldsTable({required this.form});
  final ZardFormController form;

  @override
  Widget build(BuildContext context) {
    final paths = form.registeredPaths.toList()..sort();
    if (paths.isEmpty) {
      return const Center(child: Text('No fields registered yet.'));
    }
    return Scrollbar(
      child: ListView.separated(
        itemCount: paths.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final path = paths[i];
          final field = form.field(path)!;
          return ValueListenableBuilder<ZardFieldState>(
            valueListenable: field.state,
            builder: (ctx, state, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(path,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _format(state.value),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: state.errors.isEmpty
                        ? const Text('—',
                            style: TextStyle(color: Color(0xFF94A3B8)))
                        : Text(
                            state.errors.join(', '),
                            style: const TextStyle(color: Color(0xFFB91C1C)),
                          ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Wrap(
                      spacing: 4,
                      children: [
                        if (state.isDirty) _flag('D'),
                        if (state.isTouched) _flag('T'),
                        if (state.isValidating) _flag('…'),
                        if (state.disabled) _flag('×'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _flag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );

  String _format(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    return v.toString();
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.form});
  final ZardFormController form;

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    String safeEncode(Object? o) {
      try {
        return encoder.convert(o);
      } catch (_) {
        return o.toString();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('values',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(safeEncode(form.values),
              style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 12),
          const Text('errors',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(safeEncode(form.errors),
              style: const TextStyle(fontFamily: 'monospace')),
          if (form.formErrors.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('formErrors',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(safeEncode(form.formErrors),
                style: const TextStyle(fontFamily: 'monospace')),
          ],
        ],
      ),
    );
  }
}
