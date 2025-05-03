import 'package:flutter/material.dart';
import 'package:pim/view/auth/firebase_auth_api.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'login_page.dart';
import 'terms_and_privacy_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.radio_button_checked,
                size: 60, color: AppColors.primaryBlue),
            const SizedBox(height: 20),
            Text(localizations.signUpToGetStarted,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            _buildTextField(localizations.fullName, localizations.enterFullName,
                fullnameController, false, isDarkMode),
            const SizedBox(height: 15),
            _buildTextField(
                localizations.emailLabel,
                localizations.enterYourEmail,
                emailController,
                false,
                isDarkMode),
            const SizedBox(height: 15),
            _buildTextField(
                localizations.passwordLabel,
                localizations.enterYourPassword,
                passwordController,
                true,
                isDarkMode),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value!;
                    });
                  },
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(localizations.agreeTo),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsAndPrivacyPage(
                                title: 'Terms and Conditions',
                                url:
                                    'https://www.freeprivacypolicy.com/live/23b52896-67fa-4345-a69a-5f9ecfefd4ff',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          localizations.termsAndPrivacy,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            authViewModel.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: isChecked
                        ? () async {
                            final fullName = fullnameController.text.trim();
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            await authViewModel.registerUser(
                                context, fullName, email, password);

                            final firebaseAuthApi = FirebaseAuthApi();
                            await firebaseAuthApi.initNotifications(fullName);
                          }
                        : null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.disabled)) {
                            return AppColors.primaryBlue.withOpacity(0.7);
                          }
                          if (states.contains(WidgetState.pressed)) {
                            return AppColors.primaryBlue.withOpacity(0.9);
                          }
                          return AppColors.primaryBlue;
                        },
                      ),
                      minimumSize: WidgetStateProperty.all<Size>(
                          const Size(double.infinity, 50)),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      overlayColor: WidgetStateProperty.all<Color>(
                        AppColors.primaryBlue.withOpacity(0.2),
                      ),
                      shadowColor:
                          WidgetStateProperty.all<Color>(Colors.transparent),
                    ),
                    child: Text(localizations.register,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.alreadyHaveAccount,
                    style: const TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                  child: Text(localizations.login,
                      style: const TextStyle(color: AppColors.primaryBlue)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, bool isPassword, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            suffixIcon: isPassword
                ? const Icon(Icons.visibility_off, color: Colors.grey)
                : null,
          ),
        ),
      ],
    );
  }
}
