package Cornbat::Config;

use strict;
use warnings;
use Mojo::JSON;
use File::Path qw{make_path};
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init( { level => $DEBUG, file  => ">>test.log" } );

# Loads JSON config file

sub new {
   my $class = shift; 
   my $config_file = shift; 
   my $json = Mojo::JSON->new();
 
   open(MCONFIG, $config_file);
 
   my $string = do{local( $/ ) ; <MCONFIG>}; 
   #close(MCONFIG);
   print $string;
   my $self = $json->decode($string);
   $self->{ConfigFile} = $config_file;

# Set Sane Defaults 
   if(!$self->{LogLocation}) {
      $self->{LogLocation} = "/var/log/cornbat";
      INFO("Setting Default Log Location $self->{LogLocation}");
      if ( !-e $self->{LogLocation} ) {
         INFO("Creating $self->{LogLocation}");
         make_path($self->{LogLocation});
      }
   }

   if(!$self->{ScheduleLocation}) {
      $self->{ScheduleLocation} = "/etc/cornbat/schedule.conf";
      INFO("setting default schedule location $self->{ScheduleLocation}");
   }

   if(!$self->{AuthFile}) {
      $self->{AuthFile} = "/etc/cornbat/auth.conf";
      INFO("setting Auth File $self->{AuthFile}");
   }

   if(!$self->{ACLFile}) {
      $self->{ACLFile} = "/etc/cornbat/acl.conf";
      INFO("setting Auth File $self->{ACLFile}");
   }

   if(!$self->{Port}) {
      $self->{Port} = 8080;
      INFO("setting Port $self->{Port}");
   }

   bless ($self, $class);
   return $self;
}

1;
