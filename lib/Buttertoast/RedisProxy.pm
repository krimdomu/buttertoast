package Buttertoast::RedisProxy;

use Moose;
use Redis;
use Redis::ClusterRider;

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

sub set { shift->redis_cluster->set(@_); }
sub get { shift->redis_cluster->get(@_); }
sub del { shift->redis_cluster->del(@_); }
sub setnx { shift->redis_cluster->setnx(@_); }
sub publish { shift->redis_cluster->publish(@_); }
sub subscribe { shift->redis_cluster->subscribe(@_); }
sub wait_for_messages { shift->redis_cluster->wait_for_messages(@_); }
sub keys {
    my $self = shift;
    my $keys = shift;

    my @ret;

    for my $redis ($self->redis_nodes->@*) {
        push @ret, $redis->keys($keys);
    }

    return @ret;
}

1;
