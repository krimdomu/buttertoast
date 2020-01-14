#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Driver::Docker::Command::Stop;

use Moose;
use Data::Dumper;
use Capture::Tiny 'capture';
use JSON::XS;

sub execute {
    my $self = shift;
    my %data = (@_);

    print "[|]\tstopping docker container...\n";

    my ($out, $err, @result) = capture {
        system "docker", "stop", $data{id};
    };

    if ($result[0] != 0) {
        print "[!]\tError running docker stop command. Do you have permission to access docker?\n$out\n$err\n";
        return { ok => 0};
    }

    return {
        ok => 1,
    };
}

1;
