cd /D "%~dp0"
call "C:\Program Files\7-Zip\7z.exe" a -r %1.zip -w ..\src\* -xr!bin -xr!builds -xr!steam -xr!.git -xr!*.yue
rename %1.zip %1.love
call npx love.js -m 208915200 -t %1 %2\bin\%1.love ..\builds\web
del %1.love
copy index.html ..\builds\web\index.html
