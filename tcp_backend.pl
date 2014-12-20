#!/usr/bin/perl

use strict;
use Mojo::IOLoop;

my $delay = 0;
Mojo::IOLoop->server({port => 3010} => sub {
    my ($loop, $stream) = @_;

    $stream->on(read => sub {
        my ($stream, $method) = @_;
        my $msg;

        if ($method =~ 'start_rep') {
            $msg = 'start replication';
        }
        elsif ($method =~ 'stop_rep') {
            $msg = 'stop replication';
        }
        elsif ($method =~ 'start_delay') {
            $msg = 'start_delay';
            $delay = 1;
        }
        elsif ($method =~ 'stop_delay') {
            $msg = 'start_delay';
            $delay = 1;
        }
        elsif ($method =~ 'status') {
            $msg = "delay is $delay";
        }
        else {
            $msg = 'unknown command';
        }

        $stream->write($msg . "\n");
        $delay++ if ($delay > 0);
    });
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
