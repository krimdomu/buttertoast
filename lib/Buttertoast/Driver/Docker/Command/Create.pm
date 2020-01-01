#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Driver::Docker::Command::Create;

use Moose;
use Data::Dumper;
use Capture::Tiny 'capture';
use JSON::XS;

sub execute {
    my $self = shift;
    my $args = shift;

    my ($out, $err, @result) = capture {
        system "docker", "create", "-l", "buttertoast.owner=true", $args->{image} . ":" . $args->{version};
    };

    if ($result[0] != 0) {
        die "Error running docker create command. Do you have permission to access docker?\n$out\n$err\n";
    }

    return { id => $out };
}

1;
