import 'package:first_app/PlatformClient/config.dart';
import 'package:redis/redis.dart';

class RedisService {
  late Command _cmd;
  late RedisConnection _connection;

  Future<void> connect() async {
    _connection = RedisConnection();

    // Lấy connection string từ Config
    String connectionString = Config.redisConnectionString;
    List<String> parts = connectionString.split(',');

    // Lấy host và port từ connection string
    String host = parts[0].split(':')[0];
    int port = int.parse(parts[0].split(':')[1]);

    try {
      _cmd = await _connection.connect(host, port);
      print("✅ Kết nối Redis thành công: $host:$port");
    } catch (e) {
      print("❌ Lỗi kết nối Redis: $e");
    }
  }
}