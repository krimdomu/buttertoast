package Buttertoast::Toast;

use Moose;

use Mojolicious;

use Buttertoast::RedisProxy;

use Buttertoast::Toast::Config;

use Buttertoast::Toast::App;
use Buttertoast::Toast::Root;

has app => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Mojolicious->new;
    },
);

has routes => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->app->routes;
    }
);

has config => (
    is => 'rw',
    lazy => 1,
    default => sub {
        Buttertoast::Toast::Config->new;
    }
);

has redis_rw => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::RedisProxy->new(config => $self->config);
    }
);

has redis_sub => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::RedisProxy->new(config => $self->config);
    }
);

has redis_pub => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::RedisProxy->new(config => $self->config);
    }
);

sub configure_routing {
    my $self = shift;

    my $root = Buttertoast::Toast::Root->new(toast => $self);
    $root->setup_routes;

    my $app = Buttertoast::Toast::App->new(toast => $self);
    $app->setup_routes;
}

sub start {
    my $self = shift;

    $self->configure_routing;
    $self->app->start;
}

1;
