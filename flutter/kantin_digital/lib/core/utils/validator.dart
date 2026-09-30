class Validator {
  static String? requiredText(String? v, {String label = 'Field'}) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? email(String? v) {
    final required = requiredText(v, label: 'Email');
    if (required != null) return required;
    final value = v!.trim();
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
    if (!ok) return 'Format email tidak valid';
    return null;
  }
}

