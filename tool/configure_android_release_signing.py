from pathlib import Path

path = Path('android/app/build.gradle.kts')
text = path.read_text()

if 'signingConfigs.create("release")' not in text:
    marker = '    buildTypes {'
    signing = '''    signingConfigs.create("release") {
        keyAlias = System.getenv("ANDROID_KEY_ALIAS")
        keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        storeFile = file(System.getenv("ANDROID_KEYSTORE_PATH"))
        storePassword = System.getenv("ANDROID_STORE_PASSWORD")
    }

'''
    if marker not in text:
        raise SystemExit('Could not find buildTypes block in generated Gradle file')
    text = text.replace(marker, signing + marker, 1)

text = text.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
path.write_text(text)
