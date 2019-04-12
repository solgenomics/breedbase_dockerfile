FROM debian:stretch

ARG hostname

LABEL maintainer="lam87@cornell.edu"

# open port 80
EXPOSE 80

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install build-essential -y
RUN apt-get install pkg-config -y
RUN apt-get install -y apt-utils
RUN apt-get install -y libterm-readline-zoid-perl
RUN apt-get install nginx -y
RUN apt-get install starman -y
RUN apt-get install emacs gedit vim less -y
RUN apt-get install sudo -y
RUN apt-get install htop -y
RUN apt-get install git -y
RUN apt-get install dkms linux-headers-$(uname -r) -y
RUN apt-get install perl-doc -y
RUN apt-get install memtester -y
RUN apt-get install ack-grep -y
RUN apt-get install make xutils-dev -y
RUN apt-get install nfs-common -y
RUN apt-get install curl -y
RUN curl -L https://cpanmin.us | perl - --sudo App::cpanminus
RUN apt-get install lynx -y
RUN apt-get install nginx -y
RUN apt-get install -y nmap
RUN apt-get install -y xvfb
RUN apt-get install ncbi-blast+ -y
RUN apt-get install libmunge-dev libmunge2 munge -y
RUN apt-get install slurm-wlm slurmctld slurmd -y
RUN apt-get install libslurm-perl -y
#Copy slurm.conf from shared config folder to where it needs to go
RUN touch /etc/slurm-llnl/slurm.conf
#RUN cat /vagrant/config/slurm.conf >> /etc/slurm-llnl/slurm.conf
#sudo sh -c "cp /vagrant/config/slurm.conf /etc/slurm-lnll/ "

RUN chmod 777 /var/spool/
RUN mkdir /var/spool/slurmstate
RUN chown slurm:slurm /var/spool/slurmstate/
RUN /usr/sbin/create-munge-key
RUN ln -s /var/lib/slurm-llnl /var/lib/slurm
RUN apt-get install graphviz -y
RUN apt-get install lsof -y
RUN apt-get install imagemagick -y
RUN apt-get install gnome-core -y
RUN apt-get install gnome-terminal -y
RUN apt-get install -y gnome-shell gnome-screensaver gnome-tweak-tool gnome-shell-extensions
RUN sed -i s/allowed_users=console/allowed_users=anybody/ /etc/X11/Xwrapper.config
RUN sed -i s/\#\ \ AutomaticLoginEnable\ =\ true/AutomaticLoginEnable\ =\ true/ /etc/gdm3/daemon.conf
RUN sed -i s/\#\ \ AutomaticLogin\ =\ user1/AutomaticLogin\ =\ production/ /etc/gdm3/daemon.conf
RUN /etc/init.d/gdm3 start

RUN mkdir -p /home/production/cxgn
RUN mkdir -p /home/production/cxgn/local-lib
RUN cd /home/production/cxgn
RUN bash -c "git clone --quiet https://github.com/solgenomics/cxgn-corelibs.git /home/production/cxgn/cxgn-corelibs"
RUN bash -c "git clone --quiet https://github.com/solgenomics/sgn.git /home/production/cxgn/sgn"
RUN bash -c "git clone --quiet https://github.com/solgenomics/Phenome.git /home/production/cxgn/Phenome"
RUN bash -c "git clone --quiet https://github.com/solgenomics/biosource.git /home/production/cxgn/biosource"
RUN bash -c "git clone --quiet https://github.com/solgenomics/Cview.git /home/production/cxgn/Cview"
RUN bash -c "git clone --quiet https://github.com/solgenomics/ITAG.git /home/production/cxgn/ITAG"
RUN bash -c "git clone --quiet https://github.com/solgenomics/tomato_genome.git /home/production/cxgn/tomato_genome"
RUN bash -c "git clone --quiet https://github.com/GMOD/Chado.git /home/production/cxgn/Chado"
RUN bash -c "git clone --quiet https://github.com/solgenomics/sgn-devtools.git /home/production/cxgn/sgn-devtools"
RUN bash -c "git clone --quiet https://github.com/solgenomics/solGS.git /home/production/cxcgn/solGS"
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

# This would be the preferred way to install Perl and R dependencies but I can't get it to work...
# perl Build manifest
# sudo perl Build.pl

# XML::Simple dependency
RUN apt-get install libexpat1-dev -y

# HTML::FormFu
RUN apt-get install libcatalyst-controller-html-formfu-perl -y

RUN cd /home/production/cxgn/sgn

# Install Perl Modules

ENV PERL5LIB=/home/production/cxgn/local-lib/lib/perl5

