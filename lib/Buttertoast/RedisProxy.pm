package Buttertoast::RedisProxy;

use Moose;
use Redis;
use Redis::ClusterRider;

use MIME::Base64;
use Crypt::Mode::CBC;
use Data::Random qw/rand_chars/;

has config => (
    is => 'rw',
);

has redis_cluster => (
    is => 'rw',
    isa => 'Redis::ClusterRider',
    lazy => 1,
    default => sub {
        my $self = shift;
        Redis::ClusterRider->new(startup_nodes => $self->config->redis->host);
    }
);

has redis_nodes => (
    is => 'rw',
    lazy => 1,
    isa => 'ArrayRef[Redis]',
    default => sub {
        my $self = shift;
        my @data;
        for my $host ($self->config->redis->host->@*) {
            push @data, Redis->new(server => $host);
        }

        return \@data;
    }
);

has crypt => (
    is => 'rw',
    lazy => 1,
    default => sub { Crypt::Mode::CBC->new('AES') },
);

sub _encrypt {
    my $self = shift;
    my $value = shift;

    my $iv = rand_chars(set => 'alphanumeric', min => 16, max => 16);
    my $enc_value = $self->crypt->encrypt($value, $self->config->redis->encryption_key, $iv);
    my $b64_value = encode_base64($enc_value);
    my $ret = $b64_value . ":$iv";

    return $ret;
}

sub _decrypt {
    my $self = shift;
    my $value = shift;

    my ($b64_value, $iv) = split(/:/, $value);
    my $enc_value = decode_base64($b64_value);
    my $dec_value;
    $dec_value = $self->crypt->decrypt($enc_value, $self->config->redis->encryption_key, $iv);

    return $dec_value;
}

sub _key {
    my $self = shift;
    my $key = shift;


    my $prefix = $self->config->redis->prefix;
    my $p_key = $key;
    if($key !~ m/^\Q$prefix\E/) {
        $p_key = $prefix . $key;
    }

    return $p_key;
}

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    $self->redis_cluster->set($self->_key($key), $self->_encrypt($value));
}

sub get {
    my $self = shift;
    my $key = shift;

    return $self->_decrypt($self->redis_cluster->get($self->_key($key)));
}

sub del {
    my $self = shift;
    my $key = shift;

    $self->redis_cluster->del($self->_key($key));
}

sub setnx {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->redis_cluster->setnx($self->_key($key), $self->_encrypt($value));
}

sub publish {
    my $self = shift;
    my $channel = shift;
    my $message = shift;

    $self->redis_cluster->publish($channel, $self->_encrypt($message));
}

sub subscribe {
    my $self = shift;
    my @args = @_;

    my @channels = @args[0..$#args-1];
    my $sub = $args[-1];
    
    $self->redis_cluster->subscribe(
        @channels,
        sub {
            my ($message, $topic, $subscribed_topic) = @_;
            my $dec_message = $self->_decrypt($message);
            $sub->($dec_message, $topic, $subscribed_topic);
        }
    );
}

sub wait_for_messages { shift->redis_cluster->wait_for_messages(@_); }

sub keys {
    my $self = shift;
    my $lookup = shift;

    my @ret;

    for my $redis ($self->redis_nodes->@*) {
        push @ret, $redis->keys($self->_key($lookup));
    }

    return @ret;
}

1;
