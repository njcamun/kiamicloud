/// Client ID OAuth para Google Sign-In no Windows.
///
/// Deve ser APENAS uma linha no formato:
///   372525178999-xxxxxxxx.apps.googleusercontent.com
///
/// Obter em: https://console.cloud.google.com/apis/credentials?project=kiamicloud
/// → Cliente OAuth "Web" (Firebase) OU criar "App para computador"
abstract final class GoogleOAuthClient {
  static const String desktopClientId =
      '372525178999-ml8uov59ijvcnu3rkqrpobncom9a7444.apps.googleusercontent.com';
}
