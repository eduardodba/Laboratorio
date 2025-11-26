jdbc:sqlserver://XPTO:1433;sslProtocol=TLS;jaasConfigurationName=SQLJDBCDriver;statementPoolingCacheSize=0;serverPreparedStatementDiscardThreshold=10;enablePrepareOnFirstPreparedStatementCall=false;fips=false;socketTimeout=0;authentication=NotSpecified;authenticationScheme=nativeAuthentication;xopenStates=false;workstationID=ABEBWS_WE;sendTimeAsDatetime=true;trustStoreType=JKS;trustServerCertificate=false;TransparentNetworkIPResolution=true;serverNameAsACE=false;sendStringParametersAsUnicode=false;selectMethod=cursor;responseBuffering=adaptive;queryTimeout=-1;packetSize=8000;multiSubnetFailover=true;loginTimeout=15;lockTimeout=-1;lastUpdateCount=true;encrypt=false;disableStatementPooling=true;databaseName=BASE;columnEncryptionSetting=Disabled;applicationName=Microsoft JDBC Driver for SQL Server;applicationIntent=readonly;
selectMethod=cursor, esta configuração era para estar assim selectMethod=direct

o transacional está usando driver diferente e está correto (a sintaxe é diferente para desabilitar):
WE	jdbc:jtds:sqlserver://XPTO/BASE;useCursors=false;sendStringParametersAsUnicode=false;wsid=ABEBWS_WE



SELECT  
    cp.objtype,
    cp.usecounts,
    cp.size_in_bytes / 1024 AS size_in_kb,   -- tamanho do plano em KB
    st.text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%P_CONS_CONTAS_TITULAR_CNPJCPF%' AND
 cp.objtype <> 'Adhoc'
ORDER BY cp.objtype, cp.usecounts DESC;



DECLARE @p1 INT;
DECLARE @p2 INT;
DECLARE @p7 INT;

EXEC sp_cursorprepexec 
    @p1 OUTPUT, 
    @p2 OUTPUT, 
    N'@P0 varchar(8000)', 
    N'EXEC dbo.P_CONS_CONTAS_TITULAR_CNPJCPF @P0', 
    4112, 
    8193, 
    @p7 OUTPUT, 
    '07342290386';
 
SELECT @p1 AS Handle, @p2 AS PrepStatus, @p7 AS ExecStatus;


exec dbo.P_CONS_CONTAS_TITULAR_CNPJCPF '07563244590'
 



SELECT 
    r.session_id,
    r.granted_query_memory * 8 AS memory_kb,
    c.cursor_id,
    c.name,
    c.properties,
    t.text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_cursors(0) c ON r.session_id = c.session_id
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) t;



SELECT 
    type,
    CAST(SUM(pages_in_bytes) / (1024.0 * 1024.0) AS INT) AS total_memory_MB
FROM sys.dm_os_memory_objects
WHERE type = 'MEMOBJ_CURSOREXEC'
GROUP BY type
ORDER BY total_memory_MB DESC;



SELECT cntr_value as Mem_KB, 
        cntr_value/1024.0 as Mem_MB,
         (cntr_value/1048576.0) as Mem_GB 
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Cursor memory usage' and instance_name = '_Total'




