#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade::Config::Nginx;

use Moose;

has config_path => (
    is => 'rw',
    default => sub { "/tmp/" },
);

1;
