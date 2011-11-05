package Cornbat::Access;

use strict;
use Cornbat::Job;
use MIME::Base64;
use Digest::MD5 qw (md5_hex);

sub new { 
   my $class = shift; 
   my $self = {};
   $self->{AuthFile} = shift;
   $self->{AclFile} = shift;
   bless ($self, $class);
   load_auth($self);
   load_acls($self);
   return $self;
}

sub load_auth {
   my $self = shift;
   open(PASS, $self->{AuthFile}) || die "$self->{AuthFile} can't open password file";
   while(<PASS>){
      chomp($_);
      my ($id, $key) = split(":",$_);
      $self->{AuthDB}{$id} = $key;
   }
   close PASS;
}


sub load_acls {
   my $self = shift; 
   open(ACLS, $self->{AclFile}) || die "can't open ACL file";
   while(<ACLS>) {
      chomp($_);
      my ($id, @users) = split(":", $_);
      $self->{Acl}{$id} = \@users;
   }
   close ACLS;
}



sub authenticate_request {
  my $self = shift;
  my $auth_header = shift;
  my ($auth_type, $uname_64 ) = split (" ", $auth_header);
      my $id_key_combo = decode_base64($uname_64);
      my ($id, $key) = split(":", $id_key_combo);
      if ($self->{AuthDB}{$id} eq md5_hex($key)){
         return 1;
      } 
  return 0;
} 

sub check_access {
   my $self = shift; 
   my $id = shift; 
   my $user = shift; 
   my @user_array = @{$self->{Acl}{$id}};
   foreach my $authorized (@user_array) {
      if ($user eq $authorized ){
         return 1;
      }
   }
   return 0;
}



1;
