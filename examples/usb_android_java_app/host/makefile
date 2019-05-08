# pm install DeviceControl.apk
# am start -n example.DeviceControl/.DeviceControl
# am force-stop example.DeviceControl
# pm uninstall example.DeviceControl

all:
	@mkdir -p obj apk apk/lib/arm64-v8a ../bin
	cd jni ; ndk-build APP_ABI=arm64-v8a
	cp libs/arm64-v8a/*.so apk/lib/arm64-v8a/
	@rm -f keystore
	javac src/example/DeviceControl/DeviceControl.java \
	  -sourcepath src -d obj \
	  -cp ${ANDROID_SDK}/platforms/android-25/android.jar:obj
	dx --dex --output apk/classes.dex obj
	aapt package -f -M AndroidManifest.xml \
	  -F ../bin/DeviceControl.apk \
	  -I ${ANDROID_SDK}/platforms/android-25/android.jar apk
	echo | keytool -genkeypair -validity 10000 \
	  -dname 'CN=AndroidDebug, O=Android, C=US' -keystore keystore \
	  -storepass android -alias androiddebugkey \
	  -keyalg RSA -keysize 2048 2>/dev/null
	echo android | apksigner sign --ks keystore ../bin/DeviceControl.apk
	@rm -f keystore

clean:
	rm -rf obj apk libs keystore ../bin/DeviceControl.apk
