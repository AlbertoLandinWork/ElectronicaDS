
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
IdSucursal 	    INTEGER,
IdTipoGasto 	INTEGER,
Fecha			DATE,
Monto 		    DECIMAL(10,2)
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
IdTipoGasto           INT(11) NOT NULL AUTO_INCREMENT,
Descripcion           VARCHAR(100) NOT NULL,
Monto_Aproximado      DECIMAL(10,2) NOT NULL,
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

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Gasto.csv' 
INTO TABLE gasto 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Compra.csv' 
INTO TABLE compra 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Venta.csv'
INTO TABLE venta 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\canalDeVenta.csv' 
INTO TABLE canal_venta 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY ''
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TiposDeGasto.csv' 
INTO TABLE tipo_gasto 
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Clientes.csv'
INTO TABLE cliente
FIELDS TERMINATED BY ';' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Proveedores.csv' 
INTO TABLE proveedor
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\PRODUCTOS.csv' 
INTO TABLE producto 
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Empleados.csv'
INTO TABLE empleado 
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;


LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Sucursales.csv' 
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
UPDATE CLIENTE SET PROVINCIA = 'Sin dato' WHERE TRIM(PROVINCIA) = '' OR ISNULL(PROVINCIA);
UPDATE CLIENTE SET NOMBRE_Y_APELLIDO = 'Sin dato' WHERE TRIM(NOMBRE_Y_APELLIDO) = '' OR ISNULL(NOMBRE_Y_APELLIDO);
UPDATE CLIENTE SET DOMICILIO = 'Sin dato' WHERE TRIM(DOMICILIO) = '' OR ISNULL(DOMICILIO);
UPDATE CLIENTE SET LOCALIDAD = 'Sin dato' WHERE TRIM(LOCALIDAD) = '' OR ISNULL(LOCALIDAD);
UPDATE cliente SET Telefono = 'sin dato' WHERE TRIM(Telefono) = '' OR ISNULL(Telefono);


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

-- MODIFICACION DE PALABRAS MAL TIPIADAS EN LA COLUMNA SUCURSAL. 
UPDATE empleado SET Sucursal = 'Mendoza1' WHERE Sucursal = 'Mendoza 1';
UPDATE empleado SET Sucursal = 'Mendoza2' WHERE Sucursal = 'Mendoza 2';
UPDATE empleado SET Sucursal = 'Córdoba Quiroz' WHERE Sucursal = 'Cordoba Quiroz';

-- Crear una nueva columna que almacenara el id_sucursal en la tabla empleado.
ALTER TABLE empleado ADD IdSucursal INT NULL DEFAULT '0' AFTER sucursal;
UPDATE empleado e JOIN sucursal s
	ON (e.sucursal = s.sucursal)
SET e.idsucursal = s.idsucursal;

-- CREACION DE CLAVE SUBROGADA EN IDEMPLEADO.
ALTER TABLE Empleado ADD CodigoEmpleado INT(11) NULL DEFAULT '0' AFTER IdEmpleado;
UPDATE Empleado SET CodigoEmpleado = IdEmpleado;
UPDATE Empleado SET IdEmpleado = (IdSucursal * 1000000) + CodigoEmpleado;

/*ELIMINO LA COLUMNA SUCURSAL PORQUE GENERE LA COLUMNA IDSUCURSAL*/
ALTER TABLE Empleado DROP Sucursal;


