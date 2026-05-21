import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/navigation/navigation_helper.dart';
import '../../../../core/utill/toasts.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _repository = AuthRepository();

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      final credential = await _repository.signInWithGoogle();
      if (credential != null) {
        NavigationHelper.toTasks();
      }
    } catch (e) {
      AppToast.showError('Login failed', description: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      NavigationHelper.toLogin();
    } catch (e) {
      AppToast.showError('Logout failed', description: e.toString());
    }
  }
}
