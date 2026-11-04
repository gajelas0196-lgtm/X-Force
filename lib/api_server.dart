class ApiServer {
  static final bool isProduction = true; // Ubah ke true biar pakai domain asli
  
  static final String _prodUrl = 'http://denisrealbaik.sumber.api138.smasnug.web.id:2512';
  static final String _devUrl = 'http://10.0.2.2:2512'; // Harus ada kalau mau pakai ternary

  static final String baseUrl = isProduction ? _prodUrl : _devUrl;
}