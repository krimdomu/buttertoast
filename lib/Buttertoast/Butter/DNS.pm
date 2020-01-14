#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Buttertoast::Butter::DNS;

use Moose;
use Net::DNS::Nameserver;

has butter => (
    is => 'ro',
);

sub dispatch_query {
    my $self = shift;
    my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;

    my $prefix = $self->butter->config->redis->prefix;

    my ( $rcode, @ans, @auth, @add );

    my ($service_name, $dom) = ($qname =~ m/^([^\.]+)\.(.*)$/);

    print "[-] Received query from $peerhost to " . $conn->{sockhost} . " for $service_name ($dom)\n";

    my @service_keys = grep { $self->butter->redis_rw->get($_) eq $service_name } $self->butter->redis_rw->keys("service:*:name");

    if (@service_keys) {
        my ($uuid) = ($service_keys[0] =~ m/^\Q$prefix\E[^:]+:([^:]+):.*$/);

        my $key_base = "service:$uuid";
        my $name_key = "$key_base:name";
        my $count_key = "$key_base:count";

        my $count = $self->butter->redis_rw->get($count_key);

        if($count && $count > 0) {
            if ( $qtype eq "A" && $qname ) {
                for my $i (0..$count-1) {
                    my $ip = $self->butter->redis_rw->get("$key_base:$i:ip");
                    my ( $ttl, $rdata ) = ( 3600, $ip );
                    my $rr = Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
                    push @ans, $rr;
                }
                $rcode = "NOERROR";
            } elsif ( $qname ) {
                $rcode = "NOERROR";
            } else {
                $rcode = "NXDOMAIN";
            }
        }
        else {
            $rcode = "NXDOMAIN";
        }
    }
    else {
        $rcode = "NXDOMAIN";
    }
 
    # mark the answer as authoritative (by setting the 'aa' flag)
    my $headermask = {aa => 1};
 
    # specify EDNS options  { option => value }
    my $optionmask = {};
 
    return ( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask );
}

sub start {
    my $self = shift;
    my $ns = Net::DNS::Nameserver->new(
        LocalPort    => 6000,
        ReplyHandler => sub { $self->dispatch_query(@_); },
        Verbose      => 0
    ) || die "couldn't create nameserver object\n";
 
    print "[-] DNS server is listening on 6000 ...\n";
    $ns->main_loop;
}

1;
