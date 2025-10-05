# Posture Reminder App

Una aplicación móvil diseñada especialmente para adultos mayores para ayudarles a mantener una buena postura mediante recordatorios personalizables.

## Características Principales

- Recordatorios personalizables de postura
- Interfaz simplificada para adultos mayores
- Sincronización en la nube con Firebase
- Almacenamiento local
- Notificaciones locales
- Diseño de alta legibilidad

## Testeos
- La aplicación está probada solo en android en el emulador Pixel 5.

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/tuusuario/posture_reminder_mobile_app.git
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Configurar los iconos y splash screen:
```bash
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

4. Ejecutar la aplicación:
```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── data/
│   ├── datasources/
│   │   ├── firebase_datasource.dart    # Gestión de datos en Firebase
│   │   ├── local_datasource.dart       # Almacenamiento local
│   │   └── notification_service.dart    # Servicio de notificaciones
│   ├── models/
│   │   └── reminder_model.dart         # Modelo de datos
│   └── repositories/
│       └── reminder_repository_impl.dart # Implementación del repositorio
│
├── domain/
│   ├── entities/
│   │   └── reminder.dart               # Entidad principal
│   └── repositories/
│       └── reminder_repository.dart     # Contrato del repositorio
│
├── presentation/
│   ├── bloc/
│   │   └── reminder_bloc.dart          # Gestión de estado
│   └── screens/
│       ├── create_reminder/            # Pantalla de creación
│       ├── home/                       # Pantalla principal
│       ├── login/                      # Autenticación
│       └── my_reminders/              # Lista de recordatorios
│
└── theme/
    └── app_styles.dart                # Estilos globales
```

## Tecnologías Utilizadas

- Flutter
- Firebase
- BLoC Pattern
- Clean Architecture

## Problemas Conocidos

# Error Google API

Existe un error conocido con Google API Manager que muestra el siguiente log:
```
E/GoogleApiManager: Failed to get service from broker.
E/GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'
```
Este es un [issue conocido de Google](https://issuetracker.google.com/issues/369219148) que está pendiente de solución.

# Problema con notificaciones

No se logró actualizar las remind cards en segundo plano, por ahora la aplicación se abre forzadamente para que la ui se actualice con las acciones de la notificación.


## Checklist Desafio

## 1. Creación y Gestión de Recordatorios
- [✔] Crear recordatorios
- [✔] Editar recordatorios
- [✔] Eliminar recordatorios
- Estructura del recordatorio:
  - [✔] Título
  - [✔] Descripción
  - [✔] Fecha y hora
  - [✔] Frecuencia (Único/Diario/Semanal/Personalizado)
  - [✔] Estado (Pendiente/Completado/Omitido)
- [✔] Almacenamiento local (SharedPreferences)
- [✔] Sincronización con Firebase

## 2. Notificaciones Push
- [✔] Implementación de flutter_local_notifications
- [✔] Mostrar título y descripción
- [✔] Acciones rápidas en notificación
  - [✔] Marcar como completado
  - [✔] Otras acciones personalizadas (Aplazado)

## 3. Pantalla Principal (Home -> My Reminders)
En este punto me tomé la libertad de diseñar la pagina principal más simple con 2 opciones pensada para adultos mayores, debido a que la home con las cards de recordatorios inmediatamente podria verse un poco complicado como primera pantalla.
- [✔] Lista de recordatorios
  - [X] Ordenamiento por fecha
  - [✔] Ordenamiento por estado
- [✔] Filtros
  - [✔] Pendientes
  - [✔] Completados
  - [✔] Omitidos
- [✔] Diseño adaptado para adultos mayores

## 4. Características Adicionales
- Repeticiones avanzadas
  - [✔] Intervalos personalizados
  - [✔] Selección de días específicos
- Autenticación
  - [✔] Firebase Auth
  - [✔] Modo invitado
- Firebase Realtime
  - [✔] Sincronización automática
- [✔] Función "Aplazar"
  - [✔] Botón en notificación
  - [✔] Tiempo predeterminado (2 min)

## Posibles mejoras

- Actualizar UI sin abrir aplicación con las notificaciones.
- Probar aplicación en más tamaños de emuladores Android.
- Optimizar aplicación para IOS.
- Recolectar información de usuarios finales (adultos mayores) para mejora continua.

## Autor

Carlos Salinas
