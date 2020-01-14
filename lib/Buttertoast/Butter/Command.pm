#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::Command;

use Moose;

has butter => (is => 'ro');

sub need_placement { 0; }
sub on_master { 0; };
sub on_all { 0; }

1;
