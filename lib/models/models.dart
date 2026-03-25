// ══════════════════════════════════════════════════════════════════════════
// COMPROBANTE
// ══════════════════════════════════════════════════════════════════════════
class Comprobante {
  final String externalId;
  final String serie;
  final String numero;
  final String tipoDoc;
  final String fecha;
  final String clienteNombre;
  final String clienteDoc;
  final double total;
  final String estado;
  final String? urlPdf;
  final String? clienteEmail;
  final String? clienteTelefono;

  Comprobante({
    required this.externalId, required this.serie, required this.numero,
    required this.tipoDoc, required this.fecha, required this.clienteNombre,
    required this.clienteDoc, required this.total, required this.estado,
    this.urlPdf, this.clienteEmail, this.clienteTelefono,
  });

  factory Comprobante.fromJson(Map<String, dynamic> j) => Comprobante(
    externalId:     j['external_id']?.toString() ?? j['id']?.toString() ?? '',
    serie:          j['series'] ?? j['serie_documento'] ?? '',
    numero:         j['number']?.toString() ?? j['numero_documento']?.toString() ?? '',
    tipoDoc:        j['document_type_id']?.toString() ?? '01',
    fecha:          j['date_of_issue'] ?? j['fecha_de_emision'] ?? '',
    clienteNombre:  j['customer']?['name'] ??
                    j['datos_del_cliente']?['apellidos_y_nombres_o_razon_social'] ?? '',
    clienteDoc:     j['customer']?['number'] ?? j['datos_del_cliente']?['numero'] ?? '',
    total:          double.tryParse(j['total']?.toString() ?? '0') ?? 0,
    estado:         j['state_type_id']?.toString() ?? j['estado'] ?? '11',
    urlPdf:         j['links']?['pdf'] ?? j['enlace_del_pdf'],
    clienteEmail:   j['customer']?['email'],
    clienteTelefono: j['customer']?['telephone'],
  );

  String get numeroCompleto => '$serie-$numero';

  String get tipoNombre {
    const m = {'01':'Factura','03':'Boleta','07':'N. Crédito',
        '08':'N. Débito','NV':'N. Venta','PE':'Pedido','CO':'Cotización'};
    return m[tipoDoc] ?? 'Comprobante';
  }

  String get estadoNombre {
    const m = {'01':'Aceptado','03':'Enviado','05':'Aceptado','09':'Rechazado',
        '11':'Registrado','13':'Anulado'};
    return m[estado] ?? 'Pendiente';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ITEM DE COMPROBANTE
// ══════════════════════════════════════════════════════════════════════════
class ItemDoc {
  String codigo;
  String descripcion;
  double cantidad;
  double precioUnitario;
  bool igv;

  ItemDoc({
    required this.codigo, required this.descripcion,
    required this.cantidad, required this.precioUnitario, this.igv = true,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toJson() => {
    'unit_price': precioUnitario,
    'quantity': cantidad,
    'description': descripcion,
    'item_code': codigo,
    'total': subtotal,
    'affectation_igv_type_id': igv ? '10' : '30',
  };
}

// ══════════════════════════════════════════════════════════════════════════
// CLIENTE
// ══════════════════════════════════════════════════════════════════════════
class Cliente {
  final String id;
  final String nombre;
  final String documento;
  final String tipoDoc; // '1'=DNI, '6'=RUC
  final String? email;
  final String? telefono;
  final String? direccion;

  Cliente({
    required this.id, required this.nombre, required this.documento,
    required this.tipoDoc, this.email, this.telefono, this.direccion,
  });

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
    id:        j['id']?.toString() ?? '',
    nombre:    j['name'] ?? '',
    documento: j['number'] ?? '',
    tipoDoc:   j['identity_document_type_id']?.toString() ?? '1',
    email:     j['email'],
    telefono:  j['telephone'],
    direccion: j['address']?['address'] ?? j['address'],
  );
}

// ══════════════════════════════════════════════════════════════════════════
// PRODUCTO
// ══════════════════════════════════════════════════════════════════════════
class Producto {
  final String id;
  final String codigo;
  final String nombre;
  final double precio;
  final String? unidad;
  final String? imagen;

  Producto({
    required this.id, required this.codigo, required this.nombre,
    required this.precio, this.unidad, this.imagen,
  });

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
    id:     j['id']?.toString() ?? '',
    codigo: j['internal_id'] ?? j['item_code'] ?? '',
    nombre: j['description'] ?? j['name'] ?? '',
    precio: double.tryParse(j['sale_unit_price']?.toString() ??
            j['price']?.toString() ?? '0') ?? 0,
    unidad: j['unit_type_id'],
    imagen: j['image_url'],
  );
}

// ══════════════════════════════════════════════════════════════════════════
// CAJA
// ══════════════════════════════════════════════════════════════════════════
class Caja {
  final String id;
  final String apertura;
  final double saldoInicial;
  final String estado;

  Caja({required this.id, required this.apertura,
      required this.saldoInicial, required this.estado});

  factory Caja.fromJson(Map<String, dynamic> j) => Caja(
    id:           j['id']?.toString() ?? '',
    apertura:     j['opening'] ?? j['date_opening'] ?? '',
    saldoInicial: double.tryParse(j['beginning_balance']?.toString() ?? '0') ?? 0,
    estado:       j['state'] ?? j['status'] ?? 'aperturada',
  );

  bool get aperturada =>
      estado.toLowerCase().contains('aper') || estado == '01';
}
