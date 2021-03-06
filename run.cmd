@echo OFF
SETLOCAL

set SKIP_TEST=tue
if "%TOOLS_DIR%"=="" set TOOLS_DIR=c:\java
if "%JAVA_VERSION%"=="" set JAVA_VERSION=1.8.0_101
if "%JAVA_HOME%"=="" set JAVA_HOME=%TOOLS_DIR%\jdk%JAVA_VERSION%
set JAVA_OPTS=-Xms256m -Xmx512m
if "%MAVEN_VERSION%"=="" set MAVEN_VERSION=3.5.0
if "%M2_HOME%"=="" set M2_HOME=%TOOLS_DIR%\apache-maven-%MAVEN_VERSION%
if "%M2%"=="" set M2=%M2_HOME%\bin
set MAVEN_OPTS=-Xms256m -Xmx512m
PATH=%JAVA_HOME%\bin;%M2%;%PATH%

set DEBUG=true
set TARGET=target
set VERBOSE=true

set APP_NAME=swet
set APP_VERSION=0.0.10-SNAPSHOT
set APP_PACKAGE=com.github.sergueik.swet
set DEFAULT_MAIN_CLASS=SimpleToolBarEx

call :CALL_JAVASCRIPT /project/artifactId
set APP_NAME=%VALUE%

call :CALL_JAVASCRIPT /project/groupId
set APP_PACKAGE=%VALUE%

call :CALL_JAVASCRIPT /project/version
set APP_VERSION=%VALUE%

call :CALL_JAVASCRIPT /project/properties/mainClass
set DEFAULT_MAIN_CLASS=%VALUE%

set APP_JAR=%APP_NAME%.jar

if /i "%SKIP_PACKAGE_VERSION%"=="true" goto :SKIP_PACKAGE_VERSION
set APP_JAR=%APP_NAME%-%APP_VERSION%.jar
:SKIP_PACKAGE_VERSION

if /i NOT "%VERBOSE%"=="true" goto :CONTINUE

call :SHOW_VARIABLE APP_VERSION
call :SHOW_VARIABLE APP_NAME
call :SHOW_VARIABLE APP_PACKAGE
call :SHOW_VARIABLE APP_JAR
call :SHOW_VARIABLE DEFAULT_MAIN_CLASS

:CONTINUE

CALL :SHOW_LAST_ARGUMENT %*

set CLEAN=%1

if /i "%CLEAN%" EQU "clean" shift
if /i "%DEBUG%" EQU "true" (
  if /i "%CLEAN%" EQU "clean" echo >&2 CLEAN=%CLEAN%
  if "%ARGS_COUNT%" GEQ "1" echo >&2 ARG1=%1
  if "%ARGS_COUNT%" GEQ "2" echo >&2 ARG2=%2
  if "%ARGS_COUNT%" GEQ "3" echo >&2 ARG3=%3
  if "%ARGS_COUNT%" GEQ "4" echo >&2 ARG4=%4
  if "%ARGS_COUNT%" GEQ "5" echo >&2 ARG5=%5
  if "%ARGS_COUNT%" GEQ "6" echo >&2 ARG6=%6
  if "%ARGS_COUNT%" GEQ "7" echo >&2 ARG7=%7
  if "%ARGS_COUNT%" GEQ "8" echo >&2 ARG8=%8
  if "%ARGS_COUNT%" GEQ "9" echo >&2 ARG9=%9
)

set MAIN_CLASS=%~1
if NOT "%MAIN_CLASS%" == "" shift
if "%MAIN_CLASS%"=="" set MAIN_CLASS=%DEFAULT_MAIN_CLASS%

set APP_HOME=%CD:\=/%
REM omit the extension - on different Windows
REM will be mvn.bat or mvn.cmd

if "%SKIP_TEST%"=="" (
REM Test
call mvn test
) else (
REM Compile
if /i "%CLEAN%" EQU "clean" (
  call mvn -Dmaven.test.skip=true clean package install
) else (
  call mvn -Dmaven.test.skip=true package install
)
)

REM Run
REM NOTE: shift does not modify the %*
REM The log4j configuration argument seems to be ignored
REM -Dlog4j.configuration=file:///%APP_HOME%/src/main/resources/log4j.properties ^
set COMMAND=^
java ^
  -cp %TARGET%\%APP_JAR%;%TARGET%\lib\* ^
  %APP_PACKAGE%.%MAIN_CLASS% ^
  %1 %2 %3 %4 %5 %6 %7 %8 %9
echo %COMMAND%>&2
%COMMAND%
ENDLOCAL
exit /b

:CALL_JAVASCRIPT

REM This script extracts project g.a.v a custom property from pom.xml using mshta.exe and DOM selectSingleNode method
set "SCRIPT=mshta.exe "javascript:{"
set "SCRIPT=%SCRIPT% var fso = new ActiveXObject('Scripting.FileSystemObject');"
set "SCRIPT=%SCRIPT% var out = fso.GetStandardStream(1);"
set "SCRIPT=%SCRIPT% var fh = fso.OpenTextFile('pom.xml', 1, true);"
set "SCRIPT=%SCRIPT% var xd = new ActiveXObject('Msxml2.DOMDocument');"
set "SCRIPT=%SCRIPT% xd.async = false;"
set "SCRIPT=%SCRIPT% data = fh.ReadAll();"
set "SCRIPT=%SCRIPT% xd.loadXML(data);"
set "SCRIPT=%SCRIPT% root = xd.documentElement;"
set "SCRIPT=%SCRIPT% var xpath = '%~1';"
set "SCRIPT=%SCRIPT% var xmlnode = root.selectSingleNode( xpath);"
set "SCRIPT=%SCRIPT% if (xmlnode != null) {"
set "SCRIPT=%SCRIPT%   out.Write(xpath + '=' + xmlnode.text);"
set "SCRIPT=%SCRIPT% } else {"
set "SCRIPT=%SCRIPT%   out.Write('ERR');"
set "SCRIPT=%SCRIPT% }"
set "SCRIPT=%SCRIPT% close();}""

for /F "tokens=2 delims==" %%_ in ('%SCRIPT% 1 ^| more') do set VALUE=%%_
ENDLOCAL
exit /b


:SHOW_VARIABLE
SETLOCAL ENABLEDELAYEDEXPANSION
set VAR=%1
if /i "%DEBUG%"=="true" echo>&2 VAR=!VAR!
set RESULT=!VAR!
call :SHOW_VARIABLE_VALUE !%VAR%!
set RESULT=!RESULT!="!DATA!"
echo>&2 !RESULT!
ENDLOCAL
goto :EOF

:SHOW_VARIABLE_VALUE
set VAL=%1
if /i "%DEBUG%"=="true" echo>&2 %1
set DATA=%VAL%
if /i "%DEBUG%"=="true" echo>&2 VALUE=%VAL%
goto :EOF


:SHOW_LAST_ARGUMENT
REM https://stackoverflow.com/questions/1291941/batch-files-number-of-command-line-arguments
set /A ARGS_COUNT=0
for %%_ in (%*) DO SET /A ARGS_COUNT+=1
if /i "%DEBUG%"=="true" echo>&2 The number of arguments is %ARGS_COUNT%
REM the following does not work
SETLOCAL ENABLEDELAYEDEXPANSION
for /F "tokens=*" %%_ in ('echo %%!ARGS_COUNT!') DO set P=%%_
if /i "%DEBUG%"=="true" echo P=%P%
call :SHOW_VARIABLE_VALUE !P!
set CLEAN=%VALUE%
REM the value disappears after ENDLOCAL
ENDLOCAL
goto :EOF
