#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Driver::Docker::Command::List;

use Moose;
use Data::Dumper;
use Capture::Tiny 'capture';
use JSON::XS;

sub execute {
    my $self = shift;

    my ($out, $err, @result) = capture {
        system "docker", "ps", "-a", "--format", "{{json . }}";
    };

    if ($result[0] != 0) {
        die "Error running docker ps command. Do you have permission to access docker?\n$out\n$err\n";
    }

    my @data = ();
    for my $line (split(/\n/, $out)) {
        my $ref = decode_json $line;

        # only retun containers managed by butter
        if($ref->{Labels} =~ m/butter\.owner=true/) {
            push @data, {
                id => $ref->{ID},
                image => $ref->{Image},
                labels => $ref->{Labels},
                name => $ref->{Names},
                status => $ref->{Status}
            };
        }
    }

    return \@data;
}

1;
