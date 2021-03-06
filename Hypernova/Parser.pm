package Hypernova::Parser;

use strict;
use warnings;

use Text::CSV::Slurp;
use Time::Piece;

use Hypernova::Account;

sub new {
    my ( $class, $row, $params ) = @_;

    my $self = {};

    $self->{data} = {
        accounts => {},
        incomes  => [],
        expenses => [],
    };
    $self->{row} = $row;

    bless $self, $class;
    return $self;
}

sub generate_csv {
    my ( $self ) = @_;

    my @data = (
        @{$self->{data}->{expenses}},
        @{$self->{data}->{incomes}}
    );

    my $csv = $self->_generate_csv( \@data );

    return $csv;
}

sub generate_expense_csv {
    my ( $self ) = @_;

    my $csv = $self->_generate_csv( $self->{data}->{expenses} );

    return $csv;
}

sub generate_income_csv {
    my ( $self ) = @_;

    my $csv = $self->_generate_csv( $self->{data}->{incomes} );

    return $csv;
}

sub _generate_csv {
    my ( $self, $data ) = @_;
    
    my $csv = Text::CSV::Slurp->create(
        input => $data,
        field_order => ['type', 'date', 'amount', 'description'],
        binary => 1
    );

    return $csv;
}

sub is_useless_row {
    my ( $self ) = @_;

    return $self->_should_i_ignore_row( $self->{row} ) ? 0 : 1;
}

sub parse_file {
    my ( $self, $filename ) = @_;

    my $content = `pdftotext -layout $filename -`;

    my $current_account;
    foreach my $row ( split '\n', $content ) {
        chomp $row;
        $self->row( $row );
        next if $self->is_useless_row( $row );

        my $account = Hypernova::Account->new_from_txt_row( $row );
        if ( $account ) {
            $self->{data}->{accounts}->{ $account->{code} } = {
                description => $account->{description}
            };
            $current_account = $account->{code};
            next;
        }

        if ( $current_account >= 3000 && $current_account <= 3380 ) {
            $self->register_income( $row, $current_account );
        } elsif ( $current_account == 6140 || $current_account == 6420
               || $current_account > 20000 ) {
            next;
        } elsif ( $current_account >= 4000 ) {
            $self->register_expense( $row, $current_account );
        }

        next unless $row;
    }
}

sub register_expense {
    my ( $self, $row, $account ) = @_;

    my $date = $self->_get_date( $row );
    my $description = $self->_get_description( $row );
    my $amount = $self->_get_debet( $row );

    unless ( defined $amount ) {
        $amount = $self->_get_credit( $row ) * -1;
        $description = $description . ' (CREDIT NOTE)';
    }

    push @{$self->{data}->{expenses}}, {
        account => $account,
        date => $date,
        description => $description,
        amount => $amount,
        type => 'expense'
    };

    return 1;
}

sub register_income {
    my ( $self, $row, $account ) = @_;

    my $date = $self->_get_date( $row );
    my $description = $self->_get_description( $row );
    my $amount = $self->_get_credit( $row );

    unless ( defined $amount ) {
        $amount = $self->_get_debet( $row ) * -1;
        $description = $description . ' (CREDIT NOTE)';
    }

    push @{$self->{data}->{incomes}}, {
        account => $account,
        date => $date,
        description => $description,
        amount => $amount,
        type => 'income'
    };

    return 1;
}

sub row {
    my ( $self, $row ) = @_;

    $self->{row} = $row if defined $row;
    return $self->{row};
}

sub _convert_to_number {
    my ( $self, $number ) = @_;

    $number =~ s/\s//g;
    $number =~ s/,/./;

    return $number;
}

sub _get_credit {
    my ( $self, $row ) = @_;

    my ( $credet ) = $row =~ /^\s*\d+\s*\d\d\.\d\d\.\d{4}\s*(\d+\s?\d*?,\d\d)\s{1,13}\-?\d/;

    return $self->_convert_to_number( $credet ) if defined $credet;
    return;
}

sub _get_date {
    my ( $self, $row ) = @_;

    my ( $date ) = $row =~ /^\s*\d+\s*(\d\d\.\d\d\.\d{4})/;

    $date = Time::Piece->strptime( $date, '%d.%m.%Y' );
    
    return $date->ymd;
}

sub _get_debet {
    my ( $self, $row ) = @_;

    my ( $debet ) = $row =~ /^\s*\d+\s*\d\d\.\d\d\.\d{4}\s*(\d+\s?\d*?,\d\d)\s{18,}\-?\d/;

    return $self->_convert_to_number( $debet ) if defined $debet;
    return;
}

sub _get_description {
    my ( $self, $row ) = @_;

    my ( $description ) = $row =~ /^\s*\d+\s*\d\d\.\d\d\.\d{4}\s*\d+\s?\d*?,\d\d\s*\-?\d+\s?\d*?,\d\d\s*(.*)$/;

    warn "row is $row" unless $description;
    $row =~ s/(.)/sprintf '%04x', ord $1/seg unless ( $description );
    die map { sprintf '%04X', ord } split //, $row unless $description;
    
    return $description;
}

sub _should_i_ignore_row {
    my ( $self, $row ) = @_;

    if ( $row =~ /^\s*Hypernova Oy/ ) {
        return;
    }

    if ( $row =~ /^\s*2925676\-3/ ) {
        return;
    }

    if ( $row =~ /^\s*Tili/ ) {
        return;
    }

    if ( $row =~ /^\s+$/ ) {
        return;
    }

    if ( $row =~ /^\s*\n$/ ) {
        return;
    }

    if ( $row =~ /^\s*\-?\d+\s*\d*,\d\d\s*\-?\d+\s*\d*,\d\d\s*$/ ) {
        return;
    }

    return $row;
}

1;
