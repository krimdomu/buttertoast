#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Command::List;

use Moose;
use Data::Dumper;
use Module::Load;

extends qw/Buttertoast::Butter::Command/;

override on_master => sub { 1; };

sub execute_master {
    my $self = shift;

    my $prefix = $self->butter->config->redis->prefix;

    my @keys = $self->butter->redis_rw->keys("service:*:name");
    my @services = ();

    for my $name_key (@keys) {
        my ($uuid) = ($name_key =~ m/^\Q$prefix\E[^:]+:([^:]+):.*$/);
        my $base_key = "service:$uuid";

        push @services, {
            id => $uuid,
            name => $self->butter->redis_rw->get("$base_key:name"),
            count => $self->butter->redis_rw->get("$base_key:count"),
        }
    }

    return \@services;
}

1;
