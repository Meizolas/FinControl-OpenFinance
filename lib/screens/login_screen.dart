import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _loading = false, _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signIn(_email.text, _password.text);
    } catch (error) {
      if (mounted) setState(() => _error = readableAuthError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    FocusScope.of(context).unfocus();
    if (!_key.currentState!.validate()) {
      setState(
        () => _error =
            'Informe e-mail e senha no primeiro acesso. A biometria simulada protege essas credenciais.',
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BiometricSimulationDialog(),
    );
    if (approved == true && mounted) await _submit();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (desktop) const Expanded(flex: 5, child: _LoginHero()),
              Expanded(
                flex: desktop ? 4 : 1,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _form(showLogo: !desktop),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _form({required bool showLogo}) => AutofillGroup(
    child: Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            const Align(child: BrandLogo(height: 42)),
            const SizedBox(height: 32),
          ],
          Text(
            'Bem-vindo de volta',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse para acompanhar e controlar seus compartilhamentos.',
            style: TextStyle(color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              hintText: 'voce@exemplo.com',
              prefixIcon: Icon(LucideIcons.mail),
            ),
            validator: (value) => value == null || !value.contains('@')
                ? 'Informe um e-mail válido.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _loading ? null : _submit(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(LucideIcons.lockKeyhole),
              suffixIcon: IconButton(
                tooltip: _hidePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Informe sua senha.' : null,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: _error == null
                ? const SizedBox(height: 24)
                : Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.circleAlert, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!)),
                      ],
                    ),
                  ),
          ),
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.logIn),
            label: Text(_loading ? 'Entrando...' : 'Entrar'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _biometricLogin,
            icon: const Icon(LucideIcons.fingerprint),
            label: const Text('Entrar com biometria'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demonstração: no primeiro acesso, informe suas credenciais.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.success),
              SizedBox(width: 6),
              Text(
                'Ambiente protegido por autenticação e RLS',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BiometricSimulationDialog extends StatefulWidget {
  const _BiometricSimulationDialog();
  @override
  State<_BiometricSimulationDialog> createState() =>
      _BiometricSimulationDialogState();
}

class _BiometricSimulationDialogState
    extends State<_BiometricSimulationDialog> {
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _approved = true);
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.pop(context, true);
      });
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _approved
          ? const Icon(
              LucideIcons.circleCheckBig,
              key: ValueKey('approved'),
              color: AppColors.success,
              size: 54,
            )
          : const SizedBox.square(
              key: ValueKey('reading'),
              dimension: 54,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
    ),
    title: Text(_approved ? 'Identidade confirmada' : 'Lendo biometria...'),
    content: Text(
      _approved
          ? 'Validação simulada concluída. Entrando com segurança.'
          : 'Mantenha o dedo no sensor do dispositivo.',
      textAlign: TextAlign.center,
    ),
    actionsAlignment: MainAxisAlignment.center,
    actions: const [
      Chip(
        avatar: Icon(LucideIcons.flaskConical, size: 16),
        label: Text('Modo demonstração'),
      ),
    ],
  );
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(52),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, Color(0xFF315916)],
      ),
      borderRadius: BorderRadius.circular(32),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandLogo(height: 46),
        const Spacer(),
        Text(
          'Seus dados.\nSuas escolhas.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 46,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Visualize, compreenda e controle cada autorização de compartilhamento em um só lugar.',
          style: TextStyle(color: Color(0xFFDCE8D2), fontSize: 17, height: 1.5),
        ),
        const SizedBox(height: 36),
        const Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _HeroFeature(icon: LucideIcons.scanEye, label: 'Transparência'),
            _HeroFeature(icon: LucideIcons.shieldCheck, label: 'Segurança'),
            _HeroFeature(icon: LucideIcons.history, label: 'Rastreabilidade'),
          ],
        ),
      ],
    ),
  );
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFFB9DB83), size: 20),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
