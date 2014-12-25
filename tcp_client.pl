#!/usr/bin/perl

use strict;
use Getopt::Long;
use IO::Socket;

GetOptions( 'listen=i' => \my $opt_port,
            'exec=s'   => \my $opt_exec,
            'h'        => \my $opt_help,
);

usage() if ( ! defined( $opt_port ) &&
  ! defined( $opt_exec ) || defined( $opt_help ) );

my $host   = '127.0.0.1';
my ($port) = $opt_port;

my $socket = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => $host,
        PeerPort => $port,
) or die "Could not create socket: $!";
$socket->autoflush(1);

if ( $opt_exec ) {
    print $socket $opt_exec;
    my $line = <$socket>;
    $line =~ s/^\s+//g;
    print STDOUT $line;
    exit;
}
else {
    my $welcome = "Welcome to $host:$port; type help for command list.\n";
    $welcome .= "Hit Ctrl-C to exit.\n";
    print STDERR $welcome;

    die "Cannot fork: $!" unless defined(my $kidpid = fork());

    if ($kidpid) {
        while (my $line = <$socket>) {
            print STDOUT $line;
        }
        kill("TERM", $kidpid);
    }
    else {
        while (my $line = <STDIN>) {
            print $socket $line;
        }
    }
}

sub usage {
    print "\n";
    print qq{Usage: $0 -l <port>\n}
        . qq{Usage: $0 -l <port> -e <start|stop|stat>\n\n};

    exit;
}
