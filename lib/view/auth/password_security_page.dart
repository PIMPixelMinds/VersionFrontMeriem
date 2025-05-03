import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';

class PasswordSecurityPage extends StatefulWidget {
  const PasswordSecurityPage({super.key});

  @override
  _PasswordSecurityPageState createState() => _PasswordSecurityPageState();
}

class _PasswordSecurityPageState extends State<PasswordSecurityPage> {
  bool isPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = Provider.of<AuthViewModel>(context);

    String phoneStatus = (authViewModel.userProfile?['phone'] != null && authViewModel.userProfile!['phone'].toString().isNotEmpty)
        ? localizations.registered
        : localizations.notRegistered;

    String emailStatus = (authViewModel.userProfile?['email'] != null && authViewModel.userProfile!['email'].toString().isNotEmpty)
        ? localizations.registered
        : localizations.notRegistered;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.passwordSecurity,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSecurityOption(context, Icons.lock, localizations.changePassword, "PIN", () {
              _showChangePasswordDialog(context);
            }),
            _buildSecurityOption(context, Icons.phone, localizations.verifiedPhone, phoneStatus, _showUpdatePhoneDialog),
            _buildSecurityOption(context, Icons.email, localizations.verifiedEmail, emailStatus, _showUpdateEmailDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: isDarkMode ? 0 : 1,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
        title: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: subtitle == AppLocalizations.of(context)!.registered ? Colors.green : Colors.grey)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showUpdatePhoneDialog() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentPhone = authViewModel.userProfile?['phone']?.toString() ?? '';
    final localizations = AppLocalizations.of(context)!;

    TextEditingController phoneController = TextEditingController(text: currentPhone);

    _showBottomSheet(
      context,
      localizations.updatePhone,
      localizations.enterPhoneNumber,
      TextInputType.phone,
      () async {
        int? parsedPhone = int.tryParse(phoneController.text.trim());
        if (parsedPhone == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.invalidPhone)),
          );
          return;
        }
        await authViewModel.updateProfile(
          context: context,
          newPhone: parsedPhone,
        );
      },
      controller: phoneController,
    );
  }

  void _showUpdateEmailDialog() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentEmail = authViewModel.userProfile?['email'] ?? '';
    final localizations = AppLocalizations.of(context)!;

    TextEditingController emailController = TextEditingController(text: currentEmail);

    _showBottomSheet(
      context,
      localizations.updateEmail,
      localizations.enterEmail,
      TextInputType.emailAddress,
      () async {
        await authViewModel.updateProfile(
          context: context,
          newEmail: emailController.text,
        );
      },
      controller: emailController,
    );
  }

  void _showBottomSheet(BuildContext context, String title, String hint,
      TextInputType inputType, VoidCallback onSave,
      {required TextEditingController controller}) {
    bool isFormValid = false;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 10),
                  _buildTextField(hint, controller, () {
                    setState(() {
                      isFormValid = controller.text.isNotEmpty &&
                          (inputType == TextInputType.phone
                              ? RegExp(r'^\\+?[0-9]{7,15}\$').hasMatch(controller.text)
                              : RegExp(r'^[^@]+@[^@]+\\.[^@]+\$').hasMatch(controller.text));
                    });
                  }, inputType, isDarkMode),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isFormValid
                        ? () {
                            onSave();
                            Navigator.pop(context);
                          }
                        : null,
                    style: _buildButtonStyle(isDarkMode),
                    child: Text(AppLocalizations.of(context)!.save,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      VoidCallback validateForm, TextInputType keyboardType, bool isDarkMode) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (text) => validateForm(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  ButtonStyle _buildButtonStyle(bool isDarkMode) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.primaryBlue.withOpacity(0.7);
        }
        if (states.contains(WidgetState.pressed)) {
          return AppColors.primaryBlue.withOpacity(0.9);
        }
        return AppColors.primaryBlue;
      }),
      minimumSize: WidgetStateProperty.all<Size>(const Size(double.infinity, 50)),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  // Fonction pour afficher le changement de mot de passe avec l'icône "œil"
  void _showChangePasswordDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;

  TextEditingController passwordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPasswordController = TextEditingController();

  bool isFormValid = false;

  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  void validateForm() {
    setState(() {
      isFormValid = passwordController.text.isNotEmpty &&
          newPasswordController.text.isNotEmpty &&
          confirmNewPasswordController.text.isNotEmpty &&
          newPasswordController.text == confirmNewPasswordController.text &&
          newPasswordController.text.length >= 6;
    });
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.changePassword,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  localizations.currentPassword,
                  passwordController,
                  isPasswordVisible,
                  () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                  validateForm,
                ),
                _buildPasswordField(
                  localizations.newPassword,
                  newPasswordController,
                  isNewPasswordVisible,
                  () {
                    setState(() {
                      isNewPasswordVisible = !isNewPasswordVisible;
                    });
                  },
                  validateForm,
                ),
                _buildPasswordField(
                  localizations.confirmNewPassword,
                  confirmNewPasswordController,
                  isConfirmPasswordVisible,
                  () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                  validateForm,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isFormValid
                      ? () async {
                          final authViewModel = Provider.of<AuthViewModel>(
                              context,
                              listen: false);
                          await authViewModel.changePassword(
                            context: context,
                            oldPassword: passwordController.text,
                            newPassword: newPasswordController.text,
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    localizations.save,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    },
  );
}

// Widget pour afficher un champ de mot de passe avec l'icône "œil"
  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool isVisible,
      VoidCallback toggleVisibility,
      VoidCallback validateForm) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        onChanged: (text) => validateForm(),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
