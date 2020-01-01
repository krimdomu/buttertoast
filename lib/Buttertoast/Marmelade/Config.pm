#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade::Config;

use Moose;

use Buttertoast::Marmelade::Config::Nginx;

has nginx => (
    is => 'rw',
    isa => 'Buttertoast::Marmelade::Config::Nginx',
    default => sub { Buttertoast::Marmelade::Config::Nginx->new },
);

1;
