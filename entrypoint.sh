#!/bin/bash

/etc/init.d/munge start
/etc/init.d/slurmctld start
/etc/init.d/slurmd start
screen /home/production/cxgn/sgn/bin/sgn_server.pl --fork --port 8080


