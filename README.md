-install

flutter clean

flutter pub get

flutter pub run flutter_launcher_icons:main

flutter pub run flutter_native_splash:create

flutter run



- ajustes pensados para adultos mayores
home screen con dos opcione claras
actualziar recordatorio solo con cambiar dato (con boton integrado igual apra dar seguridad)
reloj tipo rueda con intervalo de minutos de 5 minutos para mas simpleza


Log Error (Issue de Google que no se ha solucionado https://issuetracker.google.com/issues/369219148?pli=1)

E/GoogleApiManager(25974): Failed to get service from broker. 
E/GoogleApiManager(25974): java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
E/GoogleApiManager(25974):      at android.os.Parcel.createExceptionOrNull(Parcel.java:3340)
E/GoogleApiManager(25974):      at android.os.Parcel.createException(Parcel.java:3324)
E/GoogleApiManager(25974):      at android.os.Parcel.readException(Parcel.java:3307)
E/GoogleApiManager(25974):      at android.os.Parcel.readException(Parcel.java:3249)
E/GoogleApiManager(25974):      at aywi.a(:com.google.android.gms@252635038@25.26.35 (260800-783060121):36)
E/GoogleApiManager(25974):      at ayup.z(:com.google.android.gms@252635038@25.26.35 (260800-783060121):143)
E/GoogleApiManager(25974):      at aybo.run(:com.google.android.gms@252635038@25.26.35 (260800-783060121):42)
E/GoogleApiManager(25974):      at android.os.Handler.handleCallback(Handler.java:995)
E/GoogleApiManager(25974):      at android.os.Handler.dispatchMessage(Handler.java:103)
E/GoogleApiManager(25974):      at cirt.mw(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
E/GoogleApiManager(25974):      at cirt.dispatchMessage(:com.google.android.gms@252635038@25.26.35 (260800-783060121):5)
E/GoogleApiManager(25974):      at android.os.Looper.loopOnce(Looper.java:248)
E/GoogleApiManager(25974):      at android.os.Looper.loop(Looper.java:338)
E/GoogleApiManager(25974):      at android.os.HandlerThread.run(HandlerThread.java:85)

