import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'register_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscureText = true;
  bool rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Icon(Icons.radio_button_checked,
                              size: 60, color: AppColors.primaryBlue),
                          const SizedBox(height: 20),
                          Text(localizations.loginToYourAccount,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(localizations.orSocialNetworks,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
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
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Flexible(
      child: Row(
        children: [
          Checkbox(
            value: rememberMe,
            activeColor: AppColors.primaryBlue,
            onChanged: (value) {
              setState(() {
                rememberMe = value!;
              });
            },
          ),
          Expanded(
            child: Text(
              localizations.rememberMe,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
    TextButton(
      onPressed: () => _showEmailBottomSheet(context),
      child: Text(
        localizations.forgotPassword,
        style: const TextStyle(color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
const SizedBox(height: 10),
                          Consumer<AuthViewModel>(
                            builder: (context, authViewModel, child) {
                              return ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    authViewModel.login(
                                      context,
                                      emailController.text.trim(),
                                      passwordController.text.trim(),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: authViewModel.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(localizations.login,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.white)),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildDividerWithText(localizations.orContinueWith),
                          const SizedBox(height: 15),
                          _buildSocialButtons(),
                        
                          _buildSignUpOption(context),
                        
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  )
                : null,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (isPassword && value.length < 6) {
                return AppLocalizations.of(context)!.invalidPassword;
              }
              if (!isPassword &&
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return AppLocalizations.of(context)!.invalidEmail;
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: const TextStyle(color: Colors.grey)),
        ),
        const Expanded(child: Divider(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            final authViewModel =
                Provider.of<AuthViewModel>(context, listen: false);
            authViewModel.signInWithGoogle(context);
          },
          child: _buildSocialButton("assets/google.png"),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String asset) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
      child: Center(
        child: Image.asset(asset, width: 25, height: 25),
      ),
    );
  }

  Widget _buildSignUpOption(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(localizations.dontHaveAccount,
            style: const TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const RegisterPage())),
          child: Text(localizations.signup,
              style: const TextStyle(color: AppColors.primaryBlue)),
        ),
      ],
    );
  }

  void _showEmailBottomSheet(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    TextEditingController emailController = TextEditingController();
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(localizations.enterYourEmailTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    hintText: localizations.enterYourEmail,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    authViewModel.sendForgotPasswordRequest(
                        context, emailController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Continue",
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
