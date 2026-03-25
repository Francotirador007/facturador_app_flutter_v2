// ── Colores principales (igual al app Android: azul royal) ──────────────────
import 'package:flutter/material.dart';

class AppColors {
  static const primary    = Color(0xFF2E3FC2);  // Azul royal de las capturas
  static const primaryDark= Color(0xFF1E2D9E);
  static const accent     = Color(0xFF00BCD4);
  static const success    = Color(0xFF4CAF50);
  static const warning    = Color(0xFFFF9800);
  static const danger     = Color(0xFFF44336);
  static const whatsapp   = Color(0xFF25D366);
  static const bg         = Color(0xFFF0F2F8);
  static const card       = Colors.white;
}

class AppConst {
  // ── Cambia esta URL por la de tu sistema ─────────────────────────────────
  static const baseUrl = 'https://demo.factura.tecnoredperu.pe';
  // ─────────────────────────────────────────────────────────────────────────

  static const tiposDoc = {
    '01': 'Factura',
    '03': 'Boleta',
    'NV': 'Nota de Venta',
    'PE': 'Pedido',
    'CO': 'Cotización',
    '09': 'G.R. Remitente',
    '31': 'G.R. Transportista',
    '07': 'Nota de Crédito',
    '08': 'Nota de Débito',
  };

  static const metodoPago = ['Efectivo', 'Tarjeta', 'Yape', 'Plin',
      'Transferencia', 'Cheque', 'Otro'];

  static const condicionPago = ['Contado', 'Crédito 7 días',
      'Crédito 15 días', 'Crédito 30 días'];
}
