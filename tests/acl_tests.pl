use Cornbat::Access;
my $PASSFILE = "passfile"; 
my $ACLFILE = "aclfile";
my $auth = Cornbat::Access->new($PASSFILE, $ACLFILE);

print $auth->authenticate_request("BASIC QWxhZGRpbjpvcGVuIHNlc2FtZQ==");
print $auth->check_access("Aladdin", "root");

print "\n";
@foo = (1,2);
print @foo[0];
$link2 = \@foo;
@link = @{$link2};
$mon = shift @link;
print @foo[0];
print $mon;
print @link[0];
