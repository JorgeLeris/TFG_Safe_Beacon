flutter test --coverage
lcov --remove coverage/lcov.info \
  'lib/di/*' \
  'lib/face_routes.dart' \
  '*.g.dart' \
  '*.freezed.dart' \
  'lib/data/sources/*' \
  'lib/core/constants/*' \
  'lib/core/extensions/*' \
  'lib/core/language/generated/*' \
  'lib/core/language/l10n/*' \
  'lib/app/*' \
  'lib/domain/*' \
  'lib/notification_service.dart' \
  'lib/presentation/features/panic_button/widget/*' \
  'lib/presentation/features/guardian_mode/services/*' \
  'lib/presentation/shared/widgets/*' \
  'lib/firebase_options.dart' \
  -o coverage/lcov.info
genhtml coverage/lcov.info --output=coverage
open coverage/index.html