#!/usr/bin/perl

use strict;
use Data::Dumper;
use Mojolicious::Lite;

get '/' => sub {
    my $c = shift;
    my $ua = $c->req->headers->user_agent;
    $c->render(text => "Request by $ua");
};

get '/cache' => sub {
    my $c = shift;
    $c->res->headers->header('Cache-Control' => 'max-age=0');
    $c->render(text => $c->req->url->to_abs->path);
};

get '/cookies' => sub {
    my $c = shift;
    if (! $c->req->headers->cookie) {
        $c->render(text => 'No cookies. Try curl --cookies "key=val"');
    }
    else {
        $c->render(text => $c->req->headers->cookie);
    }
};

get '/hello' => sub {
    my $c = shift;
    my $host = $c->req->url->to_abs->host;
    $c->stash(one => 23);
    $c->stash(two => 24);
    $c->render('hello');
    $c->res->headers->header(
      'X-Server' => "$host:" . $c->tx->local_port);
};

# /sleep?sleep=XX
get '/sleep' => sub {
    my $c = shift;
    my $timer = $c->param('sleep') || 3;
    $c->res->headers->header('X-Sleep' => 'Simulating slow page');
    Mojo::IOLoop->timer($timer => sub {
      $c->render(text => "Delayed by $timer seconds!");
    });
};

get '/user' => sub {
    my $c = shift;
    my $all_headers = $c->req->headers;
    $c->render(text => clean_output($all_headers));
};

for my $i ('a'..'z') {
    get "/$i" => sub { generic_route(shift) };
    get "/nginx-$i" => sub { generic_route(shift) };
    get "/varnish-$i" => sub { generic_route(shift) };
}

get '/301' => sub {
    my $c = shift;
    $c->render(text => "Redirect", status => 301);
};

get '/404' => sub {
    my $c = shift;
    return $c->reply->not_found;
};

get '/500' => sub {
    my $c = shift;
    return $c->reply->exception();
};

get '/503' => sub {
    my $c = shift;
    $c->render(template => '503', status => 503);
};

# Quiet down secret warning
app->secrets(['new_secret']);

# Under Mojolicious hooks
app->hook(after_render => sub {
    my $c = shift;
    my $url = $c->req->url->to_abs->path;
    $c->res->headers->header('X-Url' => $url);
    $c->res->headers->server('127.0.0.1:' . $c->tx->local_port);
});

app->start;

sub clean_output {
    my $i = shift;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Bless = undef;

    my @raw = split('\n', Dumper \$i);
    my @new_raw;

    for (@raw) {
        next if /\( {/;
        next if /Mojo::Headers'/;
        push(@new_raw, $_);
    }
    my $output = join("\n", @new_raw) . "\n";
    return $output;
}

sub generic_route {
    my $c = shift;
    $c->render(text => $c->req->url->to_abs->path);
}

__DATA__
@@ hello.html.ep
The magic numbers are <%= $one %> and <%= $two %>.

@@ 503.html.ep
Service Unavailable error!

@@ not_found.development.html.ep
Not Found

@@ not_found.html.ep
Not Found
