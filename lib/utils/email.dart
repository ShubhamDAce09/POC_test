import 'constants.dart';

bool isInstituteEmail(String email) {
  final normalized = email.trim().toLowerCase();
  return normalized.endsWith('@${AppConstants.allowedEmailDomain}') &&
      normalized.split('@').first.isNotEmpty;
}

String normalizeEmail(String email) => email.trim().toLowerCase();
