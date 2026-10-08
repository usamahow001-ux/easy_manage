# Easy Manage: Live Khata Sharing & Sync Explained

## 1. How It Works (The 2 Stages)

To understand why it might not have worked between two different phones yet, here is how the architecture is designed:

```mermaid
flowchart LR
    subgraph Stage1 [Stage 1: Local Dual-Mode (Current App)]
        A[Shopkeeper Mode on Phone 1] <-->|Instant Local Sync| B[Customer Mode on Same Phone]
    end

    subgraph Stage2 [Stage 2: Live Internet Sync (Firebase Needed)]
        C[Shopkeeper Phone] -->|Internet Sync| D[(Firebase Cloud Database)]
        D -->|Real-Time Stream| E[Customer Phone 2 / Web Link]
    end
```

---

## 2. How to Test It Right Now on Your Phone (1-Device Test)

You can see the feature working immediately on your current phone by following these steps:

### Step 1: In Shopkeeper Mode
1. Open the app in **Shopkeeper Mode**.
2. Tap **Add Customer** and enter:
   * **Name:** `Usama Test`
   * **Phone:** `0300 1234567`
3. Open `Usama Test` and add entries:
   * Tap **Maine Diye (Gave)**: `Rs. 1,000` (Note: `Groceries`)
   * Tap **Maine Liye (Got)**: `Rs. 300` (Note: `Cash Payment`)
   * Current Balance = **Rs. 700**.

### Step 2: Switch to Customer Mode
1. Tap the **`[🏪 Shopkeeper Mode ▾]`** dropdown at the top of the Home Screen.
2. Select **`[👤 Customer Mode]`**.
3. When prompted for your phone number, enter: `0300 1234567`.
4. **Result:** You will instantly see your shop listed showing:
   * Shop Name & Owner Name
   * **You Owe: Rs. 700**
5. Tap the shop to open the **Live Customer Ledger** showing all items, dates, notes, and a **"Download PDF Statement"** button!

---

## 3. Why It Doesn't Sync Across 2 Different Phones Yet

Right now, your app saves data inside the phone's **local storage**. 
* Phone 1's local storage cannot be read by Phone 2 over the internet without a **Cloud Server / Database**.
* When you tap **"Share Live Khata Link"**, it generates a web link (`https://easymanage.app/ledger?...`). For that link or a 2nd phone to fetch live data from Phone 1, the data must be synced to **Firebase Firestore**.

---

## 4. How to Connect Firebase for Live 2-Phone Sync (100% Free)

To enable live sync between two different phones across the internet:

1. **Create a Free Firebase Project:**
   * Go to [firebase.google.com](https://firebase.google.com) $\rightarrow$ Click **Create Project** (Name: `easy-manage`).
2. **Enable Cloud Firestore:**
   * Click **Firestore Database** $\rightarrow$ **Create Database** (Start in Test Mode).
3. **Add Android App:**
   * Enter your package name: `com.example.easy_manage`
   * Download `google-services.json` and place it in your `android/app/` folder.

Once `google-services.json` is placed, we plug in `cloud_firestore` in Flutter, and whenever you add a transaction on Phone 1, Phone 2 and the web link will update **in real time within 1 second**!
