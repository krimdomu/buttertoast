#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade::Command::Die;

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

    $self->marmelade->redis_rw->del("$app_key:backend:" . $payload->{idx});

    my @backend_keys = $self->marmelade->redis_rw->keys($app_key . ":backend:*");
    my @backends = ();
    push @backends, $self->marmelade->redis_rw->get($_) for @backend_keys;

    my $mt = Mojo::Template->new(vars => 1);

    my $vars = {
        $payload->%*,
        backends => [uniq @backends],
    };

    my $config_file_content = $mt->render($self->marmelade->get_file("nginx/nginx.conf.ep"), $vars);

    open(my $fh, ">", $self->marmelade->config->nginx->config_file) or die($!);
    print $fh  $config_file_content;
    close($fh);
}

1;
