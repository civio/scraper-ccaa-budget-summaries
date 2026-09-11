Resúmenes de los presupuestos de las CCAA
=========================================

El Ministerio de Hacienda publica, para cada comunidad autónoma y cada año, un resumen del
gasto por políticas y capítulos: la 'clasificación funcional por capítulos depurados IFL y
PAC'. Este repositorio contiene el scraper que los descarga, el parser que los convierte en
CSV, las páginas descargadas y el resultado de haberlas procesado.

Hay dos conjuntos de datos, con la misma estructura y en dos aplicaciones distintas del
Ministerio:

  * **presupuesto** (`budget`): lo que cada comunidad aprobó gastar. [Web][1], en
    'Inicio > Consultas Datos Consolidados > Clasificación Funcional por capítulos depurados
    IFL y PAC'.
  * **ejecución** (`actual`): lo que luego declaró haber gastado. [Web][2], en
    'Inicio > Consulta Datos Consolidados > C. Funcional por Capítulos DC depurados IFL y PAC'.

[1]: https://serviciostelematicosext.hacienda.gob.es/SGCIEF/PublicacionPresupuestos/aspx/inicio.aspx
[2]: https://serviciostelematicosext.hacienda.gob.es/SGCIEF/PublicacionLiquidaciones/aspx/menuInicio.aspx


Requisitos
==========

Ruby 3.2 o posterior (ver `.ruby-version`) y las gemas del `Gemfile`:

    $ bundle install


Ejecutando los scripts
======================

Todo se hace con `bin/ccaa`:

    $ bin/ccaa fetch budget    # descarga las páginas a staging_budget/
    $ bin/ccaa parse budget    # las convierte en budget.sorted.csv

    $ bin/ccaa fetch actual    # lo mismo para los datos de ejecución
    $ bin/ccaa parse actual

`fetch` descarga desde 2006 hasta el año en curso, que es lo que hace falta para actualizar
un año nuevo. Se puede acotar, y se pueden cambiar las rutas:

    $ bin/ccaa fetch budget --from 2025 --to 2026
    $ bin/ccaa parse budget --input /otra/ruta --output /tmp/budget.csv

La salida va ordenada, que es lo que quiere decir el `.sorted` del nombre: así se puede
comparar con los datos ya existentes y detectar cualquier error o anomalía. Antes había que
pasarla por `sort` a mano; ahora ordena el propio parser, y ya no depende del locale de quien
lo ejecute.

Dos cosas que conviene saber del sitio del Ministerio:

  * No sirve una página de datos a quien llega de nuevas: hay que pasar antes por la página
    de inicio y conservar la cookie de sesión. `SummaryFetcher` lo hace en su primera
    petición.
  * Ya no devuelve un 404 para un año que no tiene, sino una página con la tabla vacía, y lo
    hace para cualquier año, incluso futuros. Es el parser el que reconoce esas páginas y no
    saca nada de ellas. Es también lo que pasa con Ceuta y Melilla, que dejaron de aparecer
    en 2013 aunque sus páginas se sigan sirviendo.


Las páginas descargadas
=======================

Están en `staging_budget/` y `staging_actual/`, una por comunidad y año, tal cual las sirvió
el Ministerio. Sí están en el repositorio: son 29 MB en disco pero apenas 1,4 MB comprimidas,
porque se parecen mucho entre sí, y a cambio los CSV se pueden regenerar desde cero sin tocar
la red. Que una fuente siga publicada dentro de unos años no es algo que se pueda dar por
supuesto, y una vez retirada no hay forma de volver a generar los datos que salieron de ella.

Un aviso sobre la codificación, porque parece un error y no lo es: las páginas declaran
`charset=iso-8859-1` en un meta y llegan en UTF-8. `SummaryPage` las lee como ISO-8859-1 a
propósito, mal, y luego deshace esa lectura byte a byte. Leerlas en binario y dejar que
Nokogiri se crea el meta -- que es lo correcto en casi todos los sitios del Ministerio --
destroza aquí todos los acentos.


