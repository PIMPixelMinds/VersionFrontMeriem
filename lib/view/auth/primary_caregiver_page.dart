import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';

class PrimaryCaregiverPage extends StatefulWidget {
  const PrimaryCaregiverPage({super.key});

  @override
  _PrimaryCaregiverPageState createState() => _PrimaryCaregiverPageState();
}

class _PrimaryCaregiverPageState extends State<PrimaryCaregiverPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userProfile = authViewModel.userProfile;

    if (userProfile != null) {
      nameController.text = userProfile['careGiverName'] ?? '';
      phoneController.text = userProfile['careGiverPhone']?.toString() ?? '';
      emailController.text = userProfile['careGiverEmail'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBlue : Colors.white,
      appBar: AppBar(
        title: Text(
          localizations.primaryCaregiver,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProfileHeader(localizations),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      localizations.name,
                      localizations.enterCaregiverName,
                      nameController,
                      isDarkMode,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      localizations.phone,
                      localizations.enterCaregiverPhone,
                      phoneController,
                      isDarkMode,
                      isPhone: true,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      localizations.email,
                      localizations.enterCaregiverEmail,
                      emailController,
                      isDarkMode,
                      isEmail: true,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(isDarkMode, localizations),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: AppColors.primaryBlue,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.editCaregiverDetails,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    bool isDarkMode, {
    bool isPhone = false,
    bool isEmail = false,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                width: 1,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.requiredField;
            }
            if (isPhone && !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
              return localizations.invalidPhoneNumber;
            }
            if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return localizations.invalidEmail;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isDarkMode, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ElevatedButton(
        onPressed: () async {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          final String caregiverPhoneText = phoneController.text.trim();
          int? caregiverPhone = caregiverPhoneText.isNotEmpty ? int.tryParse(caregiverPhoneText) : null;

          if (caregiverPhoneText.isNotEmpty && caregiverPhone == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.phoneNumberMustBeValid)),
            );
            return;
          }

          await authViewModel.updateProfile(
            context: context,
            newCareGiverName: nameController.text.isNotEmpty ? nameController.text : null,
            newCareGiverPhone: caregiverPhone,
            newCareGiverEmail: emailController.text.isNotEmpty ? emailController.text : null,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          localizations.edit,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}