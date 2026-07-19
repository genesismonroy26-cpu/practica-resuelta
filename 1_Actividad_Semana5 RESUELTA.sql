/*
========================================================================
                    Actividad Práctica Semana 5 
========================================================================
*/

-----------                1- SUB-CONSULTA

--          Actividad Práctica: Subconsultas Escalares y Tratamiento de NULLs
/* 📝 Listar todos los productos disponibles, incluyendo aquellos que no tuvieron ventas, 
y calcular el monto total vendido por cada uno.
Utiliza una subconsulta en el SELECT para obtener el precio total vendido por producto 
(Precio_Total), y reemplaza los valores nulos por 0 en caso de que no haya ventas registradas. */

SELECT
     np.id_PRODUCT_NAME,
	 np.ProductName AS Productos,
	 ISNULL(
	 (SELECT 
	      SUM(v.PricePerUnit * v.UnitsSold)
	 FROM dbo.FactNikeSales v
	 WHERE v.id_PRODUCT_NAME = np.id_PRODUCT_NAME
	 ), 
	 0)  AS Precio_Total

FROM dbo.DimProductName np
ORDER BY Precio_Total DESC;


-- Ver después de los JOIN
--			Refactorización a Pipelines Legibles
/* Consigna : Reescribir la consulta por producto utilizando un CTE. 
Debes separar el proceso en dos etapas:
Transformación: Crear un bloque WITH que calcule el total vendido por cada ID de producto.
Consolidación: Realizar un LEFT JOIN entre la tabla maestra de productos y el CTE para asegurar que se incluyan todos los productos, incluso los que no tienen ventas.*/


-- Definir el pipeline de transformacion 
WITH VentasAgrupadas AS (
      SELECT 
	     v.id_PRODUCT_NAME,
		 SUM(v.PricePerUnit * v.UnitsSold) AS Total_Vendido
	  FROM dbo.FactNikeSales v
	  GROUP BY v.id_PRODUCT_NAME
)
-- Reporte final
SELECT 
     np.id_PRODUCT_NAME,
	 np.ProductName AS Productos,
	 ISNULL(va.Total_Vendido, 0) AS Precio_Total
FROM dbo.DimProductName np
LEFT JOIN VentasAgrupadas va
      ON np.id_PRODUCT_NAME = va.id_PRODUCT_NAME
ORDER  BY Precio_Total DESC;


-----------                2- Inner Join
--         Actividad Práctica: Análisis de Rentabilidad con INNER JOIN
/* 📉 Mostrá una lista con el nombre de cada producto (cuyo nombre empieza con la letra L), su precio por unidad y su margen operativo. 
Ordená los resultados desde el producto más rentable al menos rentable. */
 
 SELECT 
      np.ProductName AS Producto,
	  v.PricePerUnit AS PrecioUnitario,
	  v.OperatingMargin AS MargenOperativo
 FROM dbo.FactNikeSales v
 INNER JOIN dbo.DimProductName np
    ON v.id_PRODUCT_NAME = np.id_PRODUCT_NAME
WHERE np.ProductName LIKE 'L%' 
ORDER BY v.OperatingMargin DESC;


-----------               3- Left Join 

--         Actividad Práctica: Auditoría de Catálogo y Performance de Ventas
/* 📝 Obtener un listado completo de todos los productos, incluyendo aquellos que no registraron ventas, 
y calcular monto total vendido por cada uno (Precio_Total) */

SELECT 
     np.id_PRODUCT_NAME,
	 np.ProductName AS Productos,
	 ISNULL(SUM(v.PricePerUnit * v.UnitsSold), 0) AS Precio_Total
FROM dbo.DimProductName np
LEFT JOIN dbo.FactNikeSales v
      ON np.id_PRODUCT_NAME = v.id_PRODUCT_NAME
GROUP BY np.id_PRODUCT_NAME, np.ProductName
ORDER BY Precio_Total ASC;


