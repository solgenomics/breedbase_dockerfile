FROM debian:stretch

LABEL maintainer="lam87@cornell.edu"

ENV CPANMIRROR=http://cpan.cpantesters.org
# based on the vagrant provision.sh script by Nick Morales <nm529@cornell.edu>

# open port 8080
#
EXPOSE 8080

# create directory layout
#
RUN mkdir -p /home/production/public/sgn_static_content
RUN mkdir -p /home/production/tmp/solgs
RUN mkdir -p /home/production/archive
RUN mkdir -p /home/production/public/images/image_files
RUN mkdir -p /home/production/tmp
RUN mkdir -p /home/production/archive/breedbase
RUN mkdir -p /home/production/blast/databases/current
RUN mkdir -p /home/production/cxgn
RUN mkdir -p /home/production/cxgn/local-lib
RUN mkdir /etc/starmachine
RUN mkdir /var/log/sgn

WORKDIR /home/production/cxgn

# add cran backports repo and required deps
#
#RUN echo "deb http://lib.stat.cmu.edu/R/CRAN/bin/linux/debian stretch-cran35/" >> /etc/apt/sources.list

# install system dependencies
#
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update -y --allow-unauthenticated 
RUN apt-get upgrade -y
RUN apt-get install build-essential pkg-config apt-utils gnupg2 curl -y

# key for cran-backports (not working though)
#
#RUN bash -c "apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' 2> /key.out"

RUN apt-get update --fix-missing -y

RUN apt-get install -y libterm-readline-zoid-perl
RUN apt-get install nginx starman emacs gedit vim less sudo htop git dkms linux-headers-4.9.0-9-amd64 perl-doc ack-grep make xutils-dev nfs-common lynx xvfb ncbi-blast+  -y
RUN curl -L https://cpanmin.us | perl - --sudo App::cpanminus

RUN apt-get install libmunge-dev libmunge2 munge -y
RUN apt-get install slurm-wlm slurmctld slurmd libslurm-perl -y
RUN apt-get install libssl-dev -y

RUN chmod 777 /var/spool/
RUN mkdir /var/spool/slurmstate
RUN chown slurm:slurm /var/spool/slurmstate/
RUN /usr/sbin/create-munge-key
RUN ln -s /var/lib/slurm-llnl /var/lib/slurm
RUN apt-get install graphviz lsof imagemagick mrbayes muscle bowtie bowtie2 -y
#RUN apt-get install gnome-core gnome-terminal -y
RUN apt-get install r-base r-base-dev libopenblas-base -y --allow-unauthenticated
RUN apt-get install blast2 -y

# required for sending mails from the website
RUN apt-get install postfix mailutils -y

# required for R-package spdep, and other dependencies of agricolae
#
RUN apt-get install libudunits2-dev libgdal-dev -y

# copy code repos. Run the prepare.pl script to clone them
# before the build
#
COPY repos/cxgn-corelibs /home/production/cxgn/cxgn-corelibs
COPY repos/sgn /home/production/cxgn/sgn
COPY repos/Phenome /home/production/cxgn/Phenome
COPY repos/rPackages /home/production/cxgn/rPackages
COPY repos/biosource /home/production/cxgn/biosource
COPY repos/Cview /home/production/cxgn/Cview
COPY repos/ITAG /home/production/cxgn/ITAG
COPY repos/tomato_genome /home/production/cxgn/tomato_genome
COPY repos/Chado /home/production/cxgn/Chado
COPY repos/sgn-devtools /home/production/cxgn/sgn-devtools
COPY repos/starmachine /home/production/cxgn/starmachine

# copy some tools that don't have a Debian package
#
COPY tools/gcta/gcta64  /usr/bin/
COPY tools/quicktree /usr/bin/
COPY tools/sreformat /usr/bin/

# Mason website skins
#
COPY repos/cassava /home/production/cxgn/cassava
COPY repos/yambase /home/production/cxgn/yambase
COPY repos/sweetpotatobase /home/production/cxgn/sweetpotatobase
COPY repos/ricebase /home/production/cxgn/ricebase
COPY repos/citrusgreening /home/production/cxgn/citrusgreening
COPY repos/coconut /home/production/cxgn/coconut
COPY repos/cassbase /home/production/cxgn/cassbase
COPY repos/musabase /home/production/cxgn/musabase
COPY repos/potatobase /home/production/cxgn/potatobase
COPY repos/cea /home/production/cxgn/cea
COPY repos/cippotatobase /home/production/cxgn/cippotatobase
COPY repos/fernbase /home/production/cxgn/fernbase
COPY repos/solgenomics /home/production/cxgn/solgenomics
COPY repos/panzeabase /home/production/cxgn/panzeabase
COPY repos/varitome /home/production/cxgn/varitome
COPY repos/milkweed /home/production/cxgn/milkweed
COPY repos/erysimum /home/production/cxgn/erysimum
COPY repos/vitisbase /home/production/cxgn/vitisbase
COPY repos/panandbase /home/production/cxgn/panandbase
COPY repos/triticum /home/production/cxgn/triticum

COPY repos/local-lib /home/production/cxgn/local-lib
COPY repos/R_libs /home/production/cxgn/R_libs

COPY slurm.conf /etc/slurm-llnl/slurm.conf

COPY sgn_local.conf.template /home/production/cxgn/sgn/
COPY starmachine.conf /etc/starmachine/
COPY slurm.conf /etc/slurm-llnl/slurm.conf
COPY entrypoint.sh /entrypoint.sh

# XML::Simple dependency
#
RUN apt-get install libexpat1-dev -y

# HTML::FormFu
#
RUN apt-get install libcatalyst-controller-html-formfu-perl -y

# Cairo Perl module needs this:
#
RUN apt-get install libcairo2-dev -y

# GD Perl module needs this:
#
RUN apt-get install libgd2-xpm-dev -y

# postgres driver DBD::Pg needs this:
#
RUN apt-get install libpq-dev -y

# MooseX::Runnable Perl module needs this:
#
RUN apt-get install libmoosex-runnable-perl -y

RUN apt-get install libgdbm3 libgdm-dev -y
RUN apt-get install nodejs -y

WORKDIR /home/production/cxgn/sgn

ENV PERL5LIB=/home/production/cxgn/local-lib/:/home/production/cxgn/local-lib/lib/perl5:/home/production/cxgn/sgn/lib:/home/production/cxgn/cxgn-corelibs/lib:/home/production/cxgn/Phenome/lib:/home/production/cxgn/Cview/lib:/home/production/cxgn/ITAG/lib:/home/production/cxgn/biosource/lib:/home/production/cxgn/tomato_genome/lib



# run the Build.PL to install the R dependencies...
#
ENV HOME=/home/production
RUN echo "R_LIBS_USER=/home/production/cxgn/R_libs" >> /etc/R/Renviron
RUN mkdir -p /home/production/cxgn/sgn/R_libs
ENV R_LIBS_USER=/home/production/cxgn/R_libs
#RUN rm /home/production/cxgn/sgn/static/static
#RUN rm /home/production/cxgn/sgn/static/s
#RUN rm /home/production/cxgn/sgn/documents

RUN apt-get install apt-transport-https -y
RUN bash /home/production/cxgn/sgn/js/install_node.sh

RUN apt-get install screen -y
COPY entrypoint.sh /entrypoint.sh
RUN ln -s /home/production/cxgn/starmachine/bin/starmachine_init.d /etc/init.d/sgn

# start services when running container...
ENTRYPOINT /bin/bash /entrypoint.sh

