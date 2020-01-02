#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Driver::Docker;

use Moose;
use JSON::XS;
use Data::Dumper;

use IO::Socket::UNIX qw( SOCK_STREAM );

use Buttertoast::Butter::Event::Die;

has butter => (
    is => 'ro',
);

sub listen_for_events {
    my $self = shift;

    my $socket = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $self->butter->config->docker->socket_path,
    )
    or die("Can't connect to docker socket: $!\n");

    print $socket "GET /events HTTP/1.1\nHost: localhost\nAccepts: */*\n\n";

    print "[-] Listening for docker events...\n";

    while(my $line = <$socket>) {
        $line =~ s/[\r\n]//gms;
        if($line =~ m/^\{.*\}$/) {
            # should be json

            my $ref = decode_json($line);
            print "[+] docker event: [" . $ref->{Action} . "]\n";
            if($ref->{Action} eq "die") {
                # this is an event when a container dies. so we need to update internal status
                my ($service_uuid, $service_idx) = ($ref->{Actor}->{Attributes}->{name} =~ m/vessel__(.*)\-(\d+)$/);
                $self->butter->redis_rw->set("service:$service_uuid:$service_idx:alive", "false");

                # we only set alive to false. we don't delte the data here
                # we can then restart the service if required iwth all its data available.
                #
                # for ($self->butter->redis_rw->keys("service:$service_uuid:$service_idx:*")) {
                #     print "[|] removing $_\n";
                #     $self->butter->redis_rw->del($_);
                # }

                my $id = $service_uuid;

                my $image = $self->butter->redis_rw->get("service:$id:image");
                my $version = $self->butter->redis_rw->get("service:$id:version");
                my $public = $self->butter->redis_rw->get("service:$id:public");

                my $application_port = $self->butter->redis_rw->get("service:$id:application_port");
                my $application_proto = $self->butter->redis_rw->get("service:$id:application_proto");
                
                my $public_port = $self->butter->redis_rw->get("service:$id:public_port");
                my $inbound_ip = $self->butter->inbound_ip;
                my $name = $self->butter->redis_rw->get("service:$id:name");
                my $type = $self->butter->redis_rw->get("service:$id:type");
                my $count = $self->butter->redis_rw->get("service:$id:count");

                my $environment = decode_json($self->butter->redis_rw->get("service:$id:environment"));
                my $vars = decode_json($self->butter->redis_rw->get("service:$id:vars"));
                my $files = decode_json($self->butter->redis_rw->get("service:$id:files"));

                my %more_data = ();
                if($type eq "webservice") {
                    $more_data{virtual_host} = $self->butter->redis_rw->get("service:$id:webservice:virtual_host");
                    $more_data{virtual_host_aliases} = decode_json($self->butter->redis_rw->get("service:$id:webservice:virtual_host_aliases"));
                }

                my $payload = {
                    idx => $service_idx,
                    id => $service_uuid,
                    public => $public,
                    application_port => $application_port,
                    public_port => $public_port,
                    inbound_ip => $inbound_ip,
                    name => $name,
                    application_proto => $application_proto,
                    count => $count,
                    %more_data
                };

                $self->butter->send_event(Buttertoast::Butter::Event::Die->new(payload => $payload));
                print "[+] cleaned up.\n";
            }
        }
    }
}




1;
