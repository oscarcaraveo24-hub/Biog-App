enum OnboardingStep {
  location,
  cultivationScale,

  /// «¿Cómo es tu tierra?». Va en posición 3: después de la escala de cultivo y
  /// **antes** de la categoría de cultivo.
  ///
  /// Por qué exactamente ahí:
  ///
  /// · Es atributo de la PARCELA, no del cultivo. Agrupa con ubicación y
  ///   escala. La textura no cambia si mañana se siembra frijol en vez de maíz.
  /// · Tiene que ir antes de la categoría porque de ahí en adelante el flujo se
  ///   ramifica en seis modos —árbol, ornamental, bulbo, anual ornamental,
  ///   floración recurrente, guía— con saltos condicionales. Insertarlo después
  ///   multiplicaría los casos por seis; antes, cuesta cero.
  /// · No entra en las cascadas de limpieza: el manejador que borra el borrador
  ///   al cambiar de cultivo no lo incluye, que es justo lo que se quiere —
  ///   cambiar de cultivo no debe borrar la tierra—.
  /// · Se salta cuando la escala ya lo dice (maceta): ahí el medio es sustrato
  ///   y preguntar por textura mineral no tiene sentido.
  soilTexture,

  cropCategory,
  cropDetails,
  cropStage,
  cropDate,
  pairBioG,
}
