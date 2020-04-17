package Hypernova::Account;

use Modern::Perl;

sub new {
    my ( $class, $params ) = @_;

    my $self = {};

    $self->{code} = $params->{code};
    $self->{description} = $params->{description};

    bless $self, $class;
    return $self;
}

=head3 new_from_txt_row

my $account = Hypernova::Account->new_from_txt_row( $row );

Parameter C<$row> is expecting format

^(\d+)\s*(.*)

where first match is code, and the second description.

Returns a Hypernova::Account object.

=cut

sub new_from_txt_row {
    my ( $class, $row ) = @_;

    my ( $code, $description ) = $row =~ /^(\d+)\s*(.*)$/;

    return unless $code && $description;
    return $class->new( {
        code => $code,
        description => $description,
    } );
}

sub code {
    return shift->{code};
}

sub description {
    return shift->{description};
}

1;
