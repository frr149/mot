# CLAUDE.md - MOT Framework

## Idioma y Comunicación

- **Comunicación:** Español de España (castellano)
- **Código:** Inglés (nombres de variables, funciones, clases, tipos)
- **Comentarios en código:** Inglés
- **Documentación técnica (dartdoc):** Inglés
- **Commits:** Inglés (ver sección "Git Workflow")

---

## Uso de Modelos

- **Tareas complejas** (arquitectura, código de dominio, debugging): Usar Opus/Sonnet
- **Tareas banales** (commits, editar TASKS.md, renombrar archivos): Usar Haiku
- **Notificación obligatoria:** Cuando se use un modelo barato, notificar al usuario con `[Haiku]`

---

## Informes de Finalización de Tareas

Al completar un conjunto de tareas (especialmente tras trabajo autónomo prolongado), incluir:

1. **Timestamp human-friendly**: "Completado: 23 dic 2024, 23:45 (hora local)"
2. **Resumen estructurado**: Lista de tareas completadas con estado
3. **Hallazgos críticos**: Problemas urgentes destacados
4. **Siguiente paso recomendado**: Qué debería hacerse a continuación

---

## Gestión de TASKS.md (OBLIGATORIO)

**REGLA CRÍTICA**: `docs/llm/TASKS.md` es la fuente de verdad del proyecto. DEBE mantenerse actualizado.

### Cuándo actualizar TASKS.md

1. **Al COMPLETAR cualquier tarea**: Marcar con ✅ INMEDIATAMENTE
2. **Al EMPEZAR una tarea**: Marcar con ⏳
3. **Al DESCUBRIR un problema**: Añadir nueva tarea
4. **Al BLOQUEAR una tarea**: Marcar y documentar el bloqueo
5. **ANTES de cada commit**: Verificar que TASKS.md refleja el trabajo hecho

### Formato de estados

| Estado  | Significado              |
| ------- | ------------------------ |
| (vacío) | Pendiente, no iniciada   |
| ⏳      | En progreso              |
| ✅      | Completada               |
| 🔜      | Aplazada                 |
| ❌      | Cancelada/descartada     |

---

## Principio Sacrosanto: Simplicity of Interface

> **"Simplicity of interface over simplicity of implementation"**

MOT prioriza la experiencia del usuario sobre la facilidad de implementación interna. Esto significa:

1. **MOT debe ser invisible** — "It just works". El usuario no debería pensar en el framework.
2. **Suscribirse y olvidar** — No hay cleanup manual. Si el observer muere, la limpieza es automática.
3. **Cero sorpresas** — El comportamiento debe ser obvio y predecible.
4. **Mínima ceremonia** — La API más corta que siga siendo clara y segura.

Si una decisión de diseño implica:
- API simple + implementación compleja → **Hazlo**
- API compleja + implementación simple → **No lo hagas**

El usuario nunca debería pagar el precio de nuestra comodidad como implementadores.

---

## Descripción del Proyecto

**MOT (Multitude of Triads)** es un framework de gestión de estado para Dart y Flutter que propone una alternativa cuerda a las soluciones existentes.

### Filosofía Central

> **El dominio vive fuera del árbol. La UI lo observa.**

MOT separa el estado del árbol de widgets con una arquitectura basada en tríadas:

- **Model** — estado y lógica, soberano y observable (powered by Beacon)
- **Observer** — puente reactivo entre modelo y UI
- **Widget** — proyección visual, deliberadamente pasiva

### Documentación de Referencia

- `docs/llm/mot_manifesto.md` — Manifiesto completo con todas las abstracciones
- `docs/llm/implementation.md` — Detalles de implementación (WeakReference, Finalizer, microqueue)
- `docs/llm/dart.md` — Guidelines de Dart obligatorios

---

## Stack Tecnológico

| Capa            | Tecnología                              |
| --------------- | --------------------------------------- |
| Lenguaje        | Dart ≥ 3.0                              |
| Testing         | test + glados (PBT) + mocktail          |
| Linting         | dart analyze (zero warnings)            |
| Formatting      | dart format                             |
| Package Manager | dart pub (NUNCA otros gestores)         |
| CI              | GitHub Actions                          |

---

## Estructura del Proyecto

