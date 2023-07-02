:DOCKER SERVER
--Criar 3 containers com SQL
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Senha123" -p 1433:1433 -p 15022:5022 --name SQL2022_01 --hostname SQL2022_01 -e "MSSQL_AGENT_ENABLED=True" -d mcr.microsoft.com/mssql/server:2022-latest
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Senha123" -p 1434:1433 -p 15023:5022 --name SQL2022_02 --hostname SQL2022_02 -e "MSSQL_AGENT_ENABLED=True" -d mcr.microsoft.com/mssql/server:2022-latest
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Senha123" -p 1435:1433 -p 15024:5022 --name SQL2022_03 --hostname SQL2022_03 -e "MSSQL_AGENT_ENABLED=True" -d mcr.microsoft.com/mssql/server:2022-latest

  
--Pegar o id de cada container
SQL2022_01 --> 7a12d4fc3f73
SQL2022_02 --> b0f425ec8849
SQL2022_03 --> 5cc523d961ed
  

--Habilitar a feature do AlwaysOn
docker exec -u root -it 7a12d4fc3f73 /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1
docker exec -u root -it b0f425ec8849 /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1
docker exec -u root -it 5cc523d961ed /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1


--Liberar o IP para cada porta utilizada
ufw allow 1433/tcp
ufw allow 1434/tcp
ufw allow 1435/tcp
ufw allow 15022/tcp
ufw allow 15023/tcp
ufw allow 15024/tcp


--Reiniciar todos os containers
docker restart 7a12d4fc3f73 b0f425ec8849 5cc523d961ed


--Conectar via SSMS em cada instância e pegar o IP
select  CONNECTIONPROPERTY('local_net_address') AS local_net_address, @@SERVERNAME, @@SERVICENAME
  
SQL2022_01 --> 172.17.0.2
SQL2022_02 --> 172.17.0.3
SQL2022_03 --> 172.17.0.4


--Adicionar cada Container no arquivo hosts
docker exec -u 0 7a12d4fc3f73 /bin/sh -c "echo '172.17.0.2 SQL2022_01' > /etc/hosts"	
docker exec -u 0 7a12d4fc3f73 /bin/sh -c "echo '172.17.0.3 SQL2022_02' >> /etc/hosts"
docker exec -u 0 7a12d4fc3f73 /bin/sh -c "echo '172.17.0.4 SQL2022_03' >> /etc/hosts"
	
docker exec -u 0 b0f425ec8849 /bin/sh -c "echo '172.17.0.2 SQL2022_01' > /etc/hosts"	
docker exec -u 0 b0f425ec8849 /bin/sh -c "echo '172.17.0.3 SQL2022_02' >> /etc/hosts"
docker exec -u 0 b0f425ec8849 /bin/sh -c "echo '172.17.0.4 SQL2022_03' >> /etc/hosts"

docker exec -u 0 5cc523d961ed /bin/sh -c "echo '172.17.0.2 SQL2022_01' > /etc/hosts"	
docker exec -u 0 5cc523d961ed /bin/sh -c "echo '172.17.0.3 SQL2022_02' >> /etc/hosts"
docker exec -u 0 5cc523d961ed /bin/sh -c "echo '172.17.0.4 SQL2022_03' >> /etc/hosts"


:SQL01/02/03 via SSMS
--Habilitar sessão de health do Alwayson  
ALTER EVENT SESSION AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON);

--Criar login Conectar no Endpoint
CREATE LOGIN dbm_login WITH PASSWORD = 'Senha123';
CREATE USER dbm_user FOR LOGIN dbm_login; 


:SQL01
--Criar chave e certificado  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Senha123';
CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'dbm';
BACKUP CERTIFICATE dbm_certificate
TO FILE = '/var/opt/mssql/data/dbm_certificate.cer'
WITH PRIVATE KEY ( FILE = '/var/opt/mssql/data/dbm_certificate.pvk', ENCRYPTION BY PASSWORD = 'Senha123');


:DOCKER SERVER
--Copiar certificado e chave para todos os demais nodes
--Localizar o certificado e a master key
find / -name dbm_certificate.*

--Pegar o comando acima e copiar para os demais containers
--Como saber o caminho dos outros containers???
--Busque por master.mdf
find / -name master.mdf

