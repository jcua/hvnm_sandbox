#!/bin/sh

haproxy_cfg='/tmp/haproxy-sandbox.cfg'
nginx_cfg='/tmp/nginx-sandbox.conf'
varnish_cfg='/tmp/varnish-sandbox.vcl'

function start_frontend() {
    stop_frontend
    sleep 1

    echo 'Starting haproxy.'
    echo 'Haproxy is at http://127.0.0.1:8000'
    echo
    /usr/local/bin/haproxy -f $haproxy_cfg -d \
      > /tmp/haproxy_8000 2>&1 &

    echo 'Starting nginx.'
    echo 'Nginx is at http://127.0.0.1:8001'
    echo
    /usr/local/bin/nginx -c $nginx_cfg 2>&1 \
      | grep -v "could not open error log" &

    echo 'Starting varnish.'
    echo 'Varnish is at http://127.0.0.1:8002'
    echo
    /opt/local/sbin/varnishd -a 127.0.0.1:8002 -f $varnish_cfg \
      -n /tmp -F > /tmp/varnish_8002 2>&1 &

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
    echo 'Backends are at http://127.0.0.1:{3000,3001,3002}'
    for i in 3000 3001 3002; do
      /opt/local/bin/morbo mojo_backend.pl -l http://*:${i} \
        > /tmp/mojo_${i} 2>&1 &
    done
    echo 'Logs are in /tmp'
}

function stop_backend() {
    echo 'Stopping morbo.'
    /opt/local/bin/pkill -f morbo
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

  Sample:
    - use haproxy > backend
      $ curl -I http://127.0.0.1:8000

    - use nginx > backend
      $ curl -I http://127.0.0.1:8001

    - use varnish > backend
      $ curl -I http://127.0.0.1:8002

    - use haproxy > nginx > backend
      $ curl -I http://127.0.0.1:8000/nginx-a

    - use haproxy > varnish > backend
      $ curl -I http://127.0.0.1:8000/varnish-a

    - use backend directly
      $ curl -I http://127.0.0.1:3000/{a,b,c}

_eof_
}

function test_system {
    echo 'Running test suite.'
    echo
    /opt/local/bin/curl -I http://127.0.0.1:8000/
    /opt/local/bin/curl -I http://127.0.0.1:8000/nginx-a
    /opt/local/bin/curl -I http://127.0.0.1:8000/varnish-a
    /opt/local/bin/curl -I http://127.0.0.1:8001/
    /opt/local/bin/curl -I http://127.0.0.1:8002/
    /opt/local/bin/curl -I http://127.0.0.1:3000/
    /opt/local/bin/curl -I http://127.0.0.1:3001/
    /opt/local/bin/curl -I http://127.0.0.1:3002/
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
        ps aux | egrep "haproxy |nginx|varnishd|mojo" | egrep -v egrep
        ;;
    *)
        usage
        ;;
esac
