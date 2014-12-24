#!/bin/sh

haproxy_cfg='/tmp/haproxy-sandbox.cfg'
nginx_cfg='/tmp/nginx-sandbox.conf'
varnish_cfg='/tmp/varnish-sandbox.vcl'

function check_configs() {
    /usr/local/bin/haproxy -c -f $haproxy_cfg | grep ALERT
    /usr/local/bin/nginx -t -c $nginx_cfg 2>&1 | grep emerg
    /opt/local/sbin/varnishd -C -f $varnish_cfg -n /tmp 2>&1 \
        | grep 'VCL compilation failed'
}

function start_frontend() {
    stop_frontend
    check_configs
    sleep 1

    echo 'Starting haproxy.'
    echo 'Haproxy is at http://127.0.0.1:8000'
    echo 'Haproxy is at https://127.0.0.1:8001'
    echo
    /usr/local/bin/haproxy -f $haproxy_cfg -d \
      > /tmp/haproxy_start.log 2>&1 &

    echo 'Starting nginx.'
    echo 'Nginx is at http://127.0.0.1:8002'
    echo 'Nginx is at https://127.0.0.1:8003'
    echo
    /usr/local/bin/nginx -c $nginx_cfg 2>&1 \
      | grep -v "could not open error log" &

    echo 'Starting varnish.'
    echo 'Varnish is at http://127.0.0.1:8004'
    echo
    /opt/local/sbin/varnishd -a 127.0.0.1:8004 -f $varnish_cfg \
      -n /tmp -F > /tmp/varnish.log 2>&1 &

    echo 'Logs are in /tmp'
}

function stop_frontend() {
    echo 'Stopping haproxy, nginx and varnish.'
    /opt/local/bin/pkill haproxy
    /opt/local/bin/pkill nginx
    /opt/local/bin/pkill varnishd
}

function start_backend() {
    echo 'Starting backends'
    echo 'HTTP backends are at http://127.0.0.1:{3000,3001,3002}'
    for i in 3000 3001 3002; do
      /opt/local/bin/morbo http_backend.pl -l http://*:${i} \
        > /tmp/mojo_http_${i} 2>&1 &
    done
    echo 'HTTPS backends are at https://127.0.0.1:{3003,3004,3005}'
    for i in 3003 3004 3005; do
      /opt/local/bin/morbo http_backend.pl -l https://*:${i} \
        > /tmp/mojo_https_${i} 2>&1 &
    done
    echo 'TCP backends are at https://127.0.0.1:{3010,3011,3012}'
    for i in 3010 3011 3012; do
      /opt/local/bin/perl tcp_backend.pl -l $i \
        > /tmp/mojo_tcp_${i} 2>&1 &
    done
    echo 'Logs are in /tmp'
}

function stop_backend() {
    echo 'Stopping backends.'
    /opt/local/bin/pkill -f http_backend.pl
    /opt/local/bin/pkill -f tcp_backend.pl
}

function start_all() {
    stop_all
    sleep 1

    start_frontend
    start_backend
}

function stop_all() {
    stop_frontend
    stop_backend
}

function generate_config() {
    if [ -e $1 ]; then
        /bin/mv $1 ${1}.${3}
        echo "Old $1 is now ${1}.${3}"
    fi
    echo "Generating config to ${1}"
    echo
    /bin/cp $2 $1
}

function config_setup() {
    time=$(date +%Y%m%d_%H%M%S)

    generate_config $haproxy_cfg haproxy-sandbox.cfg $time
    generate_config $nginx_cfg nginx-sandbox.conf $time
    generate_config $varnish_cfg varnish-sandbox.vcl $time

    /bin/cp 127.0.0.1.* /tmp
}

function usage() {
cat <<- _eof_

  Usage: $0 <options>
  Options: start [front|back]
           stop [front|back]
           setup
           run_test
           help
           check
           version
           watch

  Sample:
    - use haproxy > nginx > backend (http/https)
      $ curl -I http://127.0.0.1:8000/nginx-a
      $ curl -Ik https://127.0.0.1:8000/nginx-a

    - use haproxy > varnish > backend
      $ curl -I http://127.0.0.1:8000/varnish-a

    - use haproxy > backend (http/https/tcp)
      $ curl -I http://127.0.0.1:8000
      $ curl -I https://127.0.0.1:8001

    - use nginx > backend (http/https)
      $ curl -I http://127.0.0.1:8002
      $ curl -Ik https://127.0.0.1:8003

    - use varnish > backend
      $ curl -I http://127.0.0.1:8004

    - use backend directly
      $ curl -I http://127.0.0.1:300{0,1,2}
      $ curl -Ik https://127.0.0.1:300{3,4,5}
      $ nc -v 127.0.0.1 30{10,11,12}

_eof_
}

