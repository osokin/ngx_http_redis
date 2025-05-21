#!/usr/bin/perl

# (C) Maxim Dounin
# (C) Sergey A. Osokin

# Test redis database maximum database number

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

my $t = Test::Nginx->new()->has(qw/http redis/)
	->has_daemon('redis-server')->plan(2)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon         off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    upstream redisbackend {
        server 127.0.0.1:8081;
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location /0 {
            set $redis_db "0";
            set $redis_key $uri;
            redis_pass redisbackend;
        }
        location /1048575 {
            set $redis_db "1048575";
            set $redis_key $uri;
            redis_pass redisbackend;
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
databases 1048576
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

my $r = Redis->new(server => '127.0.0.1:8081');
$r->select(0);
$r->set('/0' => 'SEE-THIS-0') or die "can't put value into redis: $!";
$r->select(1048575);
$r->set('/1048575' => 'SEE-THIS-1048575') or die "can't put value into redis: $!";

like(http_get('/0'), qr/SEE-THIS-0/, 'redis request to db 0');
like(http_get('/1048575'), qr/SEE-THIS-1048575/, 'redis request to db 1048575');

###############################################################################
