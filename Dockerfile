FROM debian:stretch

LABEL maintainer="lam87@cornell.edu"

ENV CPANMIRROR=http://cpan.cpantesters.org
# based on the vagrant provision.sh script by Nick Morales <nm529@cornell.edu>

# open port 8080
#
EXPOSE 8080

# create directory layout
#
RUN mkdir -p /home/production/public
RUN mkdir /home/production/public/sgn_static_content
RUN mkdir /home/production/tmp
RUN mkdir /home/production/tmp/solgs
RUN mkdir -p /home/production/archive
RUN mkdir -p /home/production/public/images/image_files
RUN mkdir -p /home/production/tmp
RUN mkdir -p /home/production/archive/breedbase
RUN mkdir -p /home/production/blast/databases/current
RUN mkdir /etc/starmachine
RUN mkdir /var/log/sgn
RUN mkdir -p  /home/production/cxgn

# add cran backports repo and required deps
#
RUN echo "deb http://lib.stat.cmu.edu/R/CRAN/bin/linux/debian stretch-cran35/" >> /etc/apt/sources.list

# install system dependencies
#
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update -y --allow-unauthenticated 
RUN apt-get upgrade -y
RUN apt-get install build-essential pkg-config apt-utils gnupg2 curl -y

# key for cran-backports (not working though)
#
RUN bash -c "apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' 2> /key.out"

RUN apt-get update -y

RUN apt-get install -y libterm-readline-zoid-perl
RUN apt-get install nginx starman emacs gedit vim less sudo htop git dkms linux-headers-4.9.0-9-amd64 perl-doc ack-grep make xutils-dev nfs-common lynx xvfb ncbi-blast+  -y
RUN curl -L https://cpanmin.us | perl - --sudo App::cpanminus

RUN apt-get install libmunge-dev libmunge2 munge -y
RUN apt-get install slurm-wlm slurmctld slurmd libslurm-perl -y
RUN apt-get install libssl-dev -y

#Copy slurm.conf from shared config folder to where it needs to go
COPY slurm.conf /etc/slurm-llnl/slurm.conf

RUN chmod 777 /var/spool/
RUN mkdir /var/spool/slurmstate
RUN chown slurm:slurm /var/spool/slurmstate/
RUN /usr/sbin/create-munge-key
RUN ln -s /var/lib/slurm-llnl /var/lib/slurm
RUN apt-get install graphviz lsof imagemagick -y
#RUN apt-get install gnome-core gnome-terminal -y
RUN apt-get install r-base r-base-dev libopenblas-base -y --allow-unauthenticated

# required for R-package spdep, and other dependencies of agricolae
RUN apt-get install libudunits2-dev libgdal-dev -y

#RUN apt-get install gnome-shell gnome-screensaver gnome-tweak-tool gnome-shell-extensions -y
#RUN sed -i s/allowed_users=console/allowed_users=anybody/ /etc/X11/Xwrapper.config
#RUN sed -i s/\#\ \ AutomaticLoginEnable\ =\ true/AutomaticLoginEnable\ =\ true/ /etc/gdm3/daemon.conf
#RUN sed -i s/\#\ \ AutomaticLogin\ =\ user1/AutomaticLogin\ =\ production/ /etc/gdm3/daemon.conf

