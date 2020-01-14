#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Placement::Simple;

use List::Util qw/uniq/;
use Moose;
use Data::Dumper;

extends qw/Buttertoast::Butter::Placement/;

sub calculate {
    my $self = shift;
    
    my $prefix = $self->butter->config->redis->prefix;

    print "[|]\tinspecting placements\n";

    my @keys = uniq $self->butter->redis_rw->keys('metric:*:memory');

    print Dumper \@keys;
    
    my @all_data = ();

    for my $k (@keys) {
        my ($uuid) = ($k =~ m/^\Q$prefix\Emetric:([^:]+):.*/);

        push @all_data, {
            node => $uuid,
            value => $self->butter->redis_rw->get($k),
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
