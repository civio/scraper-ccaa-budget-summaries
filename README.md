## Actualizando los presupuestos autonómicos

### Datos presupuestarios

Los datos están disponibles en [la web del Ministerio de Hacienda][1], pero tenemos que descargarlos usando un scraper (que guarda las páginas en el directorio `staging`) para parsearlos posteriormente:

    $ ruby fetch.rb
    $ ruby parse.rb > BudgetData.csv

[1]: http://serviciosweb.meh.es/apps/publicacionpresupuestos/aspx/inicio.aspx

### Datos de población

Disponibles en la [web del INE][2]. Elegimos el año que nos interese, y todas las comunidades autónomas, y luego descargamos como Excel. (Ojo que si intentamos copi-pegar directamente podemos perder los ceros finales.) Algunas notas:

 * No nos interesa el desglose hombre/mujer, pero está por razones históricas.
 * Nos quedamos sólo con las líneas que contienen datos, y añadimos una cabecera fijándonos en los años anteriores.
 * No sé si es posible descargar los identificadores de las CCAA (1-19), que es lo realmente importante, así que los añado a mano.
 * Al final, como hay que quitar signos de puntuación, meter el id a mano, añadir la columan del año... lo más sencillo es meterlo en Excel y toquetear hasta que tengamos lo que necesitamos.

[2]: http://www.ine.es/jaxiT3/Tabla.htm?t=2853&L=0

### Actualizando Dónde van mis impuestos

Una vez obtenidos los datos para el nuevo año, es necesario realizar estos cambios en DVMI:

1. Añadir los datos de población al archivo `population.csv`.
2. Actualizar el archivo con datos presupuestarios, `budget_data.csv`.
3. Modificar el array `availableYears` en `ccaa.js` para incluir el nuevo año.
4. Modificar el texto introductorio en `ccaa/index.html` para hacer referencia al nuevo año.
5. Cambiar la configuración del slider en `ccaa/index.html` para mostrar los nuevos años.