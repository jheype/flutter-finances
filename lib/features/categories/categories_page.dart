import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_financas/data/models.dart';
import 'package:flutter_financas/data/repositories.dart';

final _categoryRepoProvider = Provider((ref) => CategoryRepository());
final categoriesProvider = FutureProvider<List<CategoryModel>>(
  (ref) => ref.watch(_categoryRepoProvider).getAll(),
);

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: async.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final c = items[i];
            return ListTile(
              leading: CircleAvatar(backgroundColor: c.color),
              title: Text(c.name),
              subtitle: Text(c.type == CategoryType.expense ? 'Despesa' : 'Receita'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Excluir categoria?'),
                      content: const Text('Isso também removerá transações associadas.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref.read(_categoryRepoProvider).delete(c.id!);
                    ref.invalidate(categoriesProvider);
                  }
                },
              ),
              onTap: () => _openEditor(context, ref, seed: c),
            );
          },
        ),
        error: (e, _) => Center(child: Text('Erro: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {CategoryModel? seed}) async {
    final result = await showDialog<CategoryModel>(
      context: context,
      builder: (_) => _CategoryDialog(seed: seed),
    );
    if (result != null) {
      await ref.read(_categoryRepoProvider).upsert(result);
      ref.invalidate(categoriesProvider);
    }
  }
}

class _CategoryDialog extends StatefulWidget {
  final CategoryModel? seed;
  const _CategoryDialog({this.seed});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  CategoryType _type = CategoryType.expense;
  Color _color = const Color(0xFFAB47BC);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.seed?.name ?? '');
    _type = widget.seed?.type ?? CategoryType.expense;
    _color = Color(widget.seed?.colorValue ?? 0xFFAB47BC);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.seed == null ? 'Nova categoria' : 'Editar categoria'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    label: Text('Despesa'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    label: Text('Receita'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Cor:'),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: context,
                        builder: (_) => _ColorPickerDialog(initial: _color),
                      );
                      if (picked != null) setState(() => _color = picked);
                    },
                    child: CircleAvatar(backgroundColor: _color, radius: 14),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final model = CategoryModel(
                id: widget.seed?.id,
                name: _name.text.trim(),
                type: _type,
                colorValue: _color.value,
              );
              Navigator.pop(context, model);
            }
          },
          child: const Text('Salvar'),
        )
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double h;
  late double s;
  late double v;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    h = hsv.hue;
    s = hsv.saturation;
    v = hsv.value;
  }

  @override
  Widget build(BuildContext context) {
    final color = HSVColor.fromAHSV(1, h, s, v).toColor();
    return AlertDialog(
      title: const Text('Escolher cor'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            _slider('Matiz', h, 0, 360, (x) => setState(() => h = x)),
            _slider('Saturação', s, 0, 1, (x) => setState(() => s = x)),
            _slider('Brilho', v, 0, 1, (x) => setState(() => v = x)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text('Usar cor'),
        ),
      ],
    );
  }

  Widget _slider(
      String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
      ],
    );
  }
}
