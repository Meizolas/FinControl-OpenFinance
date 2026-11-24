import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/authorization_v2.dart';
import '../services/authorization_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';
import '../widgets/state_views.dart';

class OpenFinanceConnectionScreen extends StatefulWidget {
  const OpenFinanceConnectionScreen({super.key});

  @override
  State<OpenFinanceConnectionScreen> createState() =>
      _OpenFinanceConnectionScreenState();
}

class _OpenFinanceConnectionScreenState
    extends State<OpenFinanceConnectionScreen> {
  late Future<List<Institution>> _institutions;
  Institution? _selected;
  int _step = 0;
  bool _connecting = false;

  static const _steps = [
    ('Redirecionando para o banco', 'Preparando um ambiente seguro simulado'),
    ('Autorizando acesso', 'Validando o consentimento demonstrativo'),
    (
      'Estabelecendo conexão segura',
      'Simulando troca protegida de informações',
    ),
    (
      'Importando dados fictícios',
      'Carregando conta, saldo e transações de exemplo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _institutions = AuthorizationRepository().listInstitutions();
  }

  Future<void> _connect() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma instituição para continuar.'),
        ),
      );
      return;
    }
    setState(() {
      _connecting = true;
      _step = 0;
    });
    for (var index = 0; index < _steps.length; index++) {
      if (!mounted) return;
      setState(() => _step = index);
      await Future<void>.delayed(const Duration(milliseconds: 850));
    }
    if (!mounted) return;
    setState(() {
      _step = _steps.length;
      _connecting = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Conectar instituição')),
    body: FutureBuilder<List<Institution>>(
      future: _institutions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Não foi possível carregar as instituições.',
            onRetry: () => setState(_load),
          );
        }
        final institutions = snapshot.data ?? [];
        if (institutions.isEmpty) {
          return const EmptyState(
            title: 'Nenhuma instituição disponível',
            message:
                'Cadastre uma instituição fictícia para iniciar a demonstração.',
          );
        }
        _selected ??= institutions.first;
        return ResponsiveContent(
          maxWidth: 760,
          child: ListView(
            children: [
              const _SimulationBanner(),
              const SizedBox(height: 20),
              Text(
                'Conecte sua instituição',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Veja como seria a jornada de conexão pelo Open Finance.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Instituição disponível',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      ...institutions.map(
                        (institution) => _InstitutionOption(
                          institution: institution,
                          selected: _selected?.id == institution.id,
                          enabled: !_connecting && _step < _steps.length,
                          onTap: () => setState(() => _selected = institution),
                        ),
                      ),
                      const Divider(height: 32),
                      const _SecurityNotice(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_connecting) _ConnectionProgress(step: _step, steps: _steps),
              if (_step == _steps.length) ...[
                const _ConnectedResult(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _selected),
                  icon: const Icon(LucideIcons.arrowRight),
                  label: const Text('Continuar para autorização'),
                ),
              ] else if (!_connecting)
                FilledButton.icon(
                  onPressed: _connect,
                  icon: const Icon(LucideIcons.link),
                  label: const Text('Conectar via Open Finance'),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );
}

class _SimulationBanner extends StatelessWidget {
  const _SimulationBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withValues(alpha: .28)),
    ),
    child: const Row(
      children: [
        Icon(LucideIcons.flaskConical, color: AppColors.primaryDark),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Simulação acadêmica: nenhuma instituição financeira real será acessada.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _InstitutionOption extends StatelessWidget {
  const _InstitutionOption({
    required this.institution,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final Institution institution;
  final bool selected, enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryContainer : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(LucideIcons.landmark, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Ambiente financeiro simulado',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            selected ? LucideIcons.circleCheckBig : LucideIcons.circle,
            color: selected ? AppColors.primary : AppColors.textMuted,
          ),
        ],
      ),
    ),
  );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();
  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 20),
      SizedBox(width: 10),
      Expanded(
        child: Text(
          'A FinControl não solicita nem armazena sua senha bancária. Nesta demonstração, todos os dados são fictícios.',
          style: TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
      ),
    ],
  );
}

class _ConnectionProgress extends StatelessWidget {
  const _ConnectionProgress({required this.step, required this.steps});
  final int step;
  final List<(String, String)> steps;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  steps[step].$1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            steps[step].$2,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: (step + 1) / steps.length),
          const SizedBox(height: 10),
          Text(
            'Etapa ${step + 1} de ${steps.length}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _ConnectedResult extends StatelessWidget {
  const _ConnectedResult();
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFE9F6EC),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            LucideIcons.circleCheckBig,
            color: AppColors.success,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'Instituição conectada',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Conta fictícia • Saldo e transações disponíveis para autorização',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}
