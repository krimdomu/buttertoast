#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Config::Docker;

use Moose;

has socket_path => (
    is => 'rw',
    default => sub { '/var/run/docker.sock' }
);

1;
