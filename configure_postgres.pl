
use strict;

use Config::Any;
use Data::Dumper;

my $HOME = shift || "production";

my $file =  "/home/$HOME/cxgn/sgn/sgn_local.conf";
my $config = Config::Any->load_files( { files => [ $file ] } );

print STDERR Dumper($config);

# extract postgres password
my $db_postgres_password = $config->[0]->{$file}->{DatabaseConnection}->{sgn_test}->{password};

print STDERR "Found password $db_postgres_password\n";

system("su postgres; echo \"CREATE ROLE blabla WITH password \'$db_postgres_password\'\"");

print STDERR "Done.\n";
