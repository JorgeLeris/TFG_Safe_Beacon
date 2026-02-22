import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_beacon/app/config/environment.dart';

extension EnvironmentContext on BuildContext {
  Environment get environment => read<Environment>();
}
