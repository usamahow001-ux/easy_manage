# 🚀 EasyManage Google Play Store Deployment & Cloud Sync Guide

This comprehensive guide covers everything required to deploy **EasyManage** to the Google Play Store and configure production-grade 1-Tap Google Drive Cloud Backups.

---

## 📋 Table of Contents
1. [Why Cloud Restore Requires "BACK UP NOW" First](#1-why-cloud-restore-requires-back-up-now-first)
2. [Google Cloud Console Setup for Production](#2-google-cloud-console-setup-for-production)
3. [Creating Release Keystore (Signing Certificate)](#3-creating-release-keystore-signing-certificate)
4. [Configuring Android App Signing](#4-configuring-android-app-signing)
5. [Building the Production App Bundle (.aab)](#5-building-the-production-app-bundle-aab)
6. [Google Play Console Setup](#6-google-play-console-setup)
7. [Publishing Checklist](#7-publishing-checklist)

---

## 1. Why Cloud Restore Requires "BACK UP NOW" First

When you connect a Google account:
1. **Initial State**: Google Drive has no file for this account yet until you tap **"BACK UP NOW"**.
2. **Backing Up**: When you tap **"BACK UP NOW"**, the app:
   - Packages all your customers, suppliers, transactions, cashbook entries, and calculator history into an encrypted `easymanage_ledger_backup.json`.
   - Uploads this file directly to your private **Google Drive Cloud Storage** (`appDataFolder`).
3. **Restoring**: When you tap **"Restore from Google Drive"** (on a newly installed device):
   - The app contacts Google Drive, finds `easymanage_ledger_backup.json`, and loads all your past data.

> [!NOTE]
> If you uninstall the app **before** tapping **"BACK UP NOW"** with your connected Google account, there is no file stored on Google's cloud servers yet. Always tap **"BACK UP NOW"** after connecting your account to create your first cloud snapshot.

---

## 2. Google Cloud Console Setup for Production

### Step A: Enable Google Drive API
1. Open [Google Cloud Console - APIs Library](https://console.cloud.google.com/apis/library?project=easy-manage-510316).
2. Search for **Google Drive API**.
3. Click **Enable**.

### Step B: Configure OAuth Consent Screen
1. Go to **Google Cloud Console** &rarr; **APIs & Services** &rarr; **OAuth consent screen** (or **Audience** in Google Auth Platform).
2. Set User Type to **External**.
3. Fill in:
   - **App Name**: `Easy Manage`
   - **User Support Email**: Your developer email.
   - **Developer Contact Email**: Your email.
4. Click **Publish App** to switch from *Testing* mode to *Production* (this allows any user worldwide to connect their Gmail without needing test user invitations).

### Step C: Add OAuth 2.0 Client IDs
You need **two** Android OAuth Client IDs:
1. **Debug Client ID** (for testing on your computer/phone during development):
   - **Package**: `com.easymanage.app.easy_manage`
   - **SHA-1**: `DB:84:79:44:13:14:85:76:1B:EB:E1:1A:4E:58:9A:09:5B:A5:D5:9B`
2. **Release Client ID** (for Google Play Store builds):
   - **Package**: `com.easymanage.app.easy_manage`
   - **SHA-1**: *(Generated from your release keystore / Play App Signing in Step 3 below)*.

---

## 3. Creating Release Keystore (Signing Certificate)

To publish on Google Play Store, create a secure release key:

```powershell
keytool -genkey -v -keystore c:\Users\usama.ali\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

To extract the Release SHA-1 from your keystore:
```powershell
keytool -list -v -keystore c:\Users\usama.ali\upload-keystore.jks -alias upload
```

Copy the **SHA-1** and add it as a new Android OAuth Client in Google Cloud Console.

---

## 4. Configuring Android App Signing

In `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=c:/Users/usama.ali/upload-keystore.jks
```

In `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    create("release") {
        val keystorePropertiesFile = rootProject.file("key.properties")
        val keystoreProperties = Properties()
        if (keystorePropertiesFile.exists()) {
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## 5. Building the Production App Bundle (.aab)

Run the command in your project terminal:

```powershell
flutter build appbundle --release
```

The output file will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

This `.aab` file is the official format required by Google Play Console.

---

## 6. Google Play Console Setup

1. Open [Google Play Console](https://play.google.com/console).
2. Click **Create App**:
   - **App Name**: `Easy Manage - Digital Khata & Cashbook`
   - **Default Language**: English (United States)
   - **App or Game**: App
   - **Free or Paid**: Free
3. **App Integrity / Play App Signing**:
   - Google Play will generate an **App Signing SHA-1**.
   - Copy Google Play's App Signing SHA-1 and add it to **Google Cloud Console &rarr; OAuth 2.0 Client IDs &rarr; Android**.
4. Upload `app-release.aab` under **Production** or **Internal Testing**.
5. Fill out the Store Listing (Screenshots, Short Description, Full Description, Privacy Policy).

---

## 7. Publishing Checklist

- [x] Responsive layout with zero pixel overflows across all device sizes.
- [x] Offline-first local database with instant sync.
- [x] Native 1-Tap Google Drive OAuth backup & restore.
- [x] Multi-language support (English, Urdu, Hinglish).
- [x] PDF / Invoice receipt generator and WhatsApp sharing.
- [ ] Google Drive API enabled in Google Cloud Console.
- [ ] OAuth Consent Screen published to Production.
- [ ] Release `.aab` built and uploaded to Google Play Console.
