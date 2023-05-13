import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:google_podcasts_mp3/utilidades.dart' as utilidades;

class InfoEpisodio {
  late int indice;
  String? fecha;
  String? titulo;
  String? descripcion;
  late String mp3;
}

class ResumenDescarga {
  late String nombre;
  late String error;

  ResumenDescarga(this.nombre, this.error);
}

class Controlador {
  String feed = "";
  Document? html;
  List<InfoEpisodio> episodios = [];
  late Directory ruta;
  List<String> exitos = [];

  void gestionarError(String mensajeError, bool critico) async {
    if (critico) {
      mensajeError = "ERROR CRÍTICO: $mensajeError";
    } else {
      mensajeError = "ATENCIÓN: $mensajeError";
    }
    //stderr.write(mensajeError);
    print(mensajeError);
    if (critico) {
      exit(1);
    }
  }

  void recuperarFeed() async {
    print("Incorpora el Feed del podcast a descargar:");
    final entradaUsuario = stdin.readLineSync();
    if (entradaUsuario == null) {
      gestionarError("la entrada del usuario es null", true);
    }
    feed = "https://podcasts.google.com/feed/${entradaUsuario!.trim()}";
  }

  Future consultarFeed() async {
    final respuesta = await http.get(Uri.parse(feed));
    if (respuesta.statusCode != 200) {
      final mensajeError =
          "el feed ha recibido un status code incorrecto: ${respuesta.statusCode}";
      gestionarError(mensajeError, false);
    }
    html = parse(respuesta.body);
  }

  void buscarEpisodios() {
    if (html == null) {
      gestionarError("no se ha podido parsear la respuesta del feed", true);
    }
    final selectoresEpisodios = html!.querySelectorAll('a[role="listitem"]');
    if (selectoresEpisodios.isEmpty) {
      gestionarError("no se han encontrado episodios", false);
    }
    analizarEpisodios(selectoresEpisodios);
  }

  void analizarEpisodios(List<Element> selectoresEpisodios) {
    for (var i = 0; i < selectoresEpisodios.length; i++) {
      // :nth-child no está implementado en html
      // probar en el futuro: https://pub.dev/packages/universal_html

      final contenidosPresentacion =
          selectoresEpisodios[i].querySelectorAll('div[role="presentation"]');

      var infoEpisodio = InfoEpisodio();

      if (contenidosPresentacion.length == 3) {
        infoEpisodio.fecha = contenidosPresentacion[0].text;
        infoEpisodio.titulo = contenidosPresentacion[1].text;
        infoEpisodio.descripcion = contenidosPresentacion[2].text;
      }

      final selectorEnlace =
          selectoresEpisodios[i].querySelector('div[jsdata]');
      if (selectorEnlace == null) {
        gestionarError("el registro $i no tiene selector div[jsdata]", false);
        continue;
      }

      final enlace = selectorEnlace.attributes["jsdata"];
      if (enlace == null) {
        gestionarError("el registro $i no tiene selector div[jsdata]", false);
        continue;
      }

      final componentesEnlace = enlace.split(";");
      if (componentesEnlace.length != 3) {
        gestionarError(
            "el registro $i no tiene 3 componentes en el enlace", false);
        continue;
      }
      infoEpisodio.mp3 = componentesEnlace[1];
      infoEpisodio.indice = i + 1;

      episodios.add(infoEpisodio);
    }
  }

