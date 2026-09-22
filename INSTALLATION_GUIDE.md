# How to Build and Install TextCraft on Your iPhone 📱

This guide walks you through generating the `.ipa` file using our automated GitHub Actions macOS pipeline and installing it onto your iPhone from your Windows PC without needing a Mac.

---

## 1. Push Project to GitHub

Because Apple's compilation tools (Xcode) require macOS, our repository includes a GitHub Actions workflow (`.github/workflows/build_ios.yml`) that runs on Apple Silicon macOS runners to compile and package your app into an installable `.ipa` for free.

If you haven't initialized Git yet, run these commands in your project terminal:

```bash
git init
git add .
git commit -m "Initial commit: TextCraft iOS text editor"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

---

## 2. Download the `.ipa` File from GitHub

1. Open your repository on **GitHub.com**.
2. Click on the **Actions** tab at the top.
3. Select the latest run for **"Build iOS IPA"** (or click **"Run workflow"** under Actions to trigger it manually).
4. Once the build finishes (takes ~3 to 5 minutes), scroll down to the **Artifacts** section at the bottom of the summary page.
5. Click **`TextCraft-iOS-IPA`** to download the zip file.
6. Extract the zip to find **`TextCraft.ipa`**.

---

## 3. Install `.ipa` on Your iPhone (via Windows)

You can install any `.ipa` file onto your iPhone using **Sideloadly** (the easiest, free tool for Windows).

### Using Sideloadly (Recommended):
1. **Download & Install Sideloadly on Windows**:
   - Download from: [https://sideloadly.io](https://sideloadly.io)
   - Ensure iTunes (standard installer from Apple, not Microsoft Store) or Apple Devices is installed on your PC.
2. **Connect your iPhone**:
   - Plug your iPhone into your PC via USB cable.
   - Unlock your iPhone and tap **"Trust This Computer"** if prompted.
3. **Load the `.ipa`**:
   - Open Sideloadly. Your iPhone should appear in the device dropdown.
   - Drag and drop `TextCraft.ipa` into the IPA box in Sideloadly.
4. **Enter your Apple ID**:
   - Enter your regular Apple ID email (free account works; Sideloadly communicates directly with Apple's servers to sign the app for your personal device).
5. **Click "Start"**:
   - Sideloadly will sign and install `TextCraft` directly onto your iPhone in 30 seconds.

---

## 4. Trust the App on Your iPhone (First Launch Only)

When you first tap the TextCraft icon on your iPhone home screen:
1. Open the **Settings** app on your iPhone.
2. Go to **General** ➔ **VPN & Device Management**.
3. Under **Developer App**, tap your Apple ID.
4. Tap **Trust "[Your Apple ID]"** and confirm.
5. *(iOS 16+ only)*: Go to **Settings** ➔ **Privacy & Security** ➔ scroll down to **Developer Mode** ➔ toggle **On** and restart the device if prompted.

Now open **TextCraft** and enjoy full writing, markdown preview, iOS Files integration, and AirDrop sharing!

---

## 5. Alternative Sideloading Options

- **AltStore**: Install AltServer on Windows from [altstore.io](https://altstore.io) to sideload and auto-refresh apps over local Wi-Fi.
- **TrollStore**: If your device is on supported iOS versions (iOS 14.0–16.6.1), you can install the `.ipa` permanently without 7-day expiration or re-signing.
- **Apple Developer Account / TestFlight**: If you have a paid Apple Developer subscription ($99/year), you can upload the `.ipa` directly to App Store Connect / TestFlight for over-the-air distribution to up to 10,000 testers.
