import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  // Try common regions to avoid NOT_FOUND when the project uses a non-default location.
  static const List<String> _regions = [
    'us-central1',
    'asia-southeast1',
    'europe-west1',
  ];

  Future<void> setUserRole({required String uid, required int role}) async {
    await _callWithRegionFallback(
      name: 'setUserRole',
      data: {'uid': uid, 'role': role},
    );
  }

  Future<void> deleteUserAccount({required String uid}) async {
    await _callWithRegionFallback(
      name: 'deleteUserAccount',
      data: {'uid': uid},
    );
  }

  Future<dynamic> _callWithRegionFallback({
    required String name,
    Map<String, dynamic>? data,
  }) async {
    FirebaseFunctionsException? lastNotFound;
    for (final region in _regions) {
      try {
        final fns = FirebaseFunctions.instanceFor(region: region);
        final res = await fns.httpsCallable(name).call(data ?? const {});
        return res.data;
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'not-found') {
          lastNotFound = e;
          continue; // try next region
        }
        rethrow; // other errors bubble up
      }
    }
    // If all regions failed with not-found, rethrow the last error.
    if (lastNotFound != null) throw lastNotFound;
    // Fallback catch-all (shouldn't hit):
    throw FirebaseFunctionsException(
        code: 'not-found',
        message: 'Callable $name not found in tried regions');
  }
}
