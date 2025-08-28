import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('Idioma'),
          subtitle: Text('Português (Brasil)'),
        ),
        ListTile(
          title: Text('Moeda'),
          subtitle: Text('Real (R\$)'),
        ),
        ListTile(
          title: Text('Tema'),
          subtitle: Text('Escuro com roxos (padrão) — minimalista, mas com personalidade :)'),
        ),
      ],
    );
  }
}
