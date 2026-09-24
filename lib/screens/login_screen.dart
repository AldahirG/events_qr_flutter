// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../core/app_animations.dart';
import '../core/app_theme.dart';
import '../providers/app_event_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// ── Event-mode chip shown above the login card ────────────────────────────────
class _EventChip extends StatelessWidget {
  final bool isHalloween;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _EventChip({
    required this.isHalloween,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isHalloween
        ? HalloweenColors.surface
        : AppColors.primary.withValues(alpha: 0.08);
    final chipBorder = isHalloween
        ? HalloweenColors.primary.withValues(alpha: 0.5)
        : AppColors.primary.withValues(alpha: 0.25);
    final chipText = isHalloween ? HalloweenColors.text : AppColors.primary;
    final chipIcon = isHalloween ? HalloweenColors.secondary : AppColors.primary;
    final label = isHalloween ? 'Halloween Fest 23' : 'Conferencias UNINTER';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHalloween ? Icons.whatshot_rounded : Icons.mic_rounded,
              size: 15,
              color: chipIcon,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: chipText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(Icons.swap_horiz_rounded, size: 15, color: chipIcon),
          ],
        ),
      ),
    );
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authProvider.notifier)
        .login(_userCtrl.text.trim(), _passCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final event = ref.watch(appEventProvider);
    final isHalloween = event == AppEvent.halloween;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) context.go('/home');
    });

    // Colors that fall back gracefully in both themes
    final cardColor = isHalloween
        ? HalloweenColors.surface
        : AppColors.card;
    final cardShadow = isHalloween
        ? HalloweenColors.primary.withValues(alpha: 0.25)
        : AppColors.primary.withValues(alpha: 0.10);
    final titleColor = isHalloween ? HalloweenColors.text : AppColors.primary;
    final subtitleColor = isHalloween ? HalloweenColors.textSub : AppColors.textSub;
    final errorBg = isHalloween
        ? HalloweenColors.error.withValues(alpha: 0.12)
        : AppColors.error.withValues(alpha: 0.08);
    final errorBorder = isHalloween
        ? HalloweenColors.error.withValues(alpha: 0.5)
        : AppColors.error.withValues(alpha: 0.4);
    final errorTextColor = isHalloween ? HalloweenColors.error : AppColors.error;

    return Scaffold(
      backgroundColor: isHalloween ? HalloweenColors.bg : AppColors.bg,
      body: Stack(
        children: [
          // Subtle animated background (null = no bg anim for this mode)
          if (AppAnimations.loginBg(event) != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Lottie.asset(
                  AppAnimations.loginBg(event)!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Dynamic header ────────────────────────────────
                      SizedBox(
                        height: 140,
                        child: Lottie.asset(
                          AppAnimations.header(event),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            isHalloween
                                ? Icons.whatshot_rounded
                                : Icons.school_rounded,
                            size: 80,
                            color: isHalloween
                                ? const Color(0xFF9C27B0)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isHalloween
                            ? 'Halloween Fest 23'
                            : 'Eventos UNINTER',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: isHalloween ? 2.0 : 0.5,
                              color: titleColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                      const SizedBox(height: 36),

                      // ── Change event chip ─────────────────────────────
                      _EventChip(
                        isHalloween: isHalloween,
                        subtitleColor: subtitleColor,
                        onTap: () {
                          ref.read(eventConfirmedProvider.notifier).state = false;
                          // Router redirect fires automatically
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Login card ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isHalloween
                              ? Border.all(
                                  color: HalloweenColors.primary
                                      .withValues(alpha: 0.5),
                                  width: 1,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: cardShadow,
                              blurRadius: isHalloween ? 30 : 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isHalloween
                                    ? HalloweenColors.text
                                    : AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Usuario
                            TextFormField(
                              controller: _userCtrl,
                              style: TextStyle(
                                color: isHalloween
                                    ? HalloweenColors.text
                                    : AppColors.text,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon:
                                    Icon(Icons.person_outline_rounded),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Ingresa tu usuario'
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            // Contraseña
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: TextStyle(
                                color: isHalloween
                                    ? HalloweenColors.text
                                    : AppColors.text,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: isHalloween
                                        ? HalloweenColors.textSub
                                        : AppColors.textSub,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Ingresa tu contraseña'
                                      : null,
                            ),

                            // Error banner
                            if (authState.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: errorBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: errorBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: errorTextColor, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: TextStyle(
                                            color: errorTextColor,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Login button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    authState.isLoading ? null : _submit,
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
