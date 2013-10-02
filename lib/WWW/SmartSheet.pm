package WWW::SmartSheet;
use Moo;
use MooX::late;

use LWP::UserAgent;
use JSON qw(from_json);

has token => (is => 'ro', required => 1);

has sheets => (is => 'rw', isa => 'ArrayRef');

my $API_URL = "https://api.smartsheet.com/1.1";
my @ACCESS_LEVELS = qw(VIEWER EDITOR EDITOR_SHARE ADMIN);

sub ua {
	my ($self) = @_;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->default_header("Authorization" => " Bearer " . $self->token);
	return $ua;
}

sub get_sheets {
	my ($self) = @_;

	my $sheet_URL = "$API_URL/sheets";
	my $res = $self->ua->get($sheet_URL);
	die $res->status_line if not $res->is_success;

	my $all_sheets = from_json $res->decoded_content;

	$self->sheets($all_sheets);
	return $all_sheets;
}


=head2 get_columns

Given the number of the sheet, returns an array of the column definitions each column is a hash:
  title
  type (TEXT_NUMBER, PICKLIST, ... )
  index
  id
  primary ??
  options (for PICKLIST)
  

Probably it should be the name of the sheet.

=cut

# TODO how can I make sure that get_sheet is called if sheets is empty ? is that the lazy attribute?
sub get_columns {
	my ($self, $sheet_number) = @_;
	
	my $sheets = $self->sheets;
	my $res = $self->ua->get("$API_URL/sheet/$sheets->[$sheet_number]{id}/columns");
	die $res->status_line if not $res->is_success;
	return from_json $res->decoded_content;
}

=head2 share_sheet

  sheet_id
  email => 'foo@examples.com',
  access_level => one of the following strings: VIEWER EDITOR EDITOR_SHARE ADMIN

=cut

sub share_sheet {
	my ($self, $sheet_id, $email, $access_level) = @_;
	my $url = "$API_URL/sheet/$sheet_id/shares?sendEmail=true";

	my $ua = $self->ua;
	$ua->default_header("Content-Type" => "application/json");
	my $data = to_json({email => $email, accessLevel => $access_level});
	#$ua.add_data(data)
	my $res = $ua->post($url, $data);
	die $res->status_line if not $res->is_success;
	return from_json $res->decoded_content;
}

=head2 create_sheet

=cut

sub create_sheet {
}

1;

