#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Driver::Docker::Command::Resume;

use Moose;
use Data::Dumper;
use Capture::Tiny 'capture';
use JSON::XS;

sub execute {
    my $self = shift;
    my %data = (@_);

    print "[|]\tresuming docker container...\n";

    my ($out, $err, @result) = capture {
        system "docker", "start", $data{id};
    };

    if ($result[0] != 0) {
        print "[!]\tError running docker start command. Do you have permission to access docker?\n$out\n$err\n";
        return { ok => 0};
    }

    my ($out_i, $err_i, @result_i) = capture {
        system "docker", "inspect", $data{id}, "--format", "{{ json . }}";
    };

    if ($result_i[0] != 0) {
        print "[!]\t\tError running docker inspect command. Do you have permission to access docker?\n$out\n$err\n";
        die "Error running docker inspect command. Do you have permission to access docker?\n$out\n$err\n";
    }

    my $ref = decode_json($out_i);

    return {
        ok => 1,
        container_id => $data{id},
        container_ip => $ref->{NetworkSettings}->{IPAddress},
    };
}

1;
