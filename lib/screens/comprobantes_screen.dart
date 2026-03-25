import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../app_constants.dart';
import '../widgets/widgets.dart';

class ComprobantesScreen extends StatefulWidget {
  final String? filtroEstado;
  const ComprobantesScreen({super.key, this.filtroEstado});
  @override State<ComprobantesScreen> createState() => _ComprobantesScreenState();
}

class _ComprobantesScreenState extends State<ComprobantesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  // Tabs: F...=Factura, Bole=Boleta, N...=NotaVenta, P...=Pedido,
  //       C...=Cotización, Co...=Compra, G.R...=GRRemitente, G.R.T=GRTransp
  final _tipos = ['01', '03', 'NV', 'PE', 'CO', '09', '31', 'todos'];
  final _tabLabels = ['F...', 'Bole', 'N...', 'P...', 'C...', 'Co...', 'G.R...', 'G.R.T...'];

  List<Comprobante> _items = [];
  bool _cargando = true;
  final _buscarCtrl = TextEditingController();
  int _pagina = 1;
  bool _hayMas = true;
  int _tabIdx = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tipos.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() { _tabIdx = _tab.index; });
        _cargar();
      }
    });
    _cargar();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _cargar({bool mas = false}) async {
    if (!mas) setState(() { _cargando = true; _pagina = 1; });
    final tipo = _tipos[_tabIdx];
    try {
      final r = await ApiService.listarComprobantes(
        page: _pagina,
        tipo: tipo == 'todos' ? null : tipo,
        buscar: _buscarCtrl.text.isNotEmpty ? _buscarCtrl.text : null,
        estado: widget.filtroEstado,
      );
      final lista = (r['data']?['data'] as List? ?? r['data'] as List? ?? [])
          .map((e) => Comprobante.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        if (mas) { _items.addAll(lista); } else { _items = lista; }
        _hayMas = lista.length >= 15;
        _cargando = false;
      });
    } catch (e) {
      setState(() { _cargando = false; });
      if (mounted) showSnack(context, 'Error al cargar', error: true);
    }
  }

  // ── ACCIONES ──────────────────────────────────────────────────────────────

  Future<void> _descargar(Comprobante c, {String fmt = 'a4'}) async {
    showSnack(context, 'Descargando PDF...');
    final ruta = await ApiService.descargarPdf(c.externalId, c.numeroCompleto, formato: fmt);
    if (ruta != null && mounted) {
      await OpenFilex.open(ruta);
    } else if (mounted) {
      showSnack(context, 'No se pudo descargar el PDF', error: true);
    }
  }

  Future<void> _compartir(Comprobante c) async {
    showSnack(context, 'Preparando PDF...');
    final ruta = await ApiService.descargarPdf(c.externalId, c.numeroCompleto);
    if (ruta != null && mounted) {
      await Share.shareXFiles([XFile(ruta)],
          text: '${c.tipoNombre} ${c.numeroCompleto} - ${c.clienteNombre}');
    }
  }

  Future<void> _whatsapp(Comprobante c) async {
    // Primero intentar el endpoint del sistema; si no, compartir el PDF
    final telCtrl = TextEditingController(text: c.clienteTelefono ?? '');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Row(children: [
        const Icon(Icons.message, color: AppColors.whatsapp),
        const SizedBox(width: 8),
        const Text('Enviar por WhatsApp'),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${c.numeroCompleto} · ${c.clienteNombre}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 14),
        TextField(
          controller: telCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Teléfono del cliente (51XXXXXXXXX)',
            prefixText: '+',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enviar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
    if (ok != true || telCtrl.text.isEmpty) return;

    // Descarga el PDF y abre WhatsApp
    showSnack(context, 'Preparando para WhatsApp...');
    final ruta = await ApiService.descargarPdf(c.externalId, c.numeroCompleto);
    if (ruta == null) { showSnack(context, 'Error al obtener PDF', error: true); return; }

    final numero = telCtrl.text.replaceAll(RegExp(r'\D'), '');
    final texto = Uri.encodeComponent(
        '${c.tipoNombre} ${c.numeroCompleto} · S/ ${c.total.toStringAsFixed(2)}');

    // Abrir WhatsApp
    final waUrl = Uri.parse('https://wa.me/$numero?text=$texto');
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      // También compartir el PDF por separado
      await Future.delayed(const Duration(seconds: 1));
      await Share.shareXFiles([XFile(ruta)],
          text: 'Adjunto ${c.tipoNombre} ${c.numeroCompleto}');
    } else {
      showSnack(context, 'WhatsApp no está instalado', error: true);
    }
  }

  Future<void> _email(Comprobante c) async {
    final emailCtrl = TextEditingController(text: c.clienteEmail ?? '');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Enviar por correo'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${c.numeroCompleto} · ${c.clienteNombre}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 14),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Correo del cliente',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enviar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
    if (ok == true && emailCtrl.text.isNotEmpty) {
      final r = await ApiService.enviarEmail(c.externalId, emailCtrl.text.trim());
      if (mounted) {
        if (r['statusCode'] == 200) {
          showSnack(context, '¡Correo enviado!', ok: true);
        } else {
          showSnack(context, 'Error al enviar correo', error: true);
        }
      }
    }
  }

  Future<void> _anular(Comprobante c) async {
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Anular comprobante'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${c.numeroCompleto} · ${c.clienteNombre}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(controller: motivoCtrl,
            decoration: InputDecoration(labelText: 'Motivo de anulación',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10))),
            maxLines: 2),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('ANULAR', style: TextStyle(color: Colors.red,
                fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok == true && motivoCtrl.text.isNotEmpty) {
      final r = await ApiService.anular(c.externalId, motivoCtrl.text);
      if (mounted) {
        if (r['statusCode'] == 200) {
          showSnack(context, 'Comprobante anulado', ok: true);
          _cargar();
        } else {
          showSnack(context, 'Error al anular', error: true);
        }
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      elevation: 0,
      title: const Text('Listado de comprobantes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600,
              fontSize: 16)),
      bottom: TabBar(
        controller: _tab,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.primary,
        indicator: BoxDecoration(color: AppColors.primary,
            borderRadius: BorderRadius.circular(6)),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: -4),
        tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
      ),
    ),
    body: Column(children: [
      // Buscador + filtro estado
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          Expanded(child: SizedBox(height: 40,
            child: TextField(
              controller: _buscarCtrl,
              onSubmitted: (_) => _cargar(),
              decoration: InputDecoration(
                hintText: 'Buscar...',
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
          // Filtro Todos / estado
          Container(height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: 'Todos',
              items: ['Todos', 'Aceptado', 'Pendiente', 'Anulado']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (_) => _cargar(),
            )),
          ),
        ]),
      ),

      // Lista
      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _items.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text('Sin comprobantes', style: TextStyle(color: Colors.grey[500])),
            ]))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _cargar(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length + (_hayMas ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _items.length) return _btnMas();
                  return _tarjeta(_items[i]);
                },
              ),
            ),
      ),
    ]),
  );

  Widget _tarjeta(Comprobante c) {
    Color estadoColor;
    switch (c.estadoNombre) {
      case 'Aceptado': estadoColor = Colors.green; break;
      case 'Rechazado': estadoColor = Colors.red; break;
      case 'Anulado': estadoColor = Colors.grey; break;
      default: estadoColor = Colors.grey[600]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabecera: nombre + número + estado
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.clienteNombre,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('RUC: ${c.clienteDoc}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(c.fecha, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(c.numeroCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: estadoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(c.estadoNombre,
                    style: TextStyle(color: estadoColor, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Text('Total: ${c.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ]),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Botones de acción — igual al app Android
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            AccionBtn(icon: Icons.print_outlined, label: 'Imprimir',
                color: Colors.purple, onTap: () => _descargar(c, fmt: '80mm')),
            AccionBtn(icon: Icons.search, label: 'Ver',
                color: AppColors.primary, onTap: () => _verDetalle(c)),
            AccionBtn(icon: Icons.download_outlined, label: 'Descargar',
                color: Colors.green, onTap: () => _descargar(c)),
            AccionBtn(icon: Icons.message, label: 'WhatsApp',
                color: AppColors.whatsapp, onTap: () => _whatsapp(c)),
            AccionBtn(icon: Icons.mail_outline, label: 'Email',
                color: Colors.purple[700]!, onTap: () => _email(c)),
          ]),
        ]),
      ),
    );
  }

  void _verDetalle(Comprobante c) {
    showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text('${c.tipoNombre} ${c.numeroCompleto}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              _badgeEstado(c),
            ]),
            const SizedBox(height: 14),
            _detalleRow('Cliente', c.clienteNombre),
            _detalleRow('Documento', c.clienteDoc),
            _detalleRow('Fecha', c.fecha),
            _detalleRow('Total', 'S/ ${c.total.toStringAsFixed(2)}'),
            if (c.clienteEmail != null) _detalleRow('Email', c.clienteEmail!),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Descargar PDF'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () { Navigator.pop(context); _descargar(c); },
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.message, color: AppColors.whatsapp, size: 18),
                label: const Text('WhatsApp',
                    style: TextStyle(color: AppColors.whatsapp)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.whatsapp),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () { Navigator.pop(context); _whatsapp(c); },
              )),
            ]),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity,
              child: TextButton(
                onPressed: () { Navigator.pop(context); _anular(c); },
                child: const Text('Anular comprobante',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ]),
        ));
  }

  Widget _badgeEstado(Comprobante c) {
    final color = c.estadoNombre == 'Aceptado' ? Colors.green
        : c.estadoNombre == 'Anulado' ? Colors.grey : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Text(c.estadoNombre, style: TextStyle(color: color,
          fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _detalleRow(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13))),
      Expanded(child: Text(valor,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );

  Widget _btnMas() => Center(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: OutlinedButton(
      onPressed: () { _pagina++; _cargar(mas: true); },
      style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary)),
      child: const Text('Cargar más',
          style: TextStyle(color: AppColors.primary)),
    ),
  ));
}
