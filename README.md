## Actualizando los presupuestos autonómicos

### Datos presupuestarios

Los datos están disponibles en [la web del Ministerio de Hacienda][1], en 'Inicio > Consultas Datos Consolidados > Clasificación Funcional por capítulos depurados IFL y PAC', pero tenemos que descargarlos usando un scraper (que guarda las páginas en el directorio `staging_budget`) para parsearlos posteriormente:

    $ ruby fetch.rb 2010 2021
    $ ruby parse.rb staging_budget | sort > budget.sorted.csv

Ordenamos el resultado para que se pueda comparar con los datos ya existentes y detectar así cualquier error/anomalía.

[1]: https://serviciostelematicosext.hacienda.gob.es/SGCIEF/PublicacionPresupuestos/aspx/inicio.aspx

### Datos de ejecución

Los datos están disponibles en [otra web del Ministerio de Hacienda][1], en 'Inicio > Consulta Datos Consolidados > C. Funcional por Capítulos DC depurados IFL y PAC', pero tenemos que descargarlos usando el scraper con la opción `--actual` (que guarda las páginas en el directorio `staging_actual`) para parsearlos posteriormente:

    $ ruby fetch.rb --actual 2010 2019
    $ ruby parse.rb staging_actual | sort > actual.sorted.csv

Ordenamos el resultado para que se pueda comparar con los datos ya existentes y detectar así cualquier error/anomalía.

[1]: https://serviciostelematicosext.hacienda.gob.es/SGCIEF/PublicacionLiquidaciones/aspx/menuInicio.aspx

### Datos de población

Disponibles en la [web del INE][2]. Elegimos el año que nos interese, y todas las comunidades autónomas, y luego descargamos como Excel. (Ojo que si intentamos copi-pegar directamente podemos perder los ceros finales.) Hay que modificar un poco el formato para que encaje en lo que necesitamos, lo más sencillo es toquetear un poco en Excel.

Es posible que los datos de población del año en curso no estén aún disponibles. En ese caso tenemos que duplicar los del año anterior, porque el mapa no es capaz de "rellenar huecos" como sí hace la aplicación principal. (20240228: He tenido que hacer esto -temporalmente- con los datos de 2022 y 2023.)

[2]: https://www.ine.es/jaxiT3/Tabla.htm?t=2853&L=0

### Actualizando Dónde van mis impuestos

Una vez obtenidos los datos para el nuevo año, es necesario realizar estos cambios en DVMI:

1. Añadir los datos de población al archivo `static/data/population_YYYY.csv`. Si cambiamos el nombre del fichero nos evitamos problemas con el caché.
2. Actualizar el archivo con datos presupuestarios, `static/data/budget_data_YYYY.csv`. Ojo que la primera línea tiene que decir `year`, no `#year`.
3. Modificar el array `availableYears` en `static/javascripts/ccaa.js` para incluir el nuevo año.
4. Modificar el texto introductorio en `templates/ccaa/index.html` para hacer referencia al nuevo año. Cambiamos ahí también los nombres de los ficheros CSV, y la configuración del slider.