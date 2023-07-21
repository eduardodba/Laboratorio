USE [master]
GO

--Criação de um filegroup
ALTER DATABASE [Estudo] ADD FILEGROUP [FG_PARTITION]
GO

--Criação de um datafile no novo filegroup
ALTER DATABASE [Estudo] ADD FILE ( NAME = N'Estudo_Partition', FILENAME = N'/var/opt/mssql/data/Estudo_Partition.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [FG_PARTITION]
GO

 /* TABELA PARTICIONADA POR NUMERO INTEIRO */ 
 /* PART 1 = 0-100  
    PART 2 = 101-300
    PART 3 = 301-1000
 */
  
USE Estudo
GO

--drop table TB_PARTICIONADA
--drop table TB_PARTICIONADA_history
--drop PARTITION SCHEME RangePS
--drop PARTITION FUNCTION RangePF



--Criar um partition function - LEFT(da esquerda para a direita - 0-100 / 101-300 / 301-1000)
CREATE PARTITION FUNCTION RangePF (int) AS RANGE LEFT FOR VALUES (100,300,1000)


--Criar um partition function para apontar em qual partição vai cada regra da function
CREATE PARTITION SCHEME RangePS AS PARTITION RangePF TO (FG_PARTITION,FG_PARTITION,FG_PARTITION,FG_PARTITION)


--Criação de uma tabela Particionada
CREATE TABLE TB_PARTICIONADA (col1 int PRIMARY KEY, col2 char(10)) ON RangePS(col1)


--Carregar dados na tabela de exemplo
INSERT INTO TB_PARTICIONADA VALUES ((abs(checksum(newid())) % 1500) + 1, CAST((abs(checksum(newid())) % 1500) + 1 AS VARCHAR(50))+'A')
GO 1500


--Criar um expurgo 
CREATE TABLE TB_PARTICIONADA_History (col1 int PRIMARY KEY, col2 char(10)) ON RangePS(col1)


--Mover dados de uma partição para a historico
ALTER TABLE TB_PARTICIONADA SWITCH PARTITION 4 TO TB_PARTICIONADA_History PARTITION 4


--Voltar os Dados
ALTER TABLE TB_PARTICIONADA_History SWITCH PARTITION 4 TO TB_PARTICIONADA PARTITION 4





 /* TABELA PARTICIONADA POR DATA */ 
 /* PART 1 = < 2023-01-01 
    PART 2 = 2023-01-01 à 2023-01-31
    PART 3 = 2023-02-01 à 2023-02-28
    ...
 */

--drop table TB_PARTICIONADA_2
--drop table TB_PARTICIONADA_2_history
--drop PARTITION SCHEME RangePS_2 
--drop PARTITION FUNCTION RangePF_2
  

--Criar um partition function - LEFT(da esquerda para a direita - 0-100 / 101-300 / 301-1000)
CREATE PARTITION FUNCTION RangePF_2 (date) AS RANGE RIGHT FOR VALUES ('2023-01-01','2023-02-01','2023-03-01','2023-04-01','2023-05-01','2023-06-01')


--Criar um partition function para apontar em qual partição vai cada regra da function
CREATE PARTITION SCHEME RangePS_2 AS PARTITION RangePF_2 TO (FG_PARTITION,FG_PARTITION,FG_PARTITION,FG_PARTITION,FG_PARTITION,FG_PARTITION,FG_PARTITION)


--Criação de uma tabela Particionada
CREATE TABLE TB_PARTICIONADA_2 (col1 int, col2 DATE CONSTRAINT pk_TB_PARTICIONADA_2 PRIMARY KEY (col1, col2)) ON RangePS_2(col2)


--Carregar dados na tabela de exemplo
INSERT INTO TB_PARTICIONADA_2 VALUES ((abs(checksum(newid())) % 1500) + 1, GETDATE()+checksum(newid()) %365)
GO 1000

  
--Criar um expurgo 
CREATE TABLE TB_PARTICIONADA_2_History (col1 int, col2 DATE CONSTRAINT pk_TB_PARTICIONADA_2_History PRIMARY KEY (col1, col2)) ON RangePS_2(col2)


--Mover dados de uma partição para a historico
ALTER TABLE TB_PARTICIONADA_2 SWITCH PARTITION 3 TO TB_PARTICIONADA_2_History PARTITION 3




/* QUERYS PARA APOIO */

-- Mostra quantidade de registros por partição
SELECT    OBJECT_NAME(p.object_id) as obj_name
,        p.index_id
,        p.partition_number
,        d.name
,        p.rows
,        a.type
,        a.filegroup_id
FROM        sys.system_internals_allocation_units a
JOIN        sys.partitions p    ON p.partition_id = a.container_id
left join    sys.data_spaces d    ON d.data_space_id= a.filegroup_id
WHERE    p.object_id = (OBJECT_ID(N'TB_PARTICIONADA_2'))
and        p.index_id = 1
ORDER BY
obj_name
,        p.index_id
,        p.partition_number


  
--Select na tabela por partição
select min(col1), max(col1) from TB_PARTICIONADA where $PARTITION.RangePF(col1) = 4