-- CREO LA TABLA SECTOR PARA LUEGO PONER EL IDSECTOR EN LA TABLA EMPLEADO.
DROP TABLE IF EXISTS Sector;
CREATE TABLE IF NOT EXISTS Sector (
	IdSector        INT(11) NOT NULL AUTO_INCREMENT,
    Sector          VARCHAR(50) NOT NULL,
    PRIMARY KEY (IdSector)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- INSERTO LOS DATOS DE LA COLUMNA SECTOR (TABLA EMPLEADO) EN LA COLUMNA SECTOR DE LA TABLA SECTOR.
INSERT INTO Sector(sector)
SELECT Sector
FROM Empleado
GROUP BY Sector;

-- AGREGO UNA COLUMNA IDSECTOR AL LADO DE LA COLUMNA SECTOR EN LA TABLA EMPLEADO.
ALTER TABLE Empleado ADD IdSector INT NULL DEFAULT '0'AFTER Sector;

-- COLOCO LOS VALORES DE LOS IDSECTOR EN LA TABLA EMPLEADO.
UPDATE Sector s JOIN Empleado e 
	ON (e.Sector = s.Sector)
SET e.IdSector = s.IdSector;



-- ELIMINA LA COLUMNA SECTOR DE LA TABLA EMPLEADO.
ALTER TABLE Empleado DROP Sector;

-- CREO LA TABLA CARGO PARA INSERTAR LUEGO LOS ID EN LA TABLA EMPLEADO Y PODER BORRAR LA COLUMNA CARGO. 
DROP TABLE IF EXISTS Cargo;
CREATE TABLE IF NOT EXISTS Cargo (
	IdCargo       INT(11) NOT NULL AUTO_INCREMENT,
    Cargo         VARCHAR(50) NOT NULL,
    PRIMARY KEY(IdCargo)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- INSERTO LOS DATOS DE LA COLUMNA CARGO (DE LA TABLA EMPLEADO) EN LA COLUMNA CARGO DE LA TABLA CARGO. 
INSERT INTO Cargo (Cargo)
SELECT Cargo
FROM Empleado 
GROUP BY Cargo;


-- AGREGO LA COLUMNA IDCARGO EN LA TABLA EMPLEADO AL LADO DE LA COLUMNA CARGO. 
ALTER TABLE Empleado ADD IdCargo INT(11) NULL DEFAULT '0' AFTER Cargo;

-- CARGO LOS DATOS DE IDCARGO EN LA COLUMNA IDCARGO DE LA TABLA EMPLEADO.
UPDATE EMPLEADO e JOIN CARGO c 
	ON( e.Cargo = c.Cargo)
SET e.IdCargo = c.IdCargo;

-- ELIMINO LA COLUMNA CARGO DE LA TABLA EMPLEADO. 
ALTER TABLE EMPLEADO DROP CARGO;



                               /* Tabla producto */
-- CAMBIAR EL NOMBRE DE LA COLUMNA CONCEPTO Y EL NOMBRE Y TIPO DE DATO DE PRECIO2
ALTER TABLE producto CHANGE IDProducto IdProducto INT(11) NULL DEFAULT NULL;
ALTER TABLE producto CHANGE Concepto Producto VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL;
ALTER TABLE PRODUCTO ADD Precio DECIMAL(15,2) NOT NULL DEFAULT 0 AFTER Precio2;
UPDATE PRODUCTO SET PRECIO = REPLACE(PRECIO2, ',','.');
ALTER TABLE PRODUCTO DROP PRECIO2;

-- SE LE COLOCA EL VALOR 'sin dato' EN LA COLUMNA TIPO DONDE NO TIENE NINGUN VALOR O ES NULO.
UPDATE PRODUCTO SET Tipo = 'sin dato' WHERE TRIM(Tipo) = '' OR ISNULL(Tipo);


-- CREO LA TABLA TIPO_PRODUCTO.
DROP TABLE IF EXISTS Tipo_Producto;
CREATE TABLE IF NOT EXISTS Tipo_Producto (
	IdTipo_Producto      INT(11) NOT NULL AUTO_INCREMENT,
    Tipo_Producto        VARCHAR(50)NOT NULL,
    PRIMARY KEY (IdTipo_Producto)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- INSERTO LOS DATOS DE LA COLUMNA TIPO DE LA TABLA PRODUCTO EN LA COLUMNA TIPO_PRODUCTO DE LA TABLA TIPO_PRODUCTO. 
INSERT INTO TIPO_PRODUCTO(TIPO_PRODUCTO)
SELECT TIPO
FROM PRODUCTO
GROUP BY TIPO;

-- AGREGAR UNA COLUMNA IDTIPO_PRODUCTO.
ALTER TABLE PRODUCTO ADD IdTipo_Producto INTEGER NOT NULL DEFAULT '0' AFTER TIPO;

-- INSERTO LOS DATOS DEL IDTIPO_PRODUCTO EN LA TABLA PRODUCTO. 
UPDATE PRODUCTO p JOIN TIPO_PRODUCTO tp 
	ON(p.TIPO = tp.TIPO_PRODUCTO)
SET p.IdTipo_Producto = tp.IdTipo_Producto;

-- ELIMINO LA COLUMNA TIPO DE LA TABLA PRODUCTO. 
ALTER TABLE PRODUCTO DROP TIPO;



                              /* Tabla proveedor */
-- Se encuentran datos faltantes en la columna nombre, se llenan con la consigna 'Sin dato'.
UPDATE PROVEEDOR SET NOMBRE = 'Sin dato' WHERE TRIM(NOMBRE) = '' OR ISNULL(NOMBRE); 



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
 
-- ACTUALIZA LOS IDEMPLEADO EN LA TABLA VENTA CON LA MISMA LOGICA QUE EN LA TABLA EMPLEADO.
UPDATE Venta SET IdEmpleado = (IdSucursal * 1000000) + IdEmpleado;
    
    


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
                    
                    
-- SE CREA LA TABLA AUX LOCALIDAD PARA NORMALIZAR LAS LOCALIDADES. 
DROP TABLE IF EXISTS Aux_Localidad;
CREATE TABLE IF NOT EXISTS Aux_Localidad (
	Localidad_Original         VARCHAR(80),
    Provincia_Original         VARCHAR(50),
    Localidad_Normalizada      VARCHAR(80),
    Provincia_Normalizada      VARCHAR(50),
    IdLocalidad                int
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- INSERTO LOS DATOS DE LAS COLUMNAS LOCALIDAD Y PROVINCIA EN LA TABLA AUX LOCALIDAD. 
INSERT INTO Aux_Localidad (Localidad_Original, Provincia_Original, Localidad_Normalizada, Provincia_Normalizada, IdLocalidad)
SELECT DISTINCT Localidad, Provincia, Localidad, Provincia, 0 FROM Cliente
UNION
SELECT DISTINCT Localidad, Provincia, Localidad, Provincia, 0 FROM Sucursal
UNION
SELECT DISTINCT Ciudad, Provincia, Ciudad, Provincia, 0 FROM Proveedor 
ORDER BY 2, 1;


-- NORMALIZAR DATOS EN COLUMNAS PROVINCIA Y LOCALIDAD. 
UPDATE Aux_Localidad SET Provincia_Normalizada = 'Buenos Aires'
WHERE Provincia_Original IN  ('B. Aires',
                            'B.Aires',
                            'Bs As',
                            'Bs.As.',
                            'Buenos Aires',
                            'C Debuenos Aires',
                            'Caba',
                            'Ciudad De Buenos Aires',
                            'Pcia Bs As',
                            'Prov De Bs As.',
                            'Provincia De Buenos Aires');
                            
UPDATE Aux_Localidad SET Localidad_Normalizada = 'Capital Federal'
WHERE Localidad_Original IN ('Boca De Atencion Monte Castro',
                            'Caba',
                            'Cap.   Federal',
                            'Cap. Fed.',
                            'Capfed',
                            'Capital',
                            'Capital Federal',
                            'Cdad De Buenos Aires',
                            'Ciudad De Buenos Aires')
AND Provincia_Normalizada = 'Buenos Aires';
                           

UPDATE `aux_localidad` SET Localidad_Normalizada = 'Córdoba'
WHERE Localidad_Original IN ('Coroba',
                            'Cordoba',
							'Cã³rdoba')
AND Provincia_Normalizada = 'Córdoba';


-- CREO TABLAS LOCALIDAD Y PROVINCIA PARA DISCRETIZAR LA TABLA SUCURSAL. 
DROP TABLE IF EXISTS Localidad;
CREATE TABLE IF NOT EXISTS Localidad (
	IdLocalidad         INT(11)NOT NULL AUTO_INCREMENT,
    Localidad           VARCHAR(80)NOT NULL,
    Provincia           VARCHAR(80)NOT NULL,
    IdProvincia         INT(11)NOT NULL,
    PRIMARY KEY(IdLocalidad)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

DROP TABLE IF EXISTS Provincia;
CREATE TABLE IF NOT EXISTS Provincia (
	IdProvincia           INT(11) NOT NULL AUTO_INCREMENT,
    Provincia             VARCHAR(80) NOT NULL,
    PRIMARY KEY (IdProvincia)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- INSERTO LOS DATOS EN LA TABLA LOCALIDAD. 
INSERT INTO Localidad (Localidad, Provincia, IdProvincia)
SELECT DISTINCT Localidad_Normalizada, Provincia_Normalizada,0
FROM Aux_Localidad
ORDER BY Provincia_Normalizada, Localidad_Normalizada;

-- INSERTO LOS DATOS EN LA TABLA PROVINCIA. 
INSERT INTO Provincia (Provincia)
SELECT DISTINCT Provincia_Normalizada
FROM Aux_Localidad
ORDER BY Provincia_Normalizada;

-- ACTUALIZO LOS VALORES DE LA COLUMNA IDPROVINCIA DE LA TABLA LOCALIDAD QUE TENIA CEROS. 
UPDATE Localidad l JOIN Provincia p ON (l.Provincia= p.Provincia)
SET l.IdProvincia = p.IdProvincia;

-- ACTUALIZA LOS ID DE LA TABLA AUX LOCALIDAD. 
UPDATE Aux_Localidad a JOIN Localidad l ON(l.Localidad = a.Localidad_Normalizada AND l.Provincia = a.Provincia_Normalizada)
SET a.IdLocalidad = l.IdLocalidad;

-- INSERTO COLUMNAS IDLOCALIDAD.
ALTER TABLE Cliente ADD IdLocalidad INT NULL DEFAULT '0' AFTER Provincia;
ALTER TABLE Proveedor ADD IdLocalidad INT NULL DEFAULT '0' AFTER Departamento;
ALTER TABLE Sucursal ADD IdLocalidad INT NULL DEFAULT '0' AFTER Provincia;

-- ACTUALIZO LOS ID EN LAS TABLAS CLIENTE, SUCURSAL Y PROVEEDOR. 
UPDATE Cliente c JOIN Aux_Localidad a 
	ON(a.Localidad_Original = c.Localidad AND a.Provincia_Original = c.Provincia)
SET c.IdLocalidad = a.IdLocalidad;

UPDATE sucursal s JOIN aux_localidad a
	ON (s.Provincia = a.Provincia_Original AND s.Localidad = a.Localidad_Original)
SET s.IdLocalidad = a.IdLocalidad;

UPDATE proveedor p JOIN aux_localidad a
	ON (p.Provincia = a.Provincia_Original AND p.Ciudad = a.Localidad_Original)
SET p.IdLocalidad = a.IdLocalidad;

-- ELIMINO LAS COLUMNAS SOBRANDES AL AGREGAR LA COLUMNA ID DE OTRAS TABLAS. 
ALTER TABLE Cliente DROP Provincia, DROP Localidad;

ALTER TABLE Proveedor DROP Ciudad, DROP Departamento, DROP Provincia, DROP Pais;

ALTER TABLE Sucursal DROP Localidad, DROP Provincia;

ALTER TABLE Localidad DROP Provincia;

-- CREO LOS INDICES DE LAS TABLAS DETERMINANDO CLAVES PRIMARIAS Y FORANEAS. 
ALTER TABLE Venta ADD PRIMARY KEY (IdVenta);
ALTER TABLE Venta ADD INDEX (IdProducto);
ALTER TABLE Venta ADD INDEX (IdCanal);
ALTER TABLE Venta ADD INDEX (IdCliente);
ALTER TABLE Venta ADD INDEX (IdSucursal);
ALTER TABLE Venta ADD INDEX (IdEmpleado);
ALTER TABLE Venta ADD INDEX (Fecha);
ALTER TABLE Venta ADD INDEX (Fecha_Entrega);

ALTER TABLE Calendario ADD UNIQUE (Fecha);

ALTER TABLE Canal_Venta ADD PRIMARY KEY(IdCanal);

ALTER TABLE Producto ADD PRIMARY KEY(IdProducto);
ALTER TABLE Producto ADD INDEX(IdTipo_Producto);

ALTER TABLE sucursal ADD PRIMARY KEY(`IdSucursal`);
ALTER TABLE sucursal ADD INDEX(`IdLocalidad`);

ALTER TABLE empleado ADD PRIMARY KEY(`IdEmpleado`);
ALTER TABLE empleado ADD INDEX(`IdSucursal`);
ALTER TABLE empleado ADD INDEX(`IdSector`);
ALTER TABLE empleado ADD INDEX(`IdCargo`);

ALTER TABLE localidad ADD INDEX(`IdProvincia`);

ALTER TABLE proveedor ADD PRIMARY KEY(`IdProveedor`);
ALTER TABLE proveedor ADD INDEX(`IdLocalidad`);

ALTER TABLE gasto ADD PRIMARY KEY(`IdGasto`);
ALTER TABLE gasto ADD INDEX(`IdSucursal`);
ALTER TABLE gasto ADD INDEX(`IdTipoGasto`);
ALTER TABLE gasto ADD INDEX(`Fecha`);

ALTER TABLE cliente ADD PRIMARY KEY(`IdCliente`);
ALTER TABLE cliente ADD INDEX(`IdLocalidad`);

ALTER TABLE compra ADD PRIMARY KEY(`IdCompra`);
ALTER TABLE compra ADD INDEX(`Fecha`);
ALTER TABLE compra ADD INDEX(`IdProducto`);
ALTER TABLE compra ADD INDEX(`IdProveedor`);

-- CREO LAS RELACIONES ENTRE LAS TABLAS Y LAS RESTRICCIONES.
ALTER TABLE venta ADD CONSTRAINT venta_fk_fecha FOREIGN KEY (fecha) REFERENCES calendario (fecha) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT venta_fk_cliente FOREIGN KEY (IdCliente) REFERENCES cliente (IdCliente) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT venta_fk_sucursal FOREIGN KEY (IdSucursal) REFERENCES sucursal (IdSucursal) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT venta_fk_producto FOREIGN KEY (IdProducto) REFERENCES producto (IdProducto) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT venta_fk_empleado FOREIGN KEY (IdEmpleado) REFERENCES empleado (IdEmpleado) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT venta_fk_canal FOREIGN KEY (IdCanal) REFERENCES canal_venta (IdCanal) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE producto ADD CONSTRAINT producto_fk_tipo_producto FOREIGN KEY (IdTipo_Producto) REFERENCES tipo_producto (IdTipo_Producto) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE empleado ADD CONSTRAINT empleado_fk_sector FOREIGN KEY (IdSector) REFERENCES sector (IdSector) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE empleado ADD CONSTRAINT empleado_fk_cargo FOREIGN KEY (IdCargo) REFERENCES cargo (IdCargo) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE empleado ADD CONSTRAINT empleado_fk_sucursal FOREIGN KEY (IdSucursal) REFERENCES sucursal (IdSucursal) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE cliente ADD CONSTRAINT cliente_fk_localidad FOREIGN KEY (IdLocalidad) REFERENCES localidad (IdLocalidad) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE proveedor ADD CONSTRAINT proveedor_fk_localidad FOREIGN KEY (IdLocalidad) REFERENCES localidad (IdLocalidad) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE sucursal ADD CONSTRAINT sucursal_fk_localidad FOREIGN KEY (IdLocalidad) REFERENCES localidad (IdLocalidad) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE localidad ADD CONSTRAINT localidad_fk_provincia FOREIGN KEY (IdProvincia) REFERENCES provincia (IdProvincia) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE compra ADD CONSTRAINT compra_fk_fecha FOREIGN KEY (Fecha) REFERENCES calendario (fecha) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compra ADD CONSTRAINT compra_fk_producto FOREIGN KEY (IdProducto) REFERENCES producto (IdProducto) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compra ADD CONSTRAINT compra_fk_proveedor FOREIGN KEY (IdProveedor) REFERENCES proveedor (IdProveedor) ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE gasto ADD CONSTRAINT gasto_fk_fecha FOREIGN KEY (Fecha) REFERENCES calendario (fecha) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE gasto ADD CONSTRAINT gasto_fk_sucursal FOREIGN KEY (IdSucursal) REFERENCES sucursal (IdSucursal) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE gasto ADD CONSTRAINT gasto_fk_tipogasto FOREIGN KEY (IdTipoGasto) REFERENCES tipo_gasto (IdTipoGasto) ON DELETE RESTRICT ON UPDATE RESTRICT;
