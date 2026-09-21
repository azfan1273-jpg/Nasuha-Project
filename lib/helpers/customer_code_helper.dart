class CustomerCodeHelper {
  /// Generate kode unik berbasis nama + nomor urut
  /// Contoh: "Bu Era" + 2180 → "ERA-2180"
  static String generate(String name, int sequenceNumber) {
    // 1. Bersihkan nama: hapus spasi, titik, petik, karakter non-huruf
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    
    // 2. Ambil 3 huruf terakhir (lebih representatif utk nama panjang)
    String prefix;
    if (cleanName.length >= 3) {
      prefix = cleanName.substring(cleanName.length - 3);
    } else {
      // Fallback jika nama < 3 huruf
      prefix = cleanName.padRight(3, 'X');
    }
    
    // 3. Format angka nota (4 digit)
    final codeNum = sequenceNumber.toString().padLeft(4, '0');
    
    return '$prefix-$codeNum';
  }
}
