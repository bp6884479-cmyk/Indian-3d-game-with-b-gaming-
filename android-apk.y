name: IndianCraft Android APK with AdMob

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - 'index.html'
      - 'admob-bridge.js'
      - '.github/workflows/android-apk.yml'

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21

      - name: Check required files
        run: |
          test -f index.html || {
            echo "ERROR: index.html not found"
            exit 1
          }

          test -f admob-bridge.js || {
            echo "ERROR: admob-bridge.js not found in repository root"
            exit 1
          }

      - name: Create Capacitor project and install AdMob
        run: |
          mkdir -p android-game/www
          cp index.html android-game/www/index.html
          cp admob-bridge.js android-game/admob-bridge.js

          cd android-game
          npm init -y

          npm install \
            @capacitor/core@7 \
            @capacitor/android@7 \
            @capacitor-community/admob@7

          npm install --save-dev @capacitor/cli@7 esbuild

          npx esbuild admob-bridge.js \
            --bundle \
            --platform=browser \
            --format=iife \
            --outfile=www/admob-bridge.bundle.js

      - name: Add AdMob bridge to game HTML
        working-directory: android-game
        run: |
          python3 - <<'PY'
          from pathlib import Path
          import re

          html_file = Path("www/index.html")
          html = html_file.read_text(encoding="utf-8")

          script = '<script src="./admob-bridge.bundle.js"></script>'

          if "admob-bridge.bundle.js" in html:
              print("AdMob bridge script already included")
          elif re.search(r"<head\b[^>]*>", html, re.IGNORECASE):
              html = re.sub(
                  r"(<head\b[^>]*>)",
                  lambda match: match.group(1) + "\n" + script + "\n",
                  html,
                  count=1,
                  flags=re.IGNORECASE
              )
          else:
              html = script + "\n" + html

          html_file.write_text(html, encoding="utf-8")
          print("AdMob bridge added to game HTML")
          PY

      - name: Configure Capacitor
        working-directory: android-game
        run: |
          cat > capacitor.config.json <<'EOF'
          {
            "appId": "com.indiancraft3d.game",
            "appName": "Indian Craft 3D",
            "webDir": "www"
          }
          EOF

      - name: Add Android platform
        working-directory: android-game
        run: npx cap add android

      - name: Configure AdMob App ID
        working-directory: android-game
        run: |
          python3 - <<'PY'
          from pathlib import Path
          import xml.etree.ElementTree as ET

          app_id = "ca-app-pub-7956447630438100~9662953701"
          manifest = Path("android/app/src/main/AndroidManifest.xml")

          tree = ET.parse(manifest)
          root = tree.getroot()

          android_ns = "http://schemas.android.com/apk/res/android"
          ET.register_namespace("android", android_ns)

          application = root.find("application")
          if application is None:
              raise SystemExit("Android application element not found")

          name_key = f"{{{android_ns}}}name"
          value_key = f"{{{android_ns}}}value"
          metadata_name = "com.google.android.gms.ads.APPLICATION_ID"

          for item in list(application.findall("meta-data")):
              if item.get(name_key) == metadata_name:
                  application.remove(item)

          ET.SubElement(
              application,
              "meta-data",
              {
                  name_key: metadata_name,
                  value_key: app_id
              }
          )

          tree.write(
              manifest,
              encoding="utf-8",
              xml_declaration=True
          )
          PY

      - name: Sync Capacitor and AdMob plugin
        working-directory: android-game
        run: npx cap sync android

      - name: Build debug APK
        working-directory: android-game
        run: |
          cd android
          chmod +x gradlew
          ./gradlew assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: IndianCraft-Android-APK
          path: android-game/android/app/build/outputs/apk/debug/app-debug.apk
          if-no-files-found: error
