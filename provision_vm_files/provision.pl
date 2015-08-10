#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $system = $ARGV[0];
my $user = $ARGV[1] // 'root';
if ( @ARGV < 1 or 2 < @ARGV or $ARGV[0] =~ /^-h$|^-help$|^--help$/ ) {
    help();
    exit;
}
my $help;
GetOptions(
    "system=s" => \$system,
    "user=s"   => \$user,
    "help"     => \$help
) or die("Error in command line arguments\n");

my $dir_for_files = 'provision_files';
make_tmp_dir();

set_sysip_prompt() if ( $system =~ /(\d{1,3}\.){3}\d{1,3}/ );

chomp( my @files = `cat system.plans/${user}\@$system` );
my $use_ssh_key = '';
my $use_port    = '';
foreach my $file ( sort @files ) {
    if ( $file =~ /\.ssh/ ) {
        system( "cp ${file}.pub $dir_for_files/ssh_key ");
        if ( $file =~ /(.*)\.pub$/ ) {
            $file = $1;
        }
        $use_ssh_key = "-i $file";
    }
    elsif ( $file =~ /port:(\d*)/ ) {
        $use_port = "-P $1";
    }
    elsif ( $file =~ /bash_custom/ ) {
        system( "echo '\n# $file' >> $dir_for_files/.bash_custom" );
        system( "cat files/$file >> $dir_for_files/.bash_custom" );
    }
    elsif ( $file =~ /(.*):SNR:(.*):(.*)/ ) { # so can't use colons in the regex
        my ( $filename, $search, $replace ) = ( $1, $2, $3 );
        system( "cp files/$filename $dir_for_files/" );
        replace_text_in_file( $dir_for_files, $filename, $search, $replace );
    }
    else { # default files going to ~
        system( "cp files/$file $dir_for_files/" );
    }
}

system( 'tar', '-cvf', 'totransfer.tar', $dir_for_files );
`scp $use_ssh_key $use_port totransfer.tar ${user}\@$system:~/transferred_by_provision_script.tar`;
`scp $use_ssh_key $use_port expand.pl ${user}\@$system:~/provision_expand.pl`;


# subroutines
sub make_tmp_dir {
    if ( -d $dir_for_files ) { # just in case of oops
        system( 'mv', $dir_for_files, "${dir_for_files}.bak" );
    }
    system( 'mkdir', $dir_for_files );
}

sub set_sysip_prompt {
    # TODO: use CPANEL by default if system is an IP address without a system file
    my $sys_ip = $system;
    open( my $fh, '>>', "$dir_for_files/.bash_custom" ) or die "Couldn't open file $!";
    print $fh "hostip=$sys_ip\n";
}

sub replace_text_in_file {
    my ( $dir, $filename, $search, $replace ) = @_;
    use Path::Tiny qw(path);
    my $file = path( "$dir/$filename" );
    my $data = $file->slurp_utf8;
    $data =~ s/$search/$replace/g;
    $file->spew_utf8( $data );
}

sub help {
    print "\nPlease enter one or two arguments:\n";
    print "provision.pl <system_name|ip_address> [username]\n\n";
    print "/system.plans - list of systems' plans\n";
    print "/files - list of files to include in those plans\n\n";
}

# cleanup
system( 'rm', '-rf', $dir_for_files );
system( 'rm', '-rf', 'totransfer.tar' );
