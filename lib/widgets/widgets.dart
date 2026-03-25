import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_constants.dart';

// ── Campo de texto estilizado ─────────────────────────────────────────────
class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;
  final String? hint;
  final bool numbersOnly;
  final void Function(String)? onChanged;

  const AppField({
    super.key, required this.controller, required this.label,
    this.icon, this.keyboard, this.obscure = false, this.suffix,
    this.maxLines = 1, this.hint, this.numbersOnly = false, this.onChanged,
  });

  @override
  Widget build(BuildContext ctx) => TextField(
    controller: controller,
    keyboardType: keyboard,
    obscureText: obscure,
    maxLines: maxLines,
    onChanged: onChanged,
    inputFormatters: numbersOnly
        ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
    ),
  );
}

// ── Dropdown estilizado ───────────────────────────────────────────────────
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String label;
  final void Function(T?) onChanged;
  final String Function(T) itemLabel;

  const AppDropdown({
    super.key, required this.value, required this.items,
    required this.label, required this.onChanged, required this.itemLabel,
  });

  @override
  Widget build(BuildContext ctx) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(itemLabel(e), style: const TextStyle(fontSize: 14)),
        )).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

// ── Botón acción de comprobante (PDF, Email, WhatsApp, etc.) ──────────────
class AccionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AccionBtn({
    super.key, required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Sección header ────────────────────────────────────────────────────────
class SeccionHeader extends StatelessWidget {
  final String titulo;
  final IconData icon;
  const SeccionHeader({super.key, required this.titulo, required this.icon});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 7),
      Text(titulo, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]),
  );
}

// ── Tarjeta de sección en formulario ─────────────────────────────────────
class FormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const FormCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext ctx) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding ?? const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

// ── Fila de totales ───────────────────────────────────────────────────────
class FilaTotal extends StatelessWidget {
  final String label;
  final String valor;
  final bool negrita;
  final Color? color;

  const FilaTotal({
    super.key, required this.label, required this.valor,
    this.negrita = false, this.color,
  });

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(
          fontWeight: negrita ? FontWeight.w700 : FontWeight.w400,
          fontSize: negrita ? 15 : 13,
          color: negrita ? Colors.black87 : Colors.grey[700])),
      Text(valor, style: TextStyle(
          fontWeight: negrita ? FontWeight.w800 : FontWeight.w500,
          fontSize: negrita ? 16 : 13,
          color: color ?? (negrita ? AppColors.primary : Colors.black87))),
    ]),
  );
}

// ── Snackbar helper ───────────────────────────────────────────────────────
void showSnack(BuildContext ctx, String msg,
    {bool error = false, bool ok = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(ok ? Icons.check_circle : (error ? Icons.error_outline : Icons.info_outline),
          color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg)),
    ]),
    backgroundColor: error ? AppColors.danger : (ok ? AppColors.success : AppColors.primary),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    duration: const Duration(seconds: 3),
  ));
}
