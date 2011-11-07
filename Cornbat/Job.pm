package Cornbat::Job;

use strict;
use warnings;
use POSIX qw/strftime/;
use Error qw(:try);
use Time::localtime;
use Log::Log4perl qw(:easy);
use Mojo::JSON;

Log::Log4perl->easy_init( $ERROR );

sub new {
   my $class = shift;
   my $self = {};
   $self->{JobName} = shift;
   # Should be array of [ minute, hour, day of month, month, day of week ]  
   $self->{JobSchedule} = shift;
   $self->{RunAs} = shift;
   $self->{BlockOthers} = shift;
   $self->{Command} = shift; 
   $self->{LogFile} = shift;
   $self->{NumberRuns} = 0; 
   bless ($self, $class);
   return $self;

}

sub ran {
   my $self = shift;
   $self->{NumberRuns}++;
}

sub to_js {
   my $self = shift;
   my %hash_rep = %{$self};
   my $json = Mojo::JSON->new;
   my $string = $json->encode(\%hash_rep);
   DEBUG($string);
   return $string;
}

sub from_js {
   my $class = shift;
   my $json_rep = shift; 
   my $json = Mojo::JSON->new;
   my $self = $json->decode($json_rep);
   $self->{NumberRuns}=0;
   bless ($self, $class);
   return $self;
}

sub should_run {
   # method: should run
   # returns 1 to run, 0 for false 
   my $self = shift;
   # ( min, hour, day of month, month, day of week )
   my $date_array = shift;
   my @schedule = @{$self->{JobSchedule}};
   my $sched_length = $#schedule;
   my $field;
   my $execute_command=0;
   
   #my @test_fields =  @{$date_array};
   for(my $i = 0; $i <= $sched_length ; $i++ ) {
      DEBUG("print $#schedule");
      DEBUG("$i");
      my $field = shift @schedule;

      my @intervals;
      #split based on commas, always... if it doesn't split thats fine.
      DEBUG("Splinting into an array based on commas, $field"); 
      @intervals = split("," , $field);
      # try to parse and match


      DEBUG("Current number of intervals in entry $#intervals"); 
      for(my $j=0;$j<=$#intervals;$j++){
         my $interval = shift @intervals; 

         DEBUG("$interval : @{$date_array}[$i]");
         if ($interval eq "\*") {
            DEBUG("Matching on *, $interval");
               $execute_command = 1; 
         } elsif ( $interval =~ /^\*\/[1-6]/ ){
            DEBUG("Matching on */n");
            my ($star, $modula) = split("/",$interval);  

            if(($date_array->[$i] % $modula) == 0) { 
               $execute_command = 1; 
            }

         } elsif ($interval =~ /^[0-9]?-/) {
            DEBUG("Matching on n-m, $interval");
            my ($first, $second) = split("-", $interval);
            DEBUG("F $first : S $second");
            if ($date_array->[$i] >= $first && $date_array->[$i] <= $second){
               $execute_command = 1; 
            }
         } elsif ($interval >= 0 && $interval <= 60) {
            DEBUG("Matching on interger, $interval");
            if ( $interval == $date_array->[$i]) {
               $execute_command = 1; 
            }
         }

      } 
      if ($execute_command == 1 ){
         DEBUG("Matches field ");
         $execute_command = 0;
      }else{
         DEBUG("Executed $i times; Job not scheduled");
         return 0 ; 
      }
         
   }

   INFO("$self->{JobName} should be run");
   # returning 1 for true, this method is intended to be used
   # as a bool
   return 1;

} 

1;
