import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../app_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'api_token';
  static const _urlKey   = 'base_url';

  // ── URL dinámica (el usuario puede cambiarla desde login) ─────────────────
  static String _baseUrl = AppConst.baseUrl;

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    await _storage.write(key: _urlKey, value: _baseUrl);
  }

  static Future<String> getBaseUrl() async {
    final saved = await _storage.read(key: _urlKey);
    if (saved != null) _baseUrl = saved;
    return _baseUrl;
  }

  // ── Token ─────────────────────────────────────────────────────────────────
  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> saveToken(String t) => _storage.write(key: _tokenKey, value: t);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final t = await getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  // ── HELPER genérico ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    await getBaseUrl();
    final r = await http.post(Uri.parse('$_baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    return {'statusCode': r.statusCode, 'data': _decode(r.body)};
  }

  static Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? params]) async {
    await getBaseUrl();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    final r = await http.get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 30));
    return {'statusCode': r.statusCode, 'data': _decode(r.body)};
  }

  static dynamic _decode(String body) {
    try { return jsonDecode(body); } catch (_) { return body; }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> login(String email, String pass) async {
    await getBaseUrl();
    final r = await http.post(Uri.parse('$_baseUrl/api/login'),
        headers: await _headers(auth: false),
        body: jsonEncode({'email': email, 'password': pass}))
        .timeout(const Duration(seconds: 30));
    final data = _decode(r.body);
    if (r.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token'].toString());
    }
    return {'statusCode': r.statusCode, 'data': data};
  }

  static Future<void> logout() async {
    try { await _post('/api/logout', {}); } catch (_) {}
    await clearToken();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPROBANTES — LISTADO
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> listarComprobantes({
    int page = 1, String? tipo, String? buscar, String? estado,
  }) async {
    final p = <String, String>{'page': '$page'};
    if (tipo != null && tipo != 'todos') p['document_type_id'] = tipo;
    if (buscar != null && buscar.isNotEmpty) p['search'] = buscar;
    if (estado != null) p['state_type_id'] = estado;
    return _get('/api/documents', p);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMITIR DOCUMENTOS
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> emitirFactura(Map<String, dynamic> d) =>
      _post('/api/invoice', d);

  static Future<Map<String, dynamic>> emitirBoleta(Map<String, dynamic> d) =>
      _post('/api/sale-notes', d);

  static Future<Map<String, dynamic>> emitirNotaVenta(Map<String, dynamic> d) =>
      _post('/api/sale-notes', {...d, 'document_type_id': 'NV'});

  static Future<Map<String, dynamic>> emitirPedido(Map<String, dynamic> d) =>
      _post('/api/orders', d);

  static Future<Map<String, dynamic>> emitirCotizacion(Map<String, dynamic> d) =>
      _post('/api/quotations', d);

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIONES SOBRE COMPROBANTE
  // ══════════════════════════════════════════════════════════════════════════

  /// Enviar por correo
  static Future<Map<String, dynamic>> enviarEmail(
      String externalId, String email) =>
      _post('/api/send-email', {'external_id': externalId, 'customer_email': email});

  /// Enviar por WhatsApp — devuelve el link wa.me con el PDF adjunto
  static Future<Map<String, dynamic>> enviarWhatsapp(
      String externalId, String telefono) =>
      _post('/api/send-whatsapp', {'external_id': externalId, 'phone': telefono});

  /// Descargar PDF → devuelve ruta local del archivo
  static Future<String?> descargarPdf(String externalId, String nombre,
      {String formato = 'a4'}) async {
    await getBaseUrl();
    try {
      final headers = await _headers();
      // Algunos sistemas usan formato: a4, 80mm, 58mm
      final r = await http.get(
          Uri.parse('$_baseUrl/api/pdf/$externalId?format=$formato'),
          headers: headers)
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/$nombre.pdf');
        await f.writeAsBytes(r.bodyBytes);
        return f.path;
      }
      return null;
    } catch (_) { return null; }
  }

  /// Anular comprobante
  static Future<Map<String, dynamic>> anular(
      String externalId, String motivo) =>
      _post('/api/void', {'external_id': externalId, 'motivo_anulacion': motivo});

  // ══════════════════════════════════════════════════════════════════════════
  // CAJA
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> listarCajas() => _get('/api/cash');

  static Future<Map<String, dynamic>> abrirCaja(Map<String, dynamic> d) =>
      _post('/api/cash', d);

  static Future<Map<String, dynamic>> cerrarCaja(String id, Map<String, dynamic> d) =>
      _post('/api/cash/$id/close', d);

  static Future<Map<String, dynamic>> pdfCaja(String id) =>
      _get('/api/cash/$id/pdf');

  // ══════════════════════════════════════════════════════════════════════════
  // CLIENTES
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> listarClientes({String? buscar}) =>
      _get('/api/persons', buscar != null ? {'search': buscar} : null);

  static Future<Map<String, dynamic>> buscarCliente(String doc) =>
      _get('/api/persons', {'document': doc});

  static Future<Map<String, dynamic>> crearCliente(Map<String, dynamic> d) =>
      _post('/api/persons', d);

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCTOS
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> listarProductos({String? buscar}) =>
      _get('/api/items', buscar != null ? {'search': buscar} : null);

  // ══════════════════════════════════════════════════════════════════════════
  // SERIES DISPONIBLES
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> listarSeries(String tipoDoc) =>
      _get('/api/series', {'document_type_id': tipoDoc});

  // ══════════════════════════════════════════════════════════════════════════
  // REPORTES / DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getDashboard() => _get('/api/dashboard');

  static Future<Map<String, dynamic>> getReporteVentas({
    String? fechaInicio, String? fechaFin,
  }) => _get('/api/reports/sales', {
    if (fechaInicio != null) 'date_start': fechaInicio,
    if (fechaFin != null) 'date_end': fechaFin,
  });
}
