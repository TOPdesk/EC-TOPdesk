=head1 NAME

FlowPDF::Helpers

=head1 AUTHOR

CloudBees

=head1 DESCRIPTION

This module provides various static helper functions.

To use them one should explicitly import them.

=head1 METHODS


=head2 trim

=head3 Description

=head3 Parameters

=head3 Usage

%%%LANG=perl%%%

    $str = trim(' hello world ');

%%%LANG%%%



=head2 isWin

=head3 Description

Returns true if we're running on windows system.

=head3 Parameters

=over 4

=item None

=back

=head3 Returns

=over 4

=item (Integer) 1 if FlowPDF is running on windows, 0 otherwise.

=back

=head3 Exceptions

=over 4

=item None

=back

=head3 Usage

%%%LANG=perl%%%

    if (isWin()) {
        print "This feature is not supported under windows.\n";
    }

%%%LANG%%%



=head2 genRandomNumbers

=head3 Description

Generates random numbers using an integer as base. If nothing is passed, 99 will be used as base.

=head3 Parameters

=over 4

=item (Optional)(Integer) - an integer value to be used for random number generation. Can be any integer.

=back

=head3 Returns

=over 4

=item (Integer) A random integer value.

=back

=head3 Exceptions

=over 4

=item None

=back



=head2 bailOut

=head3 Description

Immediately aborts current execution and exits with exit code 1.

This exception can't be handled or catched.

=head3 Parameters

=over 4

=item (Required)(String) An error message to be shown before exiting.

=back

=head3 Returns and Exceptions

=over 4

=item None (this call is fatal).

=back

=head3 Usage

%%%LANG=perl%%%

    bailOut("Something is very wrong");

%%%LANG%%%



=head2 inArray

=head3 Description

Returns 1 if element is present in array. Currently it works only with scalar elements.

=head3 Parameters

=over 4

=item (Required)(Scalar) Element to check it's presence in array.

=item (Required)(Array of scalars) An array of elements where element presence should be checked.

=back

=head3 Returns

=over 4

=item (Scalar) 1 if element is found in array and 0 if not.

=back

=head3 Exceptions

=over 4

=item Missing parameters exception.

=back

=head3 Usage

%%%LANG=perl%%%

    my $elem = 'two';
    my @array = ('one', 'two', 'three');
    if (inArray($elem, @array)) {
        print "$elem is present in array\n";
    }

%%%LANG%%%

=cut

package FlowPDF::Helpers;
use base qw/Exporter/;

use strict;
use warnings;
use Carp;

our @EXPORT_OK = qw/
    trim
    isWin
    genRandomNumbers
    bailOut
    inArray
/;


sub trim {
    my (@params) = @_;

    @params = map {
        s/^\s+//gs;
        s/\s+$//gs;
        $_;
    } @params;

    return wantarray() ? @params : join '', @params;
}


sub isWin {
    if ($^O eq 'MSWin32') {
        return 1;
    }
    return 0;
}


sub genRandomNumbers {
    my ($mod) = @_;

    if (!$mod) {
        $mod = 99;
    }
    my $rand = rand($mod);
    $rand =~ s/\.//s;
    return $rand;
}


sub bailOut {
    my (@messages) = @_;

    my $message = join '', @messages;
    if ($message !~ m/\n$/) {
        $message .= "\n";
    }
    $message = "[BAILED OUT]: $message";
    print $message;
    exit 1;
}


sub inArray {
    my ($elem, @array) = @_;

    if (!defined $elem || !@array) {
        croak "This function takes as parameter an element to search and non-empty array.";
    }
    for my $e (@array) {
        return 1 if $elem eq $e;
    }

    return 0;
}


1;
