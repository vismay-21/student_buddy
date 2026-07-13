import 'package:dio/dio.dart';
import 'package:student_buddy/core/network/base_api.dart';
import 'package:student_buddy/core/network/api_constants.dart';
import 'package:student_buddy/core/exceptions/sync_exceptions.dart';

/// Calls the backend endpoint that idempotently creates the user's workspace.
/// This is called once after sign-in/sign-up to provision the users table row
/// and their default app_settings.
class UserApi extends BaseApi {
  Future<void> initializeUser({String? token}) async {
    Options? options;
    if (token != null) {
      options = Options(headers: {'Authorization': 'Bearer $token'});
    }
    await dio.post('/users/me/initialize', options: options);
  }

  Future<Map<String, dynamic>> getBootstrapData({String? token}) async {
    Options? options;
    if (token != null) {
      options = Options(headers: {'Authorization': 'Bearer $token'});
    }
    final response = await dio.get('/users/me/bootstrap', options: options);
    // The response is formatted as ApiResponse, where the actual data resides inside the 'data' key.
    // BaseApi does not parse raw maps automatically unless we do it or extract it.
    // Let's get the raw response data map and return the 'data' payload.
    final responseData = response.data as Map<String, dynamic>;
    if (responseData['success'] == true) {
      final serverVersion = responseData['sync_version'] as int?;
      if (serverVersion == null ||
          serverVersion < ApiConstants.minSupportedSyncVersion ||
          serverVersion > ApiConstants.maxSupportedSyncVersion) {
        print('Synchronization aborted.');
        print('Client protocol version : ${ApiConstants.minSupportedSyncVersion}-${ApiConstants.maxSupportedSyncVersion}');
        print('Server protocol version : $serverVersion');
        throw UnsupportedSyncProtocolException(
          minExpectedVersion: ApiConstants.minSupportedSyncVersion,
          maxExpectedVersion: ApiConstants.maxSupportedSyncVersion,
          receivedVersion: serverVersion,
        );
      }
      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception(responseData['message'] ?? 'Failed to retrieve bootstrap data.');
    }
  }
}
