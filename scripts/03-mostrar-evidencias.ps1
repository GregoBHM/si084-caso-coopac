$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $project
$items = @(
    @{Title='00 - Servidor Healthy'; Command={ docker ps --filter 'name=sr_bd' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' }},
    @{Title='01 - Exposición y puertos'; File='evidencias/P1_puertos.txt'},
    @{Title='02 - Contraseña redactada'; File='evidencias/P2_credenciales.txt'},
    @{Title='03 - Roles y superusuario'; File='evidencias/P3_roles.txt'},
    @{Title='04a - Cuentas de cesados'; File='evidencias/P4_cesados.txt'},
    @{Title='04b - Cuentas sin responsable'; File='evidencias/P4_genericas.txt'},
    @{Title='05 - Segregación de funciones'; File='evidencias/P5_segregacion.txt'},
    @{Title='06 - Registro de eventos'; File='evidencias/P6_registro.txt'},
    @{Title='07a - Respaldos'; File='evidencias/P7_respaldos.txt'},
    @{Title='07b - Restauración'; File='evidencias/P7_restauracion.txt'},
    @{Title='08 - Integridad SHA-256'; Command={ & 'C:\Program Files\Git\bin\bash.exe' -lc './scripts/02-sellar.sh' }}
)
foreach ($item in $items) {
    Clear-Host
    Write-Host ('=' * 78) -ForegroundColor DarkBlue
    Write-Host $item.Title -ForegroundColor Cyan
    Write-Host ('=' * 78) -ForegroundColor DarkBlue
    if ($item.File) { Get-Content -LiteralPath $item.File }
    else { & $item.Command }
    Write-Host ''
    Write-Host 'Tome la captura ahora con Win + Shift + S.' -ForegroundColor Yellow
    Read-Host 'Pulse Enter para mostrar la siguiente evidencia'
}
Write-Host 'Capturas terminadas. Guárdelas en la carpeta capturas con el nombre indicado.' -ForegroundColor Green
