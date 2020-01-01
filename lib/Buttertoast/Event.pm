#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Event;

use Moose;
use JSON::XS;

has payload => (
    is => 'rw',
);

sub to_string {
    my $self = shift;

    my $klass = ref $self;
    my ($event_name) = ($klass =~ m/^.*:([^:]+)$/);
    
    return encode_json({
        type => uc($event_name),
        payload => $self->payload
    });
}

1;
