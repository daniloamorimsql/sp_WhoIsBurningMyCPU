CREATE OR ALTER PROCEDURE dbo.sp_WhoIsBurningMyCPU  
(  
      @Top INT = 15,  -- Quantidade de linhas retornadas
      @MinCPUms INT = 100,  -- Minimo de ms de CPU considerados 
      @ShowSystem BIT = 0, -- Mostrar as sessoes de sistema
      @KillerPercentage INT = 10, -- Porcentagem de cpu para considerar ofensora
      @KillerDop INT = 8, -- Quantidade de cores para considerar ofensora
      @KillerMemoryMB INT = 100 -- Quantidade de memória para considerar ofensora
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE @TotalCPU BIGINT;  
  
    SELECT @TotalCPU = SUM(cpu_time)  
    FROM sys.dm_exec_requests  
    WHERE (@ShowSystem = 1 OR session_id > 50);  
  
    ;WITH running AS  
    (  
        SELECT  
            r.session_id,  
            r.request_id,  
            r.status,  
            r.cpu_time,  
            r.total_elapsed_time,  
            r.logical_reads,  
            r.writes,  
            r.wait_type,  
            r.wait_time,  
            r.blocking_session_id,  
            r.granted_query_memory,  
            r.dop,  
            r.database_id,  
            r.plan_handle,  
            r.sql_handle,  
            r.statement_start_offset,  
            r.statement_end_offset,  
  
            s.login_name,  
            s.host_name,  
            s.program_name,  
            s.memory_usage,  
  
            mg.requested_memory_kb,  
            mg.granted_memory_kb,  
  
            tsu.internal_objects_alloc_page_count,  
            tsu.user_objects_alloc_page_count  
        FROM sys.dm_exec_requests r  
        JOIN sys.dm_exec_sessions s  
            ON r.session_id = s.session_id  
  
        LEFT JOIN sys.dm_exec_query_memory_grants mg  
            ON r.session_id = mg.session_id  
  
        LEFT JOIN sys.dm_db_task_space_usage tsu  
            ON r.session_id = tsu.session_id  
  
        WHERE  
            (@ShowSystem = 1 OR r.session_id > 50)  
            AND r.cpu_time >= @MinCPUms  
    )  
  
    SELECT TOP (@Top)  
  
        GETDATE() AS capture_time,
        r.session_id,  
        CONVERT(VARCHAR(8),
        DATEADD(ms, r.total_elapsed_time, 0),
        114) AS elapsed_hh_mm_ss,
        r.status,   
        DB_NAME(r.database_id) AS database_name,  
        SUBSTRING(  
            st.text,  
            (ISNULL(r.statement_start_offset,0)/2)+1,  
            (  
                CASE r.statement_end_offset  
                    WHEN -1 THEN LEN(st.text)  
                    ELSE (r.statement_end_offset-r.statement_start_offset)/2  
                END  
            ) + 1  
        ) AS running_statement, 
         r.cpu_time AS cpu_ms,   
        CAST(  
            100.0 * r.cpu_time /  
            NULLIF(@TotalCPU,0)  
        AS DECIMAL(6,2)) AS cpu_percent_estimated, 
        r.dop AS degree_of_parallelism,         
        r.wait_type,  
        r.wait_time,
        r.blocking_session_id AS blocked_by,
        CASE  
            WHEN  
                (100.0 * r.cpu_time / NULLIF(@TotalCPU,0)) >= @KillerPercentage  
                OR r.dop >= @KillerDop 
                OR r.granted_memory_kb > @KillerMemoryMB * 1024  
            THEN 'YES'  
            ELSE 'NO' 
        END AS is_cpu_killer, 
       CASE
            WHEN (
                    (100.0 * r.cpu_time / NULLIF(@TotalCPU,0)) >= @KillerPercentage
                    OR r.dop >= @KillerDop
                    OR r.granted_memory_kb > @KillerMemoryMB * 1024  
                 )
                 AND r.session_id <> @@SPID
                 AND r.session_id > 50
            THEN CONCAT('KILL ', r.session_id)
        END AS kill_command,
        qp.query_plan,
        r.login_name, 
        r.host_name,  
        r.program_name,  
        r.granted_query_memory * 8 AS memory_grant_kb,  
        r.granted_memory_kb,  
        r.requested_memory_kb,  
        (r.internal_objects_alloc_page_count * 8) AS tempdb_internal_kb,  
        (r.user_objects_alloc_page_count * 8) AS tempdb_user_kb,  
        r.logical_reads,  
        r.writes,  
        qs.query_hash,  
        qs.query_plan_hash     
    FROM running r  
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st  
    OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) qp  
    LEFT JOIN sys.dm_exec_query_stats qs  
        ON r.plan_handle = qs.plan_handle  
    ORDER BY  
        is_cpu_killer DESC,  
        cpu_percent_estimated DESC,  
        r.cpu_time DESC;  
END  
