:SQL01

--Avaliar LSN
SELECT ag.name, 
       drs.database_id, 
       db_name(drs.database_id) as database_name, 
       drs.group_id, 
       drs.replica_id, 
       drs.synchronization_state_desc, 
       drs.last_hardened_lsn  
FROM sys.dm_hadr_database_replica_states drs 
INNER JOIN sys.availability_groups ag on drs.group_id = ag.group_id 
ORDER BY database_name


--Ver se o banco está sincronizando
SELECT ag.name
       , db_name(drs.database_id) as database_name
       , drs.synchronization_state_desc
FROM sys.dm_hadr_database_replica_states drs
INNER JOIN sys.availability_groups ag on drs.group_id = ag.group_id
WHERE drs.database_id = 50

 
--Failover
--Alterar replicação para Sincrona
ALTER AVAILABILITY GROUP DAG
 MODIFY
 AVAILABILITY GROUP ON
 'AG01' WITH
  (
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
  ),
  'AG02' WITH 
  (
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT
  );


SELECT ag.name, ag.is_distributed, ar.replica_server_name, ar.availability_mode_desc, ars.connected_state_desc, ars.role_desc,
 ars.operational_state_desc, ars.synchronization_health_desc FROM sys.availability_groups ag 
 JOIN sys.availability_replicas ar on ag.group_id=ar.group_id
 LEFT JOIN sys.dm_hadr_availability_replica_states ars
 ON ars.replica_id=ar.replica_id
 WHERE ag.is_distributed=1



--No Node primary trocar para secondary
ALTER AVAILABILITY GROUP DAG SET (ROLE = SECONDARY);


:SQL02
  
--No novo node primary executar o failover
ALTER AVAILABILITY GROUP DAG FORCE_FAILOVER_ALLOW_DATA_LOSS;


SELECT ag.name, 
       drs.database_id, 
       db_name(drs.database_id) as database_name, 
       drs.group_id, 
       drs.replica_id, 
       drs.synchronization_state_desc, 
       drs.last_hardened_lsn  
FROM sys.dm_hadr_database_replica_states drs 
INNER JOIN sys.availability_groups ag on drs.group_id = ag.group_id 
ORDER BY database_name

