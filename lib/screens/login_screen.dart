import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlCtrl   = TextEditingController(text: AppConst.baseUrl);
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false, _verPass = false;
  String? _error;

  Future<void> _login() async {
    if (_urlCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await ApiService.setBaseUrl(_urlCtrl.text.trim());
    try {
      final r = await ApiService.login(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (r['statusCode'] == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        final msg = r['data']?['message'] ?? r['data']?['error'] ?? 'Credenciales incorrectas';
        setState(() => _error = msg.toString());
      }
    } catch (e) {
      setState(() => _error = 'Error de conexión. Verifica la URL.');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        // Logo
        Container(width: 90, height: 90,
          decoration: BoxDecoration(color: AppColors.primary,
              borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 48)),
        const SizedBox(height: 16),
        const Text('Facturador', style: TextStyle(fontSize: 26,
            fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const Text('TecnoRed Perú', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),

        // Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _field(_urlCtrl, 'URL del sistema', Icons.link,
                keyboard: TextInputType.url),
            const SizedBox(height: 14),
            _field(_emailCtrl, 'Correo electrónico', Icons.email_outlined,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 14),
            TextField(
              controller: _passCtrl,
              obscureText: !_verPass,
              onSubmitted: (_) => _login(),
              decoration: _deco('Contraseña', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('INGRESAR',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Facturación Electrónica SUNAT',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    ))),
  );

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard}) =>
      TextField(controller: c, keyboardType: keyboard,
          decoration: _deco(label, icon));

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    filled: true, fillColor: const Color(0xFFF9FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
  );
}
