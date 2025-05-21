#!/usr/bin/perl

# (C) Maxim Dounin
# (C) Sergey A. Osokin

# Test for redis with keepalive.

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

my $t = Test::Nginx->new()->has(qw/http redis upstream_keepalive rewrite/)
	->has_daemon('redis-server')->plan(15)
	->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    upstream rs {
        server 127.0.0.1:8081;
        keepalive 1;
    }

    upstream rs3 {
        server 127.0.0.1:8081;
        server 127.0.0.1:8082;
        keepalive 1;
    }

    upstream rs4 {
        server 127.0.0.1:8081;
        server 127.0.0.1:8082;
        keepalive 10;
    }

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        location / {
            set $redis_key $uri;
            redis_pass rs;
        }

        location /next {
            set $redis_key $uri;
            redis_next_upstream  not_found;
            redis_pass rs;
        }

        location /rs3 {
            set $redis_key "/";
            redis_pass rs3;
        }

        location /rs4 {
            set $redis_key "/";
            redis_pass rs4;
        }
    }
}

EOF

$t->write_file('rs1.conf', <<EOF);

daemonize no
pidfile ./rs1.pid
port 8081
bind 127.0.0.1
timeout 60
loglevel debug
logfile ./rs1.log
databases 16
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dbfilename rs1.rdb
dir ./
appendonly no
appendfsync always
tcp-keepalive 0

EOF


$t->write_file('rs2.conf', <<EOF);

daemonize no
pidfile ./rs2.pid
port 8082
bind 127.0.0.1
timeout 60
loglevel debug
logfile ./rs2.log
databases 16
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dbfilename rs2.rdb
dir ./
appendonly no
appendfsync always
tcp-keepalive 0

EOF

$t->run_daemon('redis-server', $t->testdir() . '/rs1.conf');
$t->run_daemon('redis-server', $t->testdir() . '/rs2.conf');

$t->run();

$t->waitforsocket('127.0.0.1:8081')
        or die "Can't start redis1";

$t->waitforsocket('127.0.0.1:8082')
        or die "Can't start redis2";


###############################################################################

my $r1 = Redis->new(server => '127.0.0.1:8081');
my $r2 = Redis->new(server => '127.0.0.1:8082');

$r1->set('/', 'SEE-THIS') or die "can't put value into redis1: $!";
$r2->set('/', 'SEE-THIS') or die "can't put value into redis2: $!";
$r1->set('/big', 'X' x 1000000) or die "can't put value into redis1: $!";

my $total = $r1->info->{connected_clients};                              # 0
print "No tests: $total\n";

like(http_get('/'), qr/SEE-THIS/, 'keepalive redis request');
like(http_get('/notfound'), qr/ 404 /, 'keepalive redis not found');
like(http_get('/next'), qr/ 404 /,
	'keepalive not found with redis_next_upstream');
like(http_get('/'), qr/SEE-THIS/, 'keepalive redis request again');
like(http_get('/'), qr/SEE-THIS/, 'keepalive redis request again');
like(http_get('/'), qr/SEE-THIS/, 'keepalive redis request again');

is($r1->info->{connected_clients}, $total + 1,                           # 1
	'only one connection used');
print "6 tests: $total\n";

# Since nginx doesn't read all data from connection in some situations (head
# requests, post_action, errors writing to client) we have to close such
# connections.  Check if we really do close them.

$total = $r1->info->{connected_client} ? $r1->info->{connected_client} : 0;
print "Again 6 tests: $total\n";

unlike(http_head('/'), qr/SEE-THIS/, 'head request');
like(http_get('/'), qr/SEE-THIS/, 'get after head');

is($r1->info->{connected_clients}, $total + 2,
	'head request does not close connection');

$total = $r1->info->{connected_clients};
print "9 tests: $total\n";

unlike(http_head('/big'), qr/XXX/, 'big head');
like(http_get('/'), qr/SEE-THIS/, 'get after big head');

is($r1->info()->{connected_clients}, $total,
	'big head request does not close connection');

print "11 tests: $total\n";
# two backends with maximum number of cached connections set to 1,
# should establish new connection on each request

$total = $r1->info->{connected_clients} +
	$r2->info->{connected_clients};
print "Again 11 tests: $total\n";

http_get('/rs3');
http_get('/rs3');
http_get('/rs3');

is($r1->info->{connected_clients} +
	$r2->info->{connected_clients}, $total + 1,
	'3 connections should be established');

# two backends with maximum number of cached connections set to 10,
# should establish only two connections (1 per backend)

$total = $r1->info->{connected_clients} +
 	$r2->info->{connected_clients};

http_get('/rs4');
http_get('/rs4');
http_get('/rs4');

is($r1->info->{connected_clients} +
	$r2->info->{connected_clients}, $total + 2,
	'connection per backend');

###############################################################################
