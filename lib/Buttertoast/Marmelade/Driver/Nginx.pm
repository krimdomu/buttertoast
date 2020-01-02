package Buttertoast::Marmelade::Driver::Nginx;

use Moose;

has marmelade => (
    is => 'ro',
);

sub start {
    my $self = shift;
    system "nginx";
}

sub reload {
    my $self = shift;
    system "nginx -s reload";
}

sub refresh {
    my $self = shift;
    my $vars = shift;

    my $mt = Mojo::Template->new(vars => 1);

    my $config_file_content = $mt->render($self->marmelade->get_file("nginx/nginx.conf.ep"), $vars);

    open(my $fh, ">", $self->marmelade->config->nginx->config_path .  "/" . $vars->{name} . ".conf") or die($!);
    print $fh  $config_file_content;
    close($fh);

    $self->reload;
}

1;
