cd /D "%~dp0"
call "C:\Program Files\7-Zip\7z.exe" a -r %1.zip -w ..\src\* -xr!bin -xr!builds -xr!steam -xr!.git -xr!*.yue -xr!..\src\conf.lua
rename %1.zip %1.love
copy /b "love.exe"+"%1.love" "%1.exe"
del %1.love
mkdir %1
for %%I in (*.dll) do copy %%I %1\
for %%I in (*.txt) do copy %%I %1\
copy %1.exe %1\
del %1.exe
copy %1\ ..\steam\ContentBuilder\content\
del /q %1\
rmdir /q %1\
