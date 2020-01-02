#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Config::HAProxy;

use Moose;

has config_file => (
    is => 'rw',
    default => sub { "/tmp/haproxy.conf" }
);

1;