```
mot/
├── lib/
│   └── mot.dart                 # Export barrel
│   └── src/
│       ├── beacon.dart          # Beacon mixin/class
│       ├── beacon_field.dart    # BeaconField<T>
│       ├── change_set.dart      # ChangeSet types
│       ├── observer.dart        # ObserverState base
│       ├── field_observer.dart  # BeaconFieldObserver widget
│       ├── beacon_tower.dart    # Signal bus
│       └── advisor.dart         # Advisor pattern
├── test/
│   ├── beacon_test.dart
│   ├── beacon_field_test.dart
│   ├── change_set_test.dart
│   ├── observer_test.dart
│   ├── beacon_tower_test.dart
│   └── property/               # Property-based tests con glados
│       └── *.dart
├── example/
│   └── *.dart                  # Ejemplos de uso
├── docs/
│   └── llm/
│       ├── CLAUDE.md           # Este archivo
│       ├── TASKS.md            # Backlog del proyecto
│       ├── mot_manifesto.md    # Manifiesto
│       ├── implementation.md   # Detalles de implementación
│       └── dart.md             # Guidelines de Dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Decisiones de Diseño v1.0

| Decisión | Resultado |
|----------|-----------|
| Identificación | Por observer: `beacon.observe(this, (self) => ...)` |
| Notificaciones | Microqueue siempre (`scheduleMicrotask`) |
| Batching | Solo implícito (microqueue coalescente) |
| Paquetes | Split: `mot` (Dart puro) + `mot_flutter` |
| BeaconField | Independiente (no notifica a parent en v1.0) |
| Errores | `Zone.current.handleUncaughtError()` |
| Nomenclatura | `observe`, `removeObserver`, `notify` |

---

## API v1.0

### Beacon (mixin)

```dart
mixin Beacon on Object {
  void observe<T extends Object>(T observer, void Function(T self) callback);
  void removeObserver<T extends Object>(T observer);
  bool hasObserver<T extends Object>(T observer);
  void notify();
}
```

### BeaconField<T>

```dart
class BeaconField<T> with Beacon {
  BeaconField(T initialValue);
  T get value;
  set value(T newValue);  // Notifica si cambia
}
```

### Uso típico

```dart
class UserModel with Beacon {
  final name = BeaconField<String>('');
  final age = BeaconField<int>(0);
}

// En un widget State:
@override
void initState() {
  super.initState();
  user.name.observe(this, (self) => self.setState(() {}));
  // Listo. Limpieza automática cuando el widget muere.
}
```

---

## Abstracciones (Roadmap)

| Abstracción           | Estado    | Propósito                                      |
| --------------------- | --------- | ---------------------------------------------- |
| `Beacon`              | **v1.0**  | Mixin de observación segura                    |
| `BeaconField<T>`      | **v1.0**  | Campo observable independiente                 |
| `ChangeSet`           | Backlog   | Cambio como dato                               |
| `BeaconTower`         | Backlog   | Señales type-safe entre componentes            |
| `BeaconList<T>`       | Backlog   | Lista observable                               |
| `BeaconMap<K,V>`      | Backlog   | Mapa observable                                |

---

## Testing

### Framework y Herramientas

- **`package:test`** — Framework de testing
- **`package:glados`** — Property-based testing (PBT)
- **`package:mocktail`** — Mocking (preferir fakes cuando sea simple)

### Requisitos de Cobertura

Cada función y clase debe tener tests cubriendo:

- **Caso nominal**: comportamiento esperado con input válido
- **Casos límite**: colecciones vacías, cero, null (si nullable), boundaries
- **Casos de error**: input inválido, excepciones esperadas

### Propiedades a Testear (PBT)

| Propiedad               | Ejemplo                                           |
| ----------------------- | ------------------------------------------------- |
| Roundtrip               | `fromJson(toJson(x)) == x`                        |
| Invertibilidad          | `invert(invert(changeSet)) == changeSet`          |
| Idempotencia            | `distinct(distinct(list)) == distinct(list)`      |
| Preservación invariante | `setValue(v); getValue() == v`                    |
| Equivalencia batch      | `applyBatch(changes) == changes.fold(apply)`      |

---

## Git Workflow

### Ramas

| Rama               | Propósito                    |
| ------------------ | ---------------------------- |
| `main`             | Producción estable           |
| `feature/<nombre>` | Nueva funcionalidad          |
| `fix/<nombre>`     | Corrección de bugs           |
| `chore/<nombre>`   | Tareas técnicas              |

### Convenciones de Commits

Formato: `<tipo>: <descripción concisa en inglés>`

**Tipos:**

- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `refactor`: Cambio sin cambiar comportamiento
- `test`: Añadir o modificar tests
- `docs`: Documentación
- `chore`: Mantenimiento

**Ejemplos:**

```
feat: add BeaconField with fine-grained notifications
fix: prevent notification during batch operation
refactor: extract weak reference logic to separate class
test: add property-based tests for ChangeSet roundtrip
```

---

## Guidelines Obligatorios

**ES OBLIGATORIO seguir `docs/llm/dart.md` en todo el código.**

Puntos clave:

- Type hints explícitos en todas las APIs públicas
- `final` sobre `var` — mutabilidad solo cuando sea estrictamente necesario
- Pattern matching (Dart 3+) para control de flujo
- Records para datos puros, clases para entidades con identidad/comportamiento
- Sealed classes para jerarquías cerradas
- Null safety estricto — evitar `!` excepto con invariante documentado
- Dartdoc en inglés para toda API pública
- Zero warnings en `dart analyze`

---

## Comandos

```bash
# Dependencias
dart pub get

# Tests
dart test
dart test --coverage

# Análisis
dart analyze
dart format .

# Publicar (cuando esté listo)
dart pub publish --dry-run
```

---

## Principios de Implementación

### Safe Observer Pattern

MOT usa WeakReference + Finalizer para que olvidar `removeObserver()` no sea catastrófico:

- El callback no captura `this`, recibe `self` como parámetro
- El observer se almacena en WeakReference
- Un Finalizer limpia automáticamente cuando el GC reclama el observer

### Microqueue Notifications

Las notificaciones se programan en la microqueue (`scheduleMicrotask`) para:

- Evitar notificaciones síncronas durante builds
- Permitir batching natural de cambios
- Prevenir stack overflow por notificaciones en cascada

Ver `docs/llm/implementation.md` para detalles.
