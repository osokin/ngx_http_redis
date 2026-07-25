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
	->has_daemon('redis-server')->plan(15)
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

like(http_get('/file'), qr/404/, 'file not found');

$r = http(<<EOF . '0123456789');
PUT /file HTTP/1.1
Host: localhost
Connection: close
Content-Length: 10

EOF

like($r, qr/201 Created.*(Content-Length|\x0d\00\x0d\x0a)/ms, 'put file');
like(http_get('/file'), qr/0123456789/, 'redis get file');

is($rr->strlen('/file'), 10, 'key length is 10');
isnt($rr->strlen('/file'), 11, 'key length isn\'t 11');
isnt($rr->strlen('/file'), 9, 'key length isn\'t 9');

$r = http(<<EOF);
PUT /file HTTP/1.1
Host: localhost
Connection: close
Content-Length: 0

EOF

like($r, qr/201 Created.*(Content-Length|\x0d\00\x0d\x0a)/ms, 'put file again');
is($rr->strlen('/file'), 0, 'put file again size');

$r = http(<<EOF);
DELETE /file HTTP/1.1
Host: localhost
Connection: close
Content-Length: 0

EOF

like($r, qr/204 No Content/, 'delete file');
like(http_get('/file'), qr/404/, 'file not found');
is($rr->get('/file'), undef, 'key is unavailable');

$r = http(<<EOF . '0123456789' . 'extra');
PUT /file HTTP/1.1
Host: localhost
Connection: close
Content-Length: 10

EOF

like($r, qr/201 Created.*(Content-Length|\x0d\00\x0d\x0a)/ms,
        'put file extra data');
like(http_get('/file'), qr/200 .*(Content-Length|\x0d\0a0\x0d\x0a)/ms, 'get file extra data');
like(http_get('/file'), qr/0123456789/, 'get file extra data');
is($rr->strlen('/file'), 10, 'put file extra data size');

###############################################################################