  void informarResultados() {
    print("\nIntroduce la ruta donde quieres guardar los informes:");
    final carpetaDestino = stdin.readLineSync();
    if (carpetaDestino == null) {
      gestionarError("la entrada del usuario para el destino es null", true);
    }
    final rutaDestino = Directory(carpetaDestino!);
    ruta = rutaDestino;

    if (rutaDestino.existsSync() == false) {
      gestionarError("la ruta introducida no existe", true);
    }

    // CSV y JSON
    List<List<Object>> lineasCSV = [
      ["indice", "fecha", "titulo", "descripcion", "mp3"]
    ];
    List<Map<String, Object?>> registrosJSON = [];

    for (final episodio in episodios) {
      var lineaCSV = [
        episodio.indice,
        episodio.fecha ?? "",
        episodio.titulo ?? "",
        episodio.descripcion ?? "",
        episodio.mp3
      ];
      lineasCSV.add(lineaCSV);
      var registroJSON = {
        "indice": episodio.indice,
        "fecha": episodio.fecha,
        "titulo": episodio.titulo,
        "descripcion": episodio.descripcion,
        "mp3": episodio.mp3
      };
      registrosJSON.add(registroJSON);
    }

    final contenidoCSV = const ListToCsvConverter().convert(lineasCSV);
    final rutaCSV = path.join(rutaDestino.path, "episodios_podcast.csv");
    File archivoCSV = File(rutaCSV);
    archivoCSV.writeAsStringSync(contenidoCSV);

    final contenidoJSON = jsonEncode(registrosJSON);
    final rutaJSON = path.join(rutaDestino.path, "episodios_podcast.json");
    File archivoJSON = File(rutaJSON);
    archivoJSON.writeAsStringSync(contenidoJSON);

    print("""

Informes del análisis generados correctamente.
Puedes consultarlo en formato csv y json en:
- $rutaCSV
- $rutaJSON
Se han encontado ${episodios.length} episodios.
""");
  }

  void recopilarEpisodiosDescargar() {
    print("""
Si quieres descargar algún podcast introduce los índices de 
los programas deseados separados por comas y pulsa intro. 
Por ejemplo, para descargar el primer, tercer y quinto programa:
1,3,5""");
    final entradaDescargas = stdin.readLineSync();
    if (entradaDescargas == null) {
      gestionarError("la entrada en la selección de descargas en nula", true);
    }
    final episodiosDescargar = entradaDescargas!.split(",");
    final indicesDescargar = [];
    for (final episodioDescargar in episodiosDescargar) {
      var episodio = episodioDescargar.trim();
      try {
        final numero = int.parse(episodio);
        if (numero < 0) {
          gestionarError("el índice para $episodio no puede menor de 0", false);
          continue;
        }
        indicesDescargar.add(numero);
      } catch (error) {
        gestionarError(
            "no se ha podido obtener un número de $episodioDescargar", false);
        continue;
      }
    }

    List<InfoEpisodio> episodiosConfirmados = [];
    for (final episodio in episodios) {
      if (indicesDescargar.contains(episodio.indice)) {
        episodiosConfirmados.add(episodio);
      }
    }

    episodios = episodiosConfirmados;

    print("""

Se han identificado ${indicesDescargar.length} programas a descargar.
Pulsa intro para continuar.""");

    stdin.readLineSync();
  }

  Future<ResumenDescarga> descargar(String url, String ruta) async {
    try {
      final respuesta = await http.get(Uri.parse(url));
      File(ruta).writeAsBytesSync(respuesta.bodyBytes);
      return ResumenDescarga(ruta, "");
    } catch (error) {
      return ResumenDescarga(ruta, error.toString());
    }
  }

  Future gestionarDescargas() async {
    final maximasDescargas = 3;
    var descargasGestionadas = 0;
    var continuarDescargas = true;

    while (continuarDescargas) {
      List<Future<ResumenDescarga>> resultados = [];

      for (var i = 0; i < maximasDescargas; i++) {
        final episodio = episodios[descargasGestionadas];
        final nombreArchivo =
            "${episodio.indice}_${utilidades.normalizarNombre(episodio.titulo)}.mp3";
        final rutaArchivo = path.join(ruta.path, nombreArchivo);
        resultados.add(descargar(episodio.mp3, rutaArchivo));
        descargasGestionadas++;

        if (descargasGestionadas == episodios.length) {
          continuarDescargas = false;
          break;
        }
      }

      final resultadosCompletos = await Future.wait(resultados);
      for (final resultado in resultadosCompletos) {
        if (resultado.error != "") {
          final mensajeError =
              "no se ha podido descargar ${resultado.nombre}: ${resultado.error}";
          gestionarError(mensajeError, false);
          continue;
        }
        exitos.add(resultado.nombre);
      }
    }
  }

  void informarResumen() {
    print("""
Se han descargado correctamente ${exitos.length} archivos.
Estan disponibles en:""");
    for (final descarga in exitos) {
      print("-- $descarga");
    }
  }
}
