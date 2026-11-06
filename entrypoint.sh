#!/bin/bash
/etc/init.d/postfix start
/etc/init.d/cron start
#/etc/init.d/postgres start

# start the job backend configured in sgn_local.conf ("backend Tsp" or "backend Slurm")
#
JOB_BACKEND=$(awk 'tolower($1) == "backend" { b = tolower($2) } END { print b }' /home/production/cxgn/sgn/sgn.conf /home/production/cxgn/sgn/sgn_local.conf)

if [ "$JOB_BACKEND" = "tsp" ] && ! command -v tsp > /dev/null; then
    echo "ERROR: backend Tsp is configured in sgn_local.conf, but tsp is not installed (Debian package task-spooler). Background jobs will fail."
elif [ "$JOB_BACKEND" = "tsp" ]; then
    # task-spooler. The tsp server uses the default per-user socket unless
    # TS_SOCKET is set (in the container environment, so that docker exec
    # shells and scripts talk to the same server); TS_MAXFINISHED is the
    # number of finished jobs it keeps track of.
    export TS_MAXFINISHED=${TS_MAXFINISHED:-10000}
    TSP_SLOTS=${TSP_SLOTS:-$(( $(nproc) > 1 ? $(nproc) / 2 : 1 ))}
    tsp -S $TSP_SLOTS
    # tsp job ids start at 0, which is false in Perl; use up id 0
    tsp -L reserved-job-id true > /dev/null
    echo "Started task-spooler with $TSP_SLOTS slots"
    if [ -n "$BB_JOB_PODMAN_URL" ]; then
        echo "Jobs will run in podman containers via $BB_JOB_PODMAN_URL"
    fi
else
    sed -i s/localhost/$HOSTNAME/g /etc/slurm/slurm.conf
    chown munge /etc/munge/munge.key
    /etc/init.d/munge start
    /etc/init.d/slurmctld start
    /etc/init.d/slurmd start

    # undrain node if needed
    #
    scontrol update NodeName=$HOSTNAME State=RESUME
fi

chown root /etc/crontab # in case it was mounted from local dir

if [ "${MODE}" = 'TESTING' ]; then
    exec perl t/test_fixture.pl --carpalways -v "${@}"
fi

umask 002

# load empty fixture and run any missing patches

echo "CHECKING IF A DATABASE NEEDS TO BE INSTALLED...";

if [[ $(psql -lqt -h ${PGHOST} -U ${PGUSER}  | cut -d '|' -f1  | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//;' |  grep -w breedbase ) = '' ]]; then
    echo "INSTALLING DATABASE...";
    echo "CREATING web_usr...";
    psql -d postgres -c "CREATE USER web_usr PASSWORD 'postgres';"
    echo "CREATING breedbase DATABASE...";

    psql -d postgres -c "CREATE DATABASE breedbase; "
    if [ -e '/db_dumps/empty_breedbase.sql' ]
    then
	echo "LOADING empty_breedbase dump...";
	psql -f /db_dumps/empty_breedbase.sql
	(cd db && ./run_all_patches.pl -u ${PGUSER} -p ${PGPASSWORD} -h ${PGHOST} -d ${PGDATABASE} -e admin )
    else
	echo "LOADING cxgn_fixture.sql dump...";
	psql -f t/data/fixture/cxgn_fixture.sql
	(cd db && ./run_all_patches.pl -u ${PGUSER} -p ${PGPASSWORD} -h ${PGHOST} -d ${PGDATABASE} -e janedoe )
    fi


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

echo "PERL5LIB: " $PERL5LIB
echo "PERL LOCATION: " `which perl`
echo "PERL VERSION: " `perl -v`

if [ "$MODE" == "DEVELOPMENT" ]; then
        perl /home/production/cxgn/sgn/bin/sgn_server.pl --fork -r -p 8080
else
    /etc/init.d/sgn start
    touch /var/log/sgn/error.log
  chmod 777 /var/log/sgn/error.log
  tail -f /var/log/sgn/error.log
fi

# for unigene page, compile drawcontig align program
#cd /home/production/cxgn/sgn/programs
#make
#cd /home/production/cxgn/sgn
