import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/shared_prefs_service.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'terms_and_privacy_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SharedPrefsService _prefsService = SharedPrefsService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.getProfile(context).then((_) {
        if (authViewModel.isProfileIncomplete()) {
          _showIncompleteProfileDialog();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final localizations = AppLocalizations.of(context)!;

    final String userName = authViewModel.userProfile?["fullName"] ?? "Jaydon Mango";
    final String userEmail = authViewModel.userProfile?["email"] ?? "jaydonmango@gmail.com";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.profile,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      backgroundColor: AppColors.primaryBlue,
      body: Stack(
        children: [
          Column(
            children: [
              _buildProfileHeader(isDarkMode, userName, userEmail),
            ],
          ),
          _buildBottomSheet(context, isDarkMode, localizations),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode, String userName, String userEmail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: AppColors.primaryBlue,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            userName.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            userEmail,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, bool isDarkMode, AppLocalizations localizations) {
    return DraggableScrollableSheet(
      initialChildSize: 0.77,
      minChildSize: 0.77,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(localizations.account, isDarkMode),
                _buildProfileOption(context, Icons.person, localizations.personalInformation, () {
                  Navigator.pushNamed(context, '/personalInformation');
                }, isDarkMode),
                _buildProfileOption(context, Icons.lock, localizations.passwordSecurity, () {
                  Navigator.pushNamed(context, '/passwordSecurity');
                }, isDarkMode),
                _buildProfileOption(context, Icons.medical_information, localizations.medicalHistory, () {
                  Navigator.pushNamed(context, '/medicalHistory');
                }, isDarkMode),
                _buildProfileOption(context, Icons.co_present, localizations.primaryCaregiver, () {
                  Navigator.pushNamed(context, '/primaryCaregiver');
                }, isDarkMode),
                const SizedBox(height: 10),
                const Divider(),
                _buildProfileOption(context, Icons.settings, localizations.settings, () {}, isDarkMode),
                _buildProfileOption(context, Icons.article_outlined, localizations.termsAndConditions, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndPrivacyPage(
                        title: 'Terms and Conditions',
                        url: 'https://www.freeprivacypolicy.com/live/23b52896-67fa-4345-a69a-5f9ecfefd4ff',
                      ),
                    ),
                  );
                }, isDarkMode),
                _buildProfileOption(context, Icons.privacy_tip_outlined, localizations.privacyPolicy, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndPrivacyPage(
                        title: 'Privacy Policy',
                        url: 'https://www.freeprivacypolicy.com/live/c4301d27-eeeb-45a2-bc22-1bb8b4900776',
                      ),
                    ),
                  );
                }, isDarkMode),
                _buildProfileOption(context, Icons.help_outline, localizations.helpAssistance, () {}, isDarkMode),
                const SizedBox(height: 15),
                const Divider(),
                _buildProfileOption(context, Icons.delete_forever, localizations.deleteMyAccount, () {
                  _confirmDeleteAccount(context);
                }, isDarkMode),
                _buildProfileOption(context, Icons.logout, localizations.logOut, () {
                  _logout(context);
                }, isDarkMode),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white60 : Colors.grey),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap, bool isDarkMode) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
        child: ListTile(
          leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.grey),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

Future<void> _logout(BuildContext context) async {
  // Clear shared preferences (token, walkthrough, etc.)
  await _prefsService.clearAll();

  try {
    // Attempt to disconnect from Google
    await _googleSignIn.signOut();
    await _googleSignIn.disconnect();
  } catch (_) {
    // Ignore sign out errors
  }

  if (!mounted) return;

  // Add a short delay to let the widget tree settle before navigation
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loggedOut)),
      );
    }
  });
}

  void _confirmDeleteAccount(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteAccount),
        content: Text(localizations.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              await authViewModel.deleteProfile(context);
            },
            child: Text(
              localizations.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncompleteProfileDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          localizations.completeYourProfile,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localizations.missingProfileInformation,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.later,
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/personalInformation');
            },
            child: Text(
              localizations.editNow,
              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}