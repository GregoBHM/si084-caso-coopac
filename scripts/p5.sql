SELECT count(*) AS casos, sum(monto) AS monto_total,
count(DISTINCT usuario_registra) AS usuarios FROM desembolsos
WHERE monto > umbral_aprobacion AND usuario_registra = usuario_aprueba;
SELECT id, fecha, monto, usuario_registra FROM desembolsos
WHERE monto > umbral_aprobacion AND usuario_registra = usuario_aprueba
ORDER BY monto DESC;

