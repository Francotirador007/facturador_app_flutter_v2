import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../app_constants.dart';
import '../widgets/widgets.dart';
import 'buscar_cliente_screen.dart';
import 'buscar_producto_screen.dart';

// ── NUEVA FACTURA ─────────────────────────────────────────────────────────
class NuevaFacturaScreen extends StatelessWidget {
  const NuevaFacturaScreen({super.key});
  @override
  Widget build(BuildContext ctx) => _FormComprobante(
    tipoDoc: '01', titulo: 'Factura Electrónica', tipoDocLabel: '6',
  );
}

// ── NUEVA BOLETA / NOTA DE VENTA / PEDIDO / COTIZACIÓN ───────────────────
class NuevaBoletaScreen extends StatelessWidget {
  final String tipoDoc;
  final bool esPOS;
  const NuevaBoletaScreen({
    super.key, this.tipoDoc = '03', this.esPOS = false,
  });

  @override
  Widget build(BuildContext ctx) {
    final titulos = {
      '03': 'Boleta Electrónica',
      'NV': 'Nota de Venta',
      'PE': 'Pedido',
      'CO': 'Cotización',
    };
    return _FormComprobante(
      tipoDoc: tipoDoc,
      titulo: esPOS ? 'POS Rápido' : (titulos[tipoDoc] ?? 'Boleta Electrónica'),
      tipoDocLabel: '1',
      esPOS: esPOS,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FORMULARIO GENÉRICO
// ══════════════════════════════════════════════════════════════════════════
class _FormComprobante extends StatefulWidget {
  final String tipoDoc;
  final String titulo;
  final String tipoDocLabel; // '6'=RUC, '1'=DNI
  final bool esPOS;

  const _FormComprobante({
    required this.tipoDoc, required this.titulo,
    required this.tipoDocLabel, this.esPOS = false,
  });

  @override
  State<_FormComprobante> createState() => _FormComprobanteState();
}

class _FormComprobanteState extends State<_FormComprobante> {
  // ── Cabecera ─────────────────────────────────────────────────────────────
  String _serie = '';
  List<String> _series = [];
  DateTime _fechaEmision = DateTime.now();
  DateTime _fechaVencimiento = DateTime.now();
  String _condPago = AppConst.condicionPago[0];
  String _metodoPago = AppConst.metodoPago[0];
  final _ordenCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _montoCtrl = TextEditingController(text: '0');
  String _destino = 'CAJA GENERAL';

  // ── Cliente ──────────────────────────────────────────────────────────────
  Cliente? _cliente;
  bool _clienteFinal = false;

  // ── Items ────────────────────────────────────────────────────────────────
  final List<ItemDoc> _items = [];

  // ── Estado ───────────────────────────────────────────────────────────────
  bool _enviando = false;
  String? _resultado;
  bool _okResult = false;

  @override
  void initState() {
    super.initState();
    _cargarSeries();
  }

  Future<void> _cargarSeries() async {
    try {
      final r = await ApiService.listarSeries(widget.tipoDoc);
      final lista = (r['data'] as List? ?? [])
          .map((e) => e['number']?.toString() ?? e['id']?.toString() ?? '')
          .where((s) => s.isNotEmpty).toList();
      setState(() {
        _series = lista.isNotEmpty ? lista : [widget.tipoDoc == '01' ? 'F001' : 'B001'];
        _serie = _series.first;
      });
    } catch (_) {
      _series = [widget.tipoDoc == '01' ? 'F001' : 'B001'];
      _serie = _series.first;
    }
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _igv => _subtotal * 0.18;
  double get _total => _subtotal + _igv;

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<void> _selFecha(bool esEmision) async {
    final d = await showDatePicker(
      context: context,
      initialDate: esEmision ? _fechaEmision : _fechaVencimiento,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (d != null) setState(() {
      if (esEmision) _fechaEmision = d; else _fechaVencimiento = d;
    });
  }

  Future<void> _selCliente() async {
    final c = await Navigator.push<Cliente>(context,
        MaterialPageRoute(builder: (_) => const BuscarClienteScreen()));
    if (c != null) setState(() => _cliente = c);
  }

  Future<void> _agregarProducto() async {
    final p = await Navigator.push<Producto>(context,
        MaterialPageRoute(builder: (_) => const BuscarProductoScreen()));
    if (p != null) {
      // Diálogo para cantidad
      final cantCtrl = TextEditingController(text: '1');
      final precioCtrl = TextEditingController(
          text: p.precio.toStringAsFixed(2));
      await showDialog(context: context, builder: (_) => AlertDialog(
        title: Text(p.nombre, style: const TextStyle(fontSize: 14)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          AppField(controller: cantCtrl, label: 'Cantidad',
              keyboard: TextInputType.number, numbersOnly: true),
          const SizedBox(height: 10),
          AppField(controller: precioCtrl, label: 'Precio unitario (S/)',
              keyboard: TextInputType.number, numbersOnly: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () {
              final cant = double.tryParse(cantCtrl.text) ?? 1;
              final precio = double.tryParse(precioCtrl.text) ?? p.precio;
              setState(() => _items.add(ItemDoc(
                codigo: p.codigo, descripcion: p.nombre,
                cantidad: cant, precioUnitario: precio,
              )));
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ));
    }
  }

  Future<void> _emitir() async {
    if (_cliente == null && !_clienteFinal) {
      showSnack(context, 'Selecciona un cliente', error: true); return;
    }
    if (_items.isEmpty) {
      showSnack(context, 'Agrega al menos un producto', error: true); return;
    }
    setState(() { _enviando = true; _resultado = null; });

    final datos = {
      'series_id': _serie,
      'document_type_id': widget.tipoDoc,
      'date_of_issue': DateFormat('yyyy-MM-dd').format(_fechaEmision),
      'time_of_issue': DateFormat('HH:mm:ss').format(_fechaEmision),
      'date_of_due': DateFormat('yyyy-MM-dd').format(_fechaVencimiento),
      'payment_condition': _condPago,
      'payment_method': _metodoPago,
      'purchase_order': _ordenCtrl.text,
      'reference': _referenciaCtrl.text,
      'cash_destination': _destino,
      'currency_type_id': 'PEN',
      'customer': _clienteFinal ? {
        'identity_document_type_id': '0',
        'number': '00000000',
        'name': 'Clientes varios',
      } : {
        'identity_document_type_id': _cliente!.tipoDoc,
        'number': _cliente!.documento,
        'name': _cliente!.nombre,
        'email': _cliente!.email ?? '',
        'telephone': _cliente!.telefono ?? '',
        'address': {'address': _cliente!.direccion ?? ''},
      },
      'items': _items.map((i) => i.toJson()).toList(),
      'legends': [{'code': '1000', 'value': 'SON ${_total.toStringAsFixed(2)} SOLES'}],
    };

    try {
      Map<String, dynamic> res;
      switch (widget.tipoDoc) {
        case '01': res = await ApiService.emitirFactura(datos); break;
        case 'PE': res = await ApiService.emitirPedido(datos); break;
        case 'CO': res = await ApiService.emitirCotizacion(datos); break;
        default:   res = await ApiService.emitirBoleta(datos);
      }
      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        final num = res['data']?['data']?['number'] ??
            res['data']?['number'] ?? '';
        setState(() {
          _resultado = '✅ ${widget.titulo} emitida: $_serie-$num';
          _okResult = true;
          _items.clear();
          _cliente = null;
          _clienteFinal = false;
          _ordenCtrl.clear();
          _referenciaCtrl.clear();
          _montoCtrl.text = '0';
        });
      } else {
        setState(() {
          _resultado = res['data']?['message'] ??
              res['data']?['errors']?.toString() ?? 'Error al emitir';
          _okResult = false;
        });
      }
    } catch (e) {
      setState(() { _resultado = 'Error de conexión: $e'; _okResult = false; });
    }
    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 0,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.titulo, style: const TextStyle(color: Colors.black87,
            fontWeight: FontWeight.w700, fontSize: 15)),
        // Nombre empresa (placeholder)
        const Text('20600340132 - INVERSIONES VERCINTH...',
            style: TextStyle(color: AppColors.primary, fontSize: 11),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── CABECERA DEL COMPROBANTE ────────────────────────────────────
        FormCard(child: Column(children: [
          Row(children: [
            // Serie
            Expanded(child: _series.isEmpty
              ? AppField(controller: TextEditingController(text: _serie),
                  label: 'Serie')
              : AppDropdown<String>(
                  value: _serie,
                  items: _series,
                  label: 'Serie',
                  onChanged: (v) => setState(() => _serie = v ?? _serie),
                  itemLabel: (s) => s,
                )),
            const SizedBox(width: 10),
            // Fecha emisión
            Expanded(child: InkWell(
              onTap: () => _selFecha(true),
              child: InputDecorator(
                decoration: InputDecoration(labelText: 'Fecha Emisión',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13)),
                child: Text(_fmt(_fechaEmision),
                    style: const TextStyle(fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AppField(controller: _ordenCtrl,
                label: 'Orden de Compra')),
            const SizedBox(width: 10),
            Expanded(child: InkWell(
              onTap: () => _selFecha(false),
              child: InputDecorator(
                decoration: InputDecoration(labelText: 'Fecha Vencimiento',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13)),
                child: Text(_fmt(_fechaVencimiento),
                    style: const TextStyle(fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AppDropdown<String>(
                value: _condPago, items: AppConst.condicionPago,
                label: 'Condición de pago',
                onChanged: (v) => setState(() => _condPago = v!),
                itemLabel: (s) => s)),
            const SizedBox(width: 10),
            Expanded(child: AppDropdown<String>(
                value: _metodoPago, items: AppConst.metodoPago,
                label: 'Metodo de pago',
                onChanged: (v) => setState(() => _metodoPago = v!),
                itemLabel: (s) => s)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AppField(controller: _referenciaCtrl,
                label: 'Referencia')),
            const SizedBox(width: 10),
            Expanded(child: AppField(controller: _montoCtrl,
                label: 'Monto a pagar', numbersOnly: true)),
          ]),
          const SizedBox(height: 10),
          AppDropdown<String>(
            value: _destino,
            items: ['CAJA GENERAL', 'CAJA CHICA', 'BANCO'],
            label: 'Destino',
            onChanged: (v) => setState(() => _destino = v!),
            itemLabel: (s) => s,
          ),
        ])),

        // ── CLIENTE ─────────────────────────────────────────────────────
        FormCard(padding: EdgeInsets.zero, child: Column(children: [
          // Si es boleta, opción "cliente final"
          if (widget.tipoDocLabel == '1')
            SwitchListTile(
              value: _clienteFinal,
              onChanged: (v) => setState(() { _clienteFinal = v; _cliente = null; }),
              title: const Text('Consumidor final', style: TextStyle(fontSize: 13)),
              activeColor: AppColors.primary,
              dense: true,
            ),
          if (!_clienteFinal)
            ListTile(
              onTap: _selCliente,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              title: Text(
                _cliente == null ? 'CLIENTE' : _cliente!.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: _cliente == null ? Colors.grey[700] : Colors.black87,
                ),
              ),
              subtitle: _cliente != null
                  ? Text(_cliente!.documento,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12))
                  : null,
              trailing: const Icon(Icons.arrow_forward, color: AppColors.primary),
            ),
        ])),

        // ── PRODUCTOS ────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2))]),
          child: Column(children: [
            // Cabecera tabla
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(children: const [
                SizedBox(width: 28, child: Text('#', style: TextStyle(
                    color: Colors.grey, fontSize: 12))),
                Expanded(child: Text('Descripción', style: TextStyle(
                    color: Colors.grey, fontSize: 12))),
                SizedBox(width: 60, child: Text('Cantidad',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey, fontSize: 12))),
                SizedBox(width: 70, child: Text('Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey, fontSize: 12))),
              ]),
            ),
            const Divider(),
            // Filas de items
            ..._items.asMap().entries.map((e) => _filaItem(e.key, e.value)),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin productos', style: TextStyle(color: Colors.grey[400])),
              ),
          ]),
        ),

        const SizedBox(height: 10),

        // Botón + AÑADIR PRODUCTO
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _agregarProducto,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('+ AÑADIR PRODUCTO',
                style: TextStyle(fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),

        // ── TOTALES ───────────────────────────────────────────────────────
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 14),
          FormCard(child: Column(children: [
            FilaTotal(label: 'OP. GRAVADAS', valor: 'S/ ${_subtotal.toStringAsFixed(2)}'),
            FilaTotal(label: 'IGV (18%)', valor: 'S/ ${_igv.toStringAsFixed(2)}'),
            const Divider(height: 16),
            FilaTotal(label: 'TOTAL A PAGAR',
                valor: 'S/ ${_total.toStringAsFixed(2)}',
                negrita: true, color: AppColors.primary),
          ])),
        ],

        // ── RESULTADO ─────────────────────────────────────────────────────
        if (_resultado != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _okResult ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _okResult ? Colors.green[200]! : Colors.red[200]!),
            ),
            child: Text(_resultado!, style: TextStyle(
                color: _okResult ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],

        const SizedBox(height: 16),

        // ── BOTÓN EMITIR ──────────────────────────────────────────────────
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _enviando ? null : _emitir,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            child: _enviando
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('EMITIR ${widget.titulo.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800,
                        letterSpacing: 0.5, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 30),
      ]),
    ),
  );

  Widget _filaItem(int idx, ItemDoc item) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(children: [
      SizedBox(width: 28, child: Text('${idx + 1}',
          style: TextStyle(color: Colors.grey[500], fontSize: 12))),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.descripcion, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500)),
        Text('S/ ${item.precioUnitario.toStringAsFixed(2)} c/u',
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ])),
      SizedBox(width: 60, child: Text(item.cantidad.toStringAsFixed(
          item.cantidad % 1 == 0 ? 0 : 2),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13))),
      SizedBox(width: 70, child: Text('S/ ${item.subtotal.toStringAsFixed(2)}',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.primary))),
      IconButton(
        icon: const Icon(Icons.close, size: 18, color: Colors.red),
        onPressed: () => setState(() => _items.removeAt(idx)),
        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
      ),
    ]),
  );
}
