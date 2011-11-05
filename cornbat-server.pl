use threads;
use Thread::Queue;
use threads::shared;
use Cornbat::Job;
use Cornbat::Access;
use POSIX ":sys_wait_h"; 

my $newJobs = Thread::Queue->new;
my $runJobs = Thread::Queue->new;
my $ranJobs = Thread::Queue->new;
my %running_jobs : shared = {};
my %jobs_schedule : shared ;
my %jobs;
my %pids;
my $PASSFILE = 'tests/passfile';
my $ACLFILE = 'tests/aclfile';

my $auth = Cornbat::Access->new($PASSFILE, $ACLFILE);

sub REAPER {
   my $child;
   while (($child = waitpid(-1, WNOHANG)) > 0) {
       my $job_name = $pid{$child};
       delete($running_jobs{$job_name});
       $Kid_Status{$child} = $?;
   }
   $SIG{CHLD} = \&REAPER;
}

$SIG{CHLD} = \&REAPER;


read_schedule();

my $webserver = threads->new(\&web, "daemon");
#$cron = threads->new(\&cron_sleep);

while(1){
  #sleep to top of minute;
  cron_sleep();
  #sleep 60;
  #check if any jobs were added
  while($newJobs->pending) {
     my $job_str = $newJobs->dequeue;
     my $job = Cornbat::Job->from_js($job_str);  
     #add jobs to queue
     $jobs{$job->{JobName}}= $job;
     $jobs_schedule{$job->{JobName}} = $job->to_js();
     print $jobs_schedule{$job->{JobName}};
     write_schedule();
  }

  # run jobs
  my @date_array= localtime(time);
  my @current_time = ($date_array[1], $date_array[2], $date_array[3], $date_array[4], $date_array[6]);
  print @current_time;
  print keys %jobs;
  foreach my $key (keys %jobs){ 
     # should this job be run?
      
     if($jobs{$key}->should_run(\@current_time)){
        # check if I'm running 
        if ($running_jobs{$key} && ($jobs{$key}->{BlockOthers} eq 1) ) { 
           print "${jobs{$key}->Name} is running, and blocks new jobs\n";
        } else { 
           my $pid = fork();
           die "Forking Issue" unless defined $pid;
           $running_jobs{$key} = time();
           if ($pid eq 0) {

              # drop to non-root user if needed
              if ($jobs{$key}->{RunAs} != "root") {
                  my $uid = getpwnam($jobs{$key}->{RunAs});
                  my $gid = getgrnam($jobs{$key}->{RunAs});
                  ($),$() = ($gid, $gid);
                  ($<,$>) = ($uid, $uid);
              }
              

              $exit_status = system($jobs{$key}->{Command});
              exit $exit_status; 
              
           }
           # increment counter & update json object
           $jobs{$key}->ran();
           $pids{$pid} = $key;
           print "\n\n" . $jobs{$key}->{NumberRuns} . "\n";
           $jobs_schedule{$key} = $jobs{$key}->to_js();
        }
     }
   }
}

$webserver->detach;

sub cron_sleep{
  # roughly equivlent to how cron sleeps on unix, wake up
  # once per min, and check for jobs that need running.
  my $sleep_for = 60 - (time % 60);
  print "Sleeping for $sleep_for\n";
  sleep($sleep_for); 
}

sub job_schedule_json{
  #my $json_rep = shift; 
  #my $json = Mojo::JSON->new;
  #my $string = $json->encode(\%jobs_schedule);
  #my $string = $json->encode(\%{$jobs});
  my $string;
  foreach my $key (keys %jobs_schedule) {
     if( $string){ 
        $string = $string . "," . "\"". $key . "\":" .$jobs_schedule{$key};    
     } else {
        $string = "\"" . $key . "\":" . $jobs_schedule{$key};
     }
  print "$string\n";
  }
  $string = "{ " . $string . "}";
  print $string;
  return $string;
}

sub job_schedule_from_json{
  my ($string) = shift;
  my $json = Mojo::JSON->new;
  my $json_array;
  $json_array = $json->decode($string);
  foreach my $key ( keys %{$json_array}){
      print "\n$key ==  $$json_array{$key}{JobName} \n";
      my $job = bless($$json_array{$key}, Cornbat::Job);
      $job->{NumberRuns}=0;
      #Cornbat::Job->from_js($json_array{$key});
      print "\n $job->{JobName} \n";
      $jobs_schedule{$key} = $job->to_js();
      $jobs{$job->{JobName}} = $job;
      print $jobs_schedule{$key};
   }
}

sub write_schedule{
  my $config = job_schedule_json();   
  open(CONFIG, ">cornbat_schedule.conf"); 
  print CONFIG $config;
  close CONFIG;
  return 0;
}

sub read_schedule {
  local $/=undef;
  if ( -e "cornbat_schedule.conf"){
     open (CONFIG, "cornbat_schedule.conf") or die "Couldn't open file: $!";
     my $string = <CONFIG>;
     close FILE;
     job_schedule_from_json($string);
  }
}


# sub to do HTTP Basic Auth

sub authorize{
  my $request = shift; 
  if ($request->req->headers->header('Authorization')) {
    my $auth_header = $request->req->headers->header('Authorization');
    return $auth->authenticate_request($auth_header);
  } else {
    return 0 ;
  }

}
sub web {

  use Mojolicious::Lite;
  use Mojo::JSON;
  use Cornbat::Job;
  use MIME::Base64;

  
  post 'job' => sub{
     my $self = shift;
     if (authorize($self)){
       my $job_request = $self->req->body;
       $newJobs->enqueue($job_request);
       $self->render(text=>"ok");
     } else {
       $self->render(text=>"fail"); 
     }
  };

  get "job" => sub{
     my $self = shift;
     if (authorize($self)){
        if ($jobs_schedule{$self->param("job")}){
           $self->render(text => $jobs_schedule{$self->param("job")});
        } else {
           $self->render(text=> "No Job");
        }
     } else {
       $self->render(text=>"No Access");
     }
       
  };

  get "jobs" => sub{
     my $self = shift;
     my $string = job_schedule_json();
     $self->render(text=>"$string");
  };

  app->start;
};
