import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap_gate.dart';
import 'app/bootstrap/app_dependencies.dart';
import 'app/bootstrap/application_bootstrap_service.dart';
import 'app/bootstrap/platform_application_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const AppBootstrapGate(
      initialize: _initializeApplication,
      appBuilder: _buildInitializedApp,
    ),
  );
}

Future<AppDependencies> _initializeApplication({
  ApplicationBootstrapProgressCallback? onProgress,
}) async {
  final bootstrap = await createPlatformApplicationBootstrap();
  return bootstrap.initialize(onProgress: onProgress);
}

Widget _buildInitializedApp(AppDependencies dependencies) {
  return IeltsGlossaryApp(dependencies: dependencies);
}
