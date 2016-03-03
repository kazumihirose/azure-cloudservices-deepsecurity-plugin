if exist timestamp.log GOTO END
date /t > timestamp.log

REM Run the Trend Micro Deep Security agent installer
PowerShell -Command "Set-ExecutionPolicy Unrestricted"
PowerShell .\DeepSecurityAgent.ps1
GOTO END

:END
exit /b 0