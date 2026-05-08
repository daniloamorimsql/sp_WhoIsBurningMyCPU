## sp_WhoIsBurningMyCPU
Stored Procedure para identificação rápida de sessões ofensivas de CPU no SQL Server.  Inspirada conceitualmente pelo WhoIsActive, porém focada exclusivamente em CPU pressure detection.

# Objetivo
Detectar rapidamente sessões que consomem CPU de forma desproporcional, utilizam paralelismo excessivo e prejudicam o ambiente.

# Parâmetros

- @Top: Número máximo de sessões retornadas
- @MinCPUms: CPU mínima considerada
- @ShowSystem: Inclui sessões do sistema
- @KillerPercentage: % estimada de CPU para marcar ofensora
- @KillerDop: DOP mínimo considerado agressivo
- @KillerMemoryMB: Memory Grant mínimo considerado agressivo

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


# Casos de uso
- CPU 100% em produção
- Paralelismo descontrolado
- Query regressiva após deploy
- Investigação rápida de incidentes
- Laboratórios de troubleshooting

# Observações
- Percentual de CPU é estimado com base nas requisições ativas.
- Não substitui monitoramento contínuo.
- Ferramenta voltada para análise operacional imediata.
