package WWW::SmartSheet::Sheet;
use Moo;
use MooX::late;

has accessLevel => (is => 'ro');
has columns     => (is => 'ro', isa => 'ArrayRef');
has id          => (is => 'ro');
has name        => (is => 'ro');
has permalink   => (is => 'ro');

1;

