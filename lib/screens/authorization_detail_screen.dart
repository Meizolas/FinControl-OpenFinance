import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/authorization_v2.dart';
import '../services/authorization_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';

class AuthorizationDetailScreen extends StatefulWidget {
  const AuthorizationDetailScreen({required this.authorization, super.key});

  final Authorization authorization;

  @override
  State<AuthorizationDetailScreen> createState() =>
      _AuthorizationDetailScreenState();
}

class _AuthorizationDetailScreenState extends State<AuthorizationDetailScreen> {
  final _repository = AuthorizationRepository();
  late Future<List<AuthorizationEvent>> _events;
  FinancialSnapshot? _snapshot;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _reloadEvents();
  }

  void _reloadEvents() {
    _events = _repository.listEvents(widget.authorization.id);
  }

  String _dateTime(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _eventLabel(String type) => switch (type) {
    'accepted' => 'Autorização aceita',
    'revoked' => 'Autorização revogada',
    'expired' => 'Autorização expirada',
    'data_accessed' => 'Dados fictícios consultados',
    _ => type,
  };

  Future<void> _synchronize() async {
    setState(() => _working = true);
    try {
      final result = await _repository.synchronize(widget.authorization.id);
      if (!mounted) return;
      setState(() {
        _snapshot = result;
        _reloadEvents();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableAuthorizationError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _revoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar autorização?'),
        content: const Text(
          'O Banco Alfa deixará de acessar os dados imediatamente. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _working = true);
    try {
      await _repository.revoke(widget.authorization.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autorização revogada com sucesso.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableAuthorizationError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorization = widget.authorization;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da autorização')),
      body: ResponsiveContent(
        maxWidth: 820,
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.landmark,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorization.institutionName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(authorization.status),
                            style: TextStyle(
                              color: _statusColor(authorization.status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações do consentimento',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 18),
                    _Field(
                      icon: LucideIcons.target,
                      label: 'Finalidade',
                      value: authorization.purpose,
                    ),
                    _Field(
                      icon: LucideIcons.database,
                      label: 'Categorias',
                      value: authorization.dataCategories.join(', '),
                    ),
                    _Field(
                      icon: LucideIcons.calendarCheck,
                      label: 'Aceita em',
                      value: _dateTime(authorization.acceptedAt),
                    ),
                    _Field(
                      icon: LucideIcons.calendarClock,
                      label: 'Válida até',
                      value: _dateTime(authorization.validUntil),
                    ),
                    _Field(
                      icon: LucideIcons.fileCheck,
                      label: 'Texto do aceite',
                      value: 'Versão ${authorization.termsVersion}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: authorization.isActive && !_working
                  ? _synchronize
                  : null,
              icon: _working
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.refreshCw),
              label: const Text('Sincronizar dados fictícios'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: authorization.isActive && !_working ? _revoke : null,
              icon: const Icon(LucideIcons.ban),
              label: const Text('Revogar autorização'),
            ),
            if (_snapshot != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.badgeInfo,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dados simulados',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_snapshot!.accountAlias),
                      Text(
                        '${_snapshot!.currency} ${_snapshot!.balance.toStringAsFixed(2)}',
                      ),
                      Text('Referência: ${_dateTime(_snapshot!.referenceAt)}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(LucideIcons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Histórico',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            FutureBuilder<List<AuthorizationEvent>>(
              future: _events,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Não foi possível carregar o histórico.'),
                  );
                }
                return Column(
                  children: snapshot.data!
                      .map(
                        (event) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              size: 17,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          title: Text(_eventLabel(event.type)),
                          subtitle: Text(_dateTime(event.occurredAt)),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'active' => 'Autorização ativa',
    'revoked' => 'Autorização revogada',
    'expired' => 'Autorização expirada',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'active' => AppColors.success,
    'expired' => AppColors.warning,
    _ => AppColors.textMuted,
  };
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.textMuted),
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
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}
