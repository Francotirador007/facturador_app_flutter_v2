import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../app_constants.dart';
import '../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════
// CLIENTES
// ══════════════════════════════════════════════════════════════════════════
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _lista = [];
  bool _cargando = true;
  final _buscarCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final r = await ApiService.listarClientes(
          buscar: _buscarCtrl.text.isNotEmpty ? _buscarCtrl.text : null);
      final lista = (r['data']?['data'] as List? ?? r['data'] as List? ?? [])
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _lista = lista; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white, foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Clientes', style: TextStyle(color: Colors.black87,
          fontWeight: FontWeight.w700, fontSize: 16)),
    ),
    body: Column(children: [
      Container(color: Colors.white, padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: TextField(controller: _buscarCtrl,
            onSubmitted: (_) => _cargar(),
            decoration: InputDecoration(hintText: 'Buscar cliente...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[50]),
          )),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _cargar,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Buscar')),
        ]),
      ),
      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(color: AppColors.primary, onRefresh: () => _cargar(),
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _lista.length,
              itemBuilder: (_, i) {
                final c = _lista[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(c.nombre.isNotEmpty ? c.nombre[0] : '?',
                          style: const TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w700))),
                    title: Text(c.nombre, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c.tipoDoc == '6' ? 'RUC' : 'DNI'}: ${c.documento}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          if (c.email != null && c.email!.isNotEmpty)
                            Text(c.email!, style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                        ]),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// PRODUCTOS
// ══════════════════════════════════════════════════════════════════════════
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Producto> _lista = [];
  bool _cargando = true;
  final _buscarCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final r = await ApiService.listarProductos(
          buscar: _buscarCtrl.text.isNotEmpty ? _buscarCtrl.text : null);
      final lista = (r['data']?['data'] as List? ?? r['data'] as List? ?? [])
          .map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _lista = lista; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white, foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Productos', style: TextStyle(color: Colors.black87,
          fontWeight: FontWeight.w700, fontSize: 16)),
    ),
    body: Column(children: [
      Container(color: Colors.white, padding: const EdgeInsets.all(12),
        child: TextField(controller: _buscarCtrl, onSubmitted: (_) => _cargar(),
          decoration: InputDecoration(hintText: 'Buscar producto...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: IconButton(icon: const Icon(Icons.search),
                onPressed: _cargar),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true, fillColor: Colors.grey[50]),
        ),
      ),
      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(color: AppColors.primary, onRefresh: () => _cargar(),
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _lista.length,
              itemBuilder: (_, i) {
                final p = _lista[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Container(width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.primary, size: 24)),
                    title: Text(p.nombre, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Cód: ${p.codigo}  ·  ${p.unidad ?? 'NIU'}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    trailing: Text('S/ ${p.precio.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800,
                            color: AppColors.primary, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// REPORTES
// ══════════════════════════════════════════════════════════════════════════
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  Map<String, dynamic> _data = {};
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final r = await ApiService.getDashboard();
      setState(() { _data = r['data'] ?? {}; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white, foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Reportes', style: TextStyle(color: Colors.black87,
          fontWeight: FontWeight.w700, fontSize: 16)),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
    ),
    body: _cargando
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : RefreshIndicator(color: AppColors.primary, onRefresh: () => _cargar(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _tarjetaMetrica('Total facturado hoy',
                  'S/ ${_data['total_today'] ?? '0.00'}',
                  Icons.trending_up, AppColors.success),
              const SizedBox(height: 10),
              _tarjetaMetrica('Facturas emitidas hoy',
                  '${_data['invoices_today'] ?? 0}',
                  Icons.description_outlined, AppColors.primary),
              const SizedBox(height: 10),
              _tarjetaMetrica('Boletas emitidas hoy',
                  '${_data['notes_today'] ?? 0}',
                  Icons.receipt_outlined, Colors.teal),
              const SizedBox(height: 10),
              _tarjetaMetrica('Pendientes de envío',
                  '${_data['documents_pending_sending'] ?? 0}',
                  Icons.pending_outlined, AppColors.warning),
              const SizedBox(height: 10),
              _tarjetaMetrica('Total del mes',
                  'S/ ${_data['total_month'] ?? '0.00'}',
                  Icons.calendar_month, Colors.purple),
            ]),
          ),
        ),
  );

  Widget _tarjetaMetrica(String label, String valor,
      IconData icon, Color color) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 28)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
            color: color)),
      ])),
    ]),
  );
}
