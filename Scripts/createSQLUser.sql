CREATE LOGIN zollsa   
   WITH PASSWORD = '!Password1',  
   CHECK_POLICY = OFF,
   CHECK_EXPIRATION = OFF;  
GO

USE master;
GRANT CONTROL SERVER TO zollsa;
GO