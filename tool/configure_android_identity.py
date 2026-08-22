from pathlib import Path

PACKAGE_ID = 'com.routeperformancetracker.app'
APP_LABEL = 'Route Performance Tracker'

gradle = Path('android/app/build.gradle.kts')
text = gradle.read_text()

import re
text = re.sub(r'namespace\s*=\s*"[^"]+"', f'namespace = "{PACKAGE_ID}"', text, count=1)
text = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{PACKAGE_ID}"', text, count=1)
gradle.write_text(text)

manifest = Path('android/app/src/main/AndroidManifest.xml')
manifest_text = manifest.read_text()
manifest_text = re.sub(r'android:label="[^"]*"', f'android:label="{APP_LABEL}"', manifest_text, count=1)
manifest.write_text(manifest_text)
