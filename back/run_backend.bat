@echo off
echo Setting up Java environment...
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo Loading environment variables from .env file...
if exist .env (
    for /f "usebackq tokens=*" %%a in (`type .env`) do set "%%a"
) else (
    echo .env file not found!
)

echo Starting Spring Boot backend...
call gradlew.bat bootRun
