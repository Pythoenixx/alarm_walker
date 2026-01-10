import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<UserProfile?> {
  final UserProfileRepository repository;

  ProfileCubit(this.repository) : super(null);

  Future<void> loadProfile(String userId) async {
    final profile = await repository.getProfile(userId);
    emit(
      profile ??
          UserProfile(
            userId: userId,
            name: '',
            language: 'en',
            theme: 'system',
          ),
    );
  }

  Future<void> updateProfile(UserProfile updated) async {
    await repository.saveProfile(updated);
    emit(updated);
  }
}
