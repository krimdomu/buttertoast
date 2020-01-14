#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Driver::Docker::Command::Remove;

use Moose;
use Data::Dumper;
use Capture::Tiny 'capture';
use JSON::XS;

sub execute {
    my $self = shift;
    my %data = (@_);

    print "[|]\t\removing docker container...\n";

    my ($out, $err, @result) = capture {
        system "docker", "rm", "-f", "vessel__$data{name}-$data{count}";
    };

    if ($result[0] != 0) {
        print "[!]\t\tError running docker rm command. Do you have permission to access docker?\n$out\n$err\n";
        return { ok => 0};
    }

    return {
        ok => 1,
    };
}

1;
