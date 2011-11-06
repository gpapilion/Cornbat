use Cornbat::Job;
use Cornbat::Access;
use POSIX ":sys_wait_h"; 

my %running_jobs;
my %jobs_schedule; 
my %jobs;
my %pids;
my $PASSFILE = 'tests/passfile';
my $ACLFILE = 'tests/aclfile';

my $auth = Cornbat::Access->new($PASSFILE, $ACLFILE);

sub REAPER {
   my $child;
   while (($child = waitpid(-1, WNOHANG)) > 0) {
       $Kid_Status{$child} = $?;
       my $job_name = $pid{$child};
       delete($running_jobs{$job_name});
   }
   $SIG{CHLD} = \&REAPER;
}

$SIG{CHLD} = \&REAPER;


read_schedule();

my $web_pid = fork();
if ( $web_pid == 0 ) {
   web();
}
   
if ($web_pid) {
while(1){
  #sleep to top of minute;
  cron_sleep();
  read_schedule();
  #sleep 60;
  # run jobs
  my @date_array= localtime(time);
  my @current_time = ($date_array[1], $date_array[2], $date_array[3], $date_array[4], $date_array[6]);
  foreach my $key (keys %jobs){ 
     # should this job be run?
      
     if($jobs{$key}->should_run(\@current_time)){
        # check if I'm running 
        if ($running_jobs{$key} && ($jobs{$key}->{BlockOthers} eq 1) ) { 
           print "${jobs{$key}->Name} is running, and blocks new jobs\n";
        } else { 
           my $pid = fork();
           die "Forking Issue" unless defined $pid;
           if (!$pid ) {

              # drop to non-root user if needed
              if ($jobs{$key}->{RunAs} != "root") {
                  my $uid = getpwnam($jobs{$key}->{RunAs});
                  my $gid = getgrnam($jobs{$key}->{RunAs});
                  ($),$() = ($gid, $gid);
                  ($<,$>) = ($uid, $uid);
              }
              $exit_status = system($jobs{$key}->{Command});
              exit $exit_status;
              
           } else {
              $running_jobs{$key} = time();
              $jobs{$key}->ran();
              $pids{$pid} = $key;
              $jobs_schedule{$key} = $jobs{$key}->to_js();
           }
        }
     }
   }
}

}
sub cron_sleep{
  # roughly equivlent to how cron sleeps on unix, wake up
  # once per min, and check for jobs that need running.
  my $start_time = time ;
  my $sleep_for = 60 - (time % 60);
  while ($start_time + $sleep_for > time) {
     $sleep_for = 60 - (time % 60);
     sleep($sleep_for); 
  }
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
  }
  $string = "{ " . $string . "}";
  return $string;
}

sub job_schedule_from_json{
  my ($string) = shift;
  my $json = Mojo::JSON->new;
  my $json_array;
  $json_array = $json->decode($string);
  foreach my $key ( keys %{$json_array}){
      my $job = bless($$json_array{$key}, Cornbat::Job);
      $job->{NumberRuns}=0;
      #Cornbat::Job->from_js($json_array{$key});
      $jobs_schedule{$key} = $job->to_js();
      $jobs{$job->{JobName}} = $job;
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
       read_schedule();
       my $job_request = $self->req->body;
       my $job = Cornbat::Job->from_js($job_request); 
       $jobs{$job->{JobName}} = $job;
       $jobs_schedule{$job->{JobName}} = $job_request;
       write_schedule();
       $self->render(text=>"ok $job->{JobName}");
     } else {
       $self->render(text=>"fail"); 
     }
  };

  post "delete" => sub{
     my $self = shift;
     if (authorize($self)){
        read_schedule();
        if ($jobs{$self->param("job")}){
            delete($jobs{$self->param("job")});
            delete($jobs_schedule{$self->param("job")});
            write_schedule();
            $self->render(text=> "Job Deleted");
         } else {
            $self->render(text=> "No Job");
         }
       }else{
          $self->render(text=> "No Access");
       }
  };

       

  get "job" => sub{
     my $self = shift;
     if (authorize($self)){
        read_schedule();
        if ($jobs{$self->param("job")}){
           $self->render(text => $jobs{$self->param("job")}->to_js());
        } else {
           $self->render(text=> "No Job");
        }
     } else {
       $self->render(text=>"No Access");
     }
       
  };

  get "jobs" => sub{
     my $self = shift;
     if (authorize($self)){
        read_schedule();
        my $string = job_schedule_json();
        $self->render(text=>"$string");
     } else {
        $self->render(text=>"No Access");
     }
  };

  app->start;
};
