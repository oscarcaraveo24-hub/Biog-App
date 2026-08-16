# Primer arranque despues de instalar o de rotar la llave.
#
# A partir de aqui ya NO hace falta: `MapsApiKey` guarda la llave en las
# preferencias del telefono la primera vez que la ve, y los arranques
# siguientes la recuperan solos. Un `flutter run` a secas funciona igual,
# con buscador de direcciones y nombre de la ubicacion incluidos.
#
# Vuelve a usar este script solo si cambias la llave o si reinstalas la app
# (una reinstalacion borra las preferencias).
flutter run --dart-define=GOOGLE_MAPS_API_KEY="AIzaSyCujhe2xUFhzPkfgj6PkQgTwfn2fcqHwBA"
