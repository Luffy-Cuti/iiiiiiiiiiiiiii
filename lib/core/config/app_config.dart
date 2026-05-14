class AppConfig {
  const AppConfig._();

  static const videoApiBaseUrl = String.fromEnvironment(
    'VIDEO_API_BASE_URL',
    defaultValue: 'https://timordev.ringme.vn',
  );

  static const videoApiSecret = String.fromEnvironment(
    'VIDEO_API_SECRET',
    defaultValue: '123',
  );

  static const defaultMsisdn = String.fromEnvironment(
    'VIDEO_API_DEFAULT_MSISDN',
    defaultValue: '+67076796381',
  );
  static const revision = String.fromEnvironment(
    'VIDEO_API_REVISION',
    defaultValue: '1.0.0',
  );

  static const uploadPassword = String.fromEnvironment(
    'VIDEO_UPLOAD_PASSWORD',
    defaultValue: '9EBB7AE993E7FCDFA600E108CC21A259',
  );
}