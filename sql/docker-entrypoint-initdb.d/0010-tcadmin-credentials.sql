CREATE USER IF NOT EXISTS 'tcadmin'@'%' IDENTIFIED BY 'tcadmin';
GRANT SELECT ON world.command TO 'tcadmin'@'%';
