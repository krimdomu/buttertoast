#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Driver::Docker::Command::Start;

use Moose;
use Data::Dumper;
use Capture::Tiny 'capture';
use JSON::XS;

sub execute {
    my $self = shift;
    my %data = (@_);

    my ($out_p, $err_p, @result_p) = capture {
        system "docker", "pull", $data{image} . ":" . $data{version};
    };

    if ($result_p[0] != 0) {
        die "Error running docker pull command. Do you have permission to access docker?\n$out_p\n$err_p\n";
    }

    my @env_arr = ();
    for my $env (keys $data{environment}->%*) {
        push @env_arr, "-e", "$env=" . $data{environment}->{$env};
    }

    my ($out, $err, @result) = capture {
        system "docker", "run", "--name", "vessel__$data{name}-$data{count}", @env_arr, "-d", $data{image} . ":" . $data{version};
    };

    chomp $out;
    my $docker_id = $out;

    if ($result[0] != 0) {
        die "Error running docker run command. Do you have permission to access docker?\n$out\n$err\n";
    }

    my ($out_i, $err_i, @result_i) = capture {
        system "docker", "inspect", $docker_id, "--format", "{{ json . }}";
    };

    if ($result_i[0] != 0) {
        die "Error running docker inspect command. Do you have permission to access docker?\n$out\n$err\n";
    }

    my $ref = decode_json($out_i);

    return {
        container_id => $docker_id,
        container_ip => $ref->{NetworkSettings}->{IPAddress},
    };
}

1;
