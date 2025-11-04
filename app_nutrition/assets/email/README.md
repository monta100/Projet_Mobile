Place your email logo image here as `logo.png` (recommended ~56px height, PNG with transparent background).

This folder is declared in `pubspec.yaml` so the asset can be bundled. If `APP_LOGO_URL` (or `EMAIL_LOGO_URL`) is not set in `.env`, the email service will try to embed this `logo.png` inline via CID.

If `logo.png` is missing, the email will fallback to showing the app name text.