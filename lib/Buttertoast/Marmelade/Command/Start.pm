#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade::Command::Start;

use Moose;
use Mojo::Template;
use Data::Dumper;
use List::Util qw/uniq/;

extends qw/Buttertoast::Marmelade::Command/;

sub execute {
    my $self = shift;
    my $payload = shift;

    my $redis_base = "marmelade:" . $self->marmelade->marmelade_id;
    my $app_key = "$redis_base:app:" . $payload->{id};

    $self->marmelade->redis_rw->set($app_key . ":backend:" . $payload->{count}, $payload->{inbound_ip});

    my @backend_keys = $self->marmelade->redis_rw->keys($app_key . ":backend:*");
    my @backends = ();
    push @backends, $self->marmelade->redis_rw->get($_) for @backend_keys;

    my $vars = {
        $payload->%*,
        backends => [uniq @backends],
    };

    $self->marmelade->ingress->refresh($vars);
}

1;
