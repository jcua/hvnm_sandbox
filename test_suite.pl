#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use Test::More;

my $lh = '127.0.0.1';
my $ua = LWP::UserAgent->new(
           ssl_opts => { verify_hostname => 0 },
);

my %url_for = (
    "http://$lh:8000/" => 'Test haproxy on http',
    "http://$lh:8000/nginx-a" => 'Test haproxy > nginx > backend on http',
    "http://$lh:8000/varnish-a" => 'Test haproxy > varnish > backend on http',
    "https://$lh:8001/" => 'Test haproxy on https',
    "https://$lh:8001/nginx-a" => 'Test haproxy > nginx > backend on https',
    "https://$lh:8001/varnish-a" => 'Test haproxy > varnish > backend on https',

);

for my $i (sort keys %url_for) {
    my $res = $ua->head($i);
    is( $res->is_success(), 1, $url_for{$i} );
};

my %tcp_ports_for = (
    '8005' => 'Test haproxy on tcp',
    '3010' => 'Testing one of the mojo ports',
    '3011' => 'Testing one of the mojo ports',
    '3012' => 'Testing one of the mojo ports',
);

for my $i (sort keys %tcp_ports_for) {
    my $result = qx(/usr/bin/nc -vz $lh $i);
    like ($result, qr/succeeded/, $tcp_ports_for{$i});
}

done_testing();
