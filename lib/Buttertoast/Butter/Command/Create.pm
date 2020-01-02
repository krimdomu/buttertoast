#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Command::Create;

use Moose;
use JSON::XS;
use Module::Load;
use Data::Dumper;
use UUID::Tiny ':std';

extends qw/Buttertoast::Butter::Command/;

sub need_placement { 0; }

sub execute {
    my $self = shift;
    my $args = shift;

    my $uuid = create_uuid_as_string(UUID_V4);

    my $key_base = "service:$uuid";
    my $name_key = "$key_base:name";
    my $count_key = "$key_base:count";

    $self->butter->redis_rw->set($name_key, $args->{name});
    $self->butter->redis_rw->set($count_key, $args->{count});

    $self->butter->redis_rw->set("$key_base:image", $args->{image});
    $self->butter->redis_rw->set("$key_base:version", $args->{version});
    $self->butter->redis_rw->set("$key_base:command", $args->{command} // "");

    $self->butter->redis_rw->set("$key_base:application_port", $args->{application_port} // "");
    $self->butter->redis_rw->set("$key_base:application_proto", $args->{application_proto} // "");

    $self->butter->redis_rw->set("$key_base:public", $args->{public} // "false");
    $self->butter->redis_rw->set("$key_base:public_port", $args->{public_port} // "");

    $self->butter->redis_rw->set("$key_base:environment", encode_json($args->{environment} // {}));
    $self->butter->redis_rw->set("$key_base:vars", encode_json($args->{vars} // {}));
    $self->butter->redis_rw->set("$key_base:files", encode_json($args->{files} // {}));

    $self->butter->redis_rw->set("$key_base:type", $args->{type} // "unknown");

    if($args->{type} eq "webservice") {
        $self->butter->redis_rw->set("$key_base:webservice:virtual_host", $args->{virtual_host} // "unknown");
        $self->butter->redis_rw->set("$key_base:webservice:virtual_host_aliases", encode_json($args->{virtual_host_aliases} // []));
    }

    return {ok => 1, id => $uuid};
}

1;
