# KiamiCloud — Firebase Authentication (Fase 3)

## 1. Criar projecto Firebase

1. [Console Firebase](https://console.firebase.google.com/) → **Criar projecto**
2. Plano **Spark (gratuito)**
3. Activar **Authentication** → Métodos:
   - E-mail/Palavra-passe
   - Google

## 2. FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

Na raiz do monorepo, por cada app:

```powershell
cd apps\cloud\mobile
flutterfire configure
```

Repita para `apps\cloud\web` e `apps\cloud\desktop` (ou um projecto Firebase com várias apps).

O comando gera `lib/firebase_options.dart` com credenciais reais.

**Nunca faça commit de credenciais reais em repositórios públicos.**

## 3. Android (Google Sign-In)

1. Firebase → Definições → App Android → impressão digital **SHA-1** (debug):

```powershell
cd apps\cloud\mobile\android
.\gradlew signingReport
```

2. Adicione o SHA-1 no Firebase Console
3. Descarregue `google-services.json` → `apps/cloud/mobile/android/app/`

## 4. Web

1. `cd apps\cloud\web` → `flutterfire configure` (marca **Web**)
   - Ou use o `firebase_options.dart` já alinhado com o projecto `kiamicloud`
2. **Authentication** → **Definições** → **Domínios autorizados**: `localhost`
3. Google na Web: popup Firebase — **permita popups** no Chrome para `localhost`
4. `.\scripts\sync-branding-assets.cmd` antes de `flutter run -d chrome`

## 5. Windows Desktop

1. `flutterfire configure` na pasta `apps/cloud/desktop` (marca **Windows**)
2. **Google Sign-In no Windows** (obrigatório — o pacote `google_sign_in` normal não funciona no PC):

### 5.1 Obter OAuth Client ID

1. Abra [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials?project=kiamicloud)
2. **+ Criar credenciais** → **ID do cliente OAuth**
3. Tipo de aplicação: **App para computador** (Desktop)
4. Nome: `KiamiCloud Windows`
5. Copie o **Client ID** (formato `xxxxx.apps.googleusercontent.com`)

**Alternativa:** em Credenciais, use o cliente **Web** já criado pelo Firebase (tipo "Aplicação Web").

### 5.2 Configurar na app

Edite `apps/cloud/desktop/lib/google_oauth_client.dart`:

```dart
static const String desktopClientId =
    'SEU_CLIENT_ID.apps.googleusercontent.com';
```

### 5.3 Executar

```powershell
cd apps\cloud\desktop
flutter pub get
flutter run -d windows
```

Ao clicar **Continuar com Google**, deve abrir o **browser** para login. Depois volta à app.

Se falhar: use **e-mail/palavra-passe** (funciona sempre no Windows).

## 6. Executar

```powershell
.\scripts\sync-branding-assets.cmd
cd apps\cloud\mobile
flutter pub get
flutter run
```

## Comportamento sem configurar

Com `YOUR_*` em `firebase_options.dart`:

- App inicia normalmente
- Banner amarelo no ecrã de login
- `UnconfiguredAuthRepository` evita crashes

Após `flutterfire configure`, autenticação fica activa.

## API Workers (Fase 4)

Com `npm run dev` em `workers/`, a API local está em http://127.0.0.1:8787.

Envie o **idToken** Firebase no header:

`Authorization: Bearer <idToken>`

Ver `docs/CLOUDFLARE_WORKERS.md`.
