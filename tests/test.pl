use threads;
use Thread::Queue;
use threads::shared;
use Cornbat::Job;
use strict;
my $newJobs = Thread::Queue->new;
my $pass :shared;

#@test = (1, 1, 1, 1, 1);

#$job = Cornbat::Job->new("test job", \@test, "root", 0, "/etc/foo");
#print "yo\n";
#$job->should_run(\@test);
#@test = ("*/10", 0, 0, 0, 0);
#@test2 = ("10", 0, 0, 0, 0);
#
#$job = Cornbat::Job->new("test job", \@test, "root", 0, "/etc/foo");
#print "yo\n";
#
#print "begining interval test\n";
my @test = ("0-11", 1, 0, 0, 0);
my @test2 = ("11", 1, 0, 0, 0);
#
my $job = Cornbat::Job->new("test job", \@test, "root", 0, "/etc/foo");
$job->should_run(\@test2);
#
#$foo=$job->to_js();
#
#print "$foo\n";

#my $th1 = threads->new(\&foo);
#$th1->join();
#my $th2 = threads->new(\&foo2);
#$th2->join();
#
#sub foo{
#   my $joab = Cornbat::Job->from_js('{"RunAs":"root","BlockOthers":0,"Command":"\/etc\/foo","NumberRuns":null,"JobSchedule":["*/1","*","*","*","*"],"LogFile":null,"JobName":"test job"}');
#   $pass = shared_clone($joab);
#   $newJobs->enqueue($pass); 
#   return 0;
#}