Datos de población
==================

Disponibles en la [web del INE][4]. Elegimos el año que nos interese, y todas las comunidades
autónomas, y luego descargamos como CSV. (Ojo que si intentamos copi-pegar directamente
podemos perder los ceros finales.) Hay que modificar un poco el formato para que encaje en lo
que necesitamos, lo más sencillo es toquetear un poco en Excel.

Es posible que los datos de población del año en curso no estén aún disponibles. En ese caso
tenemos que duplicar los del año anterior, porque el mapa no es capaz de "rellenar huecos"
como sí hace la aplicación principal.

20241118: En febrero había tenido que rellenar los datos de 2022 y 2023, pero incluso ahora
siguen sin estar. Parece que los resúmenes del Padrón por CCAA que usaba [3] ya no se
actualizan, así que paso a usar la Estadística continua de población, que sí se actualiza
siempre y parece lo mejor en cualquier caso.

[3]: https://www.ine.es/jaxiT3/Tabla.htm?t=2853&L=0
[4]: https://www.ine.es/jaxiT3/Tabla.htm?t=56940&L=0


Actualizando Dónde van mis impuestos
====================================

Una vez obtenidos los datos para el nuevo año, es necesario realizar estos cambios en DVMI
(`civio/presupuesto-pge`):

1. Añadir los datos de población al archivo `static/data/population_YYYY.csv`. Si cambiamos
   el nombre del fichero nos evitamos problemas con el caché.
2. Actualizar el archivo con datos presupuestarios, `static/data/budget_data_YYYY.csv`. Ojo
   que la primera línea tiene que decir `year`, no `#year`.
3. Modificar el array `availableYears` en `static/javascripts/ccaa.js` para incluir el nuevo
   año.
4. Modificar el texto introductorio en `templates/ccaa/index.html` para hacer referencia al
   nuevo año. Cambiamos ahí también los nombres de los ficheros CSV, y la configuración del
   slider.

Los nombres de las comunidades que se ven en el mapa no salen de estos CSV: DVMI tiene su
propia lista, el array `ccaaLabels` de `static/javascripts/ccaa.js`, y la indexa por el id de
la región. La columna `region_label` que publicamos aquí copia esa lista para que las dos
digan lo mismo, pero si se cambia una hay que cambiar la otra.


Tests
=====

    $ bundle exec ruby test/all.rb

Hay dos niveles. Los tests rápidos cubren el parseo de una página: de qué comunidad y de qué
año es, qué filas son datos y cuáles subtotales, y que los acentos sobreviven. Usan las
páginas reales del repositorio, y sólo inventan una página cuando hace falta una forma que el
Ministerio no nos ha servido nunca.

Además, `test/golden_output_test.rb` vuelve a procesar las 760 páginas y comprueba que siguen
generando exactamente `budget.sorted.csv` y `actual.sorted.csv`. Es la red de seguridad de
verdad: es lo que detectaría un cambio en nokogiri, en libxml2 o en lo que publica el
Ministerio. Como las páginas están en el repositorio, se ejecuta en cualquier sitio, CI
incluido, sin necesidad de descargar nada.


Calidad de código
=================

    $ bundle exec rubocop
    $ bundle exec bundle-audit check --update

RuboCop pasa limpio y no hay `.rubocop_todo.yml`: el código que quedaba de 2013 se reescribió
al pasar a Ruby 3.4, así que no hay nada que eximir. Si algún día hace falta uno:

    $ bundle exec rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 30

La configuración está en `.rubocop.yml`, y cada excepción lleva escrito su porqué.

GitHub Actions ejecuta el linter, la auditoría de dependencias y los tests en cada push y
cada pull request (ver `.github/workflows/ci.yml`). Los tests que se ejecutan en CI son
todos, incluido el que compara contra los CSV publicados, porque las páginas del Ministerio
están en el repositorio y no hay nada que descargar.
