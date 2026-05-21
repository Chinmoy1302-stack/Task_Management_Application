import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/navigation/navigation_helper.dart';
import '../../../../core/utill/toasts.dart';
import '../../../../i18n/strings.g.dart';

class OnboardingController extends GetxController {
  // OTP State
  final RxString otp = ''.obs;

  // Profile State
  final RxString name = ''.obs;
  final RxString bio = ''.obs;
  final Rx<File?> profileImage = Rx<File?>(null);
  final RxString profileImageUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('name')) name.value = args['name'] ?? '';
      if (args.containsKey('photoUrl')) {
        profileImageUrl.value = args['photoUrl'] ?? '';
      }
    }
  }

  // Permissions State
  final RxBool cameraPermission = false.obs;
  final RxBool galleryPermission = false.obs;
  final RxBool locationPermission = false.obs;

  final isLoading = false.obs;

  // --- OTP Logic ---
  Future<void> verifyOtp(String enteredOtp) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2)); // Mock API delay

    if (enteredOtp == '1234') {
      // Onboarding flow removed - redirect to tasks
      NavigationHelper.toTasks();
    } else {
      AppToast.showError(t.onboarding.otp.invalidOtp);
    }
    isLoading.value = false;
  }

  // --- Profile Logic ---
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      profileImage.value = File(image.path);
    }
  }

  Future<void> saveProfile() async {
    if (name.value.isEmpty) {
      AppToast.showError(t.onboarding.profileCreation.enterName);
      return;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 2)); // Mock Save
    NavigationHelper.toTasks();
    isLoading.value = false;
  }

  // --- Permissions Logic ---
  Future<void> requestPermissions() async {
    // In a real app, use permission_handler here
    cameraPermission.value = true;
    galleryPermission.value = true;
    locationPermission.value = true;

    NavigationHelper.toTasks();
  }
}
