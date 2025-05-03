import 'package:flutter/material.dart';
import 'package:pim/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ Import des traductions

class ResetPasswordBottomSheet extends StatefulWidget {
  final String email;
  const ResetPasswordBottomSheet({super.key, required this.email});

  @override
  _ResetPasswordBottomSheetState createState() => _ResetPasswordBottomSheetState();
}

class _ResetPasswordBottomSheetState extends State<ResetPasswordBottomSheet> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isError = false;

  void _resetPassword(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      setState(() {
        isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseFillAllFields)),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.passwordsDoNotMatch)),
      );
      return;
    }

    try {
      await authViewModel.resetPassword(context, widget.email, newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.passwordResetSuccess)),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color inputFieldColor = isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;

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
          Text(localizations.resetPassword,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Champ New Password
          TextField(
            controller: newPasswordController,
            obscureText: !isPasswordVisible,
            decoration: InputDecoration(
              labelText: localizations.newPassword,
              filled: true,
              fillColor: inputFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Champ Confirm Password
          TextField(
            controller: confirmPasswordController,
            obscureText: !isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: localizations.confirmNewPassword,
              filled: true,
              fillColor: inputFieldColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
              ),
              errorText: isError ? localizations.passwordsDoNotMatch : null,
            ),
          ),
          const SizedBox(height: 20),

          // Bouton Reset Password
          ElevatedButton(
            onPressed: () => _resetPassword(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(localizations.resetPassword,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}