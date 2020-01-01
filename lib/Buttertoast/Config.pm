#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Config;

use Moose;

use Buttertoast::Config::Docker;
use Buttertoast::Config::HAProxy;

has docker => (
    is => 'rw',
    isa => 'Buttertoast::Config::Docker',
    default => sub { Buttertoast::Config::Docker->new },
);

has haproxy => (
    is => 'rw',
    isa => 'Buttertoast::Config::HAProxy',
    default => sub { Buttertoast::Config::HAProxy->new },
);

1;
