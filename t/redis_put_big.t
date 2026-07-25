#!/usr/bin/perl

# (C) Maxim Dounin
# (C) Sergey A. Osokin

# Test for redis backend.

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

eval { require Redis; };
plan(skip_all => 'Redis not installed') if $@;


my $t = Test::Nginx->new()->has(qw/http/)
	->has_daemon('redis-server')->plan(2)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    upstream r {
        server 127.0.0.1:8081;
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        client_max_body_size 1g;

        location / {
            set $redis_key $uri;
            redis_pass r;
        }
    }
}

EOF

$t->write_file('redis.conf', <<EOF);

daemonize no
pidfile ./redis.pid
port 8081
bind 127.0.0.1
timeout 300
loglevel debug
logfile ./redis.log
databases 16
save ""
rdbcompression yes
dbfilename dump.rdb
dir ./
appendonly no
appendfsync always

EOF

$t->run_daemon('redis-server', $t->testdir() . '/redis.conf');
$t->run();

$t->waitforsocket('127.0.0.1:8081')
	or die "Can't start redis";

###############################################################################

my $r;
my $rr;

$rr = Redis->new(server => '127.0.0.1:8081');

my $body = 'xXaAbBcC' x 64 x 1024 x 1024;

$r = http(<<EOF);
PUT /file HTTP/1.1
Host: localhost
Connection: close
Content-Length: 536870912

$body
EOF

like($r, qr/201 Created/, 'put max size file');
is($rr->strlen('/file'), 536870912, 'key length is 512M');

###############################################################################
