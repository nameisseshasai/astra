import 'package:flutter/material.dart';

import '../../domain/entities/app_state.dart';
import '../theme/app_theme.dart';

/// Full-screen loading overlay with progress indication
class LoadingOverlayWidget extends StatelessWidget {
  final AppStatus status;
  final ModelDownloadProgress? downloadProgress;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const LoadingOverlayWidget({
    super.key,
    required this.status,
    this.downloadProgress,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AstraTheme.backgroundColor,
            AstraTheme.backgroundColor.withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              _buildLogo(),
              const SizedBox(height: 48),
              // Status message
              _buildStatusContent(),
              const SizedBox(height: 32),
              // Error handling
              if (status == AppStatus.error && errorMessage != null)
                _buildErrorContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 180,
      height: 180,

      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(12),
      //   gradient: const LinearGradient(
      //     colors: [AstraTheme.primaryColor, AstraTheme.secondaryColor],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   shape: BoxShape.circle,
      //   boxShadow: [
      //     BoxShadow(
      //       color: AstraTheme.primaryColor.withValues(alpha: 0.4),
      //       blurRadius: 30,
      //       spreadRadius: 5,
      //     ),
      //   ],
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRect(
            child: Image.asset(
              'assets/icons/ic_launcher.png',
              width: 60,
              height: 60,
            ),
          ),
          Text(
            'ASTRA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AstraTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    return switch (status) {
      AppStatus.initial || AppStatus.loading => _buildLoadingContent(
        'Initializing...',
        'Setting up accessibility features',
      ),
      AppStatus.modelDownloading => _buildDownloadContent(),
      AppStatus.modelInitializing => _buildLoadingContent(
        'Preparing Vision Model...',
        'This may take a moment',
      ),
      AppStatus.error => _buildLoadingContent(
        'Error Occurred',
        errorMessage ?? 'Unknown error',
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLoadingContent(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (status != AppStatus.error)
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AstraTheme.primaryColor,
              ),
            ),
          ),
        if (status != AppStatus.error) const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AstraTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: AstraTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDownloadContent() {
    final progress = downloadProgress?.progress ?? 0;
    final progressPercent = (progress * 100).toInt();

    return Column(
      children: [
        // Circular progress with percentage
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: AstraTheme.cardColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AstraTheme.primaryColor,
                ),
              ),
            ),
            Text(
              '$progressPercent%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AstraTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          progress < 0.5
              ? 'Downloading Vision Model'
              : 'Downloading Tool Model',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AstraTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          downloadProgress?.status ?? 'Please wait...',
          style: const TextStyle(fontSize: 14, color: AstraTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AstraTheme.cardColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AstraTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    // Check if it's an internet/download error
    final isConnectionError =
        errorMessage?.toLowerCase().contains('internet') == true ||
        errorMessage?.toLowerCase().contains('download') == true ||
        errorMessage?.toLowerCase().contains('connection') == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // WiFi/Connection icon for connection errors
        if (isConnectionError) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AstraTheme.warningColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AstraTheme.warningColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AstraTheme.dangerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AstraTheme.dangerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConnectionError ? Icons.cloud_off : Icons.error_outline,
                color: AstraTheme.dangerColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AstraTheme.dangerColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Connection tips for internet errors
        if (isConnectionError) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AstraTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '💡 Tips:',
                  style: TextStyle(
                    color: AstraTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Check WiFi or mobile data\n• Move closer to router\n• Try airplane mode on/off',
                  style: TextStyle(
                    color: AstraTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AstraTheme.primaryColor,
              foregroundColor: AstraTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}
