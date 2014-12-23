hvnm_sandbox
============

Haproxy, varnish, nginx and mojolicious sandbox in Mac. The goal is to be able to test a feature by creating an environment where it takes seconds to setup. This also allows you to repeatedly test your setup to make sure you understand what is happening.

While I can have this same setup in my virtualbox or vagrant, the problem with that is that it takes a long time for me to start them up. Also, I do not want to leave them up and running. I want something that I can easily start, test and forget about it until the next time I need to test something again.

Installation
===============
```
$ sudo brew install haproxy
$ sudo brew install varnish
$ sudo brew install nginx
$ curl get.mojolicio.us | sudo sh
```

Usage
========
```
1. Create the initial configs (needs to be done once only).
   $ ./sandbox setup

2. Start the system.
   $ ./sandbox start

3. Watch for any config changes and restart the system.
   $ ./sandbox watch

4. Make changes in the configs located in the /tmp. Logs are in /tmp too.

```

Tests that can be done
=========================
The current config allows you to test the following:

```

         +---------+    +---------+    +------+
         | HAProxy | -> |  Nginx  | -> | Mojo |
         +---------+    +---------+    +------+

         +---------+    +---------+    +------+
         | HAProxy | -> | Varnish | -> | Mojo |
         +---------+    +---------+    +------+

         +---------+    +------+
         | HAProxy | -> | Mojo |
         +---------+    +------+

         +---------+    +------+
         |  Nginx  | -> | Mojo |
         +---------+    +------+

         +---------+    +------+
         | Varnish | -> | Mojo |
         +---------+    +------+

```

Backends
===========

1. There are three kinds of backends that you can test: http, https, and tcp-based application.
2. There are 3 http backends listening on 3000, 3001, and 3002 and 3 https backends listening on 3003, 3004, and 3005.
3. The tcp-based application accepts three basic commands: start, stat, stop which mimics starting/stopping of database replication. In order to issue these commands, you can use tcp_client.pl or even netcat can work too.
