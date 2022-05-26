
                                                                   /* CREACION DEL DATA WAREHOUSE DE ELECTRONICA-DS */

DROP DATABASE IF EXISTS electronicaDS;
CREATE DATABASE IF NOT EXISTS electronicaDS;
USE electronicaDS;
SET SQL_SAFE_UPDATES = 0;

/*Catalogo de funciones y procedimientos*/
SET GLOBAL log_bin_trust_function_creators = 1;
DROP FUNCTION IF EXISTS `UC_Words`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `UC_Words`( str VARCHAR(255) ) RETURNS varchar(255) CHARSET utf8
BEGIN  
  DECLARE c CHAR(1);  
  DECLARE s VARCHAR(255);  
  DECLARE i INT DEFAULT 1;  
  DECLARE bool INT DEFAULT 1;  
  DECLARE punct CHAR(17) DEFAULT ' ()[]{},.-_!@;:?/';  
  SET s = LCASE( str );  
  WHILE i < LENGTH( str ) DO  
     BEGIN  
       SET c = SUBSTRING( s, i, 1 );  
       IF LOCATE( c, punct ) > 0 THEN  
        SET bool = 1;  
      ELSEIF bool=1 THEN  
        BEGIN  
          IF c >= 'a' AND c <= 'z' THEN  
             BEGIN  
               SET s = CONCAT(LEFT(s,i-1),UCASE(c),SUBSTRING(s,i+1));  
               SET bool = 0;  
             END;  
           ELSEIF c >= '0' AND c <= '9' THEN  
            SET bool = 0;  
          END IF;  
        END;  
      END IF;  
      SET i = i+1;  
    END;  
  END WHILE;  
  RETURN s;  
END$$
DELIMITER ;



