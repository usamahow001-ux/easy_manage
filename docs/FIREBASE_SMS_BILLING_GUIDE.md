# Firebase SMS Authentication & `BILLING_NOT_ENABLED` Guide

## 1. What is `BILLING_NOT_ENABLED` and What Happened?

When attempting to send a real SMS code via Firebase Phone Authentication on a new project, Firebase returns the error:
`[firebase_auth/billing-not-enabled] The project must be on the Blaze plan to use phone authentication.`

### Why Google Changed This Policy:
1. **SMS Toll Fraud & Bot Protection:** In recent years, malicious bots automated SMS requests globally, racking up millions of dollars in telecom costs for app providers.
2. **Identity Platform Upgrade:** To protect developers from telecom abuse, Google migrated Firebase Phone Authentication to Google Cloud Identity Platform.
3. **Billing Requirement:** Google now requires linking a billing account (Credit Card / Debit Card) to your Firebase project by selecting the **Blaze Plan (Pay-as-you-go)** before their telecom gateway sends live carrier SMS messages to Pakistani and international mobile networks.

---

## 2. Is it Free on the Blaze Plan?

**YES, it is 100% FREE for standard usage.**

- **Monthly Free Tier:** Google Firebase gives **10,000 free Phone/SMS authentications per month** across most countries.
- **No Upfront Charge:** Upgrading to Blaze simply validates your identity and unlocks the global carrier SMS gateway. As long as your app sends fewer than 10,000 OTPs a month, your monthly bill is **$0.00**.
- **Budget Alerts:** You can set a budget limit (e.g. $1 or $0) to receive email warnings before any charges occur.

---

## 3. How to Enable Real SMS (Step-by-Step)

Follow these steps to enable real SMS delivery to all Pakistani networks (Jazz, Telenor, Zong, Ufone) and international numbers:

### Step 1: Open the Firebase Console
1. Go to [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Select your project: **`easy-manage-live`** (or your active project).

### Step 2: Upgrade to the Blaze Plan
1. In the bottom-left corner of the Firebase Console, look for your current plan (it says **Spark**).
2. Click **Upgrade** $\rightarrow$ select **Blaze (Pay as you go)**.
3. Link your Google Cloud Billing account (any Visa/Mastercard debit or credit card).
4. *(Optional but recommended)* Set a monthly budget alert of **$1.00** so you never get unexpected charges.

### Step 3: Enable Phone Authentication in Firebase
1. In the left navigation menu, go to **Build** $\rightarrow$ **Authentication**.
2. Click the **Sign-in method** tab.
3. Click on **Phone** under Sign-in providers.
4. Toggle **Enable** to ON.
5. Click **Save**.

### Step 4: Add SHA-1 and SHA-256 Fingerprints
For SMS auto-retrieval and SafetyNet / Play Integrity verification on Android:
1. In Firebase Console, click the **Gear icon (⚙️)** next to *Project Overview* $\rightarrow$ **Project settings**.
2. Scroll down to **Your apps** $\rightarrow$ select the Android app (`com.easymanage.khata.live`).
3. Click **Add fingerprint** and add your debug & release SHA-256 / SHA-1 certificates.

---

## 4. Alternative Methods (No Credit Card Required)

If you do not want to add a credit/debit card right now, you have 3 instant alternatives:

### Method A: Use Firebase Whitelisted Test Phone Numbers (100% Free, No Billing)
You can set up test numbers in Firebase Console that always succeed with a fixed OTP code:
1. In Firebase Console $\rightarrow$ **Authentication** $\rightarrow$ **Sign-in method** $\rightarrow$ **Phone**.
2. Expand **Phone numbers for testing (optional)**.
3. Add:
   - Phone number: `+923404779596`
   - Test Code: `123456`
   - Add as many test numbers (e.g., `+923165503723`, `+923001234567`) as you need.
4. Now, entering that phone number in the app sends the verification flow and entering `123456` logs you in immediately with real Firestore sync!

### Method B: In-App Direct Login (Offline & Instant Dev Mode)
On the [PhoneAuthScreen](file:///c:/Users/usama.ali/.gemini/antigravity-ide/scratch/easy_manage/lib/screens/phone_auth_screen.dart), enter your mobile number and tap:
⚡ **"Direct / Quick Login"** or **"فوری لاگ ان / بغیر ایس ایم ایس"**
- This bypasses carrier SMS entirely and logs into the account directly with real-time Firebase cloud database sync.

### Method C: Sending Khata Statements & Reminders via WhatsApp / Device SMS
For sending customer bills, payment reminders, and PDF reports:
- The app uses direct Android intents to open the user's default **SMS App** or **WhatsApp**.
- This sends messages directly from the user's SIM card or WhatsApp account at zero cost through their carrier/data plan.

---

## Summary Table

| Feature | Spark Plan (Free) | Blaze Plan (Pay-as-you-go) |
| :--- | :--- | :--- |
| **Real Carrier SMS Delivery** | ❌ Blocked by Google | ✅ Enabled (10,000 SMS/mo Free) |
| **Test Phone Numbers (`+92...`)** | ✅ Fully Supported | ✅ Fully Supported |
| **Direct / Quick Login** | ✅ Supported | ✅ Supported |
| **Cloud Firestore Real-Time Sync** | ✅ Fully Free & Live | ✅ Fully Free & Live |
| **WhatsApp / Device SMS Sharing** | ✅ Unlimited & Free | ✅ Unlimited & Free |
