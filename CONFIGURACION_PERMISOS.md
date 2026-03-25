# Configuración necesaria para iOS y Android

## Android — android/app/src/main/AndroidManifest.xml
Agrega dentro de <manifest>:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```

Agrega dentro de <application> para abrir PDFs:
```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/provider_paths"/>
</provider>
```

Crea el archivo android/app/src/main/res/xml/provider_paths.xml:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <files-path name="files" path="."/>
    <external-files-path name="external_files" path="."/>
</paths>
```

## iOS — ios/Runner/Info.plist
Agrega dentro de <dict>:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
</array>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesario para guardar PDFs</string>
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>PDF</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.adobe.pdf</string>
        </array>
    </dict>
</array>
```