RUN mkdir -p /home/production/cxgn
RUN mkdir -p /home/production/cxgn/local-lib
WORKDIR /home/production/cxgn	
RUN bash -c "git clone --quiet https://github.com/solgenomics/cxgn-corelibs.git /home/production/cxgn/cxgn-corelibs"
RUN bash -c "git clone --quiet https://github.com/solgenomics/sgn.git /home/production/cxgn/sgn"
RUN bash -c "git clone --quiet https://github.com/solgenomics/Phenome.git /home/production/cxgn/Phenome"
RUN bash -c "git clone --quiet https://github.com/solgenomics/rPackages.git /home/production/cxgn/rPackages"
RUN bash -c "git clone --quiet https://github.com/solgenomics/biosource.git /home/production/cxgn/biosource"
RUN bash -c "git clone --quiet https://github.com/solgenomics/Cview.git /home/production/cxgn/Cview"
RUN bash -c "git clone --quiet https://github.com/solgenomics/ITAG.git /home/production/cxgn/ITAG"
RUN bash -c "git clone --quiet https://github.com/solgenomics/tomato_genome.git /home/production/cxgn/tomato_genome"
RUN bash -c "git clone --quiet https://github.com/GMOD/Chado.git /home/production/cxgn/Chado"
RUN bash -c "git clone --quiet https://github.com/solgenomics/sgn-devtools.git /home/production/cxgn/sgn-devtools"
RUN bash -c "git clone --quiet https://github.com/solgenomics/solGS.git /home/production/cxgn/solGS"
RUN bash -c "git clone --quiet https://github.com/solgenomics/Barcode-Code128.git /home/production/cxgn/Barcode-Code128"
RUN bash -c "git clone --quiet https://github.com/solgenomics/starmachine.git /home/production/cxgn/starmachine"

# Mason website skins
RUN bash -c "git clone --quiet https://github.com/solgenomics/cassava.git /home/production/cxgn/cassava"
RUN bash -c "git clone --quiet https://github.com/solgenomics/yambase.git /home/production/cxgn/yambase"
RUN bash -c "git clone --quiet https://github.com/solgenomics/sweetpotatobase.git /home/production/cxgn/sweetpotatobase"
RUN bash -c "git clone --quiet https://github.com/solgenomics/ricebase.git /home/production/cxgn/ricebase"
RUN bash -c "git clone --quiet https://github.com/solgenomics/citrusgreening.git /home/production/cxgn/citrusgreening"
RUN bash -c "git clone --quiet https://github.com/solgenomics/coconut.git /home/production/cxgn/coconut"
RUN bash -c "git clone --quiet https://github.com/solgenomics/cassbase.git /home/production/cxgn/cassbase"
RUN bash -c "git clone --quiet https://github.com/solgenomics/musabase.git /home/production/cxgn/musabase"
RUN bash -c "git clone --quiet https://github.com/solgenomics/potatobase.git /home/production/cxgn/potatobase"
RUN bash -c "git clone --quiet https://github.com/solgenomics/cea.git /home/production/cxgn/cea"

COPY sgn_local.conf.template /home/production/cxgn/sgn
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

# ENV PERL5LIB=/home/production/cxgn/local-lib/:/home/production/cxgn/local-lib/lib/perl5:/home/production/cxgn/sgn/lib:/home/production/cxgn/cxgn-corelibs/lib:/home/production/cxgn/Phenome/lib:/home/production/cxgn/Cview/lib:/home/production/cxgn/ITAG/lib:/home/production/cxgn/biosource/lib:/home/production/cxgn/tomato_genome/lib

# # load prerequisites for building packages using Build.PL
# #
# RUN cpanm -L /home/production/cxgn/local-lib --mirror $CPANMIRROR Parse::Deb::Control Module::Build Class::MethodMaker Data::UUID HTML::Lint Module::Build::Tiny Test::JSON  Test::Most  Test::WWW::Mechanize  Test::WWW::Mechanize::Catalyst  Test::WWW::Selenium DBIx::Connector local::lib ExtUtils::PkgConfig

# # data structure basics
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR IO::Event --force
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Hash::Merge  Tie::UrlEncoder Data::BitMask enum  Class::MethodMaker  Modern::Perl   Config::JFDI Config::INI::Reader Array::Utils JSON::Any JSON::XS URI::FromHash URI::Encode JSAN::ServerSide  String::Random String::CRC String::Approx Tie::Function Digest::Crc32  Math::Base36   Array::Compare Number::Bytes::Human List::Compare List::AllUtils Data::UUID  XML::Twig XML::Generator XML::Feed

# # file system
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR --force File::Find::Rule
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Cache::File File::Flock File::NFSLock
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Lucy::Simple

