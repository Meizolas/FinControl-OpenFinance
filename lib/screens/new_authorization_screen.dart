import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/authorization_v2.dart';
import '../services/authorization_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';
import '../widgets/state_views.dart';

class NewAuthorizationScreen extends StatefulWidget {
  const NewAuthorizationScreen({this.initialInstitutionId, super.key});
  final String? initialInstitutionId;
  @override
  State<NewAuthorizationScreen> createState() => _NewAuthorizationScreenState();
}

class _NewAuthorizationScreenState extends State<NewAuthorizationScreen> {
  static const categories = ['Saldo', 'Transações', 'Dados da conta'];
  final _purpose = TextEditingController(
    text: 'Organização financeira pessoal',
  );
  final _selected = <String>{'Saldo', 'Transações'};
  late final Future<List<Institution>> _institutions;
  Institution? _institution;
  DateTime _until = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _institutions = AuthorizationRepository().listInstitutions();
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    if (_institution == null ||
        _purpose.text.trim().isEmpty ||
        _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revise os campos destacados antes de continuar.'),
        ),
      );
      return;
    }
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Revise antes de autorizar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirme se as informações abaixo representam sua escolha.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              _ReviewRow(
                icon: LucideIcons.landmark,
                label: 'Instituição',
                value: _institution!.name,
              ),
              _ReviewRow(
                icon: LucideIcons.target,
                label: 'Finalidade',
                value: _purpose.text.trim(),
              ),
              _ReviewRow(
                icon: LucideIcons.database,
                label: 'Categorias',
                value: _selected.join(', '),
              ),
              _ReviewRow(
                icon: LucideIcons.calendarDays,
                label: 'Validade',
                value: _date(_until),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ao confirmar, você aceita o texto de consentimento versão 1.0.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(LucideIcons.shieldCheck),
                label: const Text('Aceitar e autorizar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar e revisar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted != true) return;
    setState(() => _saving = true);
    try {
      await AuthorizationRepository().create(
        institutionId: _institution!.id,
        purpose: _purpose.text,
        categories: _selected.toList(),
        validUntil: _until,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar. Confira sua conexão e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova autorização')),
    body: FutureBuilder<List<Institution>>(
      future: _institutions,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Não foi possível carregar as instituições.',
            onRetry: () => setState(() {}),
          );
        }
        if (_institution == null && widget.initialInstitutionId != null) {
          for (final item in snapshot.data!) {
            if (item.id == widget.initialInstitutionId) {
              _institution = item;
              break;
            }
          }
        }
        return ResponsiveContent(
          maxWidth: 760,
          child: ListView(
            children: [
              Text(
                'Compartilhe com clareza',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Você poderá revogar esta autorização a qualquer momento.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle(
                        icon: LucideIcons.landmark,
                        title: 'Instituição e finalidade',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Institution>(
                        initialValue: _institution,
                        decoration: const InputDecoration(
                          labelText: 'Instituição',
                          prefixIcon: Icon(LucideIcons.building2),
                        ),
                        items: snapshot.data!
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _institution = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _purpose,
                        maxLength: 240,
                        decoration: const InputDecoration(
                          labelText: 'Finalidade',
                          prefixIcon: Icon(LucideIcons.target),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const _SectionTitle(
                        icon: LucideIcons.database,
                        title: 'Dados compartilhados',
                      ),
                      const SizedBox(height: 8),
                      ...categories.map(
                        (category) => CheckboxListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(category),
                          subtitle: Text(
                            _categoryDescription(category),
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _selected.contains(category),
                          onChanged: (checked) => setState(
                            () => checked!
                                ? _selected.add(category)
                                : _selected.remove(category),
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                      const _SectionTitle(
                        icon: LucideIcons.calendarClock,
                        title: 'Prazo da autorização',
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.calendarDays,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Válida até',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      _date(_until),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                LucideIcons.chevronRight,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _confirm,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.scanEye),
                label: Text(_saving ? 'Salvando...' : 'Revisar autorização'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );

  String _categoryDescription(String category) => switch (category) {
    'Saldo' => 'Valor disponível na conta fictícia',
    'Transações' => 'Movimentações financeiras simuladas',
    _ => 'Identificação e características da conta fictícia',
  };

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _until = picked);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}
