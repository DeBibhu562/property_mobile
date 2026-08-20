/// Mobile UI personas mapped from API UserRole values.
enum AppPersona {
  buyer,
  seller,
  agent,
  agencyAdmin,
  admin;

  String get label => switch (this) {
        AppPersona.buyer => 'Buyer',
        AppPersona.seller => 'Seller / Owner',
        AppPersona.agent => 'Agent',
        AppPersona.agencyAdmin => 'Agency Admin',
        AppPersona.admin => 'Admin',
      };

  static AppPersona fromApiRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'OWNER':
      case 'SELLER':
        return AppPersona.seller;
      case 'AGENT':
        return AppPersona.agent;
      case 'AGENCY_ADMIN':
        return AppPersona.agencyAdmin;
      case 'ADMIN':
      case 'SUPER_ADMIN':
        return AppPersona.admin;
      default:
        return AppPersona.buyer;
    }
  }

  /// Roles allowed at OTP sign-up (new accounts).
  static const signupRoles = <String, String>{
    'USER': 'Buyer — browse & enquire',
    'OWNER': 'Owner — list & sell property',
    'AGENT': 'Agent — manage agency listings',
  };
}
