backend localhost_3000 {
    .host = "127.0.0.1";
    .port = "3000";
}

backend localhost_3001 {
    .host = "127.0.0.1";
    .port = "3001";
}

backend localhost_3002 {
    .host = "127.0.0.1";
    .port = "3002";
}

director all_backends round-robin {
    { .backend = localhost_3000; }
    { .backend = localhost_3001; }
    { .backend = localhost_3002; }
}

sub vcl_recv {
    set req.backend = all_backends;

    return(lookup);
}

sub vcl_fetch {
    set beresp.ttl = 5s;
    set beresp.http.X-Backend = beresp.backend.name;

    return(deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
