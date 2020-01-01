#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Driver::Docker;

use Moose;
use JSON::XS;
use Data::Dumper;

use IO::Socket::UNIX qw( SOCK_STREAM );

use Buttertoast::Event::Die;

has buttertoast => (
    is => 'ro',
);

sub listen_for_events {
    my $self = shift;

    my $socket = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $self->buttertoast->config->docker->socket_path,
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
                $self->buttertoast->redis_rw->set("service:$service_uuid:$service_idx:alive", "false");

                # we only set alive to false. we don't delte the data here
                # we can then restart the service if required iwth all its data available.
                #
                # for ($self->buttertoast->redis_rw->keys("service:$service_uuid:$service_idx:*")) {
                #     print "[|] removing $_\n";
                #     $self->buttertoast->redis_rw->del($_);
                # }

                my $id = $service_uuid;

                my $image = $self->buttertoast->redis_rw->get("service:$id:image");
                my $version = $self->buttertoast->redis_rw->get("service:$id:version");
                my $public = $self->buttertoast->redis_rw->get("service:$id:public");

                my $application_port = $self->buttertoast->redis_rw->get("service:$id:application_port");
                my $application_proto = $self->buttertoast->redis_rw->get("service:$id:application_proto");
                
                my $public_port = $self->buttertoast->redis_rw->get("service:$id:public_port");
                my $inbound_ip = $self->buttertoast->inbound_ip;
                my $name = $self->buttertoast->redis_rw->get("service:$id:name");
                my $type = $self->buttertoast->redis_rw->get("service:$id:type");
                my $count = $self->buttertoast->redis_rw->get("service:$id:count");

                my $environment = decode_json($self->buttertoast->redis_rw->get("service:$id:environment"));
                my $vars = decode_json($self->buttertoast->redis_rw->get("service:$id:vars"));
                my $files = decode_json($self->buttertoast->redis_rw->get("service:$id:files"));

                my %more_data = ();
                if($type eq "webservice") {
                    $more_data{virtual_host} = $self->buttertoast->redis_rw->get("service:$id:webservice:virtual_host");
                    $more_data{virtual_host_aliases} = decode_json($self->buttertoast->redis_rw->get("service:$id:webservice:virtual_host_aliases"));
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

                $self->buttertoast->send_event(Buttertoast::Event::Die->new(payload => $payload));
                print "[+] cleaned up.\n";
            }
        }
    }
}




1;