--Execute os comandos com base no retorno dos seus dados
cp /var/lib/docker/overlay2/d64a064814bf52ac6cd5ac7b7d68eb35936399eb6b71ba8e7b28c2a5db74e656/merged/var/opt/mssql/data/SQL2022_01_Cert.* /var/lib/docker/overlay2/51ee0e42ea86fa9a2b5c5e190fafade8b33072fdca36a5e2323cccad0addbb87/merged/var/opt/mssql/data/
cp /var/lib/docker/overlay2/51ee0e42ea86fa9a2b5c5e190fafade8b33072fdca36a5e2323cccad0addbb87/merged/var/opt/mssql/data/SQL2022_02_Cert.* /var/lib/docker/overlay2/d64a064814bf52ac6cd5ac7b7d68eb35936399eb6b71ba8e7b28c2a5db74e656/merged/var/opt/mssql/data/


:SQL02/03
--Conecte nos containers e troque o owner dos arquivos
docker exec -it --user root b0f425ec8849 /bin/bash
chown mssql:mssql /var/opt/mssql/data/dbm_certificate.cer
chown mssql:mssql /var/opt/mssql/data/dbm_certificate.pvk
ls -ll /var/opt/mssql/data/

  
docker exec -it --user root 5cc523d961ed /bin/bash
chown mssql:mssql /var/opt/mssql/data/dbm_certificate.cer
chown mssql:mssql /var/opt/mssql/data/dbm_certificate.pvk
ls -ll /var/opt/mssql/data/


--Via SSMS cria a chave com base nos arquivos copiados
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Senha123';
CREATE CERTIFICATE dbm_certificate
AUTHORIZATION dbm_user
FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer'
WITH PRIVATE KEY (FILE = '/var/opt/mssql/data/dbm_certificate.pvk',DECRYPTION BY PASSWORD = 'Senha123');


:SQL01/02/03
--Via SSMS crie os endpoints, inicie e conceda permissão para o usuário criado
CREATE ENDPOINT [Hadr_endpoint]
 AS TCP (LISTENER_IP = (0.0.0.0), LISTENER_PORT = 5022)
 FOR DATA_MIRRORING (
 ROLE = ALL,
 AUTHENTICATION = CERTIFICATE dbm_certificate,
 ENCRYPTION = REQUIRED ALGORITHM AES);
 
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;

GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login]; 


:SQL01
--Via SSMS crie o AG
CREATE AVAILABILITY GROUP [AG_LNX]
 WITH (DB_FAILOVER = ON, CLUSTER_TYPE = EXTERNAL)
 FOR REPLICA ON
 N'SQL2022_01'
 WITH (
 ENDPOINT_URL = N'tcp://SQL2022_01:5022',
 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
 FAILOVER_MODE = EXTERNAL,
 SEEDING_MODE = AUTOMATIC
 ),
 N'SQL2022_02'
 WITH (
 ENDPOINT_URL = N'tcp://SQL2022_02:5022',
 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
 FAILOVER_MODE = EXTERNAL,
 SEEDING_MODE = AUTOMATIC
 ),
 N'SQL2022_03'
 WITH (
 ENDPOINT_URL = N'tcp://SQL2022_03:5022',
 AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
 FAILOVER_MODE = EXTERNAL,
 SEEDING_MODE = AUTOMATIC
 );
ALTER AVAILABILITY GROUP [AG_LNX] GRANT CREATE ANY DATABASE;


:SQL02/03
--Via SSMS ingresse os demais nodes ao AG
ALTER AVAILABILITY GROUP [AG_LNX] JOIN WITH (CLUSTER_TYPE = EXTERNAL);
ALTER AVAILABILITY GROUP [AG_LNX] GRANT CREATE ANY DATABASE; 


:SQL01
--Crie uma database, faça o backup full e adicione ao AG
CREATE DATABASE [DBA];
ALTER DATABASE [DBA] SET RECOVERY FULL;
BACKUP DATABASE [DBA] TO DISK = N'var/opt/mssql/data/DBA.bak'; 


ALTER AVAILABILITY GROUP [AG_LNX] ADD DATABASE [DBA]; 
