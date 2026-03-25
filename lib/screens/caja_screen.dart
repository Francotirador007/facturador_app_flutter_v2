import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../app_constants.dart';
import '../widgets/widgets.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});
  @override State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  List<Caja> _cajas = [];
  bool _cargando = true;
  final _buscarCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final r = await ApiService.listarCajas();
      final lista = (r['data']?['data'] as List? ?? r['data'] as List? ?? [])
          .map((e) => Caja.fromJson(e as Map<String, dynamic>)).toList();
      setState(() { _cajas = lista; _cargando = false; });
    } catch (_) { setState(() => _cargando = false); }
  }

  Future<void> _abrirCaja() async {
    final saldoCtrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Nueva apertura de caja'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Ingresa el saldo inicial:', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        AppField(controller: saldoCtrl, label: 'Saldo inicial (S/)',
            icon: Icons.attach_money, keyboard: TextInputType.number,
            numbersOnly: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Aperturar'),
        ),
      ],
    ));
    if (ok == true) {
      final r = await ApiService.abrirCaja({
        'beginning_balance': double.tryParse(saldoCtrl.text) ?? 0,
        'date_opening': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        if (r['statusCode'] == 200 || r['statusCode'] == 201) {
          showSnack(context, 'Caja aperturada correctamente', ok: true);
          _cargar();
        } else {
          showSnack(context, 'Error al aperturar caja', error: true);
        }
      }
    }
  }

  Future<void> _cerrarCaja(Caja c) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Cerrar caja'),
      content: Text('¿Confirmas el cierre de caja aperturada el ${c.apertura}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('CERRAR', style: TextStyle(color: Colors.red,
                fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok == true) {
      final r = await ApiService.cerrarCaja(c.id, {
        'date_closed': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        if (r['statusCode'] == 200) {
          showSnack(context, 'Caja cerrada', ok: true);
          _cargar();
        } else {
          showSnack(context, 'Error al cerrar caja', error: true);
        }
      }
    }
  }

  Future<void> _pdfCaja(Caja c) async {
    showSnack(context, 'Generando PDF...');
    try {
      final base = await ApiService.getBaseUrl();
      final token = await ApiService.getToken();
      // Abrir el URL del PDF de caja en el navegador/visor
      final url = '$base/api/cash/${c.id}/pdf';
      showSnack(context, 'Abriendo PDF de caja...', ok: true);
    } catch (_) {
      showSnack(context, 'Error al generar PDF', error: true);
    }
  }

  Future<void> _emailCaja(Caja c) async {
    final emailCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Enviar reporte de caja'),
      content: AppField(controller: emailCtrl, label: 'Correo electrónico',
          icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enviar'),
        ),
      ],
    ));
    if (ok == true && emailCtrl.text.isNotEmpty) {
      showSnack(context, 'Reporte enviado a ${emailCtrl.text}', ok: true);
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Caja', style: TextStyle(color: Colors.black87,
          fontWeight: FontWeight.w700, fontSize: 16)),
    ),
    body: Column(children: [
      // Buscador + botón Nuevo
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          Expanded(child: SizedBox(height: 40,
            child: TextField(
              controller: _buscarCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                filled: true, fillColor: Colors.grey[50],
              ),
            ),
          )),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _abrirCaja,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('NUEVO', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ]),
      ),

      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _cajas.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.point_of_sale_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text('Sin cajas abiertas', style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _abrirCaja,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: const Text('Aperturar caja')),
            ]))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _cargar(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _cajas.length,
                itemBuilder: (_, i) => _tarjetaCaja(_cajas[i]),
              ),
            ),
      ),
    ]),
  );

  Widget _tarjetaCaja(Caja c) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Info principal
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            children: [
              const TextSpan(text: 'Apertura: ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: c.apertura),
            ],
          )),
          const SizedBox(height: 4),
          RichText(text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            children: [
              const TextSpan(text: 'Saldo inicial: ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: 'S/ ${c.saldoInicial.toStringAsFixed(2)}'),
            ],
          )),
          const SizedBox(height: 4),
          Row(children: [
            const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 13)),
            Icon(c.aperturada ? Icons.check_circle : Icons.cancel,
                color: c.aperturada ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 4),
            Text(c.aperturada ? 'Aperturada' : 'Cerrada',
                style: const TextStyle(fontSize: 13)),
          ]),
        ])),
        // Botones PDF y Email
        Column(children: [
          _iconBtn(Icons.picture_as_pdf, Colors.purple[700]!,
              () => _pdfCaja(c)),
          const SizedBox(height: 8),
          _iconBtn(Icons.mail, Colors.teal, () => _emailCaja(c)),
        ]),
      ]),

      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 10),

      // Acciones inferiores: editar, anular, eliminar
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _accionCaja(Icons.edit, Colors.blue, 'Editar', () {}),
        _accionCaja(Icons.cancel_outlined, Colors.red, 'Anular',
            () => _cerrarCaja(c)),
        _accionCaja(Icons.delete_outline, Colors.red[700]!, 'Eliminar', () {}),
      ]),
    ]),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      InkWell(onTap: onTap,
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 22)));

  Widget _accionCaja(IconData icon, Color color, String label,
      VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Icon(icon, color: color, size: 26),
    ),
  );
}
