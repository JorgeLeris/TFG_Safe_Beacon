import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/core/constants/constants.dart';

/// Types of feedback a user can send.
enum FeedbackType {
  suggestion('Sugerencia'),
  incident('Incidencia');

  const FeedbackType(this.label);

  /// Human-readable label sent to the EmailJS template.
  final String label;

  static FeedbackType fromDropdownValue(String? value) =>
      value == Constants.incidentTypeKey
          ? FeedbackType.incident
          : FeedbackType.suggestion;
}

/// Sends feedback emails via the EmailJS REST API.
class EmailJsService {
  /// Sends a suggestion or incident email.
  ///
  /// [type] — the feedback category.
  /// [fromEmail] — the authenticated user's email address.
  /// [message] — the body text entered by the user.
  Future<void> sendFeedback({
    required FeedbackType type,
    required String fromEmail,
    required String message,
  }) async {
    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());

    appLogger.fine('EmailJS: sending ${type.label} from $fromEmail');

    final response = await http.post(
      Uri.parse(Constants.emailJsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': dotenv.env['EMAILJS_SERVICE_ID'],
        'template_id': dotenv.env['EMAILJS_TEMPLATE_ID'],
        'user_id': dotenv.env['EMAILJS_PUBLIC_KEY'],
        'template_params': {
          'type': type.label,
          'from_email': fromEmail,
          'message': message,
          'date': date,
        },
      }),
    );

    if (response.statusCode == 200) {
      appLogger.info('EmailJS: feedback sent successfully');
    } else {
      appLogger.warning(
        'EmailJS: failed to send feedback — ${response.statusCode} ${response.body}',
      );
      throw Exception('EmailJS error ${response.statusCode}');
    }
  }
}