# # Moose etc.
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Moose MooseX::FollowPBP MooseX::Object::Pluggable MooseX::Types::URI MooseX::Runnable@0.09 MooseX::Declare MooseX::Singleton
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR --force MooseX::Daemonize

# # graphics libraries (older)
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR GD GD::Graph::lines GD::Graph::Map GD::Barcode::QRcode Graph Chart::Clicker SVG Cairo Imager::QRCode Barcode::Code128

# # bioperl
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Bio::Restriction::Analysis Bio::PrimarySeq Bio::BLAST::Database  Bio::GFF3::LowLevel Bio::GMOD::GenericGenePage Bio::SeqFeature::Annotated Catalyst::ScriptRunner Bio::GMOD::Blast::Graph
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR --force Starman Bio::Graphics::FeatureFile 

# # generic web
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR WWW::Mechanize::TreeBuilder HTML::Mason::Interp HTML::TreeBuilder::XPath  LWP::UserAgent
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR/ URI::SmartURI HTML::Lint Mail::Sendmail --force

# # database
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR DBI DBIx::Class::Schema Bio::Chado::Schema DBIx::Class::Schema::Loader DBD::Pg

# # Catalyst
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Catalyst Catalyst::Helper Catalyst::Restarter Captcha::reCAPTCHA  Catalyst::Plugin::SmartURI Catalyst::Plugin::Authorization::Roles Catalyst::View::Email Catalyst::View::HTML::Mason  Catalyst::View::Bio::SeqIO Catalyst::View::JavaScript::Minifier::XS@2.101001  Catalyst::View::Download::CSV Class::DBI Catalyst::DispatchType::Regex

# RUN cpanm -L ../local-lib --mirror $CPANMIRROR CatalystX::GlobalContext Catalyst::Plugin::Assets --force

# # math
# #
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Math::Round Math::Round::Var Statistics::Descriptive Algorithm::Combinatorics Statistics::R
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR --force R::YapRI::Base
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Test::Aggregate::Nested --force
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR IPC::Run3 SOAP::Transport::HTTP 
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Spreadsheet::WriteExcel Spreadsheet::ParseExcel Spreadsheet::Read PDF::Create  PDF::API2 CAM::PDF Archive::Zip
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR  --force
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR AnyEvent --force
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR DateTime::Format::Flexible DateTime::Format::Pg
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Lingua::EN::Inflect
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Test::Class Test::JSON Test::MockObject Test::WWW::Selenium
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Sort::Versions Sort::Maker
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Term::ReadKey --force
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Term::Size::Any Proc::ProcessTable
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Text::CSV
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Set::Product
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Server::Starter
# RUN cpanm -L ../local-lib --mirror $CPANMIRROR Net::Server::SS::PreFork --force

RUN bash -c "git clone --quiet https://github.com/solgenomics/perl-local-lib /home/production/cxgn/local-lib"

RUN bash -c "git clone --quiet https://github.com/solgenomics/R_libs /home/production/cxgn/R_libs"

# run the Build.PL to install the R dependencies...
#
ENV HOME=/home/production
RUN echo "R_LIBS_USER=/home/production/cxgn/R_libs" >> /etc/R/Renviron
RUN mkdir -p /home/production/cxgn/sgn/R_libs
ENV R_LIBS_USER=/home/production/cxgn/R_libs
RUN rm /home/production/cxgn/sgn/static/static
RUN rm /home/production/cxgn/sgn/static/s
RUN rm /home/production/cxgn/sgn/documents
#RUN perl /home/production/cxgn/sgn/Build.PL
#RUN perl /home/production/cxgn/sgn/Build manifest
#RUN perl /home/production/cxgn/sgn/Build installdeps

RUN apt-get install apt-transport-https -y
RUN bash /home/production/cxgn/sgn/js/install_node.sh
RUN sed -i s/localhost/$HOSTNAME/g /etc/slurm-llnl/slurm.conf
RUN apt-get install screen -y
COPY entrypoint.sh /entrypoint.sh

# start services when running container...
ENTRYPOINT bash /entrypoint.sh

