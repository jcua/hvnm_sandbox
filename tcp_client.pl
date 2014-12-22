#!/usr/bin/perl

use strict;
use IO::Socket;

my $host   = '127.0.0.1';
my ($port) = @ARGV;
die "Usage: $0 port\n" unless (@ARGV == 1);

my $socket = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => $host,
        PeerPort => $port,
) or die "Could not create socket: $!";
$socket->autoflush(1);

my $welcome = "Welcome to $host:$port; type help for command list.\n";
$welcome .= "Hit Ctrl-C to exit.\n";
print STDERR $welcome;

die "Cannot fork: $!" unless defined(my $kidpid = fork());

if ($kidpid) {
    while (my $line = <$socket>) {
        print STDOUT $line;
    }
    kill("TERM", $kidpid)
}
else {
    while (my $line = <STDIN>) {
        print $socket $line;
    }
}

