@echo off
title WinHealth
setlocal enabledelayedexpansion
color 0A
chcp 65001 >nul 2>&1

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo =====================================================
    echo ERRO: VOCE PRECISA EXECUTAR COMO ADMINISTRADOR.
    echo =====================================================
    pause
    exit
)

set "LOG_DIR=%PROGRAMDATA%\Logs_Manutencao"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f "usebackq" %%I in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd'"`) do set "mydate=%%I"
set "LOG_FILE=%LOG_DIR%\WinHealth_Log_%mydate%.txt"

echo [LOG] Sessao iniciada: %date% %time% >> "%LOG_FILE%"

:menu
cls
echo.
echo  =========================================================================
echo  Yb        dP 88 88b 88 88  88 888888    db    88     888888 88  88
echo   Yb  db  dP  88 88Yb88 88  88 88__     dPYb   88       88   88  88
echo    YbdPYbdP   88 88 Y88 888888 88""    dP__Yb  88  .o   88   888888
echo     YP  YP    88 88  Y8 88  88 888888 dP""""Yb 88ood8   88   88  88
echo  =========================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ver  = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion;" ^
    "$os   = (Get-CimInstance Win32_OperatingSystem).Caption;" ^
    "$cpu  = (Get-CimInstance Win32_Processor).Name;" ^
    "$gpu  = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name;" ^
    "$mb   = (Get-CimInstance Win32_BaseBoard).Manufacturer + ' ' + (Get-CimInstance Win32_BaseBoard).Product;" ^
    "$ramT = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1);" ^
    "$ramF = [Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1);" ^
    "$ramU = [Math]::Round($ramT - $ramF,1);" ^
    "$ramP = [Math]::Round(($ramU/$ramT)*100,0);" ^
    "$disk = Get-CimInstance Win32_DiskDrive | Select-Object -First 1;" ^
    "$diskT = [Math]::Round($disk.Size/1GB,0);" ^
    "$diskM = $disk.Model;" ^
    "$vol  = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DeviceID -eq 'C:'};" ^
    "$volT = [Math]::Round($vol.Size/1GB,1);" ^
    "$volF = [Math]::Round($vol.FreeSpace/1GB,1);" ^
    "$volU = [Math]::Round($volT - $volF,1);" ^
    "$volP = [Math]::Round(($volU/$volT)*100,0);" ^
    "$pc   = [char]37;" ^
    "$lp   = [char]40;" ^
    "$rp   = [char]41;" ^
    "Write-Host ('  SO          : ' + $os + ' ' + $ver);" ^
    "Write-Host ('  CPU         : ' + $cpu);" ^
    "Write-Host ('  GPU         : ' + $gpu);" ^
    "Write-Host ('  Placa Mae   : ' + $mb);" ^
    "Write-Host ('  RAM         : ' + $ramU + ' GB usados / ' + $ramT + ' GB total ' + $lp + $ramP + $pc + $rp);" ^
    "Write-Host ('  Disco       : ' + $diskM + ' ' + $lp + $diskT + ' GB' + $rp);" ^
    "Write-Host ('  Volume C:   : ' + $volU + ' GB usados / ' + $volT + ' GB total ' + $lp + $volP + $pc + $rp);"
echo  =========================================================================
echo   MENU:
echo   [1] Reparar Sistema
echo   [2] Limpar Temporarios
echo   [3] Checagem de Rede
echo   [4] Reset Total de Rede
echo   [5] Verificacao de Portas
echo   [6] Atualizar Apps (Winget)
echo   [7] Atualizar Politicas de Grupo
echo   [8] Saude do Disco
echo   [9] Reinicio do Spooler de Impressao
echo   [A] Verificacao de Logs
echo   [0] Sair
echo  =========================================================================
echo   Log salvo em: %LOG_DIR%
echo  =========================================================================
set /p opcao= Escolha uma opcao: 

if /i "%opcao%"=="1" goto reparo
if /i "%opcao%"=="2" goto limpeza
if /i "%opcao%"=="3" goto rede
if /i "%opcao%"=="4" goto reset_rede
if /i "%opcao%"=="5" goto verificacao_portas
if /i "%opcao%"=="6" goto upgrade_apps
if /i "%opcao%"=="7" goto atualizar_politicas
if /i "%opcao%"=="8" goto saude_disco
if /i "%opcao%"=="9" goto reinicio_spooler
if /i "%opcao%"=="A" goto verificacao_logs
if /i "%opcao%"=="0" goto sair
if "%opcao%"=="" goto sair
goto menu

:reparo
cls
echo [1/3] Executando DISM (Reparo de Imagem)...
echo [LOG] Iniciado DISM >> "%LOG_FILE%"
dism /online /cleanup-image /restorehealth
echo.
echo [2/3] Executando SFC (Integridade de Arquivos)...
echo [LOG] Iniciado SFC >> "%LOG_FILE%"
sfc /scannow
echo.
echo [3/3] Executando CHKDSK (Verificacao de Disco)...
echo [LOG] Iniciado CHKDSK >> "%LOG_FILE%"
set /p confirm_chk= Deseja agendar o CHKDSK? (S/N): 
if /i not "%confirm_chk%"=="S" (
    echo [!] Operacao cancelada pelo usuario.
    echo [LOG] CHKDSK cancelado pelo usuario >> "%LOG_FILE%"
    pause
    goto menu
)
echo S> "%temp%\chkdsk_answer.txt"
chkdsk C: /f /r < "%temp%\chkdsk_answer.txt"
del "%temp%\chkdsk_answer.txt"

echo [^>] CHKDSK agendado para proximo boot
echo [LOG] CHKDSK agendado para proximo boot >> "%LOG_FILE%"
echo.
echo [OK] Reparos concluidos.
echo [LOG] Finalizado em %time% >> "%LOG_FILE%"
pause
goto menu

:limpeza
cls
echo [^>] Limpando arquivos temporarios...
echo.

if exist "%temp%" (
    for /f "delims=" %%F in ('dir /b /s /a-d "%temp%" 2^>nul') do (
        echo   [-] %%F
        del /q /f "%%F" >nul 2>&1
    )
    for /d %%x in ("%temp%\*") do rd /s /q "%%x" >nul 2>&1
)

if exist "C:\Windows\Temp" (
    for /f "delims=" %%F in ('dir /b /s /a-d "C:\Windows\Temp" 2^>nul') do (
        echo   [-] %%F
        del /q /f "%%F" >nul 2>&1
    )
    for /d %%x in ("C:\Windows\Temp\*") do rd /s /q "%%x" >nul 2>&1
)

echo.
echo [LOG] Limpeza de temporarios realizada >> "%LOG_FILE%"
echo [OK] Limpeza concluida.
pause
goto menu

:rede
cls
echo [1/4] Testando Gateway (Roteador)...
set "found_gw="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "Default Gateway"') do (
    set "gw=%%a"
    set "gw=!gw: =!"
    if not "!gw!"=="" if not "!gw!"=="0.0.0.0" (
        echo [OK] Gateway encontrado: !gw!
        ping !gw! -n 4 -w 1000
        set "found_gw=1"
    )
)
if not defined found_gw echo [LOG] Gateway nao localizado ou invalido.

echo.
echo [2/4] Testando Servidores DNS...
set "found_dns="
for /f "tokens=2 delims=:" %%b in ('ipconfig /all ^| findstr /i "DNS Servers"') do (
    set "dns=%%b"
    set "dns=!dns: =!"
    if not "!dns!"=="" (
        echo [OK] DNS detectado: !dns!
        ping !dns! -n 4 -w 1000
        set "found_dns=1"
    )
)
if not defined found_dns echo [LOG] Servidor DNS nao detectado.

echo.
echo [3/4] Testando Conexao (google.com)...
ping google.com -n 4 -w 1000

echo.
echo [4/4] Testando Conexao (a.ntp.br)...
ping a.ntp.br -n 4 -w 1000

echo [LOG] Teste de rede completo >> "%LOG_FILE%"
pause
goto menu

:reset_rede
cls
echo [^>] Resetando configuracoes de rede...
set /p confirm= Deseja continuar? (S/N): 
if /i not "%confirm%"=="S" (
    echo [!] Operacao cancelada pelo usuario.
    echo [LOG] Reset de rede cancelado pelo usuario >> "%LOG_FILE%"
    pause
    goto menu
)
echo.
echo [1/3] Limpando cache DNS...
ipconfig /flushdns
echo [2/3] Resetando pilha TCP/IP...
netsh int ip reset
echo [3/3] Resetando Winsock...
netsh winsock reset
echo [LOG] Reset de rede executado >> "%LOG_FILE%"
echo.
echo [OK] Reset concluido. Reinicie o computador para aplicar as mudancas.
pause
goto menu

:verificacao_portas
cls
echo ===============================================
echo  VERIFICACAO DE PORTAS
echo ===============================================
echo.
echo [!] Portas monitoradas: 21 FTP, 22 SSH, 23 TELNET, 53 DNS,
echo     80 HTTP, 135 RPC, 139 NetBIOS, 445 SMB, 3389 RDP
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$RiskyPorts = @(21, 22, 23, 53, 80, 135, 139, 445, 3389);" ^
    "Get-NetTCPConnection -State Listen |" ^
    "Where-Object { $RiskyPorts -contains $_.LocalPort } |" ^
    "Select-Object LocalPort, OwningProcess, @{Name='ProcessName'; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |" ^
    "Format-Table -AutoSize"
echo.
echo [LOG] Verificacao de portas realizada >> "%LOG_FILE%"
pause
goto menu

:upgrade_apps
cls
where winget >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Winget nao encontrado neste sistema.
    echo     Instale o App Installer pela Microsoft Store ou atualize o Windows.
    echo [LOG] Winget indisponivel >> "%LOG_FILE%"
    pause
    goto menu
)
echo [^>] Verificando atualizacoes via Winget...
winget upgrade --all
echo [LOG] Winget executado >> "%LOG_FILE%"
pause
goto menu

:atualizar_politicas
cls
echo [^>] Atualizando politicas de grupo...
gpupdate /force
echo [LOG] Atualizacao de politicas realizada >> "%LOG_FILE%"
pause
goto menu

:saude_disco
cls
echo ===============================================
echo  SAUDE DO DISCO
echo ===============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Import-Module Storage -ErrorAction SilentlyContinue;" ^
    "try {" ^
    "    Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, Size | Format-Table -AutoSize;" ^
    "} catch {" ^
    "    Write-Host '[!] Modulo Storage indisponivel nesta edicao do Windows.';" ^
    "    Write-Host '    Tente usar o fabricante do disco (CrystalDiskInfo, etc.).';" ^
    "}"
echo.
echo [LOG] Verificacao de disco realizada >> "%LOG_FILE%"
pause
goto menu

:reinicio_spooler
cls
echo [^>] Reiniciando Spooler de Impressao...
net stop spooler
net start spooler
echo [LOG] Spooler de Impressao reiniciado >> "%LOG_FILE%"
echo [OK] Spooler reiniciado.
pause
goto menu

:verificacao_logs
cls
echo ===============================================
echo  VERIFICACAO DE LOGS
echo ===============================================
echo.
echo [^>] Erros recentes - Log do Sistema (ultimos 5)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction SilentlyContinue |" ^
    "Format-Table TimeGenerated, Source, EventID, Message -AutoSize"
echo.
echo [^>] Erros recentes - Log de Aplicacao (ultimos 5)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-EventLog -LogName Application -EntryType Error -Newest 5 -ErrorAction SilentlyContinue |" ^
    "Format-Table TimeGenerated, Source, EventID, Message -AutoSize"
echo.
echo [^>] Erros recentes - Log de Seguranca (ultimos 5)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-EventLog -LogName Security -EntryType Error -Newest 5 -ErrorAction SilentlyContinue |" ^
    "Format-Table TimeGenerated, Source, EventID, Message -AutoSize"
echo.
echo [^>] Avisos e Erros - Sistema e Aplicacao (ultimos 10 cada)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-EventLog -LogName System -EntryType Warning,Error -Newest 10 -ErrorAction SilentlyContinue |" ^
    "Format-Table TimeGenerated, Source, EventID, EntryType, Message -AutoSize"
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-EventLog -LogName Application -EntryType Warning,Error -Newest 10 -ErrorAction SilentlyContinue |" ^
    "Format-Table TimeGenerated, Source, EventID, EntryType, Message -AutoSize"
echo.
echo [LOG] Verificacao de logs realizada >> "%LOG_FILE%"
pause
goto menu

:sair
echo [LOG] Sessao encerrada: %time% >> "%LOG_FILE%"
exit