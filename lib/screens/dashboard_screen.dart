import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/authorization_v2.dart';
import '../services/auth_service.dart';
import '../services/authorization_repository.dart';
import '../services/rights_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/state_views.dart';
import 'authorization_detail_screen.dart';
import 'new_authorization_screen.dart';
import 'open_finance_connection_screen.dart';
import 'privacy_policy_screen.dart';
import 'rights_requests_screen.dart';
import 'support_queue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final _repository = AuthorizationRepository();
  final List<Authorization> _items = [];
  Timer? _refreshTimer;
  bool _loading = true, _requestInFlight = false, _isSupport = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _loadRole();
    _startAutomaticRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
      _startAutomaticRefresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _refreshTimer?.cancel();
    }
  }

  void _startAutomaticRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _load(silent: true),
    );
  }

  Future<void> _loadRole() async {
    try {
      final value = await RightsRepository().isSupport();
      if (mounted) setState(() => _isSupport = value);
    } catch (_) {}
  }

  Future<void> _load({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _repository.listMine();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted && _items.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar suas autorizações.';
        });
      }
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _create() async {
    final institution = await Navigator.push<Institution>(
      context,
      MaterialPageRoute(builder: (_) => const OpenFinanceConnectionScreen()),
    );
    if (institution == null || !mounted) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewAuthorizationScreen(initialInstitutionId: institution.id),
      ),
    );
    if (created == true) {
      await _load(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorização criada com sucesso.')),
        );
      }
    }
  }

  Future<void> _openDetails(Authorization item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorizationDetailScreen(authorization: item),
      ),
    );
    await _load(silent: true);
  }

  void _open(Widget screen) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => screen));

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      return Scaffold(
        appBar: desktop
            ? null
            : AppBar(
                title: const Text('FinControl'),
                actions: [
                  IconButton(
                    tooltip: 'Atualizar',
                    onPressed: () => _load(silent: true),
                    icon: const Icon(LucideIcons.refreshCw),
                  ),
                ],
              ),
        drawer: desktop
            ? null
            : Drawer(
                child: SafeArea(
                  child: _NavigationPanel(
                    isDrawer: true,
                    isSupport: _isSupport,
                    onOpen: _open,
                  ),
                ),
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 272,
                  child: _NavigationPanel(
                    isDrawer: false,
                    isSupport: _isSupport,
                    onOpen: _open,
                  ),
                ),
              if (desktop) const VerticalDivider(width: 1),
              Expanded(child: _content(desktop)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(LucideIcons.plus),
          label: const Text('Nova autorização'),
        ),
      );
    },
  );

  Widget _content(bool desktop) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (desktop)
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: () => _load(silent: true),
                icon: const Icon(LucideIcons.refreshCw),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  (Supabase.instance.client.auth.currentUser?.email ?? 'U')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          desktop ? 32 : 16,
          desktop ? 12 : 8,
          desktop ? 32 : 16,
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minhas autorizações',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Acompanhe quem pode acessar seus dados e por quanto tempo.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      Expanded(child: _body()),
    ],
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            EmptyState(
              title: 'Nenhuma autorização por aqui',
              message:
                  'Crie sua primeira autorização e mantenha o controle dos seus dados.',
              action: FilledButton.icon(
                onPressed: _create,
                icon: const Icon(LucideIcons.plus),
                label: const Text('Criar autorização'),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _AuthorizationCard(
              item: _items[index],
              date: _date,
              onTap: () => _openDetails(_items[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorizationCard extends StatelessWidget {
  const _AuthorizationCard({
    required this.item,
    required this.date,
    required this.onTap,
  });
  final Authorization item;
  final String Function(DateTime) date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      'active' => AppColors.success,
      'expired' => AppColors.warning,
      _ => AppColors.textMuted,
    };
    final label = switch (item.status) {
      'active' => 'Ativa',
      'expired' => 'Expirada',
      'revoked' => 'Revogada',
      _ => item.status,
    };
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.institutionName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.purpose,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Meta(
                          icon: LucideIcons.database,
                          text: item.dataCategories.join(', '),
                        ),
                        _Meta(
                          icon: LucideIcons.calendarDays,
                          text: 'Até ${date(item.validUntil)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    ],
  );
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.isDrawer,
    required this.isSupport,
    required this.onOpen,
  });
  final bool isDrawer, isSupport;
  final void Function(Widget) onOpen;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BrandLogo(height: 30, compact: true),
        const SizedBox(height: 28),
        const _NavItem(
          icon: LucideIcons.layoutDashboard,
          label: 'Autorizações',
          selected: true,
        ),
        _NavItem(
          icon: LucideIcons.clipboardList,
          label: 'Meus pedidos',
          onTap: () => onOpen(const RightsRequestsScreen()),
        ),
        _NavItem(
          icon: LucideIcons.shieldCheck,
          label: 'Privacidade',
          onTap: () => onOpen(const PrivacyPolicyScreen()),
        ),
        if (isSupport)
          _NavItem(
            icon: LucideIcons.headset,
            label: 'Fila de suporte',
            onTap: () => onOpen(const SupportQueueScreen()),
          ),
        const Spacer(),
        const Divider(),
        _NavItem(
          icon: LucideIcons.logOut,
          label: 'Sair',
          danger: true,
          onTap: () => AuthService().signOut(),
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected, danger;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      selected: selected,
      selectedTileColor: AppColors.primaryContainer,
      selectedColor: AppColors.primaryDark,
      textColor: danger ? AppColors.danger : AppColors.text,
      iconColor: danger ? AppColors.danger : AppColors.textMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 21),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    ),
  );
}
