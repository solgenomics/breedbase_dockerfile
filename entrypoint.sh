#!/bin/bash
sed -i s/localhost/$HOSTNAME/g /etc/slurm-llnl/slurm.conf
/etc/init.d/postfix start
/etc/init.d/cron start
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
#/etc/init.d/postgres start


# load empty fixture and run any missing patches

if [ $(psql -Atc 'select count(distinct table_schema) from information_schema.tables;') -eq 2 ]; then
    psql -c "CREATE USER web_usr PASSWORD 'postgres';"
    psql -f t/data/fixture/empty_fixture.sql
    ( cd db && ./run_all_patches.pl -u ${PGUSER} -p "${PGPASSWORD}" -h ${PGHOST} -d ${PGDATABASE} -e janedoe )
fi

# create necessary dirs/permissions if we have a docker volume dir
# at /home/production/volume

if [[ -e /home/production/volume ]]
then
    if [[ ! -e /home/production/volume/archive ]]
    then
        mkdir /home/production/volume/archive
        chown www-data /home/production/volume/archive
    fi

    if [[ ! -e /home/production/volume/logs ]]
    then
        mkdir /home/production/volume/logs
        chown www-data /home/production/volume/logs
    fi

    if [[ ! -e /home/production/volume/blast ]]
    then
        mkdir /home/production/volume/blast
    fi

    if [[ ! -e /home/production/volume/public ]]
    then
        mkdir /home/production/volume/public
    fi

    if [[ ! -e /home/production/volume/public/images ]]
    then
        mkdir /home/production/volume/public/images
        chown www-data /home/production/volume/public/images
    fi

    if [[ ! -e /home/production/volume/tmp ]]
    then
        mkdir /home/production/volume/tmp
        chown www-data /home/production/volume/tmp
    fi

    if [[ ! -e /home/production/volume/cache ]]
    then
        mkdir /home/production/volume/cache
        chown www-data /home/production/volume/cache
    fi

    if [[ ! -e /home/production/volume/cluster ]]
    then
        mkdir /home/production/volume/cluster
        chown www-data /home/production/volume/cluster
    fi
    
    if [[ ! -e /home/production/volume/pgdata ]]
    then
        mkdir /home/production/volume/pgdata
        chown postgres /home/production/pgdata
    fi
else
    echo "/home/production/volume does not exist... not creating dirs";
fi


if [ "$MODE" == "DEVELOPMENT" ]; then
        /home/production/cxgn/sgn/bin/sgn_server.pl --fork -r -d -p 8080
else
  /etc/init.d/sgn start
  chmod 777 /var/log/sgn/error.log
  tail -f /var/log/sgn/error.log
fi
