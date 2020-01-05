#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade::Config;

use YAML;
use Moose;

use UUID::Tiny ':std';

use Buttertoast::Marmelade::Config::Nginx;
use Buttertoast::Marmelade::Config::Redis;

has nginx => (
    is => 'rw',
    isa => 'Buttertoast::Marmelade::Config::Nginx',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::Marmelade::Config::Nginx->new(%{ $self->config_ref->{nginx} });
    },
);

has redis => (
    is => 'rw',
    isa => 'Buttertoast::Marmelade::Config::Redis',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::Marmelade::Config::Buttertoast::RedisProxy->new(%{ $self->config_ref->{redis} });
    },
);

has driver => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->config_ref->{driver} // "Nginx";
    },
);

has id => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->config_ref->{id};
    },
);

has inbound_ip => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->config_ref->{inbound_ip};
    },
);


has placement => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        return $self->config_ref->{placement};
    },
);

has config_ref => (
    is => 'ro',
    writer => '_config_ref',
    default => sub {{}}
);

sub BUILD {
    my $self = shift;

    if(-f "config/marmelade.yml") {
        my $ref = YAML::LoadFile("config/marmelade.yml");
        $self->_config_ref($ref);
    }
    elsif($ENV{MARMELADE_ENV_CONFIG} eq "1") {
        my $config_ref = {
            redis => {
                host => ($ENV{MARMELADE_REDIS_HOST} // "localhost"),
                port => ($ENV{MARMELADE_REDIS_PORT} // "6379"),
            },
            id => ($ENV{MARMELADE_ID} // create_uuid_as_string(UUID_V4)),
            driver => ($ENV{MARMELADE_DRIVER} // "Nginx"),
            nginx => {
                config_path => ($ENV{MARMELADE_NGINX_CONFIG_PATH} // "/etc/nginx/conf.d/"),
            }
        };

        unless($ENV{MARMELADE_ID}) {
            print "[#] The marmelade ID is " . $config_ref->{id} . ". Please provide this ID during next startup via \$ENV{MARMELADE_ID}.\n";
        }

        $self->_config_ref($config_ref);
    }
    else {
        print "[!] no configuration file found for marmelade.\n";
    }
}

1;
