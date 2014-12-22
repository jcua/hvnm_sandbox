#!/usr/bin/perl

use strict;
use Mojo::IOLoop;

my $delay = 0;
my $current_time = 0;

Mojo::IOLoop->server({port => 3010} => sub {
    my ($loop, $stream) = @_;

    $stream->on(read => sub {
        my ($stream, $method) = @_;
        my $msg = '';

        if ($method =~ 'start') {
            $msg = "  Delay has been started.\n";
            $delay = 1;
            $current_time = time();
        }
        elsif ($method =~ 'stop') {
            $msg = "  Delay has been stopped\n";
            $delay = 0;
        }
        elsif ($method =~ 'stat') {
            my $time_diff = time() - $current_time;
            if ($delay == 1) {
                $msg = "  Delay is $time_diff.\n";
            }
            else {
                $msg = "  Delay is 0.\n";
            }
        }
        elsif ($method =~ 'help') {
            $msg = "  Available commands: start, stop, stat.\n";
        }

        $stream->write($msg);
    });
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
