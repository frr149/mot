# TASKS.md - MOT Framework

> Fuente de verdad del proyecto. Mantener actualizado.

---

## Decisiones de Diseño v1.0 (Cerradas)

| # | Decisión | Resultado |
|---|----------|-----------|
| D1 | Identificación de observers | Por observer: `beacon.observe(this, (self) => ...)` |
| D2 | Notificaciones | Microqueue siempre (`scheduleMicrotask`), escape hatch para tests |
| D3 | Batching | Solo implícito (microqueue coalescente), sin API de batch explícito |
| D4 | Paquetes | Split: `mot` (Dart puro) + `mot_flutter` (widgets) |
| D5 | BeaconField → parent | Independiente en v1.0 (notificar a parent → backlog) |
| D6 | ChangeSet | No en v1.0 (backlog) |
| D7 | BeaconTower | No en v1.0 (backlog, type-safe con sealed classes) |
| D8 | Errores en callbacks | `Zone.current.handleUncaughtError()` |
| D9 | Nomenclatura | `observe`, `removeObserver`, `notify` |

---

## Alcance v1.0

### Incluido

- **`mot` (Dart puro)**
  - `Beacon` mixin con observación segura
  - `BeaconField<T>` independiente
  - WeakReference + Finalizer + limpieza oportunista
  - Microqueue notifications

- **`mot_flutter`**
  - Helpers básicos para integración con Flutter
  - Re-exporta `mot`

### Excluido (Backlog)

- BeaconField notifica a parent
- ChangeSet (cambio como dato)
- BeaconTower (señales type-safe)
- Undo/redo
- BeaconList<T>, BeaconMap<K,V>
- DevTools extension

---

## Fase 0: Setup del Proyecto

- [ ] Crear estructura de monorepo:
  ```
  mot/
  ├── packages/
  │   ├── mot/           # Dart puro
  │   └── mot_flutter/   # Flutter
  ```
- [ ] Crear `packages/mot/pubspec.yaml`
- [ ] Crear `packages/mot_flutter/pubspec.yaml` (depende de mot)
- [ ] Crear `analysis_options.yaml` con reglas estrictas
- [ ] Crear `packages/mot/lib/mot.dart` (barrel export)
- [ ] Añadir dependencias dev: `test`, `glados`, `mocktail`

---

## Fase 1: Core — ObserverEntry

La unidad mínima de observación.

### 1.1 Implementación

- [ ] Crear `lib/src/observer_entry.dart`
- [ ] Implementar `ObserverEntry<T extends Object>`:
  ```dart
  class ObserverEntry<T extends Object> {
    final WeakReference<T> _observerRef;
    final void Function(T self) callback;
    final int id;

    bool get isAlive;
    bool tryInvoke();
  }
  ```

### 1.2 Tests

