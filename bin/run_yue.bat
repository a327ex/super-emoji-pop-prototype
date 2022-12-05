cd /D "%~dp0"
call yue.exe -l -t ..\lua ..\yue
call love.exe --console ..\lua
