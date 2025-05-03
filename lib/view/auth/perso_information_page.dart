import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 👈 Ajout

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  _PersonalInformationPageState createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  String? selectedGender;
  final TextEditingController fullNameController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final profile = authViewModel.userProfile;

    if (profile != null) {
      fullNameController.text = profile["fullName"] ?? '';

      if (profile["birthday"] != null) {
        selectedDate = DateTime.tryParse(profile["birthday"]);
      }

      final gender = profile["gender"];
      if (gender != null) {
        selectedGender = gender.toLowerCase() == "male" ? "Male" : "Female";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!; // 👈 Ajout

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBlue : Colors.white,
      appBar: AppBar(
        title: Text(
          localizations.personalInformation,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
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
                        _buildTextField(localizations.fullName, localizations.enterFullName, fullNameController, false, isDarkMode),
                        const SizedBox(height: 15),
                        Text(
                          localizations.birthday,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        _buildDatePickerField(isDarkMode, localizations),
                        const SizedBox(height: 15),
                        _buildGenderSelector(isDarkMode, localizations),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomButton(isDarkMode, authViewModel, localizations),
            ],
          ),
          if (authViewModel.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Widget _buildDatePickerField(bool isDarkMode, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: localizations.birthday,
            hintText: selectedDate != null
                ? "${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}"
                : localizations.selectBirthday,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
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
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.editProfile,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isDarkMode, AuthViewModel authViewModel, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ElevatedButton(
        onPressed: () async {
          if (fullNameController.text.isEmpty || selectedDate == null || selectedGender == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.pleaseFillAllFields)),
            );
            return;
          }

          await authViewModel.updateProfile(
            context: context,
            newName: fullNameController.text,
            newBirthday: selectedDate!.toIso8601String(),
            newGender: selectedGender == localizations.male ? "male" : "female",
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.profileUpdatedSuccessfully)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          localizations.edit,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(bool isDarkMode, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.gender,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGenderButton(localizations.male, Icons.male, isDarkMode),
            const SizedBox(width: 10),
            _buildGenderButton(localizations.female, Icons.female, isDarkMode),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton(String gender, IconData icon, bool isDarkMode) {
    bool isSelected = selectedGender == gender;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedGender = gender;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : (isDarkMode ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 22),
              const SizedBox(width: 5),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, bool isPassword, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ],
    );
  }
}