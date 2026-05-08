--Uso básico
EXEC dbo.sp_WhoIsBurningMyCPU;

--Detalhado
sp_WhoIsBurningMyCPU @Top = 15, 
                     @MinCPUms = 100, 
                     @ShowSystem = 0,
                     @KillerPercentage = 10,
                     @KillerDop = 8, 
                     @KillerMemoryMB  = 100 
                       

--Ajustando sensibilidade
EXEC dbo.sp_WhoIsBurningMyCPU
     @KillerPercentage = 5,
     @KillerDop = 4;


EXEC dbo.sp_WhoIsBurningMyCPU
     @KillerPercentage = 25,
     @KillerDop = 16;

