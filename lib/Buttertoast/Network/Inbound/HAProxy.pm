#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Network::Inbound::HAProxy;

use Moose;

use Mojo::Template;
use Data::Dumper;

extends qw/Buttertoast::Network::Inbound/;

sub start {
    my $self = shift;
    
}

sub refresh {
    my $self = shift;
    $self->generate_configuration;
    $self->reload;
}

sub generate_configuration {
    my $self = shift;

    my $mt = Mojo::Template->new(vars => 1);
    
    my @container_keys = $self->buttertoast->redis_rw->keys("service:*:*:buttertoast");
    
    my @this_node = grep { $self->buttertoast->redis_rw->get($_) eq $self->buttertoast->client_uuid } @container_keys;
    my $services = {
    };
    for my $c (@this_node) {
        my ($service_uuid, $container_idx) = ($c =~ m/^service:([^:]+):([^:]+):/);
        my $s_name = $self->buttertoast->redis_rw->get("service:$service_uuid:name");

        unless ($services->{$s_name}->{backends}) {
            $services->{$s_name} = {
                backends => [],
            };
        }
        $services->{$s_name}->{public_port} = $self->buttertoast->redis_rw->get("service:$service_uuid:public_port");

        $services->{$s_name}->{backends}->[$container_idx] = {
            ip => $self->buttertoast->redis_rw->get("service:$service_uuid:$container_idx:container_ip"),
            port => $self->buttertoast->redis_rw->get("service:$service_uuid:application_port"),
        };
    }

    my $config_file_content = $mt->render($self->buttertoast->get_file("haproxy/haproxy.conf.ep"), {services => $services});

    open(my $fh, ">", $self->buttertoast->config->haproxy->config_file) or die($!);
    print $fh  $config_file_content;
    close($fh);
}

sub reload {
    my $self = shift;
}

1;
