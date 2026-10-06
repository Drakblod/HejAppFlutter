import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../models/rating_models.dart';

class RatingRepository {
  Future<Map<String, dynamic>> call(
    String groupId,
    String action, [
    Map<String, dynamic> data = const {},
  ]) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable(
          'customRating',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
        )
        .call({
          'groupId': groupId,
          'moduleId': 'main',
          'action': action,
          ...data,
        });
    return ratingMap(result.data);
  }

  Future<RatingArchive> load(String groupId) async =>
      RatingArchive.fromJson(await call(groupId, 'get'));
}

final ratingRepositoryProvider = Provider((ref) => RatingRepository());
final ratingArchiveProvider = FutureProvider.autoDispose
    .family<RatingArchive, String>((ref, groupId) {
      ref.watch(authStateChangesProvider);
      return ref.watch(ratingRepositoryProvider).load(groupId);
    });

String ratingError(Object error) => error is FirebaseFunctionsException
    ? error.message ?? 'Kunde inte spara. Försök igen.'
    : 'Kunde inte ansluta. Kontrollera anslutningen och försök igen.';