- [ ] `isAlive` true cuando observer vivo
- [ ] `isAlive` false cuando observer muerto (GC'd)
- [ ] `tryInvoke()` ejecuta callback si vivo
- [ ] `tryInvoke()` retorna false si muerto, sin crash

---

## Fase 2: Core — Beacon Mixin

El corazón del sistema.

### 2.1 Estructura

- [ ] Crear `lib/src/beacon.dart`
- [ ] Implementar `mixin Beacon on Object`:
  ```dart
  mixin Beacon on Object {
    final List<ObserverEntry> _observers = [];
    final Map<int, ObserverEntry> _entriesById = {};
    int _nextId = 0;
    bool _notificationScheduled = false;
    late final Finalizer<int> _finalizer;
  }
  ```

### 2.2 Registro de observers

- [ ] `observe<T extends Object>(T observer, void Function(T self) callback)`:
  - Crear entry con WeakRef
  - Registrar en Finalizer
  - Añadir a lista

- [ ] `removeObserver<T extends Object>(T observer)`:
  - Buscar por identidad del observer
  - Detach del Finalizer
  - Remover de lista

- [ ] `hasObserver<T extends Object>(T observer) → bool`

### 2.3 Notificación (microqueue)

- [ ] `notify()`:
  - Si `_notificationScheduled`, no-op (coalescing)
  - `scheduleMicrotask(_executeNotify)`
  - Set `_notificationScheduled = true`

- [ ] `_executeNotify()`:
  - Set `_notificationScheduled = false`
  - Limpieza oportunista: `_observers.removeWhere((e) => !e.isAlive)`
  - Iterar copia de lista
  - `tryInvoke()` cada entry
  - Errores → `Zone.current.handleUncaughtError()`

- [ ] `notifySync()` (escape hatch para tests):
  - Ejecuta `_executeNotify()` síncronamente

### 2.4 Finalizer

- [ ] `_onObserverFinalized(int id)`:
  - Remover de `_entriesById`
  - Remover de `_observers`

### 2.5 Tests para Beacon

**Básicos:**
- [ ] `observe` registra correctamente
- [ ] `notify` invoca callback con `self` correcto
- [ ] `removeObserver` elimina
- [ ] `hasObserver` funciona

**Microqueue:**
- [ ] Múltiples cambios síncronos → una notificación
- [ ] Notificación ocurre después del código síncrono
- [ ] `notifySync()` ejecuta inmediatamente (para tests)

**Limpieza:**
- [ ] Observer muerto no crashea en notify
- [ ] Observer muerto se elimina en notify (limpieza oportunista)

**Errores:**
- [ ] Callback que lanza no detiene otros callbacks
- [ ] Error se reporta via Zone

### 2.6 Tests PBT (glados)

- [ ] Cualquier secuencia de observe/remove/notify no crashea
- [ ] Observers vivos siempre se invocan en notify
- [ ] Observers removidos nunca se invocan

---

## Fase 3: BeaconField<T>

Campo observable independiente.

### 3.1 Implementación

- [ ] Crear `lib/src/beacon_field.dart`
- [ ] Implementar `class BeaconField<T>`:
  ```dart
  class BeaconField<T> with Beacon {
    T _value;

    T get value;
    set value(T newValue);  // Notifica si cambia
  }
  ```

### 3.2 Comportamiento

- [ ] Getter retorna valor actual
- [ ] Setter:
  - Si `newValue == _value`, no-op
  - Si diferente, actualiza y llama `notify()`

### 3.3 Tests

- [ ] Set/get básico
- [ ] No notifica si valor igual (mismo objeto)
- [ ] Notifica si valor diferente
- [ ] Múltiples observers reciben notificación
- [ ] Observer puede leer nuevo valor en callback

### 3.4 Tests PBT

- [ ] `field.value = x; expect(field.value, x)` para cualquier x
- [ ] Notificación siempre ocurre cuando valor cambia

---

## Fase 4: Barrel Export y Documentación

### 4.1 Exports

- [ ] `lib/mot.dart`:
  ```dart
  export 'src/beacon.dart';
  export 'src/beacon_field.dart';
  ```

### 4.2 Dartdoc

- [ ] Documentar `Beacon` mixin
- [ ] Documentar `observe`, `removeObserver`, `notify`
- [ ] Documentar `BeaconField<T>`
- [ ] Ejemplos en dartdoc

---

## Fase 5: mot_flutter

### 5.1 Setup

- [ ] Crear `packages/mot_flutter/pubspec.yaml`
- [ ] Dependencia a `mot`
- [ ] Dependencia a `flutter`

### 5.2 Re-export

- [ ] `lib/mot_flutter.dart`:
  ```dart
  export 'package:mot/mot.dart';
  // + helpers de Flutter
  ```

### 5.3 Helpers (mínimos para v1.0)

- [ ] Evaluar qué helpers son realmente necesarios
- [ ] Posiblemente solo re-export de mot es suficiente

---

## Fase 6: Documentación y Ejemplos

### 6.1 Documentación para humanos

- [ ] README.md para `mot`:
  - Filosofía (principio sacrosanto)
  - Instalación
  - Quick start
  - API

- [ ] README.md para `mot_flutter`:
  - Instalación
  - Uso con Flutter

- [ ] Ejemplo: Counter
- [ ] Ejemplo: User profile con múltiples BeaconFields

### 6.2 Documentación para LLMs (MUY IMPORTANTE)

Los LLMs tienen knowledge cutoff y no conocerán MOT. Debemos generar documentos optimizados para que puedan asistir a usuarios de MOT:

- [ ] `docs/llm/mot_for_llms.md` — Documento completo con:
  - Qué es MOT y su filosofía
  - API completa con ejemplos
  - Patrones comunes
  - Errores típicos y cómo evitarlos
  - Migración desde otros state managers

- [ ] Incluir en el repo instrucciones para usuarios:
  - "Añade este archivo a tu contexto cuando pidas ayuda con MOT"
  - O usar como system prompt

- [ ] Mantener actualizado con cada versión

---

## Fase 7: Publicación

- [ ] `dart analyze` sin warnings
- [ ] `dart format` aplicado
- [ ] Tests al 100%
- [ ] CHANGELOG.md
- [ ] LICENSE (MIT)
- [ ] `dart pub publish --dry-run` sin errores
- [ ] Publicar `mot` v1.0.0
- [ ] Publicar `mot_flutter` v1.0.0

---

## Fase 8: Lanzamiento y Promoción

### 8.1 Web del proyecto

- [ ] Buscar y registrar dominio (mot.dev? motframework.dev? usemot.dev?)
- [ ] Crear landing page:
  - Filosofía y principio sacrosanto
  - Quick start
  - Links a pub.dev y GitHub
  - Ejemplos interactivos (si es viable)

### 8.2 Promoción

- [ ] Anunciar en r/FlutterDev
- [ ] Anunciar en Flutter Discord
- [ ] Post en X/Twitter con hashtags #Flutter #Dart
- [ ] Artículo en Medium o dev.to explicando la filosofía
- [ ] Considerar video corto para YouTube

---

## Backlog (Post v1.0)

### Prioridad Alta

- [ ] **BeaconField notifica a parent**
  - Permitir `BeaconField('', parent: this)`
  - Cambio en field → notifica field + parent

- [ ] **BeaconTower (type-safe)**
  - Señales con sealed classes, NO strings
  ```dart
  sealed class AppSignal {}
  class UserLogout extends AppSignal {}

  BeaconTower.emit(UserLogout());
  BeaconTower.on<UserLogout>((s) => ...);
  ```

### Prioridad Media

- [ ] **ChangeSet**
  - `typedef ChangeSet<T> = ({String field, T oldValue, T newValue})`
  - Listeners detallados que reciben ChangeSet

- [ ] **Batch explícito**
  - `batch(() async { ... })` para operaciones cross-microtask
  - Evaluar si realmente se necesita

### Prioridad Baja

- [ ] BeaconList<T> — lista observable
- [ ] BeaconMap<K,V> — mapa observable
- [ ] Undo/redo basado en ChangeSets
- [ ] DevTools extension
- [ ] Sync remoto con ChangeSets

---

## Notas de Implementación

### Patrón "self, not this"

```dart
// ❌ Captura this → memory leak
beacon.observe(() => this.refresh());

// ✅ No captura nada → seguro
beacon.observe(this, (self) => self.refresh());
```

El callback recibe `self` como parámetro, no captura `this`.

### Triple capa de limpieza

1. **Limpieza oportunista** — en cada `notify()`, elimina entries con `isAlive == false`
2. **Finalizer** — cuando GC reclama observer, callback limpia la entry
3. **Manual opcional** — `removeObserver()` para limpieza determinista

### Microqueue coalescing

```dart
model.name = 'A';  // Schedules notify
model.name = 'B';  // Already scheduled, no-op
model.name = 'C';  // Already scheduled, no-op
// → UNA sola notificación con value = 'C'
```
