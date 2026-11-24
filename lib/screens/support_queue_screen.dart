import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/rights_request.dart';
import '../services/rights_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';
import '../widgets/state_views.dart';

class SupportQueueScreen extends StatefulWidget {
  const SupportQueueScreen({super.key});
  @override
  State<SupportQueueScreen> createState() => _SupportQueueScreenState();
}

class _SupportQueueScreenState extends State<SupportQueueScreen> {
  final _repository = RightsRepository();
  late Future<List<SupportQueueItem>> _queue;
  final Set<String> _updating = {};
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _queue = _repository.listSupportQueue();
  String _type(String value) =>
      {
        'access': 'Acesso',
        'correction': 'Correção',
        'deletion': 'Exclusão',
      }[value] ??
      value;
  String _status(String value) =>
      {
        'submitted': 'Recebido',
        'in_review': 'Em análise',
        'completed': 'Concluído',
        'rejected': 'Recusado',
      }[value] ??
      value;
  Color _color(String status) => switch (status) {
    'completed' => AppColors.success,
    'rejected' => AppColors.danger,
    'in_review' => AppColors.warning,
    _ => AppColors.primary,
  };

  Future<void> _update(SupportQueueItem item, String status) async {
    if (status == 'completed' && item.type == 'deletion') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(LucideIcons.triangleAlert, color: AppColors.warning),
          title: const Text('Concluir exclusão?'),
          content: const Text(
            'Esta ação removerá os dados vinculados ao titular e não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar exclusão'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _updating.add(item.id));
    try {
      await _repository.updateStatus(item.id, status);
      if (mounted) {
        setState(_reload);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido atualizado para ${_status(status)}.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível atualizar o pedido. Tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fila de suporte')),
    body: FutureBuilder<List<SupportQueueItem>>(
      future: _queue,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Acesso negado ou fila indisponível.',
            onRetry: () => setState(_reload),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            title: 'Tudo em dia',
            message: 'Não há solicitações aguardando atendimento.',
          );
        }
        return ResponsiveContent(
          maxWidth: 1000,
          child: RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView(
              children: [
                Text(
                  'Atendimento aos titulares',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${items.length} ${items.length == 1 ? 'solicitação encontrada' : 'solicitações encontradas'}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ...items.map((item) {
                  final busy = _updating.contains(item.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.ticketCheck,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.protocol,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_type(item.type)} • ${item.maskedOwner}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _color(
                                    item.status,
                                  ).withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _status(item.status),
                                  style: TextStyle(
                                    color: _color(item.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Text(
                            item.details,
                            style: const TextStyle(height: 1.5),
                          ),
                          if (item.status == 'submitted' ||
                              item.status == 'in_review') ...[
                            const SizedBox(height: 18),
                            if (busy)
                              const LinearProgressIndicator()
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (item.status == 'submitted')
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _update(item, 'in_review'),
                                      icon: const Icon(
                                        LucideIcons.search,
                                        size: 18,
                                      ),
                                      label: const Text('Iniciar análise'),
                                    ),
                                  FilledButton.icon(
                                    onPressed: () => _update(item, 'completed'),
                                    icon: const Icon(
                                      LucideIcons.check,
                                      size: 18,
                                    ),
                                    label: const Text('Concluir'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _update(item, 'rejected'),
                                    icon: const Icon(LucideIcons.x, size: 18),
                                    label: const Text('Recusar'),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    ),
  );
}
