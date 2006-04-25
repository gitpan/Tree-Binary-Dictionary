package Tree::Binary::Dictionary;

=head1 NAME

Tree::Binary::Dictionary - A dictionary API to a binary tree

=head1 DESCRIPTION

A simple class to provide a dictionary style API
to a binary tree of data.

This can provide a useful alternative to a long-lived
hash in long running daemons and processes.


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
our $VERSION = 0.03;

use Tree::Binary::Search;
use Tree::Binary::Visitor::InOrderTraversal;

use constant _COUNTER    => 0;
use constant _BTREE      => 1;
use constant _KEYS_VIS   => 2;
use constant _VALUES_VIS => 3 ;
use constant _HASH_VIS   => 4;

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

  my $self = [ 0, $btree, $keys_visitor, $values_visitor, $hash_visitor ];
  return bless $self, ref $class || $class;
}

sub count {
  return shift()->[_COUNTER];
}

sub keys {
  my $self = shift;
  return () unless ($self->[_COUNTER]);
  $self->[_BTREE]->accept($self->[_KEYS_VIS]);
  return $self->[_KEYS_VIS]->getResults();
}

sub values {
  my $self = shift;
  return () unless ($self->[_COUNTER]);
  $self->[_BTREE]->accept($self->[_VALUES_VIS]);
  return $self->[_VALUES_VIS]->getResults();
}

sub to_hash {
  my $self = shift;
  return () unless ($self->[_COUNTER]);
  $self->[_BTREE]->accept($self->[_HASH_VIS]);
  return $self->[_HASH_VIS]->getResults();
}

sub delete {
  my $self = shift;
  return 0 unless ($self->[_COUNTER]);
  my $ok = eval { $self->[_BTREE]->delete(shift()); };
  warn "attempted to delete non-existant key" if $@;
  $self->[_COUNTER]-- unless ($@);
  return $ok || 0;
}

sub exists {
  my $self = shift;
  return 0 unless ($self->[_COUNTER]);
  return $self->[_BTREE]->exists(shift());
}

sub get {
  my $self = shift;
  return 0 unless ($self->[_COUNTER]);
  my $value = eval {$self->[_BTREE]->select(shift()); };
  warn "attempted to get value from non-existant key" if $@;
  return $value;
}

sub add {
  my $self = shift;
  eval { $self->[_BTREE]->insert(@_); };
  if ($@) {
    warn $@;
    return 0;
  } else {
    $self->[_COUNTER]++;
    return 1;
  }
}

sub set {
  my $self = shift;
  if ($self->[_COUNTER] && $self->[_BTREE]->exists($_[0])) {
    eval { $self->[_BTREE]->update(@_); };
  } else {
    eval { $self->[_BTREE]->insert(@_); };
    $self->[_COUNTER]++ unless ($@);
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
