#!/usr/bin/perl

use Modern::Perl;

use Data::Dumper;

use Hypernova::Account;
use Hypernova::Parser;

die "Filename not given or does not exist" unless -e $ARGV[0];

my $filename = $ARGV[0];

my $parser = Hypernova::Parser->new();

$parser->parse_file( $filename );

my $incomes = 0;
my $expenses = 0;

foreach my $income ( @{$parser->{data}->{incomes}} ) {
    $incomes += $income->{amount};
}

foreach my $expense ( @{$parser->{data}->{expenses}} ) {
    $expenses += $expense->{amount};
}

warn "incomes: $incomes , expenses: $expenses . total: " . ($incomes-$expenses);

my $csv = $parser->generate_csv();

open(my $fh, '>', "$filename.csv") or die "Could not open file '$filename.csv' $!";
print $fh $csv;
close $fh;
print "done\n";
