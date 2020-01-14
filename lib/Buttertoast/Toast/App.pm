package Buttertoast::Toast::App;

use Moose;
use JSON::XS;
use UUID::Tiny ':std';

use Data::Dumper;

has toast => (
    is => 'rw',
);

sub setup_routes {
    my $self = shift;

    $self->toast->routes->get("/app")->to(cb => sub {
        $self->list_apps(@_);
    });

    $self->toast->routes->post("/app")->to(cb => sub {
        $self->create_app(@_);
    });

    $self->toast->routes->post("/app/:id/start")->to(cb => sub {
        $self->start_app(@_);
    });

    $self->toast->routes->post("/app/:id/stop")->to(cb => sub {
        $self->stop_app(@_);
    });

    $self->toast->routes->post("/app/:id/remove")->to(cb => sub {
        $self->remove_app(@_);
    });
}

sub list_apps {
    my ($self, $c) = @_;
    $c->render(json => [
        {"name" => "foo"}
    ]);
}

sub create_app {
    my ($self, $c) = @_;

    my $args = $c->req->json;

    my $uuid = create_uuid_as_string(UUID_V4);

    my $key_base = "service:$uuid";
    my $name_key = "$key_base:name";
    my $count_key = "$key_base:count";

    $self->toast->redis_rw->set($name_key, $args->{name});
    $self->toast->redis_rw->set($count_key, $args->{count});

    $self->toast->redis_rw->set("$key_base:image", $args->{image});
    $self->toast->redis_rw->set("$key_base:version", $args->{version});
    $self->toast->redis_rw->set("$key_base:command", $args->{command} // "");

    $self->toast->redis_rw->set("$key_base:application_port", $args->{application_port} // "");
    $self->toast->redis_rw->set("$key_base:application_proto", $args->{application_proto} // "");

    $self->toast->redis_rw->set("$key_base:public", $args->{public} // "false");
    $self->toast->redis_rw->set("$key_base:public_port", $args->{public_port} // "");

    $self->toast->redis_rw->set("$key_base:environment", encode_json($args->{environment} // {}));
    $self->toast->redis_rw->set("$key_base:vars", encode_json($args->{vars} // {}));
    $self->toast->redis_rw->set("$key_base:files", encode_json($args->{files} // {}));
    $self->toast->redis_rw->set("$key_base:volumes", encode_json($args->{volumes} // {}));

    $self->toast->redis_rw->set("$key_base:type", $args->{type} // "unknown");

    if($args->{type} eq "webservice") {
        $self->toast->redis_rw->set("$key_base:webservice:virtual_host", $args->{virtual_host} // "unknown");
        $self->toast->redis_rw->set("$key_base:webservice:virtual_host_aliases", encode_json($args->{virtual_host_aliases} // []));
    }
    
    $c->render(json => {"id" => $uuid});
}

sub start_app {
    my ($self, $c) = @_;

    my $app_id = $c->param("id");

    my $command_uuid = create_uuid_as_string(UUID_V4);
    my $command = {
        rpc => "1.0",
        id => $command_uuid,
        command => "Start",
        arguments => [$app_id],
    };
    $self->toast->redis_pub->publish("vessel_command_comm", encode_json($command));
    
    $c->render(json => {"status" => "queued", id => $command_uuid});
}

sub stop_app {
    my ($self, $c) = @_;

    my $app_id = $c->param("id");

    my $command_uuid = create_uuid_as_string(UUID_V4);
    my $command = {
        rpc => "1.0",
        id => $command_uuid,
        command => "Stop",
        arguments => [$app_id],
    };
    $self->toast->redis_pub->publish("vessel_command_comm", encode_json($command));
    
    $c->render(json => {"status" => "queued", id => $command_uuid});
}

sub remove_app {
    my ($self, $c) = @_;

    my $app_id = $c->param("id");

    my $command_uuid = create_uuid_as_string(UUID_V4);
    my $command = {
        rpc => "1.0",
        id => $command_uuid,
        command => "Remove",
        arguments => [$app_id],
    };
    $self->toast->redis_pub->publish("vessel_command_comm", encode_json($command));

    $c->render(json => {"status" => "queued"});
}


1;
