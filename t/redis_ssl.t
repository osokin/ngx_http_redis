#!/usr/bin/perl

# (C) Maxim Dounin
# (C) Sergey A. Osokin

# Test for redis backend with SSL.

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


my $t = Test::Nginx->new()->has(qw/http http_ssl/)
	->has_daemon('redis-server')->plan(4)
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

        location / {
            set $redis_key $uri;
            redis_pass rediss://redisbackend;
        }
    }
}

EOF

$t->write_file('openssl.conf', <<EOF);
[ req ]
default_bits = 2048
encrypt_key = no
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
EOF

my $d = $t->testdir();
my $crt = "$d/redis.crt";
my $key = "$d/redis.key";

foreach my $name ('redis') {
	system('openssl req -x509 -new '
		. "-config $d/openssl.conf -subj /CN=$name/ "
		. "-out $d/$name.crt -keyout $d/$name.key "
		. ">>$d/openssl.out 2>&1") == 0
		or die "Can't create certificate for $name: $!\n";
}

$t->write_file('redis.conf', <<EOF);

daemonize no
pidfile ./redis.pid
port 8082
tls-port 8081
tls-cert-file $crt
tls-key-file $key
tls-auth-clients no
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

my $r = Redis->new(server => '127.0.0.1:8082');
$r->set('/' => 'SEE-THIS') or die "can't put value into redis: $!";
$r->set('/0/' => 'SEE-THIS.0') or die "can't put value into redis: $!";

like(http_get('/'), qr/SEE-THIS/, 'redis request /');

like(http_get('/0/'), qr/SEE-THIS.0/, 'redis request from db 0');

like(http_get('/notfound'), qr/404/, 'redis not found');

unlike (http_head('/'), qr/SEE-THIS/, 'redis no data in HEAD');

###############################################################################
