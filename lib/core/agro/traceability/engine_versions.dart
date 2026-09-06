// lib/core/agro/traceability/engine_versions.dart
//
// Versiones de los motores que producen consejo agronómico.
//
// Sin esto es imposible responder la pregunta que cualquier auditoría, cliente
// serio o reclamación va a hacer: "¿con qué reglas me dijiste esto en marzo?".
// El código cambia; el registro de lo que se aconsejó no. La única forma de
// reconstruir una recomendación vieja es saber qué versión la emitió.
//
// Regla de mantenimiento: subir la versión SIEMPRE que cambie el resultado
// para una misma entrada. Refactors que no alteran la salida no la tocan.
//
//  - MAJOR: cambia la semántica de una acción (p. ej. `esperar` pasa a
//    significar otra cosa) o desaparece un estado.
//  - MINOR: cambia un umbral, se añade una regla, cambia una redacción que el
//    agricultor lee como razón.
//  - PATCH: corrección de un defecto sin cambiar la política declarada.

class BioGEngineVersions {
  const BioGEngineVersions._();

  /// Motor de riego por veto (Fundacional 2.1 §V1-A).
  ///
  /// 1.0.0 — Primera versión con decisión estructurada de cinco estados,
  ///         veto por lluvia, vigencia de lectura y confianza degradable.
  ///         Sustituye al `switch` de cuatro cadenas del presentador del Panel.
  static const String irrigation = '1.0.0';

  /// Motor de eventos agronómicos existente.
  ///
  /// Se versiona a partir de ahora sin cambiar su comportamiento: 1.0.0 es la
  /// foto de lo que ya hacía, para que los registros nuevos sean comparables.
  static const String events = '1.0.0';

  /// Motor de score de suelo.
  ///
  /// 2.0.0 — NPK Interpretation Reset (Guía oficial del nuevo motor
  ///         nutricional v0.4, §4 y §6). N/P/K crudos salen del score (peso
  ///         cero); una señal ausente sale del denominador en vez de valer 0 o
  ///         0.5; la cobertura de evidencia se reporta aparte. MAJOR porque el
  ///         mismo dato produce otro número y desaparece el score nutricional.
  static const String agroScore = '2.0.0';

  /// Planificador de fertilización por déficit (raw → target → déficit ppm →
  /// dosis). **Retirado del runtime** en el NPK Interpretation Reset; se
  /// conserva la constante para poder leer registros antiguos que la citan.
  /// El último código vivo está en el tag `legacy-npk-v1`.
  static const String fertilization = '1.1.0';

  /// Motor de manejo nutricional (Nutrition Readiness Engine).
  ///
  /// 1.0.0 — Primera versión: estados LEARNING → MONITOR → PREPARE → ACTION
  ///         WINDOW → RESPONSE WINDOW a partir de cultivo, etapa, guía
  ///         auditada, reglas 3R, historial de aplicaciones y condiciones
  ///         físicas. Nunca lee N/P/K de la sonda para decidir; solo los usa
  ///         como firma de respuesta después de una aplicación registrada.
  static const String nutrition = '1.0.0';

  /// Detector de ventana de respuesta (firma multicanal EC + N/P/K + VWC).
  ///
  /// 1.0.0 — Baseline robusto (mediana/MAD) sobre ventana limpia previa,
  ///         firmas ionicImmediate / ureaDelayed / mixed / unknown, veredicto
  ///         compatible / menor / inconcluso / no comparable.
  static const String responseWindow = '1.0.0';

  /// Versión del formato del registro auditable de recomendaciones.
  ///
  /// Independiente de los motores: describe la forma de la fila guardada, no
  /// las reglas que la produjeron.
  static const String recommendationRecordSchema = '1';
}
