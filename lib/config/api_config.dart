class ApiConfig {
  // Ganti dengan IP Server FastAPI Anda. Jangan gunakan localhost/127.0.0.1 di mobile device.
  static const String baseUrl = 'http://10.168.60.41:8000'; 
  
  // ID perangkat harus statis sementara ini, nantinya dinamis dari login/pilihan kandang
  static const String deviceId = 'KANDANG_01'; 
}