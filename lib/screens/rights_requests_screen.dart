import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/rights_request.dart';
import '../services/rights_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';
import '../widgets/state_views.dart';

class RightsRequestsScreen extends StatefulWidget {
  const RightsRequestsScreen({super.key});
  @override
  State<RightsRequestsScreen> createState() => _RightsRequestsScreenState();
}

class _RightsRequestsScreenState extends State<RightsRequestsScreen> {
  final _repository = RightsRepository();
  late Future<List<RightsRequest>> _requests;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _requests = _repository.listMine();
  String _date(DateTime v) =>
      '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}';
  String _type(String v) =>
      {
        'access': 'Acesso',
        'correction': 'Correção',
        'deletion': 'Exclusão',
      }[v] ??
      v;
  String _status(String v) =>
      {
        'submitted': 'Enviado',
        'in_review': 'Em análise',
        'completed': 'Concluído',
        'rejected': 'Recusado',
      }[v] ??
      v;
  Color _statusColor(String v) => switch (v) {
    'completed' => AppColors.success,
    'rejected' => AppColors.danger,
    'in_review' => AppColors.warning,
    _ => AppColors.primary,
  };
  IconData _typeIcon(String v) => switch (v) {
    'correction' => LucideIcons.filePenLine,
    'deletion' => LucideIcons.trash2,
    _ => LucideIcons.fileSearch,
  };

  Future<void> _newRequest() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NewRequestSheet(),
    );
    if (created == true && mounted) {
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado com sucesso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus pedidos')),
    body: FutureBuilder<List<RightsRequest>>(
      future: _requests,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Não foi possível carregar os pedidos.',
            onRetry: () => setState(_reload),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return EmptyState(
            title: 'Nenhum pedido registrado',
            message: 'Solicite acesso, correção ou exclusão dos seus dados.',
            action: FilledButton.icon(
              onPressed: _newRequest,
              icon: const Icon(LucideIcons.plus),
              label: const Text('Criar pedido'),
            ),
          );
        }
        return ResponsiveContent(
          maxWidth: 900,
          child: RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView(
              children: [
                Text(
                  'Acompanhe seus direitos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Consulte o protocolo e o andamento de cada solicitação.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _typeIcon(item.type),
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _type(item.type),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          item.status,
                                        ).withValues(alpha: .12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _status(item.status),
                                        style: TextStyle(
                                          color: _statusColor(item.status),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.protocol,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendarDays,
                                      size: 15,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Criado em ${_date(item.createdAt)}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newRequest,
      icon: const Icon(LucideIcons.plus),
      label: const Text('Novo pedido'),
    ),
  );
}

class _NewRequestSheet extends StatefulWidget {
  const _NewRequestSheet();
  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  final _details = TextEditingController();
  String _type = 'access';
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_details.text.trim().length < 10) {
      setState(
        () =>
            _error = 'Explique a solicitação usando pelo menos 10 caracteres.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await RightsRepository().submit(type: _type, details: _details.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = readableRightsError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Novo pedido',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Exerça seus direitos de forma simples e acompanhe pelo protocolo.',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Direito solicitado',
                prefixIcon: Icon(LucideIcons.scale),
              ),
              items: const [
                DropdownMenuItem(value: 'access', child: Text('Acesso')),
                DropdownMenuItem(value: 'correction', child: Text('Correção')),
                DropdownMenuItem(value: 'deletion', child: Text('Exclusão')),
              ],
              onChanged: _saving ? null : (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _details,
              enabled: !_saving,
              minLines: 4,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Detalhes',
                hintText:
                    'Descreva o que você precisa. Não informe dados financeiros reais.',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: Icon(LucideIcons.messageSquareText),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.send),
              label: Text(_saving ? 'Enviando...' : 'Enviar pedido'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
}
