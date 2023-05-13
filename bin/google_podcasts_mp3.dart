import 'package:google_podcasts_mp3/controlador.dart' as google_podcasts_mp3;

void main(List<String> arguments) async {
  final controlador = google_podcasts_mp3.Controlador();
  controlador.recuperarFeed();
  await controlador.consultarFeed();
  controlador.buscarEpisodios();
  controlador.informarResultados();
  controlador.recopilarEpisodiosDescargar();
  await controlador.gestionarDescargas();
  controlador.informarResumen();
}
