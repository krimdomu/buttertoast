#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Command::Remove;

use Moose;
use JSON::XS;
use Module::Load;
use Data::Dumper;
use UUID::Tiny ':std';

extends qw/Buttertoast::Butter::Command/;

# override need_placement => sub { 1; };
override on_master => sub { 1; };
override on_all => sub { 1; };

sub execute_master {
    my $self = shift;
    my $uuid = shift;

    my $key_base = "service:$uuid";

    my @all_service_keys = $self->butter->redis_rw->keys($key_base . ":*");
    $self->butter->redis_rw->del($_) for @all_service_keys;

    return {ok => 1};
}

sub execute_all {
    my $self = shift;
    my $uuid = shift;
}

1;
