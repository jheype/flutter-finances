import 'package:flutter/material.dart';

import 'package:flutter_financas/core/utils/format.dart';
import 'package:flutter_financas/data/models.dart';
import 'package:flutter_financas/data/repositories.dart';

enum _TxType { income, expense }

class TransactionForm extends StatefulWidget {
  final TransactionModel? seed;
  const TransactionForm({super.key, this.seed});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  int? _categoryId;
  DateTime _date = DateTime.now();
  _TxType _type = _TxType.expense;

  @override
  void initState() {
    super.initState();
    if (widget.seed != null) {
      final t = widget.seed!;
      _type = t.amountCents >= 0 ? _TxType.income : _TxType.expense;
      _amountCtrl.text = (t.amountCents.abs() / 100).toStringAsFixed(2).replaceAll('.', ',');
      _categoryId = t.categoryId;
      _date = t.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesFuture = CategoryRepository().getAll();

    return AlertDialog(
      title: Text(widget.seed == null ? 'Nova transação' : 'Editar transação'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: FutureBuilder<List<CategoryModel>>(
            future: categoriesFuture,
            builder: (context, snap) {
              final items = snap.data ?? const <CategoryModel>[];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: false),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      helperText: 'Informe apenas números; o tipo define entrada/saída',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe um valor';
                      final cents = _parseToCents(v);
                      if (cents == null || cents <= 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<_TxType>(
                      segments: const [
                        ButtonSegment(
                            value: _TxType.income,
                            label: Text('Receita'),
                            icon: Icon(Icons.trending_up)),
                        ButtonSegment(
                            value: _TxType.expense,
                            label: Text('Despesa'),
                            icon: Icon(Icons.trending_down)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      for (final c in items)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: c.color, radius: 6),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ),
                    ],
                    initialValue: _categoryId,
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) => v == null ? 'Selecione a categoria' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data'),
                    subtitle: Text(Format.date(_date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final cents = _parseToCents(_amountCtrl.text)!;
            final signedCents = _type == _TxType.expense ? -cents : cents;

            final model = TransactionModel(
              id: widget.seed?.id,
              categoryId: _categoryId!,
              amountCents: signedCents,
              date: _date,
            );

            Navigator.pop(context, model);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  int? _parseToCents(String input) {
    final cleaned = input
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final v = double.tryParse(cleaned);
    if (v == null) return null;
    return (v * 100).round();
  }
}
