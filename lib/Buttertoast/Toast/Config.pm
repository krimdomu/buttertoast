#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Toast::Config;

use YAML;
use Moose;
use Data::Dumper;

use Buttertoast::Toast::Config::Redis;

has redis => (
    is => 'rw',
    isa => 'Buttertoast::Toast::Config::Redis',
    lazy => 1,
    default => sub {
        my $self = shift;
        Buttertoast::Toast::Config::Redis->new(%{ $self->config_ref->{redis} });
    },
);

has config_ref => (
    is => 'ro',
    writer => '_config_ref',
    default => sub {{}}
);

sub BUILD {
    my $self = shift;

    if(-f "/etc/buttertoast/toast.yml") {
        my $ref = YAML::LoadFile("/etc/buttertoast/toast.yml");
        $self->_config_ref($ref);
    }
    elsif(-f "config/toast.yml") {
        my $ref = YAML::LoadFile("config/toast.yml");
        $self->_config_ref($ref);
    }
    else {
        print "[!] no configuration file found for toast.\n";
    }
}

1;
