#!/usr/bin/env bash
# شغّله من جذر المشروع (openlibrary/):  bash fix-android-layout.sh
# يحوّل مجلد android/ من تخطيط Gradle القديم إلى تخطيط Qt، ولا يكتب فوق ملف موجود أصلاً في المكان الجديد.
set -euo pipefail
cd android

mkdir -p src/com/ahmed_x86/openlibrary

OLD_J=app/src/main/java/com/ahmed_x86/openlibrary/MainActivity.java
NEW_J=src/com/ahmed_x86/openlibrary/MainActivity.java
[ -f "$OLD_J" ] && [ ! -f "$NEW_J" ] && mv "$OLD_J" "$NEW_J"

OLD_M=app/src/main/AndroidManifest.xml
[ -f "$OLD_M" ] && [ ! -f AndroidManifest.xml ] && mv "$OLD_M" AndroidManifest.xml

# حذف بقايا Gradle القديمة (قالب Qt يولّد البديل أثناء البناء)
rm -rf app build.gradle settings.gradle gradle gradlew gradlew.bat .gradle local.properties

# تحقق من أن الملفين بنسخة Qt وليسا القديمين
fail() { echo "✗ $1"; exit 1; }
grep -q 'INSERT_APP_LIB_NAME' AndroidManifest.xml || fail "AndroidManifest.xml ليس بنسخة Qt: انسخ النسخة المرفقة فوقه"
grep -q 'extends QtActivity' "$NEW_J"             || fail "MainActivity.java ليس بنسخة Qt: انسخ النسخة المرفقة فوقه"

echo "✓ التخطيط صحيح:"; find . -type f | sort
