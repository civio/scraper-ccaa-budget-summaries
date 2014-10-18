## Actualizando los presupuestos autonómicos

### Datos presupuestarios

Los datos están disponibles en [la web del Ministerio de Hacienda][1], pero tenemos que descargarlos usando un scraper (que guarda las páginas en el directorio `staging`) para parsearlos posteriormente:

    $ ruby fetch.rb
    $ ruby parse.rb > BudgetData.csv

[1]: http://serviciosweb.meh.es/apps/publicacionpresupuestos/aspx/inicio.aspx

### Datos de población

Disponibles en la [web del INE][1]. Elegimos el año que nos interese, y todas las comunidades autónomas, y descargamos como CSV. Algunas notas:

 * No nos interesa el desglose hombre/mujer, pero está por razones históricas.
 * Nos quedamos sólo con las líneas que contienen datos, y añadimos una cabecera fijándonos en los años anteriores.
 * No sé si es posible descargar los identificadores de las CCAA (1-19), que es lo realmente importante, así que los añado a mano.

[1]: http://www.ine.es/jaxiBD/tabla.do?per=12&type=db&divi=DPOP&idtab=1

### Actualizando Dónde van mis impuestos

Una vez obtenidos los datos para el nuevo año, es necesario realizar estos cambios en DVMI:

1. Añadir el archivo con datos de población, p.ej. `Censo2012.csv`
2. Actualizar el archivo con datos presupuestarios, `BudgetData.csv`
3. Modificar el array `availableYears` en `ccaa.js` para incluir el nuevo año.
4. Modificar el texto introductorio en `ccaa.erb` para hacer referencia al nuevo año.