# Deploy — Gatodex (Android / Google Play)

Pipeline de build → assinatura → publicação no Google Play já configurada.
Workflow: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)

## O que já está pronto ✅

- **Keystore de release** gerado em `android/app/upload-keystore.jks` (alias `upload`, validade ~27 anos).
- **Assinatura no Gradle** ([android/app/build.gradle.kts](android/app/build.gradle.kts)) lendo `android/key.properties` local, com fallback para debug em `flutter run --release`.
- **Fingerprints** SHA-1 e SHA-256 da chave de upload já registrados nos apps Android do Firebase `gatodex-app` (necessário pro `firebase_auth`).
- **Secrets no GitHub** (`DiegoEmanuel/gatodex`): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.
- **Build validado** localmente: AAB assinado com a chave de upload gerado com sucesso.

### Fingerprints da chave de upload

```
SHA1:   0C:3D:3B:2F:37:25:85:A1:0F:CE:97:41:E8:4F:7E:D4:81:95:4E:08
SHA256: 2C:3B:96:A9:65:33:E7:1D:38:96:92:B1:DA:48:BB:EE:85:A1:D1:CF:2C:18:90:88:05:75:22:C6:42:7A:51:55
```

### ⚠️ Credenciais — guarde em local seguro

As senhas do keystore estão em `.deploy-credentials.txt` (gitignored) e `android/key.properties` (gitignored).
**Faça backup do `upload-keystore.jks` e das senhas.** Se perder a chave de upload você precisa pedir reset à Google; se perder e não estiver no Play App Signing, perde a capacidade de atualizar o app.

## Passos manuais que faltam (uma vez só)

### 1. Criar o app no Google Play Console
- Console → criar app com package `com.diegoemanuel.gatodex`.
- Aceitar **Play App Signing** (recomendado/padrão).
- Fazer o **primeiro upload do AAB manualmente** (o Google exige isso antes de a API aceitar uploads). Gere o AAB com:
  ```bash
  flutter build appbundle --release
  # arquivo em build/app/outputs/bundle/release/app-release.aab
  ```

### 2. Adicionar o fingerprint do Play App Signing ao Firebase 🔑
Com Play App Signing, o Google **re-assina** o app com a chave de produção dele. Logo, em produção, o `firebase_auth` precisa do SHA da chave **do Google**, não só da de upload.
- Play Console → seu app → **Configuração → Integridade do app → Assinatura de apps**.
- Copie o **SHA-1 e SHA-256 da "chave de assinatura de apps"** (App signing key).
- Adicione no Firebase:
  ```bash
  firebase apps:android:sha:create 1:237561692289:android:b3a5f51f27361a2f24cd80 <SHA-1-do-Play> --project gatodex-app
  firebase apps:android:sha:create 1:237561692289:android:b3a5f51f27361a2f24cd80 <SHA-256-do-Play> --project gatodex-app
  ```
  (repita pro outro app id `...fa6687df...` se for usar os dois).

### 3. Criar service account pro deploy automático
- Play Console → **Configuração → acesso via API** → vincular projeto Google Cloud → criar service account.
- No Google Cloud, gere uma **chave JSON** dessa service account.
- No Play Console, conceda à conta permissão de **release** (admin de versões).
- Suba o JSON como secret:
  ```bash
  gh secret set PLAY_SERVICE_ACCOUNT_JSON --repo DiegoEmanuel/gatodex < caminho/para/service-account.json
  ```

## Como lançar uma versão 🚀

1. Ajuste a versão em [pubspec.yaml](pubspec.yaml) (ex: `version: 1.0.0+1`). O `versionCode` é sobrescrito no CI pelo número do run.
2. Crie e envie a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. O workflow builda, assina e publica no track `production`.

Também dá pra disparar manualmente em **Actions → Deploy Android → Run workflow**, escolhendo o track (`internal`, `alpha`, `beta`, `production`).

> Dica: pro primeiro ciclo, vale rodar pelo track `internal` antes de ir pra `production`.
