#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Command::List;

use Moose;
use Module::Load;

extends qw/Buttertoast::Butter::Command/;

sub need_placement { 0; }

sub execute {
    my $self = shift;

    my @keys = $self->butter->redis_rw->keys("service:*:name");

    my @services = ();

    for my $name_key (@keys) {
        my ($uuid) = ($name_key =~ m/^[^:]+:([^:]+):.*$/);
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
