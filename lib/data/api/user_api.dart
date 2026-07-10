import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

/// Calls the backend endpoint that idempotently creates the user's workspace.
/// This is called once after sign-in/sign-up to provision the users table row
/// and their default app_settings.
class UserApi {
  final _dio = DioClient().dio;

  Future<void> initializeUser({String? token}) async {
    Options? options;
    if (token != null) {
      options = Options(headers: {'Authorization': 'Bearer $token'});
    }
    await _dio.post('/users/me/initialize', options: options);
  }
}
