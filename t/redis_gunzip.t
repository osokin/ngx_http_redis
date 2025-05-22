#!/usr/bin/perl

# (C) Maxim Dounin
# (C) Sergey A. Osokin

# Test for a gzipped content in redis.

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use lib 'lib';
use Test::Nginx qw/ :DEFAULT :gzip /;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

eval { require Redis; };
plan(skip_all => 'Redis not installed') if $@;

eval { require IO::Compress::Gzip; };
plan(skip_all => "IO::Compress::Gzip not found") if $@;

my $t = Test::Nginx->new()->has(qw/http gunzip redis rewrite/)
	->has_daemon('redis-server')
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

        location /t1 {
            set $redis_key $uri;
            redis_pass redisbackend;
            redis_gzip_flag 2;
        }
        location /t2 {
            gunzip on;
            set $redis_key $uri;
            redis_pass redisbackend;
            redis_gzip_flag 2;
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

my $in = join('', map { sprintf "X%03dXXXXXX", $_ } (0 .. 99));
my $out;

IO::Compress::Gzip::gzip(\$in => \$out);

$t->run_daemon('redis-server', $t->testdir() . '/redis.conf');

$t->run()->plan(2);

$t->waitforsocket('127.0.0.1:8081')
	or die "Can't start redis";

my $r = Redis->new(server => '127.0.0.1:8081');
$r->set('/t1', $out)
	or die "can't put value into redis: $!";
$r->set('/t2', $out)
	or die "can't put value into redis: $!";

###############################################################################

like(http_gzip_request('/t1'), qr/Content-Encoding: gzip.*/, 'redis response gzipped');
like(http_get('/t2'), qr/(?!Content-Encoding).*^(X\d\d\dXXXXXX){100}$/m,
        'correct gunzipped response');

###############################################################################
