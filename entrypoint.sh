#!/bin/bash
sed -i s/localhost/$HOSTNAME/g /etc/slurm-llnl/slurm.conf
/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
/home/production/cxgn/sgn/bin/sgn_server.pl --fork --port 8080


