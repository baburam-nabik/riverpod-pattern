import 'package:flutter/material.dart';
import 'app_exception.dart';

class ErrorScreen extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  const ErrorScreen({super.key, required this.exception, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              exception.runtimeType.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (exception.statusCode != null)
              Text(
                'Status code: ${exception.statusCode}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 8),
            Text(
              exception.message,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
