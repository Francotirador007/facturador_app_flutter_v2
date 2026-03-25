import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../app_constants.dart';
import '../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════════════════
// BUSCAR CLIENTE
// ══════════════════════════════════════════════════════════════════════════
class BuscarClienteScreen extends StatefulWidget {
  const BuscarClienteScreen({super.key});
  @override State<BuscarClienteScreen> createState() => _BuscarClienteState();
}

class _BuscarClienteState extends State<BuscarClienteScreen> {
  final _buscarCtrl = TextEditingController();
  List<Cliente> _clientes = [];
  bool _cargando = false;

  Future<void> _buscar([String? q]) async {
    setState(() => _cargando = true);
    try {
      final r = await ApiService.listarClientes(buscar: q ?? _buscarCtrl.text);
      final lista = (r['data']?['data'] as List? ?? r['data'] as List? ?? [])
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _clientes = lista; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  @override
  void initState() { super.initState(); _buscar(''); }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Seleccionar cliente', style: TextStyle(
          color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
    ),
    body: Column(children: [
      Container(color: Colors.white, padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _buscarCtrl,
            onSubmitted: _buscar,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, RUC o DNI...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[50],
            ),
          )),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () => _buscar(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Buscar')),
        ]),
      ),
      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _clientes.length,
            itemBuilder: (_, i) {
              final c = _clientes[i];
              return ListTile(
                onTap: () => Navigator.pop(ctx, c),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(c.nombre.isNotEmpty ? c.nombre[0] : '?',
                        style: const TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w700))),
                title: Text(c.nombre, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${c.tipoDoc == '6' ? 'RUC' : 'DNI'}: ${c.documento}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              );
            },
          ),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// BUSCAR PRODUCTO
// ══════════════════════════════════════════════════════════════════════════
class BuscarProductoScreen extends StatefulWidget {
  const BuscarProductoScreen({super.key});
  @override State<BuscarProductoScreen> createState() => _BuscarProductoState();
}

class _BuscarProductoState extends State<BuscarProductoScreen> {
  final _buscarCtrl = TextEditingController();
  List<Producto> _productos = [];
  bool _cargando = false;

  Future<void> _buscar([String? q]) async {
    setState(() => _cargando = true);
    try {
      final r = await ApiService.listarProductos(buscar: q ?? _buscarCtrl.text);
      final lista = (r['data']?['data'] as List? ?? r['data'] as List? ?? [])
          .map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _productos = lista; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  @override
  void initState() { super.initState(); _buscar(''); }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Seleccionar producto', style: TextStyle(
          color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
    ),
    body: Column(children: [
      Container(color: Colors.white, padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _buscarCtrl,
            onSubmitted: _buscar,
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[50],
            ),
          )),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () => _buscar(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Buscar')),
        ]),
      ),
      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _productos.length,
            itemBuilder: (_, i) {
              final p = _productos[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  onTap: () => Navigator.pop(ctx, p),
                  leading: Container(width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 22)),
                  title: Text(p.nombre, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('Cód: ${p.codigo}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  trailing: Text('S/ ${p.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800,
                          color: AppColors.primary, fontSize: 14)),
                ),
              );
            },
          ),
      ),
    ]),
  );
}