DROP PROCEDURE IF EXISTS `Llenar_dimension_calendario`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Llenar_dimension_calendario`(IN `startdate` DATE, IN `stopdate` DATE)
BEGIN
    DECLARE currentdate DATE;
    SET currentdate = startdate;
    WHILE currentdate < stopdate DO
        INSERT INTO calendario VALUES (
                        YEAR(currentdate)*10000+MONTH(currentdate)*100 + DAY(currentdate),
                        currentdate,
                        YEAR(currentdate),
                        MONTH(currentdate),
                        DAY(currentdate),
                        QUARTER(currentdate),
                        WEEKOFYEAR(currentdate),
                        DATE_FORMAT(currentdate,'%W'),
                        DATE_FORMAT(currentdate,'%M'));
        SET currentdate = ADDDATE(currentdate,INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;






                                                                                  /* CREACION DE LAS TABLAS */


DROP TABLE IF EXISTS gasto;
CREATE TABLE IF NOT EXISTS gasto (
IdGasto 		INTEGER,
IdSucursal 	INTEGER,
IdTipoGasto 	INTEGER,
Fecha			DATE,
Monto 		DECIMAL(10,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;	

DROP TABLE IF EXISTS compra;
CREATE TABLE IF NOT EXISTS compra (
IdCompra			INTEGER,
Fecha 				DATE,
IdProducto			INTEGER,
Cantidad			INTEGER,
Precio				DECIMAL(10,2),
IdProveedor			INTEGER
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS VENTA;
CREATE TABLE IF NOT EXISTS venta (
IdVenta				INTEGER,
Fecha 				DATE NOT NULL,
Fecha_Entrega 		DATE NOT NULL,
IdCanal				INTEGER, 
IdCliente			INTEGER, 
IdSucursal			INTEGER,
IdEmpleado			INTEGER,
IdProducto			INTEGER,
Precio				VARCHAR(30),
Cantidad			VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS canal_venta;
CREATE TABLE IF NOT EXISTS canal_venta (
IdCanal				INTEGER,
Canal 				VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS tipo_gasto;
CREATE TABLE IF NOT EXISTS tipo_gasto (
IdTipoGasto int(11) NOT NULL AUTO_INCREMENT,
Descripcion varchar(100) NOT NULL,
Monto_Aproximado DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (IdTipoGasto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS cliente;
CREATE TABLE IF NOT EXISTS cliente (
ID					INTEGER,
Provincia			VARCHAR(50),
Nombre_y_Apellido	VARCHAR(80),
Domicilio			VARCHAR(150),
Telefono			VARCHAR(30),
Edad				VARCHAR(5),
Localidad			VARCHAR(80),
X					VARCHAR(30),
Y					VARCHAR(30),
col10				VARCHAR(1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS proveedor;
CREATE TABLE IF NOT EXISTS proveedor (
IDProveedor		INTEGER,
Nombre			VARCHAR(80),
Domicilio		VARCHAR(150),
Ciudad			VARCHAR(80),
Provincia		VARCHAR(50),
Pais			VARCHAR(20),
Departamento	VARCHAR(80)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS producto;
CREATE TABLE IF NOT EXISTS producto (
IDProducto					INTEGER,
Concepto					VARCHAR(100),
Tipo						VARCHAR(50),
Precio2						VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS empleado;
CREATE TABLE IF NOT EXISTS empleado (
IDEmpleado					INTEGER,
Apellido					VARCHAR(100),
Nombre						VARCHAR(100),
Sucursal					VARCHAR(50),
Sector						VARCHAR(50),
Cargo						VARCHAR(50),
Salario2					VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS sucursal;
CREATE TABLE IF NOT EXISTS sucursal (
ID			INTEGER,
Sucursal	VARCHAR(40),
Domicilio	VARCHAR(150),
Localidad	VARCHAR(80),
Provincia	VARCHAR(50),
Latitud2	VARCHAR(30),
Longitud2	VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

/*Se genera la dimension calendario*/
DROP TABLE IF EXISTS `calendario`;
CREATE TABLE calendario (
        id                      INTEGER PRIMARY KEY,  -- year*10000+month*100+day
        fecha                 	DATE NOT NULL,
        anio                    INTEGER NOT NULL,
        mes                   	INTEGER NOT NULL, -- 1 to 12
        dia                     INTEGER NOT NULL, -- 1 to 31
        trimestre               INTEGER NOT NULL, -- 1 to 4
        semana                  INTEGER NOT NULL, -- 1 to 52/53
        dia_nombre              VARCHAR(9) NOT NULL, -- 'Monday', 'Tuesday'...
        mes_nombre              VARCHAR(9) NOT NULL -- 'January', 'February'...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;






                                                                                           /* INGESTA DE LOS DATOS */

CALL Llenar_dimension_calendario('2015-01-01','2020-12-31');

LOAD DATA INFILE 'gasto.csv' 
INTO TABLE gasto 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'compra.csv' 
INTO TABLE compra 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'venta.csv' 
INTO TABLE venta 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'canaldeventa.csv' 
INTO TABLE canal_venta 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'TiposDeGasto.csv' 
INTO TABLE tipo_gasto 
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'Cliente.csv'
INTO TABLE cliente
FIELDS TERMINATED BY ';' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'Proveedores.csv' 
INTO TABLE proveedor
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'Productos.csv' 
INTO TABLE producto 
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'Empleados.csv' 
INTO TABLE empleado 
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'Sucursales.csv' 
INTO TABLE sucursal
FIELDS TERMINATED BY ';' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;



                                                                                                            /* HALLAZGOS DURANTE EL ANÁLISIS EXPLORATORIO */


									/* Tabla clinte */
-- El nombre del campo id resulta ambiguo y se remplaza por IdCliente
ALTER TABLE CLIENTE CHANGE ID IdCliente INT(15) NOT NULL;

-- Se encuentra la columna col10 vacía y se elimina
ALTER TABLE CLIENTE DROP col10;

-- Se encuentran las columnas de ubicación por coordenadas con nombres ambiguos y valores faltantes, se realizan las correcciones necesarias.
ALTER TABLE CLIENTE ADD Latitud DECIMAL(13,10) NOT NULL DEFAULT 0 AFTER Y;
ALTER TABLE CLIENTE ADD Longitud DECIMAL(13,10) NOT NULL DEFAULT 0 AFTER Latitud;
UPDATE CLIENTE SET X = '0' WHERE X = '';
UPDATE CLIENTE SET Y = '0' WHERE Y = '';
UPDATE CLIENTE SET LATITUD = REPLACE(Y, ',', '.');
UPDATE CLIENTE SET LONGITUD = REPLACE(X, ',', '.');
ALTER TABLE CLIENTE DROP X;
ALTER TABLE CLIENTE DROP Y;

-- Se encuentran valores faltantes en las columnas provincia, nombre_y_apellido, localidad y domicilio. Se marcan los campos con la consigna 'sin dato'.
UPDATE CLIENTE SET PROVINCIA = 'Sin dato' WHERE PROVINCIA = '';
UPDATE CLIENTE SET NOMBRE_Y_APELLIDO = 'Sin dato' WHERE NOMBRE_Y_APELLIDO = '';
UPDATE CLIENTE SET DOMICILIO = 'Sin dato' WHERE DOMICILIO = '';
UPDATE CLIENTE SET LOCALIDAD = 'Sin dato' WHERE LOCALIDAD = '';

-- Se encuentran valores faltantes en la columna teléfono, los campos se llenan con '0' y se castea el tipo de dato.
UPDATE CLIENTE SET TELEFONO = '0' WHERE TELEFONO = '';
ALTER TABLE CLIENTE CHANGE Telefono Telefono int(15) NOT NULL DEFAULT 0;

-- Se castea el tipo de dato de la columna edad.
ALTER TABLE CLIENTE CHANGE Edad Edad int(15) NULL DEFAULT NULL;





                               /* Tabla sucursal */
-- El nombre de la columna id resulta ambiguo, se cambia por IdSucursal
ALTER TABLE SUCURSAL CHANGE ID IdSucursal INT(11);

-- Se corrigen las columnas Latitud2 y longitud2  para que tengan el nombre y tipo de dato correcto.
ALTER TABLE SUCURSAL ADD Latitud DECIMAL(13,10) NOT NULL DEFAULT 0 AFTER Latitud2;
ALTER TABLE SUCURSAL ADD Longitud DECIMAL(13,10) NOT NULL DEFAULT 0 AFTER Longitud2;
UPDATE SUCURSAL SET LATITUD = REPLACE(Latitud2, ',', '.');
UPDATE SUCURSAL SET LONGITUD = REPLACE(Longitud2, ',', '.');
ALTER TABLE SUCURSAL DROP LATITUD2;
ALTER TABLE SUCURSAL DROP LONGITUD2;





                                    /* Tabla empleado */
-- Se modifica la columna SALARIO2 PARA QUE TENGA EL NOMBRE Y EL TIPO DE DATO CORRECTO
ALTER TABLE EMPLEADO CHANGE SALARIO2 SALARIO DECIMAL(10,2);

-- Crear una nueva columna que almacenara el id_sucursal en la tabla empleado.
ALTER TABLE empleado ADD IdSucursal INT NULL DEFAULT '0' AFTER sucursal;
UPDATE empleado e JOIN sucursal s
	ON (e.sucursal = s.sucursal)
SET e.idsucursal = s.idsucursal;





                               /* Tabla producto */
-- CAMBIAR EL NOMBRE DE LA COLUMNA CONCEPTO Y EL NOMBRE Y TIPO DE DATO DE PRECIO2
ALTER TABLE producto CHANGE IDProducto IdProducto INT(11) NULL DEFAULT NULL;
ALTER TABLE producto CHANGE Concepto Producto VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL;
ALTER TABLE PRODUCTO ADD Precio DECIMAL(15,2) NOT NULL DEFAULT 0 AFTER Precio2;
UPDATE PRODUCTO SET PRECIO = REPLACE(PRECIO2, ',','.');
ALTER TABLE PRODUCTO DROP PRECIO2;





                              /* Tabla proveedor */
-- Se encuentran datos faltantes en la columna nombre, se llenan con la consigna 'Sin dato'.
UPDATE PROVEEDOR SET NOMBRE = 'Sin dato' WHERE NOMBRE = ''; 






                                /*Tabla Venta*/
-- Se encuentran datos faltantes en las columnas precio y cantidad, se corrigen y se cambia el tipo de dato.
UPDATE VENTA SET PRECIO = '0' WHERE PRECIO = '';
UPDATE VENTA SET CANTIDAD = '0' WHERE CANTIDAD = CHAR(13);
ALTER TABLE VENTA CHANGE Precio Precio DECIMAL(10,2) NOT NULL;
ALTER TABLE VENTA CHANGE Cantidad Cantidad INT(30) NOT NULL;
UPDATE venta v
        JOIN
    producto p ON (v.IdProducto = p.IdProducto) 
SET 
    v.Precio = p.Precio
WHERE
    v.Precio = 0;
    
    
    


                                   /* Tabla calendario */
-- El nombre del campo id resulta ambiguo
ALTER TABLE CALENDARIO CHANGE id IdCalendario INT(15) NOT NULL;






-- CAPITALIZAR TABLAS
UPDATE cliente SET 	Provincia = UC_Words(TRIM(Provincia)),
					Localidad = UC_Words(TRIM(Localidad)),
                    Domicilio = UC_Words(TRIM(Domicilio)),
                    Nombre_y_Apellido = UC_Words(TRIM(Nombre_y_Apellido));
					
UPDATE sucursal SET Provincia = UC_Words(TRIM(Provincia)),
					Localidad = UC_Words(TRIM(Localidad)),
                    Domicilio = UC_Words(TRIM(Domicilio)),
                    Sucursal = UC_Words(TRIM(Sucursal));
					
UPDATE proveedor SET Provincia = UC_Words(TRIM(Provincia)),
					Ciudad = UC_Words(TRIM(Ciudad)),
                    Departamento = UC_Words(TRIM(Departamento)),
                    Pais = UC_Words(TRIM(Pais)),
                    Nombre = UC_Words(TRIM(Nombre)),
                    Domicilio = UC_Words(TRIM(Domicilio));

UPDATE producto SET Producto = UC_Words(TRIM(Producto)),
					Tipo = UC_Words(TRIM(Tipo));
					
UPDATE empleado SET Sucursal = UC_Words(TRIM(Sucursal)),
                    Sector = UC_Words(TRIM(Sector)),
                    Cargo = UC_Words(TRIM(Cargo)),
                    Nombre = UC_Words(TRIM(Nombre)),
                    Apellido = UC_Words(TRIM(Apellido));