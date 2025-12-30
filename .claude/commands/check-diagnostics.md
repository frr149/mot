---
description: Verify all Dart diagnostics - Zero Warnings Policy
---

# Check Project Diagnostics

Verifica la calidad del código en el proyecto MOT.

## Paquetes a Verificar

| Paquete | Verificaciones |
|---------|----------------|
| `packages/mot` | dart analyze, dart format --set-exit-if-changed, dart test |
| `packages/mot_flutter` | flutter analyze, flutter format, flutter test |

## Proceso

### 1. Paquete mot (Dart puro)

```bash
cd packages/mot
dart pub get
dart analyze --fatal-infos
dart format --set-exit-if-changed .
dart test
```

### 2. Paquete mot_flutter (si existe)

```bash
cd packages/mot_flutter
flutter pub get
flutter analyze --fatal-infos
flutter format --set-exit-if-changed .
flutter test
```

### 3. Cobertura (opcional)

```bash
cd packages/mot
dart test --coverage
# Generar reporte
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

## Output

```
📋 Diagnósticos del Proyecto MOT

packages/mot:
  dart analyze:  ✅ 0 errores | ❌ X errores
  dart format:   ✅ formatted | ❌ X files need formatting
  dart test:     ✅ X passed  | ❌ X failed
  cobertura:     X%

─────────────────────────────────────
RESUMEN: X errores totales, Y warnings
```

## Zero Warnings Policy

**OBJETIVO**: El proyecto debe tener 0 errores en:
- `dart analyze` con `--fatal-infos`
- `dart format` (código formateado)
- `dart test` (todos los tests pasan)

## Cuándo Usar

- Antes de crear un PR
- Después de un refactor
- Para diagnosticar el estado del proyecto
- El skill `/commit` ejecuta esto automáticamente
