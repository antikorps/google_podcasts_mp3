# Descargar MP3 de episodios de Google Podcast
Automatización para la descarga de episodios de Google Podcast.\
Se ha desarrollado como primera toma de contacto con Dart.\
Aunque operativo, realmente no está pensado para que su uso por parte de usuarios.

## Instrucciones
Es una utilidad para sistemas operativos GNU/Linux amd64.\
No hace falta ninguna instalación, simplemente descargar el archivo **google_podcasts_mp3** de la carpeta **output**.\
Asegurar que el archivo tiene permisos de ejecución:
```bash
sudo chmod +x ruta/hasta/ejecutable/google_podcasts_mp3
```
**Pasos:**
- Incorporar el FEED identificativo del programa
- Introducir la carpeta donde se guardará el informe del análisis del programa y lo episodios que se descarguen
- Consultar los informes para buscar los identificadores de los programas que se desean descargar
- Introducir los identificadores seguidos separados por comas (por ejemplo: 1,5,6,8)

**¿Cómo se localiza el feed?**
Al acceder a la página de un programa aparece una URL del siguiente tipo:
```txt
https://podcasts.google.com/feed/XXX?YYY
```
El feed corresponde al contenido identificado como XXX, es decir, todos los caracteres después de /feed/ y antes del primer signo de interrogación.\
Utilizando una URL real:
https://podcasts.google.com/feed/<mark>aHR0cHM6Ly93d3cuaXZvb3guY29tL2ZlZWRfZmdfZjExNDUyMTc4X2ZpbHRyb18xLnhtbA</mark>?sa=X&ved=0CDIQjs4CKAFqFwoTCICrhYK-6P4CFQAAAAAdAAAAABAB&hl=es
Generalmente es suficiente con hacer doble click sobre parte de este contenido para seleccionarlo completamente.


