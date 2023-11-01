FROM debian:bullseye

ENV CPANMIRROR=http://cpan.cpantesters.org
# based on the vagrant provision.sh script by Nick Morales <nm529@cornell.edu>

# open port 8080
#
EXPOSE 8080

# create directory layout
#
RUN mkdir -p /home/production/public/sgn_static_content
RUN mkdir -p /home/production/cxgn
RUN mkdir -p /home/production/cxgn/local-lib
RUN mkdir /etc/starmachine
RUN mkdir /var/log/sgn

WORKDIR /home/production/cxgn

# install system dependencies
#
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update -y --allow-unauthenticated
RUN apt-get upgrade -y
RUN apt-get install build-essential pkg-config apt-utils gnupg2 curl wget -y

# for R cran-40
#
RUN bash -c "apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' 1>/key.out 2> /key.err"


# add cran backports repo and required deps
#
RUN echo "deb http://lib.stat.cmu.edu/R/CRAN/bin/linux/debian bullseye-cran40/" >> /etc/apt/sources.list

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc |  apt-key add -

RUN apt-get update --fix-missing -y
#RUN apt-get update -y;

RUN apt-get install -y aptitude

RUN aptitude install -y npm libterm-readline-zoid-perl nginx starman emacs gedit vim less sudo htop git dkms linux-headers-generic perl-doc ack make xutils-dev nfs-common lynx xvfb ncbi-blast+ primer3 libmunge-dev libmunge2 munge slurm-wlm slurmctld slurmd libslurm-perl libssl-dev graphviz lsof imagemagick mrbayes muscle bowtie bowtie2 postfix mailutils libcupsimage2 postgresql-client-12 libglib2.0-dev libglib2.0-bin screen apt-transport-https libgdal-dev libproj-dev libudunits2-dev locales locales-all rsyslog cron libnlopt0 plink

# Set the locale correclty to UTF-8
RUN locale-gen en_US.UTF-8
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

RUN curl -L https://cpanmin.us | perl - --sudo App::cpanminus

RUN rm /etc/munge/munge.key

RUN chmod 777 /var/spool/ \
    && mkdir /var/spool/slurmstate \
    && chown slurm:slurm /var/spool/slurmstate/ \
    && /usr/sbin/mungekey \
    && ln -s /var/lib/slurm-llnl /var/lib/slurm \
    && mkdir -p /var/log/slurm

RUN apt-get install r-base r-base-dev -y --allow-unauthenticated

# required for R-package spdep, and other dependencies of agricolae
#
RUN apt-get install libudunits2-dev libproj-dev libgdal-dev -y

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
RUN apt-get install libgd-dev -y

# postgres driver DBD::Pg needs this:
#
RUN apt-get install libpq-dev -y

# MooseX::Runnable Perl module needs this:
#
RUN apt-get install libmoosex-runnable-perl -y

RUN apt-get install libgdbm6 libgdm-dev -y
RUN apt-get install nodejs -y

RUN cpanm Selenium::Remote::Driver@1.44

#INSTALL OPENCV IMAGING LIBRARY

RUN apt-get install -y python3-dev  python3-pip python3-numpy libgtk2.0-dev libgtk-3-0 libgtk-3-dev libavcodec-dev libavformat-dev libswscale-dev libhdf5-serial-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libxvidcore-dev libatlas-base-dev gfortran libgdal-dev exiftool libzbar-dev cmake

RUN pip3 install --upgrade pip
RUN pip3 install grpcio==1.40.0 imutils numpy matplotlib pillow statistics PyExifTool pytz pysolar scikit-image packaging pyzbar pandas opencv-python \
    && pip3 install -U keras-tuner

# copy some tools that don't have a Debian package
#
COPY tools/gcta/gcta64  /usr/local/bin/
COPY tools/quicktree /usr/local/bin/
COPY tools/sreformat /usr/local/bin/



# copy code repos.
# This also adds the Mason website skins
#
ADD cxgn /home/production/cxgn

# move this here so it is not clobbered by the cxgn move
#
COPY slurm.conf /etc/slurm/slurm.conf
COPY starmachine.conf /etc/starmachine/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY sgn_local.conf /home/production/cxgn/sgn/sgn_local.conf

# compile the simsearch and contigalign tools
#
RUN cd /home/production/cxgn/gtsimsrch/src; make; cd -;
RUN cd /home/production/cxgn/sgn/programs/; make; cd -;
 
# npm install needs a non-root user (new in latest version)
#
RUN adduser --disabled-password --gecos "" -u 1250 production && chown -R production /home/production

WORKDIR /home/production/cxgn/sgn

ENV PERL5LIB=/home/production/cxgn/Bio-Chado-Schema/lib:/home/production/cxgn/local-lib/:/home/production/cxgn/local-lib/lib/perl5:/home/production/cxgn/sgn/lib:/home/production/cxgn/cxgn-corelibs/lib:/home/production/cxgn/Phenome/lib:/home/production/cxgn/Cview/lib:/home/production/cxgn/ITAG/lib:/home/production/cxgn/biosource/lib:/home/production/cxgn/tomato_genome/lib:/home/production/cxgn/chado_tools/chado/lib:.

ENV HOME=/home/production
ENV PGPASSFILE=/home/production/.pgpass
RUN echo "R_LIBS_USER=/home/production/cxgn/R_libs" >> /etc/R/Renviron
ENV R_LIBS_USER=/home/production/cxgn/R_libs

RUN ln -s /home/production/cxgn/starmachine/bin/starmachine_init.d /etc/init.d/sgn

ARG CREATED
ARG REVISION
ARG BUILD_VERSION

LABEL maintainer="lam87@cornell.edu"
LABEL org.opencontainers.image.created=$CREATED
LABEL org.opencontainers.image.url="https://breedbase.org/"
LABEL org.opencontainers.image.source="https://github.com/solgenomics/breedbase_dockerfile"
LABEL org.opencontainers.image.version=$BUILD_VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.vendor="Boyce Thompson Institute"
LABEL org.opencontainers.image.title="breedbase/breedbase"
LABEL org.opencontainers.image.description="Breedbase web server"
LABEL org.opencontainers.image.documentation="https://solgenomics.github.io/sgn/"

# start services when running container...
#
ENTRYPOINT ["/entrypoint.sh"]
