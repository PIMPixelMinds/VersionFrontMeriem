class ApiConstants {
  static const String baseUrl = "http://192.168.100.7:3000";
  static const String loginEndpoint = "$baseUrl/auth/login";
  static const String signupEndpoint = "$baseUrl/auth/signup";
  static const String googleLoginEndpoint = "$baseUrl/auth/google/login";
  static const String googleRedirectEndpoint = "$baseUrl/auth/google/redirect";
  static const String forgotPasswordEndpoint = "$baseUrl/auth/forgot-password";
  static const String verifyOtpEndpoint = "$baseUrl/auth/verify-reset-code";
  static const String resendOtpEndpoint = "$baseUrl/auth/get-reset-code";
  static const String resetPasswordEndpoint = "$baseUrl/auth/reset-password";
  static const String getProfileEndpoint = "$baseUrl/auth/profile";
  static const String updateProfileEndpoint =
      "$baseUrl/auth/update-profile"; // Add this line
  static const String completeProfileEndpoint =
      "$baseUrl/auth/completeProfile"; // Add this line
  static const String updateAuthFcmTokenEndpoint =
      "$baseUrl/auth/updateFcmToken"; //Notif
  static const String changePasswordEndpoint = "$baseUrl/auth/change-password";
  static const String addAppointmentEndpoint =
      "$baseUrl/appointment/addAppointment";
  static const String updateAppointmentEndpoint =
      "$baseUrl/appointment/updateAppointment";
  static const String cancelAppointmentEndpoint =
      "$baseUrl/appointment/cancelAppointment";
  static const String displayAppointmentEndpoint =
      "$baseUrl/appointment/displayAppointment";
  static const String updateFcmTokenEndpoint =
      "$baseUrl/appointment/updateFcmToken";
  static const String fetchActivitiesEndpoint = "$baseUrl/activities";
  static const String countAppointmentsEndpoint =
      "$baseUrl/appointment/countAppointments";
  static const String fetchCompletedAppointmentsEndpoint =
      "$baseUrl/appointment/completedAppointments";

  // Medication API endpoints
  static const String getMedicationsEndpoint = "$baseUrl/medications";
  static const String addMedicationEndpoint = "$baseUrl/medications";
  static const String updateMedicationEndpoint =
      "$baseUrl/medications"; // + /{id}
  static const String deleteMedicationEndpoint =
      "$baseUrl/medications"; // + /{id}
  static const String getMedicationByIdEndpoint =
      "$baseUrl/medications"; // + /{id}
  static const String takeMedicationEndpoint =
      "$baseUrl/medications"; // + /{id}/take
  static const String skipMedicationEndpoint =
      "$baseUrl/medications"; // + /{id}/skip
  static const String getMedicationHistoryEndpoint =
      "$baseUrl/medications"; // + /{id}/history
  static const String getTodayRemindersEndpoint =
      "$baseUrl/medications/today-reminders";
  static const String getRemindersForDateEndpoint =
      "$baseUrl/medications/reminders";

  static const String medicationUpdateStockEndpoint =
      "$baseUrl/medications/{id}/stock";
  static const String medicationAddStockEndpoint =
      "$baseUrl/medications/{id}/stock/add";
  static const String medicationStockHistoryEndpoint =
      "$baseUrl/medications/{id}/stock/history";
  static const String fixRemindersEndpoint =
      "$baseUrl/medications/fix-reminders";

  static const String getHistoriqueEndpoint =
      "$baseUrl/historique"; // Add this line
  static const String saveHistoriqueEndpoint =
      "$baseUrl/historique/upload-screenshot";
  static const String getGroupedHistoriqueEndpoint =
      "$baseUrl/historique/grouped";
  static const String getHistoriqueByDateEndpoint =
      "$baseUrl/historique/by-date"; // ✅ Ajouté
  static const String checkPainHistoriqueEndpoint =
      "$baseUrl/historique/check-douleur";
  static const String getHistoriqueNeedsPainCheckEndpoint =
      "$baseUrl/historique/needs-check";
  static const String updateHistoriqueFcmTokenEndpoint =
      "$baseUrl/historique/updateFcmToken";
  static const String questionsEndpoint = '$baseUrl/questionnaire/questions';
  static const String answersEndpoint =
      '$baseUrl/questionnaire/submit'; // endpoint for submitting answers
  static const String checkAvailabilityEndpoint =
      '$baseUrl/questionnaire/can-submit'; //
  static const String deleteProfileUrl = '$baseUrl/auth/delete-profile';
}
