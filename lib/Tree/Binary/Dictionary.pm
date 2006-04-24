package Tree::Binary::Dictionary;

=head1 NAME

Schedule::Chronic::Distributed - Constrained Distributed Scheduler for Perl

=head1 SYNOPSIS

  use Schedule::Chronic::Distributed;

=head1 DESCRIPTION

Class representing main scheduler. Used by daemon to schedule jobs, interacts
with all the objects in the system.

=head1 SYNOPSIS

use Tree::Binary::Dictionary;

my $dictionary = Tree::Binary::Dictionary->new;

# populate
$dictionary->add(aaaa => "One");
$dictionary->add(cccc => "Three");
$dictionary->add(dddd => "Four");
$dictionary->add(eeee => "Five");
$dictionary->add(foo => "Foo");
$dictionary->add(bar => "quuz");

# interact
$dictionary->exists('bar');
$dictionary->get('eeee');
$dictionary->delete('cccc');

# hash stuff
my %hash = $dictionary->to_hash;
my @values = $dictionary->values;
my @keys = $dictionary->keys;


=head1 METHODS

=head2 new - constructor

my $dictionary = Tree::Binary::Dictionary->new;

Instantiates and returns a new dictionary object, doesn't take any arguments.

=head2 add

my $added = $dictionary->add(bar => "quuz");

Adds new key and value in dictionary object, returns true on success, warns and returns 0
on duplicate key or other failure.

=head2 set

my $set = $dictionary->set(bar => 'quuuz');

Sets key and value in dictionary object, returns true on success, 0 on error.

This will add a new key and value if the key is new, or update the value of an existing key

=head2 exists

$dictionary->exists('bar');

=head2 get

my $value = $dictionary->get('eeee');

=head2 delete

my $deleted = $dictionary->delete('cccc');

=head2 to_hash

my %hash = $dictionary->to_hash;

returns a hash populated from the dictionary

=head2 values

my @values = $dictionary->values;

returns dictionary values as an array

=head2 keys

my @keys = $dictionary->keys;

returns dictionary keys as an array

=head2 count

my $count = $dictionary->count

returns the number of entries in the dictionary

=cut

use strict;
our $VERSION = 0.01;

use Tree::Binary::Search;
use Tree::Binary::Visitor::InOrderTraversal;

sub new {
  my ($class,%args) = @_;
  my $btree = Tree::Binary::Search->new();
  $btree->useStringComparison();
  my $hash_visitor = Tree::Binary::Visitor::InOrderTraversal->new();
  $hash_visitor->setNodeFilter(sub {
				 my ($t) = @_;
				 return ($t->getNodeKey, $t->getNodeValue());
			       });
  my $keys_visitor = Tree::Binary::Visitor::InOrderTraversal->new();
  $keys_visitor->setNodeFilter(sub { return shift()->getNodeKey; } );

  my $values_visitor = Tree::Binary::Visitor::InOrderTraversal->new();
  $values_visitor->setNodeFilter(sub { return shift()->getNodeValue; } );

  my $self = { _counter=>0,_btree => $btree, _keys_vis => $keys_visitor, _values_vis => $values_visitor, _hash_vis=>$hash_visitor };
  return bless $self, ref $class || $class;
}

sub count {
  return shift()->{_counter}
}

sub keys {
  my $self = shift;
  return () unless ($self->{_counter});
  $self->{_btree}->accept($self->{_keys_vis});
  return $self->{_keys_vis}->getResults();
}

sub values {
  my $self = shift;
  return () unless ($self->{_counter});
  $self->{_btree}->accept($self->{_values_vis});
  return $self->{_values_vis}->getResults();
}

sub to_hash {
  my $self = shift;
  return () unless ($self->{_counter});
  $self->{_btree}->accept($self->{_hash_vis});
  return $self->{_hash_vis}->getResults();
}

sub delete {
  my $self = shift;
  return 0 unless ($self->{_counter});
  my $ok = eval { $self->{_btree}->delete(shift()); };
  warn "attempted to delete non-existant key" if $@;
  $self->{_counter}-- unless ($@);
  return $ok || 0;
}

sub exists {
  my $self = shift;
  return 0 unless ($self->{_counter});
  return $self->{_btree}->exists(shift());
}

sub get {
  my $self = shift;
  return 0 unless ($self->{_counter});
  my $value = eval {$self->{_btree}->select(shift()); };
  warn "attempted to get value from non-existant key" if $@;
  return $value;
}

sub add {
  my $self = shift;
  eval { $self->{_btree}->insert(@_); };
  if ($@) {
    warn $@;
    return 0;
  } else {
    $self->{_counter}++;
    return 1;
  }
}

sub set {
  my $self = shift;
  if ($self->{_counter} && $self->{_btree}->exists($_[0])) {
    eval { $self->{_btree}->update(@_); };
  } else {
    eval { $self->{_btree}->insert(@_); };
    $self->{_counter}++ unless ($@);
  }
  if ($@) {
    warn $@;
    return 0;
  } else {
    return 1;
  }
}


=head1 SEE ALSO

Tree::Binary

=head1 AUTHOR

aaron trevena, E<lt>teejay@droogs.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut


    1;
