package Buttertoast::Toast::Root;

use Moose;

has toast => (
    is => 'rw',
);

sub setup_routes {
    my $self = shift;
    $self->toast->routes->get("/")->to(cb => sub {
        $self->serve_index(@_);
    });
}

sub serve_index {
    my ($self, $c) = @_;
    $c->render(text => "Buttertoast API server!");
}

1;
