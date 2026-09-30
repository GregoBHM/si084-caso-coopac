#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
mkdir -p evidencias capturas
export MSYS_NO_PATHCONV=1
trap 'echo "ERROR: revise la salida antes de continuar." >&2' ERR
pause_capture() {
  echo
  echo "CAPTURA $1"
  read -r -p "Guarde la captura en capturas/ y pulse Enter..."
}
sql() { docker exec -i sr_bd psql -X -v ON_ERROR_STOP=1 -P pager=off -U postgres -d core "$@"; }
docker compose version
docker info >/dev/null
if compgen -G 'evidencias/P*.txt' >/dev/null; then
  echo "Ya existen evidencias. Consérvelas en otra carpeta antes de repetir."
  exit 1
fi
echo 'INICIO: docker compose up -d --wait'
docker compose up -d --wait
docker compose ps
pause_capture '00-inicio.png: servidor Healthy'
echo 'P1: docker compose ps'
docker compose ps | tee evidencias/P1_puertos.txt
pause_capture '01-puertos.png: dirección y puerto'
echo 'P2: archivo, línea y longitud de contraseña'
grep -n 'PASSWORD' docker-compose.yml > evidencias/P2_credenciales.txt
awk '/POSTGRES_PASSWORD:/ {v=$0; sub(/^.*POSTGRES_PASSWORD:[[:space:]]*/, "", v); sub(/\r$/, "", v); printf "docker-compose.yml:%d POSTGRES_PASSWORD: [OCULTA]; longitud=%d\n", NR,length(v)}' docker-compose.yml
pause_capture '02-credenciales.png: línea y longitud, sin contraseña'
echo 'P3: roles PostgreSQL'
sql -c '\du' | tee evidencias/P3_roles.txt
pause_capture '03-roles.png: app_core Superuser'
echo 'P4: cesados'
sql -c "SELECT u.usuario,e.nombre,e.fecha_cese FROM usuarios u JOIN empleados e ON e.documento=u.documento WHERE u.estado='activo' AND e.fecha_cese IS NOT NULL ORDER BY e.fecha_cese" -c "SELECT count(*) AS cuentas,count(DISTINCT e.documento) AS personas,min(e.fecha_cese) AS cese_mas_antiguo FROM usuarios u JOIN empleados e ON e.documento=u.documento WHERE u.estado='activo' AND e.fecha_cese IS NOT NULL" | tee evidencias/P4_cesados.txt
pause_capture '04a-cesados.png: detalle y resumen 16 / 10 / 2015-12-18'
echo 'P4: cuentas sin responsable'
sql -c "SELECT usuario,perfil FROM usuarios WHERE documento IS NULL AND estado='activo' ORDER BY perfil,usuario" -c "SELECT count(*) AS cuentas,count(*) FILTER (WHERE perfil='ADMIN') AS admin FROM usuarios WHERE documento IS NULL AND estado='activo'" | tee evidencias/P4_genericas.txt
pause_capture '04b-genericas.png: detalle y resumen 22 / 4'
echo 'P5: monto > umbral_aprobacion AND usuario_registra = usuario_aprueba'
sql -f - < scripts/p5.sql | tee evidencias/P5_segregacion.txt
pause_capture '05-segregacion.png: 23 / 709370.47 / 21 y detalle (dos imágenes si hace falta)'
echo 'P6: registro'
sql -c 'SHOW log_connections' -c 'SHOW log_statement' | tee evidencias/P6_registro.txt
grep -n 'log_connections' docker-compose.yml | tee -a evidencias/P6_registro.txt
pause_capture '06-registro.png: off / none y configuración'
echo 'P7: respaldos y causas'
{
  ls respaldos/
  tail -n 5 respaldos/respaldo.log
  cat respaldos/respaldo.sh
} | tee evidencias/P7_respaldos.txt
sql -c "SELECT DATE '2025-11-14' AS ultimo_respaldo, DATE '2025-12-31' AS corte, DATE '2025-12-31'-DATE '2025-11-14' AS dias" | tee -a evidencias/P7_respaldos.txt
pause_capture '07a-respaldos.png: fecha, 47 días, error y exclusión'
exists="$(docker exec sr_bd psql -X -At -U postgres -d postgres -c "SELECT 1 FROM pg_database WHERE datname='restauracion'")"
if [[ "$exists" == "1" ]]; then
  echo 'Ya existe restauracion. No se borrará ni sobrescribirá. Revísela antes de repetir P7.'
  exit 1
fi
echo 'P7: crear restauracion y restaurar core_2025-11-14.sql'
docker exec sr_bd psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres -c 'CREATE DATABASE restauracion' | tee evidencias/P7_restauracion.txt
docker exec -i sr_bd psql -X -v ON_ERROR_STOP=1 -U postgres -d restauracion < respaldos/core_2025-11-14.sql 2>&1 | tee -a evidencias/P7_restauracion.txt
docker exec sr_bd psql -X -v ON_ERROR_STOP=1 -P pager=off -U postgres -d restauracion -c '\dt' -c "SELECT to_regclass('public.desembolsos') IS NULL AS falta_desembolsos" | tee -a evidencias/P7_restauracion.txt
pause_capture '07b-restauracion.png: CREATE/COPY, tablas y falta_desembolsos=t'
echo 'Contraste INFORME.md, complete datos e inserte capturas. Luego: bash scripts/02-sellar.sh'
echo 'El servidor queda encendido.'

