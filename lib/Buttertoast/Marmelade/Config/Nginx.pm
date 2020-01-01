#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Marmelade::Config::Nginx;

use Moose;

has config_file => (
    is => 'rw',
    default => sub { "/tmp/nginx.conf" },
);

1;
