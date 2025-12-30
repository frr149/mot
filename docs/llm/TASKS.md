# TASKS.md - MOT Framework

> Fuente de verdad del proyecto. Mantener actualizado.

---

## Estado Actual

| Fase | Descripción | Estado |
|------|-------------|--------|
| 0 | Setup del proyecto | ✅ (falta mot_flutter pubspec) |
| 1 | ObserverEntry | ✅ |
| 2 | Beacon mixin | ✅ (falta PBT) |
| 3 | BeaconField | ✅ (falta PBT) |
| 4 | Barrel + Dartdoc | ✅ |
| 5 | mot_flutter | ✅ (solo re-export) |
| 6 | Documentación | ⏳ Pendiente |
| 7 | Publicación | ⏳ Pendiente |
| 8 | Web + Promoción | ⏳ Pendiente |

**Total tests: 45** (34 sync + 11 async)

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

## Fase 0: Setup del Proyecto ✅

- [x] Crear estructura de monorepo
- [x] Crear `packages/mot/pubspec.yaml`
- [ ] Crear `packages/mot_flutter/pubspec.yaml` (depende de mot)
- [x] Crear `analysis_options.yaml` con reglas estrictas
- [x] Crear `packages/mot/lib/mot.dart` (barrel export)
- [x] Añadir dependencias dev: `test`, `glados`, `mocktail`

---

## Fase 1: Core — ObserverEntry ✅

- [x] Crear `lib/src/observer_entry.dart`
- [x] Implementar `ObserverEntry<T extends Object>`
- [x] Tests: `isAlive`, `tryInvoke()`, `observer` getter, `id` (7 tests)

---

## Fase 2: Core — Beacon Mixin ✅

- [x] Crear `lib/src/beacon.dart`
- [x] Implementar `mixin Beacon on Object` con:
  - `observe()`, `removeObserver()`, `hasObserver()`
  - `notify()` (microqueue), `notifySync()` (tests)
  - Finalizer para limpieza automática
- [x] Tests síncronos (15 tests): registro, notificación, errores
- [x] Tests asíncronos (11 tests): microqueue, coalescing, orden
- [ ] Tests PBT con glados (pendiente)

---

## Fase 3: BeaconField<T> ✅

- [x] Crear `lib/src/beacon_field.dart`
- [x] Implementar `class BeaconField<T> with Beacon`
- [x] Tests síncronos (12 tests): get/set, equality, herencia
- [x] Tests asíncronos: coalescing, microqueue (incluidos en beacon_async_test)
- [ ] Tests PBT con glados (pendiente)

---

## Fase 4: Barrel Export y Documentación

- [x] `lib/mot.dart` barrel export
- [x] Dartdoc en `Beacon` mixin (completo)
- [x] Dartdoc en `BeaconField<T>` (completo)
- [x] Dartdoc en `ObserverEntry` (completo)
- [ ] Revisar ejemplos en dartdoc

---

## Fase 5: mot_flutter ✅

- [x] Crear `packages/mot_flutter/pubspec.yaml`
- [x] Crear `lib/mot_flutter.dart` (re-export de mot)
- [x] Decidido: solo re-export para v1.0 (helpers al backlog)

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