-----------             4- Right Join 
--        Actividad Práctica: Análisis de Ingresos y Auditoría Geográfica
/* 📝 Calcula el total de ventas por ciudad. */

SELECT 
      c.City AS Ciudad,
	  SUM(v.PricePerUnit * v.UnitsSold) AS VentasTotales 
FROM dbo.DimCity c
RIGHT JOIN dbo.FactNikeSales v
     ON c.id_City = v.id_City
GROUP BY c.City

-- Validacion 
SELECT 
     *
FROM dbo.DimCity



-----------             5- UNION – UNION ALL
--        Actividad Práctica: Consolidación Regional con UNION
/* 📝 Obtené un listado unificado con los productos vendidos en dos ciudades específicas: Miami y Denver */

-- Productos vendidos en Miami
SELECT 
     np.ProductName AS Producto, 
	 'Miami' AS Ciudad 
FROM dbo.FactNikeSales v
INNER JOIN dbo.DimCity c
      ON v.id_City = c. id_City
INNER JOIN dbo.DimProductName np
      ON v.id_PRODUCT_NAME = np.id_PRODUCT_NAME
WHERE c.City = 'Miami'

UNION 
-- Productos vendidos en Denver (1269)

SELECT 
     np.ProductName AS Producto, 
	 'Denver' AS Ciudad 
FROM dbo.FactNikeSales v
INNER JOIN dbo.DimCity c
      ON v.id_City = c. id_City
INNER JOIN dbo.DimProductName np
      ON v.id_PRODUCT_NAME = np.id_PRODUCT_NAME
WHERE c.City = 'Denver';




-----------            6- Window Functions
--        Top productos por rentabilidad en cada ciudad

-- 📝 Obtené los productos más rentables por ciudad con un Ranking

SELECT 
     c.id_City AS Sucursal,
	 np.ProductName AS Productos,
	 v.OperatingMargin AS Margen_Operativo,
	 ROW_NUMBER() OVER (PARTITION BY c.City ORDER BY v.OperatingMargin DESC) AS Ranking_Margen

-- Vemos tambien ROW_NUMBER

FROM dbo.FactNikeSales v
INNER JOIN dbo.DimCity c
    ON v.id_City = c.id_City
INNER JOIN dbo.DimProductName np
    ON v.id_PRODUCT_NAME = np.id_PRODUCT_NAME;



--  📝 Calculá el share de ventas de las tallas S, M y L durante los últimos 3 meses disponibles (Sep, Oct y Nov 2024), mostrando el período en formato YYYY-MM.

/* El objetivo es identificar qué porcentaje de las ventas representa cada talla dentro de cada mes y, 
adicionalmente, qué porcentaje representa cada combinación mes/talla sobre el total del período analizado.*/ 

WITH ventas_por_talla AS (
    SELECT 
	    FORMAT(v.InvoiceDate, 'yyyy-MM') AS Periodo,
		v.PRODUCT_SIZE AS Talla,
		SUM(v.UnitsSold * v.PricePerUnit) AS Ventas
	
	FROM dbo.FactNikeSales v 
	WHERE v.InvoiceDate >= '2024-09-01'
	AND v.InvoiceDate < '2024-12-01'
	AND v.PRODUCT_SIZE IN ('S','M','L')
	GROUP BY 
	      fORMAT (v.InvoiceDate, 'yyyy-MM'),
		  v.PRODUCT_SIZE
)

SELECT 
    Periodo,
	Talla,
	Ventas,
	SUM(Ventas) OVER (
	       partition by Periodo
  ) AS Ventas_Totales_Mes,
  CAST(Ventas 
      / SUM(Ventas) OVER (
	       PARTITION BY Periodo 
   ) AS DECIMAL(18,2)) AS Share_Mensual,
	SUM(Ventas) OVER() AS Ventas_Totales_Periodo,
  CAST (Ventas
	   / SUM(Ventas) OVER()
	 AS DECIMAL(18,2)) AS Share_Total_Periodo

FROM ventas_por_talla
ORDER BY 
    Periodo,
	Talla






