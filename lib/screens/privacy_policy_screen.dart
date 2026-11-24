import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacidade')),
    body: ResponsiveContent(
      maxWidth: 820,
      child: ListView(
        children: const [
          _PrivacyHeader(),
          SizedBox(height: 16),
          _PolicySection(
            icon: LucideIcons.target,
            title: 'Finalidades',
            body:
                'Permitir que o titular registre, acompanhe e revogue autorizações de compartilhamento financeiro fictício e exerça seus direitos de privacidade.',
          ),
          _PolicySection(
            icon: LucideIcons.database,
            title: 'Dados tratados',
            body:
                'Identificador da conta, e-mail de autenticação, autorizações, finalidade, categorias escolhidas, prazos, histórico de eventos e pedidos do titular. Saldos e contas exibidos são fictícios.',
          ),
          _PolicySection(
            icon: LucideIcons.share2,
            title: 'Compartilhamento',
            body:
                'A demonstração simula o compartilhamento com o Banco Alfa. Não há integração com instituições financeiras reais nem venda de dados.',
          ),
          _PolicySection(
            icon: LucideIcons.clock3,
            title: 'Retenção',
            body:
                'Autorizações e eventos permanecem durante a demonstração acadêmica. Um pedido de exclusão concluído remove as autorizações e seus eventos. O protocolo é preservado para comprovação do atendimento.',
          ),
          _PolicySection(
            icon: LucideIcons.shieldCheck,
            title: 'Segurança',
            body:
                'O acesso usa autenticação, RLS e HTTPS. O texto livre dos pedidos é cifrado no PostgreSQL, e a chave permanece em schema privado no servidor.',
          ),
          _PolicySection(
            icon: LucideIcons.userRoundCheck,
            title: 'Direitos do titular',
            body:
                'O titular pode solicitar acesso, correção ou exclusão pelo menu Meus pedidos e acompanhar o protocolo e a situação.',
          ),
          _PolicySection(
            icon: LucideIcons.headphones,
            title: 'Canal de atendimento',
            body:
                'Ambiente acadêmico: suporte.fincontrol@example.test. Não envie dados financeiros reais.',
          ),
          SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _PrivacyHeader extends StatelessWidget {
  const _PrivacyHeader();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      children: [
        Icon(LucideIcons.lockKeyhole, color: Colors.white, size: 32),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seus dados, suas escolhas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Política de Privacidade • versão acadêmica 1.0',
                style: TextStyle(color: Color(0xFFDDE8D8), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
