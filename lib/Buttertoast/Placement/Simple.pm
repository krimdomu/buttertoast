#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Placement::Simple;

use Moose;

extends qw/Buttertoast::Placement/;

sub calculate {
    my $self = shift;

    my @keys = $self->buttertoast->redis_rw->keys('metric:*:memory');
    my @all_data = ();

    print "[+] inspecting placements\n";
    for my $k (@keys) {
        my ($uuid) = ($k =~ m/^metric:([^:]+):.*/);

        push @all_data, {
            node => $uuid,
            value => $self->buttertoast->redis_rw->get($k),
        };
    }

    print "[|] sorting data...\n";
    my @sorted = sort { $b->{value} <=> $a->{value} } @all_data;

    my @return = ();

    for my $d (@sorted) {
        push @return, $d->{node};
    }

    print "[+] done.\n";

    return @return;
}

1;
