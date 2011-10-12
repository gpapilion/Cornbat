use threads;
use Thread::Queue;
use threads::shared;
use Cornbat::Job;

my $newJobs = Thread::Queue->new;
my $running_jobs : shared = {};
my %jobs_schedule : shared = {};

my $webserver = threads->new(\&web, "daemon");
#$cron = threads->new(\&cron_sleep);

my %jobs;
while(1){
  #sleep to top of minute;
  cron_sleep();
  #sleep 60;
  #check if any jobs were added
  while($newJobs->pending) {
     my $job_str = $newJobs->dequeue;
     my $job = Cornbat::Job->from_js($job_str);  
     #add jobs to queue
     $jobs{$job->{JobName}} = $job;
     
  }

  # run jobs
  my @date_array= localtime(time);
  my @current_time = (@date_array[1], @date_array[2], @date_array[3], @date_array[4], @date_array[6]  );
  print @current_time;
  print keys %jobs;
  foreach my $key (keys %jobs){ 
     print "$jobs{$key}->{JobName}\n";
     print "$jobs{$key}->{JobName}\n";
     print "$jobs{$key}->{Command}\n";
     # should this job be run?
     if($jobs{$key}->should_run(\@current_time)){
        $running_jobs{$key} = time();
        $pid=fork();
        if(!$pid){
           print "awesome\n";
           system("$jobs{$key}->{Command}");
           delete($running_jobs{$key});
           exit;
        }
     }
   
  }
}

@return = $webserver->join;

sub cron_sleep{
  my $sleep_for = 60 - (time % 60);
  print "Sleeping for $sleep_for\n";
  sleep($sleep_for); 
}

sub web {
  use Mojolicious::Lite;
  use Mojo::JSON;
  use Cornbat::Job;
  post 'job' => sub{
     my $self = shift;
     #my $json = Mojo::JSON->new;
     my $job_request = $self->req->body;
     #my $body = $job_request->{JobName};
  #   print STDERR "`$job_request\n\n\n";
     $newJobs->enqueue($job_request);
     $self->render(text=>"ok");
 #{"RunAs":"root","BlockOthers":0,"Command":"\/etc\/foo","NumberRuns":null,"JobSchedule":["0-11",1,0,0,0],"LogFile":null,"JobName":"test job"}
     #my $user = self->param{'user'};
     #my $command = self->param{'command'};
     #my $run_as = self->param{'run_as'};
  };
  get "jobs" => sub{
     my $self = shift;
     my $jobs_string;
     for my $key (keys %{$running_jobs}) {
        $jobs_string .= $key;
     }
     $self->render(text=>"$jobs_string");

  };
  app->start;
};
