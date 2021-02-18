#!/bin/bash
sed -i s/localhost/$HOSTNAME/g /etc/slurm-llnl/slurm.conf
/etc/init.d/postfix start
/etc/init.d/cron start
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
#/etc/init.d/postgres start
if [ $(psql -Atc 'select count(distinct table_schema) from information_schema.tables;') -eq 2 ]; then
  psql -c "CREATE USER web_usr PASSWORD 'postgres';"
  psql -f t/data/fixture/empty_fixture.sql
  ( cd db && ./run_all_patches.pl -u ${PGUSER} -p "${PGPASSWORD}" -h ${PGHOST} -d ${PGDATABASE} -e janedoe )
fi

if [ "$MODE" == "DEVELOPMENT" ]; then
	/home/production/cxgn/sgn/bin/sgn_server.pl --fork -r -d -p 8080
else
  /etc/init.d/sgn start
  chmod 777 /var/log/sgn/error.log
  tail -f /var/log/sgn/error.log
fi