RUN cpanm -L ../local-lib/ GD
RUN cpanm -L ../local-lib/ build
RUN cpanm -L ../local-lib ExtUtils::PkgConfig
RUN cpanm -L ../local-lib/ Bio::Restriction::Analysis
RUN cpanm --force -L ../local-lib/ Starman
RUN cpanm -L ../local-lib/ install Catalyst::ScriptRunner
RUN cpanm -L ../local-lib/ local::lib
RUN cpanm -L ../local-lib/ Catalyst::Restarter
RUN cpanm -L ../local-lib/ HTML::Mason::Interp
RUN cpanm -L ../local-lib/ Selenium::Remote::Driver
RUN cpanm -L ../local-lib/ DBI
RUN cpanm -L ../local-lib/ Hash::Merge
RUN cpanm -L ../local-lib/ DBIx::Connector
RUN cpanm -L ../local-lib/ Catalyst::Plugin::Authorization::Roles
RUN cpanm -L ../local-lib/ Bio::PrimarySeq
RUN cpanm -L ../local-lib/ Class::DBI
RUN cpanm -L ../local-lib/ Tie::UrlEncoder
RUN cpanm -L ../local-lib/ Data::BitMask
RUN cpanm -L ../local-lib/ enum
RUN cpanm -L ../local-lib/ File::NFSLock
RUN cpanm -L ../local-lib/ Class::MethodMaker
RUN cpanm -L ../local-lib/ Bio::BLAST::Database
RUN cpanm -L ../local-lib/ Catalyst::Plugin::SmartURI
RUN cpanm -L ../local-lib/ Modern::Perl
RUN cpanm -L ../local-lib/ List::Compare
RUN cpanm -L ../local-lib/ Cache::File
RUN cpanm -L ../local-lib/ Config::JFDI
RUN cpanm -L ../local-lib/ CatalystX::GlobalContext --force
RUN cpanm -L ../local-lib/ DBIx::Class::Schema
RUN cpanm -L ../local-lib/ Bio::Chado::Schema
RUN cpanm -L ../local-lib/ Array::Utils
RUN cpanm -L ../local-lib/ JSON::Any
RUN cpanm -L ../local-lib/ Math::Round
RUN cpanm -L ../local-lib/ Math::Round::Var
RUN cpanm -L ../local-lib/ Catalyst::View::Email
RUN cpanm -L ../local-lib/ Catalyst::View::HTML::Mason
RUN cpanm -L ../local-lib/ Catalyst::View::Bio::SeqIO
RUN cpanm -L ../local-lib/ Catalyst::View::JavaScript::Minifier::XS@2.101001
RUN cpanm -L ../local-lib/ Catalyst::View::Download::CSV
RUN cpanm -L ../local-lib/ URI::FromHash
RUN cpanm -L ../local-lib/ JSAN::ServerSide
RUN cpanm -L ../local-lib/ Config::INI::Reader
RUN cpanm -L ../local-lib/ Bio::GFF3::LowLevel
RUN cpanm -L ../local-lib/ Statistics::Descriptive
RUN cpanm -L ../local-lib/ String::Random
RUN cpanm -L ../local-lib/ MooseX::FollowPBP
RUN apt-get install libgd2-xpm-dev -y
RUN cpanm -L ../local-lib/ Tie::Function
RUN cpanm -L ../local-lib/ Digest::Crc32
RUN cpanm -L ../local-lib/ Barcode::Code128
RUN cpanm -L ../local-lib/ Math::Base36
RUN cpanm -L ../local-lib/ Captcha::reCAPTCHA
RUN cpanm -L ../local-lib/ Test::Aggregate::Nested --force
RUN cpanm -L ../local-lib/ SVG
RUN cpanm -L ../local-lib/ IPC::Run3
RUN cpanm -L ../local-lib/ Spreadsheet::WriteExcel
RUN cpanm -L ../local-lib/ MooseX::Object::Pluggable
RUN cpanm -L ../local-lib/ R::YapRI::Base
RUN cpanm -L ../local-lib/ PDF::Create
RUN cpanm -L ../local-lib/ String::CRC
RUN cpanm -L ../local-lib/ Algorithm::Combinatorics
RUN cpanm -L ../local-lib/ String::Approx
RUN apt-get install libcairo2-dev -y
RUN cpanm -L ../local-lib/ Cairo
RUN cpanm -L ../local-lib/ Chart::Clicker
RUN cpanm -L ../local-lib/ Spreadsheet::ParseExcel
RUN cpanm -L ../local-lib/ MooseX::Types::URI
RUN cpanm -L ../local-lib/ Bio::Graphics::FeatureFile --force
RUN cpanm -L ../local-lib/ Mail::Sendmail --force
RUN cpanm -L ../local-lib/ Array::Compare
RUN cpanm -L ../local-lib/ GD::Graph::lines
RUN cpanm -L ../local-lib/ GD::Graph::Map
RUN cpanm -L ../local-lib/ Bio::GMOD::GenericGenePage
RUN cpanm -L ../local-lib/ Number::Bytes::Human
RUN cpanm -L ../local-lib/ AnyEvent --force
RUN cpanm -L ../local-lib/ IO::Event --force
RUN cpanm -L ../local-lib/ File::Flock
RUN cpanm -L ../local-lib/ Graph
RUN cpanm -L ../local-lib/ Bio::SeqFeature::Annotated
RUN cpanm -L ../local-lib/ XML::Twig
RUN cpanm -L ../local-lib/ XML::Generator
RUN apt-get install libpq-dev -y
RUN cpanm -L ../local-lib/ DBD::Pg
RUN apt-get install libmoosex-runnable-perl -y
RUN cpanm -L ../local-lib/ MooseX::Runnable@0.09
RUN cpanm -L ../local-lib/ XML::Feed
RUN cpanm -L ../local-lib/ Parse::Deb::Control
RUN cpanm -L ../local-lib/ Bio::GMOD::Blast::Graph
RUN cpanm -L ../local-lib/ Catalyst::DispatchType::Regex
RUN cpanm -L ../local-lib/ DateTime::Format::Flexible
RUN cpanm -L ../local-lib/ DateTime::Format::Pg
RUN cpanm -L ../local-lib/ HTML::TreeBuilder::XPath
RUN cpanm -L ../local-lib/ JSON::XS
RUN cpanm -L ../local-lib/ Lingua::EN::Inflect
RUN cpanm -L ../local-lib/ List::AllUtils
RUN cpanm -L ../local-lib/ MooseX::Declare
RUN cpanm -L ../local-lib/ MooseX::Singleton
RUN cpanm -L ../local-lib/ SOAP::Transport::HTTP
RUN cpanm -L ../local-lib/ Test::Class
RUN cpanm -L ../local-lib/ WWW::Mechanize::TreeBuilder
RUN cpanm -L ../local-lib/ Data::UUID
RUN cpanm -L ../local-lib/ HTML::Lint --force
RUN cpanm -L ../local-lib/ Test::JSON
RUN cpanm -L ../local-lib/ Test::MockObject
RUN cpanm -L ../local-lib/ Test::WWW::Selenium
RUN cpanm -L ../local-lib/ Sort::Versions
RUN cpanm -L ../local-lib/ Term::ReadKey --force
RUN cpanm -L ../local-lib/ Spreadsheet::Read
RUN cpanm -L ../local-lib/ Sort::Maker
RUN cpanm -L ../local-lib/ Term::Size::Any
RUN cpanm -L ../local-lib/ Proc::ProcessTable
RUN cpanm -L ../local-lib/ URI::Encode
RUN cpanm -L ../local-lib/ Archive::Zip
RUN cpanm -L ../local-lib/ Statistics::R
RUN cpanm -L ../local-lib/ Lucy::Simple
RUN cpanm -L ../local-lib/ DBIx::Class::Schema::Loader
RUN cpanm -L ../local-lib/ Text::CSV
RUN cpanm -L ../local-lib/ Imager::QRCode
RUN cpanm -L ../local-lib/ GD::Barcode::QRcode
RUN cpanm -L ../local-lib/ LWP::UserAgent
RUN cpanm -L ../local-lib/ Set::Product
RUN cpanm -L ../local-lib/ Server::Starter
RUN cpanm -L ../local-lib/ Net::Server::SS::PreFork --force
RUN cpanm -L ../local-lib/ Catalyst::Plugin::Assets --force
RUN cpanm -L ../local-lib/ PDF::API2
RUN cpanm -L ../local-lib/ CAM::PDF
RUN mkdir /export
RUN mkdir /export/prod
RUN mkdir /export/prod/public
RUN mkdir /export/prod/public/sgn_static_content
RUN mkdir /export/prod/tmp
RUN mkdir /export/prod/tmp/solgs
RUN mkdir /data
RUN mkdir /data/prod
RUN mkdir /data/prod/archive
RUN mkdir /export/prod/public/images
RUN mkdir /export/prod/public/images/image_files
RUN mkdir /data/shared
RUN mkdir /data/shared/tmp
RUN mkdir /etc/starmachine
RUN mkdir /var/log/sgn

# start all services
RUN systemctl enable slurmctld.service
RUN systemctl start slurmctld.service
RUN systemctl enable slurmd.service
RUN systemctl start slurmd.service
RUN systemctl enable munge.service
RUN systemctl restart munge.service
CMD systemctl start sgn
