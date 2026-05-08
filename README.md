## sp_WhoIsBurningMyCPU
Stored Procedure para identificação rápida de sessões ofensivas de CPU no SQL Server.  Inspirada conceitualmente pelo WhoIsActive, porém focada exclusivamente em CPU pressure detection.

# Objetivo
Detectar rapidamente sessões que consomem CPU de forma desproporcional, utilizam paralelismo excessivo e prejudicam o ambiente.

A procedure classifica sessões usando múltiplos critérios simultâneos:

# Métricas coletadas

A procedure correlaciona múltiplas DMVs:
- sys.dm_exec_requests
- sys.dm_exec_sessions
- sys.dm_exec_query_memory_grants 
- sys.dm_db_task_space_usage 
- sys.dm_exec_query_plan
- sys.dm_exec_query_stats



# Informações retornadas
- statement em execução
- cpu_ms
- cpu_percent_estimated
- degree_of_parallelism
- waits
- blocking session
- memory grants
- TempDB usage
- query_hash / plan_hash
- execution plan XML

# Classificação automática — CPU Killer
Uma sessão é marcada como ofensora quando qualquer condição é verdadeira:

CPU% >= @KillerPercentage |
 OR DOP >= @KillerDop | 
 OR MemoryGrant >= @KillerMemoryMB
