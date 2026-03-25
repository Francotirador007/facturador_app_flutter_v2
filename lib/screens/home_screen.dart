import 'package:flutter/material.dart';
import '../app_constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'comprobantes_screen.dart';
import 'nueva_factura_screen.dart';
import 'nueva_boleta_screen.dart';
import 'caja_screen.dart';
import 'clientes_screen.dart';
import 'productos_screen.dart';
import 'reportes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _empresa = 'Cargando...';
  int _pendientesEnvio = 0;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    try {
      final d = await ApiService.getDashboard();
      setState(() {
        _empresa = d['data']?['company']?['name'] ??
            d['data']?['establishment']?['description'] ?? '';
        _pendientesEnvio = d['data']?['documents_pending_sending'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Deseas salir de tu cuenta?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('CERRAR SESIÓN',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _ir(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        // ── Header con logo y menú ─────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.receipt_long,
                  color: AppColors.primary, size: 22)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary, size: 28),
              onPressed: _logout,
            ),
          ]),
        ),

        // ── Nombre empresa ────────────────────────────────────────────────
        if (_empresa.isNotEmpty)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(_empresa,
                style: const TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),

        // ── Grilla de módulos ─────────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Fila 1
            _grilla([
              _modulo(Icons.point_of_sale, 'POS',
                  () => _ir(const NuevaBoletaScreen(esPOS: true))),
              _modulo(Icons.description_outlined, 'Factura',
                  () => _ir(const NuevaFacturaScreen())),
              _modulo(Icons.receipt_outlined, 'Boleta',
                  () => _ir(const NuevaBoletaScreen())),
              _modulo(Icons.note_add_outlined, 'Nota de\nventa',
                  () => _ir(const NuevaBoletaScreen(tipoDoc: 'NV'))),
            ]),
            const SizedBox(height: 10),
            // Fila 2
            _grilla([
              _modulo(Icons.list_alt, 'Pedido',
                  () => _ir(const NuevaBoletaScreen(tipoDoc: 'PE'))),
              _modulo(Icons.request_quote_outlined, 'Cotización',
                  () => _ir(const NuevaBoletaScreen(tipoDoc: 'CO'))),
              _modulo(Icons.local_shipping_outlined, 'G.R.\nremitente',
                  () => showDialog(context: ctx, builder: (_) => _proximamente())),
              _modulo(Icons.drive_eta_outlined, 'G.R.\ntransportista',
                  () => showDialog(context: ctx, builder: (_) => _proximamente())),
            ]),
            const SizedBox(height: 10),
            // Fila 3
            _grilla([
              _modulo(Icons.format_list_bulleted, 'Listado',
                  () => _ir(const ComprobantesScreen())),
              _modulo(Icons.shopping_cart_outlined, 'Compra',
                  () => showDialog(context: ctx, builder: (_) => _proximamente())),
              _modulo(Icons.people_outline, 'Clientes',
                  () => _ir(const ClientesScreen())),
              _modulo(Icons.point_of_sale_outlined, 'Caja',
                  () => _ir(const CajaScreen())),
            ]),
            const SizedBox(height: 10),
            // Fila 4
            _grilla([
              _modulo(Icons.inventory_2_outlined, 'Productos',
                  () => _ir(const ProductosScreen())),
              _modulo(Icons.bar_chart, 'Reportes',
                  () => _ir(const ReportesScreen())),
              _modulo(Icons.qr_code_scanner, 'Validador',
                  () => showDialog(context: ctx, builder: (_) => _proximamente())),
              const SizedBox(width: 70), // espacio vacío
            ]),

            const SizedBox(height: 16),

            // ── Pendientes ──────────────────────────────────────────────
            _tarjetaPendiente(
                'Comprobantes pendiente de envío', _pendientesEnvio,
                () => _ir(ComprobantesScreen(filtroEstado: '11'))),
            const SizedBox(height: 6),
            _tarjetaPendiente('Comprobantes pendientes de rectificación', 0,
                () {}),

            const SizedBox(height: 16),

            // ── Configuración ───────────────────────────────────────────
            _itemConfig('Configuración de cuenta', Icons.settings_outlined,
                () {}),
            const SizedBox(height: 6),
            _itemConfig('Listado de productos con imagen',
                Icons.image_outlined, () {}),
            const SizedBox(height: 6),
            _itemConfig('Formato PDF (CPE)', Icons.picture_as_pdf_outlined,
                () {}),

            const SizedBox(height: 20),
            // Botón cerrar sesión
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0),
                child: const Text('CERRAR SESIÓN',
                    style: TextStyle(fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        )),
      ])),
    );
  }

  Widget _grilla(List<Widget> items) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: items,
  );

  Widget _modulo(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: SizedBox(width: 74, child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 28)),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w500, color: Color(0xFF444))),
          ],
        )),
      );

  Widget _tarjetaPendiente(String label, int count, VoidCallback onTap) =>
      InkWell(onTap: onTap, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 13))),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$count', style: const TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ));

  Widget _itemConfig(String label, IconData icon, VoidCallback onTap) =>
      InkWell(onTap: onTap, child: Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ));

  AlertDialog _proximamente() => AlertDialog(
    title: const Text('Próximamente'),
    content: const Text('Este módulo estará disponible en la siguiente versión.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: const Text('OK'))],
  );
}
