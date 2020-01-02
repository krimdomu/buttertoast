#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Config;

use YAML;
use Moose;
use Data::Dumper;

use Buttertoast::Butter::Config::Docker;
use Buttertoast::Butter::Config::HAProxy;
use Buttertoast::Butter::Config::Redis;

has docker => (
    is => 'rw',
    isa => 'Buttertoast::Butter::Config::Docker',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::Butter::Config::Docker->new(%{ $self->config_ref->{docker} });
    },
);

has redis => (
    is => 'rw',
    isa => 'Buttertoast::Butter::Config::Redis',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::Butter::Config::Redis->new(%{ $self->config_ref->{redis} });
    },
);


has haproxy => (
    is => 'rw',
    isa => 'Buttertoast::Butter::Config::HAProxy',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::Butter::Config::HAProxy->new(%{ $self->config_ref->{haproxy} });
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

has config_ref => (
    is => 'ro',
    writer => '_config_ref',
    default => sub {{}}
);

sub BUILD {
    my $self = shift;

    if(-f "config/butter.yml") {
        my $ref = YAML::LoadFile("config/butter.yml");
        $self->_config_ref($ref);
    }
    else {
        print "[!] no configuration file found for butter.\n";
    }
}

1;
