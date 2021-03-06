#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Command::Stop;

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

    $self->butter->redis_rw->set("$key_base:enabled", "false");

    return {ok => 1};
}

sub execute_all {
    my $self = shift;
    my $uuid = shift;

    my $driver = $self->butter->driver;

    my $list_mod_to_load = "Buttertoast::Butter::Driver::${driver}::Command::List";
    load $list_mod_to_load;
    my $stop_mod_to_load = "Buttertoast::Butter::Driver::${driver}::Command::Stop";
    load $stop_mod_to_load;

    my $list_o = $list_mod_to_load->new(butter => $self->butter);
    my $stop_o = $stop_mod_to_load->new(butter => $self->butter);

    my $data = $list_o->execute();

    for my $container ($data->@*) {
        if($container->{labels} =~ m/butter.id=\Q$uuid\E/) {
            $stop_o->execute(id => $container->{id});
        }
    }
}

1;
