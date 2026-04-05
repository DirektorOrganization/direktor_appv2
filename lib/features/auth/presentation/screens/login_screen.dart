// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../shared/widgets/direktor_logo.dart';

// ─── Brand palette (Manual de Marca · Direktor) ───────────────────────────────
abstract final class _B {
  // Azul corporativo primario
  static const blue        = Color(0xFF0A66B7);
  static const blueDeep    = Color(0xFF0852A3);
  static const blueLight   = Color(0xFF1580D8);
  // Azul cielo — fondo superior (más claro y luminoso)
  static const navy        = Color(0xFF0A66B7);   // antes 0xFF0F1E33
  static const navyLight   = Color(0xFF42A5F5);   // antes 0xFF1E3A5F
  // Texto
  static const textDark    = Color(0xFF0F172A);
  static const textMid     = Color(0xFF334155);
  static const textMuted   = Color(0xFF64748B);
  static const textLight   = Color(0xFF94A3B8);
  // Superficie
  static const white       = Colors.white;
  static const surface     = Color(0xFFF8FAFC);
  static const stroke      = Color(0xFFE2E8F0);
  // Acento / error
  static const accent      = Color(0xFFBAE6FD);   // celeste claro sobre azul
  static const error       = Color(0xFFEF4444);
}

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _userController     = TextEditingController();
  final _passwordController = TextEditingController();
  final _userFocus          = FocusNode();
  final _passFocus          = FocusNode();

  bool _obscureText  = true;
  bool _keepSession  = true;
  bool _userFocused  = false;
  bool _passFocused  = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _userFocus.addListener(() => setState(() => _userFocused = _userFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final size       = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF4FB),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Stack(
              children: [
                // ── Fondo superior navy con gradiente ──────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: size.height * 0.46,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_B.blueDeep, _B.blue, _B.navyLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),

                // ── Cuerpo scrollable ───────────────────────────────
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                      child: Column(
                        children: [
                          // ── Hero brand ─────────────────────────────
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 40, 0, 28),
                                child: Column(
                                  children: [
                                    // Isotipo con halo
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _B.white.withValues(alpha: 0.07),
                                        border: Border.all(color: _B.white.withValues(alpha: 0.12), width: 1.5),
                                      ),
                                      child: const Center(
                                        child: DirektorLogo(size: 52),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    // Nombre marca
                                    const Text(
                                      'DIREKTOR',
                                      style: TextStyle(
                                        color: _B.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 5,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Línea celeste decorativa
                                    Container(
                                      width: 40,
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: _B.accent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Gestión de proyectos y restricciones',
                                      style: TextStyle(
                                        color: _B.white.withValues(alpha: 0.55),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Card formulario ────────────────────────
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                decoration: BoxDecoration(
                                  color: _B.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _B.navy.withValues(alpha: 0.18),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Encabezado del card
                                    const Text(
                                      'Bienvenido',
                                      style: TextStyle(
                                        color: _B.textDark,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Ingresa tus credenciales para continuar',
                                      style: TextStyle(
                                        color: _B.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Campo usuario
                                    _FieldLabel('Usuario o correo electrónico'),
                                    const SizedBox(height: 6),
                                    _InputField(
                                      controller: _userController,
                                      focusNode: _userFocus,
                                      isFocused: _userFocused,
                                      hint: 'nombre@empresa.com',
                                      icon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) => _passFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 16),

                                    // Campo contraseña
                                    _FieldLabel('Contraseña'),
                                    const SizedBox(height: 6),
                                    _InputField(
                                      controller: _passwordController,
                                      focusNode: _passFocus,
                                      isFocused: _passFocused,
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscureText,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => controller.isBusy ? null : _submit(),
                                      suffixIcon: GestureDetector(
                                        onTap: () => setState(() => _obscureText = !_obscureText),
                                        child: Icon(
                                          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          size: 18,
                                          color: _B.textMuted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Mantener sesión
                                    GestureDetector(
                                      onTap: () => setState(() => _keepSession = !_keepSession),
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 160),
                                            width: 18, height: 18,
                                            decoration: BoxDecoration(
                                              color: _keepSession ? _B.blue : _B.white,
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: _keepSession ? _B.blue : _B.stroke,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: _keepSession
                                                ? const Icon(Icons.check_rounded, size: 12, color: _B.white)
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Mantener sesión iniciada',
                                            style: TextStyle(
                                              color: _B.textMid,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Error
                                    if (controller.error != null) ...[
                                      const SizedBox(height: 14),
                                      _ErrorBanner(message: controller.error!),
                                    ],
                                    const SizedBox(height: 22),

                                    // Botón ingresar
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_B.blueDeep, _B.blueLight],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(13),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _B.blue.withValues(alpha: 0.35),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: MaterialButton(
                                          onPressed: controller.isBusy ? null : _submit,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                          child: controller.isBusy
                                              ? const SizedBox(
                                                  width: 20, height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                                )
                                              : const Text(
                                                  'Ingresar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Olvidé contraseña
                                    Center(
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          foregroundColor: _B.blue,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        child: const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Footer ─────────────────────────────────
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  // Modo offline badge
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                    decoration: BoxDecoration(
                                      color: _B.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _B.white.withValues(alpha: 0.10)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.wifi_off_rounded, size: 13, color: _B.accent.withValues(alpha: 0.8)),
                                        const SizedBox(width: 7),
                                        Text(
                                          'Modo offline disponible — trabaja sin conexión',
                                          style: TextStyle(
                                            color: _B.white.withValues(alpha: 0.55),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 10, color: _B.white.withValues(alpha: 0.30)),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Conexión segura  ·  v2.0',
                                        style: TextStyle(
                                          color: _B.white.withValues(alpha: 0.30),
                                          fontSize: 10,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
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
  }

  Future<void> _submit() async {
    final controller = AppScope.of(context);
    final success = await controller.login(
      userOrEmail: _userController.text.trim(),
      password: _passwordController.text,
      keepSignedIn: _keepSession,
    );
    if (!mounted || !success) return;
    Navigator.pushReplacementNamed(context, RouteNames.projects);
  }
}

// ─── Grid painter (fondo navy con puntos sutiles) ─────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _B.textMid,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );
}

// ─── Input Field ──────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isFocused ? _B.blue.withValues(alpha: 0.04) : _B.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? _B.blue : _B.stroke,
          width: isFocused ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: _B.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _B.textLight, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: isFocused ? _B.blue : _B.textLight),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  /// Convierte mensajes técnicos del backend en texto amigable.
  static String _friendly(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('credenciales') || lower.contains('incorrectas') || lower.contains('invalid')) {
      return 'Usuario o contraseña incorrectos. Verifica tus datos e intenta de nuevo.';
    }
    if (lower.contains('sin conexión') || lower.contains('socket') || lower.contains('connection') || lower.contains('network')) {
      return 'Sin conexión al servidor. Revisa tu internet e intenta de nuevo.';
    }
    if (lower.contains('timeout') || lower.contains('time out')) {
      return 'El servidor tardó demasiado en responder. Intenta nuevamente.';
    }
    if (lower.contains('no configuró') || lower.contains('api_base_url') || lower.contains('isConfigured')) {
      return 'La aplicación no está configurada para acceso remoto.';
    }
    // Fallback: devuelve el mensaje original capitalizado
    return raw.isNotEmpty ? '${raw[0].toUpperCase()}${raw.substring(1)}' : 'Ocurrió un error inesperado.';
  }

  @override
  Widget build(BuildContext context) {
    final text = _friendly(message);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _B.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _B.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _B.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded, size: 14, color: _B.error),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se pudo iniciar sesión',
                  style: TextStyle(
                    color: _B.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: _B.error.withValues(alpha: 0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
