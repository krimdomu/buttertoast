#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Command::List;

use Moose;
use Module::Load;

extends qw/Buttertoast::Command/;

sub need_placement { 0; }

sub execute {
    my $self = shift;

    my @keys = $self->buttertoast->redis_rw->keys("service:*:name");

    my @services = ();

    for my $name_key (@keys) {
        my ($uuid) = ($name_key =~ m/^[^:]+:([^:]+):.*$/);
        my $base_key = "service:$uuid";

        push @services, {
            id => $uuid,
            name => $self->buttertoast->redis_rw->get("$base_key:name"),
            count => $self->buttertoast->redis_rw->get("$base_key:count"),
        }
    }

    return \@services;
}

1;
