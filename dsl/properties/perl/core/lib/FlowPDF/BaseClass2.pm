=head1 NAME

FlowPDF::BaseClass2;

=head1 AUTHOR

CloudBees

=head1 DESCRIPTION

This class is desined to be the base class for an internal classes of FlowPDF. Using this class gives following benefits:

=over

=item Automatic generation of constructor.

=item Automatic generation of getters/setters.

=item Types validation for setters/constructors.

=item Inheritance support.

=back

=head1 USAGE

To use this class, following 2 conditions should be met.

=over

=item Your class should be inherited from this class.

=item defineClass method should be called.

=back

=head2 defineClass method

defineClass is a method that is being used to generate type checkers, getters, setters and constructor for your class.
This mehod accepts as single parameter a hash reference with where keys are the field names and values are types for these fields.

To get information about type validators see L<FlowPDF::Types> documentation.

Also, note that this class was designed with camelCase in mind, so if you defining field "one" and field twoThree for YourClass,
following getters/setters will be generated alongside with new() function:

=over

=item getOne()

=item setOne()

=item getTwoThree()

=item setTwoThree()

=back

As you see, first letter of field was capitalized, and get/set prepended to this field name.

=head3 Parameters

=over 4

=item (Required)(HASH reference) A hash reference in format field => type.

=back

=head2 Example of a class

Following example demonstrates this approach:

%%%LANG=perl%%%

    package YourClass;
    use base FlowPDF::BaseClass2;
    use strict;
    use warnings;

    # if you're not a perl expert, __PACKAGE__ is a kinda macro,
    # which is being replaced with package name during compile time.
    # so, __PACKAGE__->method() and YourClass->method() are the same calls.
    __PACKAGE__->defineClass({
        one => FlowPDF::Types::Scalar(),
        two => FlowPDF::Types::Reference('HASH')
    });

    1;

%%%LANG%%%

After your class is defined as above, you can use a benefits from this package.

To create an object of YourClass;

%%%LANG=perl%%%

    use YourClass;
    my $o = YourClass->new({
        one => 'hello',
        two => {
            three => 'four'
        }
    });

    print $o->getOne();
    $o->setOne('world');
    print $o->getOne(), "\n";

%%%LANG%%%

=cut

package FlowPDF::BaseClass2;
use strict;
use warnings;
use Data::Dumper;
use Carp;


sub defineClass {
    my ($class, $definitions) = @_;

    for my $k (keys %$definitions) {
        my $field = ucfirst $k;
        my $getter = "get$field";
        my $setter = "set$field";
        my $code = sprintf q|
        *{%s::%s} = sub {
            my ($self) = @_;
            return __get($self, $definitions, $k);
        };
        *{%s::%s} = sub {
            my ($self, $value) = @_;
            return __set($self, $definitions, $k, $value);
        };
|, $class, $getter, $class, $setter;
        # print "Code: $code\n";
        eval $code or do {
            croak "Error during method creation: $!\n";
        };
    }
    return 1;
}


sub __get {
    my ($self, $definitions, $field) = @_;
    if (defined $self->{$field}) {
        return $self->{$field};
    }
    return undef;
}


sub __set {
    my ($self, $definitions, $field, $value) = @_;

    if (ref $definitions->{$field}) {
        my $matcher = $definitions->{$field};
        if (!$matcher->match($value)) {
            if ($matcher->can('describe')) {
                my $msg = sprintf(
                    'Value for %s->{%s} should be: %s, but got: %s',
                    ref $self, $field, $matcher->describe(),
                    ref $value ? Dumper($value) : $value
                );
                croak $msg;
            }
            else {
                croak "Value for $self : $field should be a " . Dumper($matcher) . ", got: " . Dumper($value) . "\n";
            }
        }
    }
    else {
        print "[DEVWARNING] $field from " . ref $self . " does not have proper definition.\n";
    }
    $self->{$field} = $value;
    return $self;
}


sub new {
    my ($class, $opts) = @_;

    my $self = {};
    bless $self, $class;
    for my $k (keys %$opts) {
        my $setter = 'set' . ucfirst($k);
        my $getter = 'get' . ucfirst($k);

        if ($class->can($setter) && $class->can($getter)) {
            $self->$setter($opts->{$k});
        }
        else {
            croak "Field '$k' does not exist and was not defined\n";
        }
    }

    return $self;
}

1;
