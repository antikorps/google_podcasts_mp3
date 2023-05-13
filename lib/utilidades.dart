String normalizarNombre(String? titulo) {
  if (titulo == null) {
    return "sin_titulo";
  }
  final noAlfaNumerico = RegExp(r"\W");
  titulo = titulo.replaceAll(noAlfaNumerico, "_");
  final multiplesGuiones = RegExp(r"_{2,}");
  titulo = titulo.replaceAll(multiplesGuiones, "_");
  if (titulo.length > 12) {
    return titulo.substring(0, 11);
  }
  return titulo;
}
