#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Hypernova::Account;
use Hypernova::Parser;

die "Filename not given or does not exist" unless -e $ARGV[0];

my $filename = $ARGV[0];

my $parser = Hypernova::Parser->new();

$parser->parse_file( $filename );

my $income_csv = $parser->generate_income_csv();
my $expense_csv = $parser->generate_expense_csv();
my $csv = $parser->generate_csv();

print "$csv\n";
