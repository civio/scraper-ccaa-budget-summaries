## Actualizando los presupuestos autonómicos

### Datos presupuestarios

Los datos están disponibles en [la web del Ministerio de Hacienda][1], pero tenemos que descargarlos usando un scraper (que guarda las páginas en el directorio `staging_budget`) para parsearlos posteriormente:

    $ ruby fetch_budget.rb
    $ ruby parse.rb | sort > budget.sorted.csv

Ordenamos el resultado para que se pueda comparar con los datos ya existentes y detectar así cualquier error/anomalía.

[1]: http://serviciosweb.meh.es/apps/publicacionpresupuestos/aspx/inicio.aspx

### Datos de población

Disponibles en la [web del INE][2]. Elegimos el año que nos interese, y todas las comunidades autónomas, y luego descargamos como Excel. (Ojo que si intentamos copi-pegar directamente podemos perder los ceros finales.) Hay que modificar un poco el formato para que encaje en lo que necesitamos, lo más sencillo es toquetear un poco en Excel.

Es posible que los datos de población del año en curso no estén aún disponibles. En ese caso tenemos que duplicar los del año anterior, porque el mapa no es capaz de "rellenar huecos" como sí hace la aplicación principal. He tenido que hacer esto -temporalmente- con los datos de 2017.

[2]: http://www.ine.es/jaxiT3/Tabla.htm?t=2853&L=0

### Actualizando Dónde van mis impuestos

Una vez obtenidos los datos para el nuevo año, es necesario realizar estos cambios en DVMI:

1. Añadir los datos de población al archivo `population.csv`.
2. Actualizar el archivo con datos presupuestarios, `budget_data.csv`.
3. Modificar el array `availableYears` en `ccaa.js` para incluir el nuevo año.
4. Modificar el texto introductorio en `ccaa/index.html` para hacer referencia al nuevo año.
5. Cambiar la configuración del slider en `ccaa/index.html` para mostrar los nuevos años.