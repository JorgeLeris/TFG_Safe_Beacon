flutter test --coverage
lcov --remove coverage/lcov.info \
'lib/di/*' \
'lib/face_routes.dart' \
'*.g.dart' \
'*.freezed.dart' \
-o coverage/lcov.info
genhtml coverage/lcov.info --output=coverage
open coverage/index.html