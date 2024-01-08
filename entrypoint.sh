#!/bin/bash
sed -i s/localhost/$HOSTNAME/g /etc/slurm/slurm.conf
/etc/init.d/postfix start
/etc/init.d/cron start
chown 106 /etc/munge/munge.key
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
#/etc/init.d/postgres start

if [ "${MODE}" = 'TESTING' ]; then
    exec perl t/test_fixture.pl --carpalways -v "${@}"
fi

umask 002

# load empty fixture and run any missing patches

if [ $(psql -h breedbase_db -U postgres -Atc 'select count(distinct table_schema) from information_schema.tables;') == "3" ]; then
    psql -c "CREATE EXTENSION age; "
    psql -c "LOAD 'age';"    
    psql -c "CREATE USER web_usr PASSWORD 'postgres';"
    psql -c "GRANT USAGE ON SCHEMA ag_catalog TO web_usr;"
    psql -c "SET search_path = ag_catalog, web_usr, public;"
    psql -c "SELECT * FROM ag_catalog.create_graph('pedigree_graph');"
    psql -c "SELECT *
        FROM ag_catalog.cypher('pedigree_graph', \$\$
        CREATE (:PEDIGREE{
            name: 'create',
            stock_id: 0001
        })
        \$\$) as (v ag_catalog.agtype);"
    psql -c "GRANT USAGE ON SCHEMA pedigree_graph TO web_usr;"
    psql -c "GRANT CREATE ON SCHEMA pedigree_graph TO web_usr;"
    psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pedigree_graph TO web_usr;"
    psql -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pedigree_graph TO web_usr;"
    psql -f t/data/fixture/empty_breedbase.sql
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
	chmod 770 /home/production/volume/archive
    fi

    if [[ ! -e /home/production/volume/logs ]]
    then
        mkdir /home/production/volume/logs
        chown www-data /home/production/volume/logs
	chmod 770 /home/production/volume/logs
    fi

    if [[ ! -e /home/production/volume/blast ]]
    then
        mkdir /home/production/volume/blast
    fi

    if [[ ! -e /home/production/volume/public ]]
    then
        mkdir /home/production/volume/public
	chown www-data /home/production/volume/public
	chmod 770 /home/production/volume/public
    fi

    if [[ ! -e /home/production/volume/public/images ]]
    then
        mkdir /home/production/volume/public/images
        chown www-data /home/production/volume/public/images
	chmod 770 /home/production/volume/images
    fi

    if [[ ! -e /home/production/volume/tmp ]]
    then
        mkdir /home/production/volume/tmp
        chown www-data /home/production/volume/tmp
	chmod 770 /home/production/volume/tmp
    fi

    if [[ ! -e /home/production/volume/cache ]]
    then
        mkdir /home/production/volume/cache
        chown www-data /home/production/volume/cache
	chmod 770 /home/production/volume/cache
    fi

    if [[ ! -e /home/production/volume/cluster ]]
    then
        mkdir /home/production/volume/cluster
        chown www-data /home/production/volume/cluster
	chmod 770 /home/production/volume/cluster
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
        /home/production/cxgn/sgn/bin/sgn_server.pl --fork -r -p 8080
else
    /etc/init.d/sgn start
    touch /var/log/sgn/error.log
  chmod 777 /var/log/sgn/error.log
  tail -f /var/log/sgn/error.log
fi
