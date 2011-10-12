use Cornbat::Job;
use strict;

#@test = (1, 1, 1, 1, 1);

#$job = Cornbat::Job->new("test job", \@test, "root", 0, "/etc/foo");
#print "yo\n";
#$job->should_run(\@test);

#print "begining modula test\n";
#@test = ("*/10", 0, 0, 0, 0);
#@test2 = ("10", 0, 0, 0, 0);
#
#$job = Cornbat::Job->new("test job", \@test, "root", 0, "/etc/foo");
#print "yo\n";
#$job->should_run(\@test2);
#
#print "begining interval test\n";
#@test = ("0-11", 1, 0, 0, 0);
my@test2 = ("11", 1, 0, 0, 0);
#
#$job = Cornbat::Job->new("test job", \@test, "root", 0, "/etc/foo");
#
#$foo=$job->to_js();
#
#print "$foo\n";
my $joab = Cornbat::Job->from_js('{"RunAs":"root","BlockOthers":0,"Command":"\/etc\/foo","NumberRuns":null,"JobSchedule":["*/1","*","*","*","*"],"LogFile":null,"JobName":"test job"}');

$joab->should_run(\@test2);
