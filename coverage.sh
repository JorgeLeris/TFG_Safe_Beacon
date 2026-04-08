flutter test --coverage
lcov --remove coverage/lcov.info \
  'lib/di/*' \
  'lib/face_routes.dart' \
  '*.g.dart' \
  '*.freezed.dart' \
  'lib/data/sources/*' \
  'lib/core/*' \
  'lib/app/*' \
  'lib/domain/*' \
  'lib/notification_service.dart' \
  'lib/presentation/features/panic_button/widget/*' \
  'lib/presentation/shared/widgets/*' \
  -o coverage/lcov.info
genhtml coverage/lcov.info --output=coverage
open coverage/index.html