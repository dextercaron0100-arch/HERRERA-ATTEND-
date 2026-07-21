import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

const geoNavy = Color(0xff031635);
const geoBackground = Color(0xfff6faff);
const geoText = Color(0xff141d23);
const geoMuted = Color(0xff5c5f60);

class GeoAttendMark extends StatelessWidget {
  const GeoAttendMark({super.key, this.size = 104, this.rounded = false});
  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(rounded ? 24 : size / 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x18031635), blurRadius: 24, offset: Offset(0, 8))
          ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.location_on_rounded, size: size * .62, color: geoNavy),
          Positioned(
            top: size * .26,
            child: Container(
              width: size * .18,
              height: size * .18,
              decoration: const BoxDecoration(
                  color: Color(0xff83fc8e), shape: BoxShape.circle),
              child:
                  Icon(Icons.check_rounded, size: size * .13, color: geoNavy),
            ),
          ),
        ]),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen(
      {super.key,
      required this.onFinished,
      this.duration = const Duration(milliseconds: 1800)});
  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _timer = Timer(widget.duration, widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(children: [
            Center(
              child: FadeTransition(
                opacity: Tween(begin: .82, end: 1.0).animate(CurvedAnimation(
                    parent: _controller, curve: Curves.easeInOut)),
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  GeoAttendMark(size: 132),
                  SizedBox(height: 24),
                  Text('HERRERA ATTEND',
                      style: TextStyle(
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: geoNavy)),
                  SizedBox(height: 12),
                  Text('SMART ATTENDANCE.\nACCURATE PAYROLL.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          letterSpacing: 2.1,
                          fontWeight: FontWeight.w600,
                          color: geoMuted)),
                ]),
              ),
            ),
            const Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Center(
                    child: SizedBox.square(
                        dimension: 34,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: geoNavy)))),
          ]),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen(
      {super.key, required this.onLogin, required this.onBiometric});
  final Future<bool> Function(String username, String password, bool remember)
      onLogin;
  final Future<bool> Function() onBiometric;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;
  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1050))
      ..forward();
    _ambient = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _entrance.dispose();
    _ambient.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }
    final accepted =
        await widget.onLogin(_username.text.trim(), _password.text, _remember);
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      if (!accepted) {
        _error = 'Incorrect employee ID or password.';
        _shake.forward(from: 0);
      }
    });
  }

  Future<void> _biometricLogin() async {
    try {
      if (!await widget.onBiometric() && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Face or fingerprint login is unavailable. Sign in once and enroll biometrics in Android settings.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Biometric verification was cancelled or failed.')));
      }
    }
  }

  void _notConfigured(String feature) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '$feature will be available after identity-provider setup.')));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: geoBackground,
        body: Stack(children: [
          AnimatedBuilder(
              animation: _ambient,
              builder: (context, child) => Positioned(
                  top: -90 + (_ambient.value * 18),
                  right: -70 + (_ambient.value * 10),
                  child: Transform.scale(
                      scale: 1 + (_ambient.value * .06), child: child)),
              child: const _Glow(size: 260, color: Color(0x22364768))),
          AnimatedBuilder(
              animation: _ambient,
              builder: (context, child) => Positioned(
                  bottom: -80 + (_ambient.value * 13),
                  left: -80 + (_ambient.value * 16),
                  child: Transform.scale(
                      scale: 1.06 - (_ambient.value * .06), child: child)),
              child: const _Glow(size: 250, color: Color(0x2283fc8e))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) => Transform.translate(
                        offset: Offset(
                            math.sin(_shake.value * math.pi * 6) *
                                7 *
                                (1 - _shake.value),
                            0),
                        child: child),
                    child: Form(
                      key: _formKey,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                            parent: _entrance,
                            curve:
                                const Interval(0, .7, curve: Curves.easeOut)),
                        child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(0, .035),
                                  end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: _entrance,
                                  curve: Curves.easeOutCubic)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                    child: AnimatedBuilder(
                                        animation: _ambient,
                                        builder: (context, child) =>
                                            Transform.rotate(
                                                angle: (_ambient.value - .5) *
                                                    .025,
                                                child: Transform.scale(
                                                    scale: 1 +
                                                        _ambient.value * .035,
                                                    child: child)),
                                        child: const Hero(
                                            tag: 'geoattend-mark',
                                            child: GeoAttendMark(
                                                size: 92, rounded: true)))),
                                const SizedBox(height: 24),
                                const Text('HERRERA ATTEND',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        letterSpacing: 2.2,
                                        fontWeight: FontWeight.w800,
                                        color: geoNavy)),
                                const SizedBox(height: 10),
                                const Text('Welcome Back',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: geoText)),
                                const SizedBox(height: 7),
                                const Text('Secure access to your workspace',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14, color: geoMuted)),
                                const SizedBox(height: 20),
                                Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                        color: const Color(0xffecf5fe),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xffd8e2ff))),
                                    child: const Row(children: [
                                      Icon(Icons.science_outlined,
                                          size: 20, color: geoNavy),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: Text(
                                              'TEST LOGIN\nEmployee ID: EMP-001   Password: Herrera123!',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: geoNavy)))
                                    ])),
                                const SizedBox(height: 24),
                                _FieldLabel('EMPLOYEE ID OR EMAIL'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _username,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.username],
                                  decoration: const InputDecoration(
                                      prefixIcon:
                                          Icon(Icons.person_outline_rounded),
                                      hintText: 'Enter your ID or email'),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Enter your employee ID or email'
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                _FieldLabel('PASSWORD'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    hintText: 'Enter your password',
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter your password'
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    children: [
                                      InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () => setState(
                                              () => _remember = !_remember),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                    value: _remember,
                                                    onChanged: (value) =>
                                                        setState(() =>
                                                            _remember = value ??
                                                                false)),
                                                const Text('Remember device',
                                                    style: TextStyle(
                                                        color: geoMuted)),
                                              ])),
                                      TextButton(
                                          onPressed: () => _notConfigured(
                                              'Password recovery'),
                                          child:
                                              const Text('Forgot password?')),
                                    ]),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  switchInCurve: Curves.easeOutBack,
                                  transitionBuilder: (child, animation) =>
                                      SizeTransition(
                                          sizeFactor: animation,
                                          child: FadeTransition(
                                              opacity: animation,
                                              child: child)),
                                  child: _error == null
                                      ? const SizedBox.shrink(
                                          key: ValueKey('empty'))
                                      : Container(
                                          key: ValueKey(_error),
                                          margin: const EdgeInsets.only(top: 5),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 9),
                                          decoration: BoxDecoration(
                                              color: const Color(0xffffe8e5),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                    Icons.error_outline_rounded,
                                                    size: 17,
                                                    color: Color(0xffba1a1a)),
                                                const SizedBox(width: 7),
                                                Flexible(
                                                    child: Text(_error!,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                                0xff93000a))))
                                              ])),
                                ),
                                const SizedBox(height: 16),
                                AnimatedScale(
                                  scale: _submitting ? .985 : 1,
                                  duration: const Duration(milliseconds: 180),
                                  child: FilledButton(
                                    onPressed: _submitting ? null : _login,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                              opacity: animation,
                                              child: ScaleTransition(
                                                  scale: Tween(
                                                          begin: .86, end: 1.0)
                                                      .animate(animation),
                                                  child: child)),
                                      child: _submitting
                                          ? const Row(
                                              key: ValueKey('loading'),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                  SizedBox.square(
                                                      dimension: 19,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2.3,
                                                              color: Colors
                                                                  .white)),
                                                  SizedBox(width: 10),
                                                  Text('Signing in...'),
                                                ])
                                          : const Row(
                                              key: ValueKey('login'),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                  Text('Login'),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 19),
                                                ]),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Row(children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 14),
                                      child: Text('OR',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: geoMuted))),
                                  Expanded(child: Divider())
                                ]),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xffd8e2ff))),
                                  child: Column(children: [
                                    OutlinedButton.icon(
                                        onPressed: _biometricLogin,
                                        icon: const Icon(
                                            Icons.face_retouching_natural),
                                        label: const Text(
                                            'Face / Biometric Login')),
                                    const Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(12, 0, 12, 9),
                                      child: Text(
                                          'Uses your enrolled face or fingerprint. Sign in with your password once before first use.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: geoMuted,
                                              fontSize: 11,
                                              height: 1.35)),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 24),
                                TextButton.icon(
                                    onPressed: () =>
                                        _notConfigured('Help and support'),
                                    icon: const Icon(Icons.help_outline_rounded,
                                        size: 19),
                                    label: const Text('Help and Support')),
                              ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          letterSpacing: .7,
          fontWeight: FontWeight.w700,
          color: Color(0xff44474e)));
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