function test_system {
    echo 'Running test suite.'
    echo 'Testing haproxy (http).'
    /opt/local/bin/curl -Is http://127.0.0.1:8000/ | grep 'OK'
    /opt/local/bin/curl -Is http://127.0.0.1:8000/nginx-a | grep 'OK'
    /opt/local/bin/curl -Is http://127.0.0.1:8000/varnish-a | grep 'OK'

    echo
    echo 'Testing haproxy (https).'
    /opt/local/bin/curl -Isk https://127.0.0.1:8001/ | grep 'OK'
    /opt/local/bin/curl -Isk https://127.0.0.1:8002/nginx-a | grep 'OK'
    /opt/local/bin/curl -Isk https://127.0.0.1:8001/varnish-a | grep 'OK'

    echo
    echo 'Testing nginx (http/https).'
    /opt/local/bin/curl -Is http://127.0.0.1:8002/ | grep 'OK'
    /opt/local/bin/curl -Isk https://127.0.0.1:8003/ | grep 'OK'

    echo
    echo 'Testing varnish.'
    /opt/local/bin/curl -Is http://127.0.0.1:8004 | grep 'OK'

    echo
    echo 'Testing mojo (http).'
    /opt/local/bin/curl -Is http://127.0.0.1:3000/ | grep 'OK'
    /opt/local/bin/curl -Is http://127.0.0.1:3001/ | grep 'OK'
    /opt/local/bin/curl -Is http://127.0.0.1:3002/ | grep 'OK'

    echo
    echo 'Testing mojo (https).'
    /opt/local/bin/curl -Isk https://127.0.0.1:3003/ | grep 'OK'
    /opt/local/bin/curl -Isk https://127.0.0.1:3004/ | grep 'OK'
    /opt/local/bin/curl -Isk https://127.0.0.1:3005/ | grep 'OK'

    echo
    echo 'Testing mojo (tcp).'
    /usr/bin/nc -vz 127.0.0.1 3010 | grep 'succeeded'
}

function watch_config {
    haproxy_old_time=$(stat -ln $haproxy_cfg)
    haproxy_new_time=$haproxy_old_time

    nginx_old_time=$(stat -ln $nginx_cfg)
    nginx_new_time=$nginx_old_time

    varnish_old_time=$(stat -ln $varnish_cfg)
    varnish_new_time=$varnish_old_time

    while true; do
        haproxy_old_time=$(stat -ln $haproxy_cfg)
        nginx_old_time=$(stat -ln $nginx_cfg)
        varnish_old_time=$(stat -ln $varnish_cfg)

        if [[ "$haproxy_old_time" != "$haproxy_new_time" ]] \
          || [[ "$nginx_old_time" != "$nginx_new_time" ]] \
          || [[ "$varnish_old_time" != "$varnish_new_time" ]]
        then
            start_frontend
            haproxy_new_time=$haproxy_old_time
            nginx_new_time=$nginx_old_time
            varnish_new_time=$varnish_old_time
        fi
    sleep 1
    done
}

case "$1" in
    start)
        case "$2" in
            front)
                start_frontend
                ;;
            back)
                start_backend
                ;;
            *)
                start_all
                ;;
        esac
        ;;
    stop)
        case "$2" in
            front)
                stop_frontend
                ;;
            back)
                stop_backend
                ;;
            *)
                stop_all
                ;;
        esac
        ;;
    setup)
        config_setup
        ;;
    run_test)
        test_system
        ;;
    check)
        egrep_var='haproxy |nginx|varnishd|http_backend|tcp_backend'
        ps aux | egrep "$egrep_var" | egrep -v egrep
        ;;
    version)
        /usr/local/bin/haproxy -v | grep version
        /usr/local/bin/nginx -v | grep version
        /opt/local/sbin/varnishd -V 2>&1 | grep varnishd
        ;;
    watch)
        watch_config
        ;;
    help)
        usage
        ;;
    *)
        usage
        ;;
esac
