#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Command::Start;

use Moose;
use JSON::XS;
use Module::Load;
use Data::Dumper;

use MIME::Base64;

use Mojo::Template;

use File::Basename;
use File::Path qw/make_path/;

use Buttertoast::Event::Start;

extends qw/Buttertoast::Command/;

sub need_placement { 1; }

sub calculate_placement {
    my $self = shift;
    my $id = shift;

    my $count = $self->buttertoast->redis_rw->get("service:$id:count");
    my @cluster_alive = $self->buttertoast->redis_rw->keys("alive:*");

    my @placement_order = $self->buttertoast->placement->calculate;
    
    return @placement_order;
}

sub generate_cluster_command {
    my $self = shift;
    
    my $placement = shift;
    my $id = shift;

    my $count = $self->buttertoast->redis_rw->get("service:$id:count");

    my $cluster_node_idx = -1;
    my @cluster_commands = ();

    for my $i (0 .. $count-1) {
        $cluster_node_idx += 1;
        if( $cluster_node_idx > $#{ $placement }) {
            $cluster_node_idx = 0;
        }
        my $on_node = $placement->[$cluster_node_idx];
        print "[+] executing on node: $on_node\n";
        push @cluster_commands, {
            on_node => $on_node,
            command => "Start",
            arguments => [$id],
            count => $i,
        };
    }

    return @cluster_commands;
}

sub execute {
    my $self = shift;
    my $count = shift;
    my $id = shift;

    my $mt = Mojo::Template->new(vars => 1);

    my $driver = $self->buttertoast->driver;
    my $mod_to_load = "Buttertoast::Driver::${driver}::Command::Start";
    load $mod_to_load;

    my $image = $self->buttertoast->redis_rw->get("service:$id:image");
    my $version = $self->buttertoast->redis_rw->get("service:$id:version");
    my $public = $self->buttertoast->redis_rw->get("service:$id:public");

    my $application_port = $self->buttertoast->redis_rw->get("service:$id:application_port");
    my $application_proto = $self->buttertoast->redis_rw->get("service:$id:application_proto");
    
    my $public_port = $self->buttertoast->redis_rw->get("service:$id:public_port");
    my $inbound_ip = $self->buttertoast->inbound_ip;
    my $name = $self->buttertoast->redis_rw->get("service:$id:name");
    my $type = $self->buttertoast->redis_rw->get("service:$id:type");

    my $environment = decode_json($self->buttertoast->redis_rw->get("service:$id:environment"));
    my $vars = decode_json($self->buttertoast->redis_rw->get("service:$id:vars"));
    my $files = decode_json($self->buttertoast->redis_rw->get("service:$id:files"));

    for my $file (keys $files->%*) {
        my $dir = dirname($file);
        # create directories if not exists
        make_path($dir) unless(-d $dir);

        eval {
            no warnings;
            open(my $fh, ">", $file) or die($!);
            print $fh $mt->render(decode_base64($files->{$file}->{content}), $vars);
            close($fh);

            if($files->{$file}->{mode}) {
                chmod $files->{$file}->{mode}, $file;
            }

            $files->{$file}->{owner} //= -1;
            $files->{$file}->{group} //= -1;

            if($files->{$file}->{owner} || $files->{$file}->{group}) {
                chown $files->{$file}->{owner}, $files->{$file}->{group}, $file;
            }
            use warnings;
            1;
        } or do {
            print "[!] something went wrong with file: $file\n";
        };
    }

    my %more_data = ();
    if($type eq "webservice") {
        $more_data{virtual_host} = $self->buttertoast->redis_rw->get("service:$id:webservice:virtual_host");
        $more_data{virtual_host_aliases} = decode_json($self->buttertoast->redis_rw->get("service:$id:webservice:virtual_host_aliases"));
    }

    my $mod = $mod_to_load->new(buttertoast => $self->buttertoast);

    my $mod_data = $mod->execute(image => $image, version => $version, name => $id, count => $count, environment => $environment);
    $mod_data = {
        id => $id,
        public => $public,
        application_port => $application_port,
        public_port => $public_port,
        inbound_ip => $inbound_ip,
        name => $name,
        application_proto => $application_proto,
        count => $count,
        %{ $mod_data },
        %more_data
    };

    $self->buttertoast->redis_rw->set("service:$id:$count:container_id", $mod_data->{container_id});
    $self->buttertoast->redis_rw->set("service:$id:$count:container_ip", $mod_data->{container_ip});
    $self->buttertoast->redis_rw->set("service:$id:$count:buttertoast", $self->buttertoast->client_uuid);
    $self->buttertoast->redis_rw->set("service:$id:$count:alive", "true");

    $self->buttertoast->send_event(Buttertoast::Event::Start->new(payload => $mod_data));
}

1;
