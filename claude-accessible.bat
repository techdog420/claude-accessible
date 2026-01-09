@echo off
REM claude-accessible.bat - Screen reader friendly Claude Code wrapper for Windows
REM Usage: claude-accessible.bat "your prompt here"
REM        claude-accessible.bat --continue "follow-up prompt"
REM        claude-accessible.bat --new "start fresh conversation"
REM        claude-accessible.bat --file prompt.txt
REM        type prompt.txt | claude-accessible.bat

setlocal enabledelayedexpansion

set SESSION_FILE=.claude-session
set HISTORY_FILE=claude-history.txt
set ALLOWED_TOOLS=Read,Write,Edit,Bash,Grep,Glob,Task

REM Parse arguments
set MODE=auto
set PROMPT=
set FILE_INPUT=
set OPEN_EDITOR=0

if "%1"=="--continue" (
    set MODE=continue
    shift
) else if "%1"=="-c" (
    set MODE=continue
    shift
) else if "%1"=="--new" (
    set MODE=new
    if exist "%SESSION_FILE%" del "%SESSION_FILE%"
    shift
) else if "%1"=="-n" (
    set MODE=new
    if exist "%SESSION_FILE%" del "%SESSION_FILE%"
    shift
) else if "%1"=="--file" (
    shift
    set FILE_INPUT=%~1
    shift
) else if "%1"=="-f" (
    shift
    set FILE_INPUT=%~1
    shift
) else if "%1"=="--editor" (
    set OPEN_EDITOR=1
    shift
) else if "%1"=="-e" (
    set OPEN_EDITOR=1
    shift
)

REM Collect all remaining arguments as prompt
:loop
if "%~1"=="" goto endloop
set PROMPT=!PROMPT! %~1
shift
goto loop
:endloop

REM Trim leading space
if defined PROMPT set PROMPT=!PROMPT:~1!

REM Check for file input
if defined FILE_INPUT (
    if not exist "!FILE_INPUT!" (
        echo Error: File not found: !FILE_INPUT!
        exit /b 1
    )
    REM Read file content into PROMPT
    set PROMPT=
    for /f "usebackq delims=" %%a in ("!FILE_INPUT!") do (
        if defined PROMPT (
            set PROMPT=!PROMPT! %%a
        ) else (
            set PROMPT=%%a
        )
    )
)

REM Check for stdin input (if no prompt and no file specified)
if "!PROMPT!"=="" (
    REM Check if stdin has data using PowerShell
    for /f "delims=" %%i in ('powershell -Command "if ([Console]::KeyAvailable) { 'false' } else { 'true' }"') do set STDIN_AVAILABLE=%%i

    if "!STDIN_AVAILABLE!"=="true" (
        REM Read from stdin
        set PROMPT=
        for /f "usebackq delims=" %%a in (`more`) do (
            if defined PROMPT (
                set PROMPT=!PROMPT! %%a
            ) else (
                set PROMPT=%%a
            )
        )
    )
)

if "!PROMPT!"=="" (
    echo Error: Please provide a prompt
    echo Usage: %0 "your prompt here"
    echo        %0 --continue "follow-up prompt"
    echo        %0 --new "start fresh conversation"
    echo        %0 --file prompt.txt
    echo        %0 --editor "prompt to edit in default editor"
    echo        type prompt.txt ^| %0
    exit /b 1
)

REM Log the prompt
echo ======================================== >> "%HISTORY_FILE%"
echo PROMPT: !PROMPT! >> "%HISTORY_FILE%"
echo TIME: %date% %time% >> "%HISTORY_FILE%"
echo ======================================== >> "%HISTORY_FILE%"

REM Check if we have an existing session
if exist "%SESSION_FILE%" if not "%MODE%"=="new" (
    set /p SESSION_ID=<"%SESSION_FILE%"
    echo Continuing session: !SESSION_ID!
    echo.

    REM Continue the conversation
    claude --print "!PROMPT!" --resume "!SESSION_ID!" --allowedTools "%ALLOWED_TOOLS%" > temp-output.txt 2>&1

    REM Check error level and display output
    if exist temp-output.txt (
        type temp-output.txt

        REM Log response to history
        echo. >> "%HISTORY_FILE%"
        echo RESPONSE: >> "%HISTORY_FILE%"
        type temp-output.txt >> "%HISTORY_FILE%"
        echo. >> "%HISTORY_FILE%"
        echo ---------------------------------------- >> "%HISTORY_FILE%"
        echo. >> "%HISTORY_FILE%"
        del temp-output.txt
    ) else (
        echo ERROR: temp-output.txt was not created!
        echo Claude command may have failed or produced no output.
    )
) else (
    echo Starting new conversation...
    echo.
    echo DEBUG: Running command:
    echo claude --print "!PROMPT!" --allowedTools "%ALLOWED_TOOLS%" --output-format json
    echo.

    REM Start new conversation with JSON output to capture session ID
    claude --print "!PROMPT!" --allowedTools "%ALLOWED_TOOLS%" --output-format json > temp-output.txt 2>&1

    REM Check error level
    if !ERRORLEVEL! NEQ 0 (
        echo ERROR: Claude command failed with exit code !ERRORLEVEL!
        echo.
    )

    REM Check if output was captured
    if exist temp-output.txt (
        REM Extract and display the result field from JSON
        echo Response:
        echo ========================================
        powershell -Command "$json = Get-Content temp-output.txt -Raw | ConvertFrom-Json; $json.result"
        echo ========================================
        echo.

        REM Log response to history
        echo. >> "%HISTORY_FILE%"
        echo RESPONSE: >> "%HISTORY_FILE%"
        powershell -Command "$json = Get-Content temp-output.txt -Raw | ConvertFrom-Json; $json.result" >> "%HISTORY_FILE%"
        echo. >> "%HISTORY_FILE%"
        echo ---------------------------------------- >> "%HISTORY_FILE%"
        echo. >> "%HISTORY_FILE%"

        REM Extract session ID from JSON
        for /f "delims=" %%i in ('powershell -Command "$json = Get-Content temp-output.txt -Raw | ConvertFrom-Json; $json.session_id"') do set NEW_SESSION_ID=%%i

        if defined NEW_SESSION_ID (
            echo !NEW_SESSION_ID! > "%SESSION_FILE%"
            echo Session ID saved: !NEW_SESSION_ID!
            echo Use --continue flag for follow-up questions
        ) else (
            echo Warning: Could not extract session ID from output
        )

        del temp-output.txt
    ) else (
        echo ERROR: temp-output.txt was not created!
        echo Claude command may have failed or produced no output.
    )
)

echo. >> "%HISTORY_FILE%"

REM Open in editor if requested
if "%OPEN_EDITOR%"=="1" (
    set OUTPUT_FILE=claude-output-%RANDOM%.txt
    echo Opening output in default editor: !OUTPUT_FILE!

    REM Extract the last response from history file
    powershell -Command "$lines = Get-Content '%HISTORY_FILE%'; $lastResponseIndex = ($lines.Length - 1)..0 | Where-Object { $lines[$_] -match '^RESPONSE:' } | Select-Object -First 1; if ($lastResponseIndex) { $lines[$lastResponseIndex..($lines.Length - 1)] | Out-File '!OUTPUT_FILE!' -Encoding UTF8 }"

    REM Open in default editor
    start "" "!OUTPUT_FILE!"
)

endlocal
