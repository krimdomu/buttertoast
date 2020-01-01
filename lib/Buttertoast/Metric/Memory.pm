#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Metric::Memory;

use Moose;
use Capture::Tiny qw'capture';

sub execute {
    my $self = shift;

    my ($out, $err, @result) = capture {
        system "free";
    };

    my ($mem) = grep { m/^Mem:/} split(/\n/, $out);
    my ($_n, $total, $used, $free, $shared, $buff_cache, $avail) = split(/\s+/, $mem);

    return $avail;
}

1;
