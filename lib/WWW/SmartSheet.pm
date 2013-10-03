package WWW::SmartSheet;
use Moo;
use MooX::late;

use LWP::UserAgent;
use JSON qw(from_json to_json);
use Data::Dumper qw(Dumper);

has token => (is => 'ro', required => 1);

has sheets => (is => 'rw', isa => 'ArrayRef');

my $API_URL = "https://api.smartsheet.com/1.1";
my @ACCESS_LEVELS = qw(VIEWER EDITOR EDITOR_SHARE ADMIN);

sub ua {
	my ($self) = @_;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->default_header("Authorization" => "Bearer " . $self->token);
	return $ua;
}

=head2 get_sheets

=cut

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

  $w->create_sheet(
    name    => 'Name of the sheet',
	columns =>  [

        { title => "Baked Good", type => 'TEXT_NUMBER', primary => 1 },
    	{ title => "Baker",      type => 'CONTACT_LIST' },
        { title => 'Price Per Item', type => 'TEXT_NUMBER' },
        { title => "Gluten Free?", "type":"CHECKBOX", "symbol":"FLAG"},
        { title => 'Status', type => 'PICKLIST', options => ['Started', 'Finished' , 'Delivered'] }
   ]);

=cut

sub create_sheet {
	my ($self, %args) = @_;

	my $url = "$API_URL/sheets";
	my $ua = $self->ua;
	$ua->default_header("Content-Type" => "application/json");
	my $data = to_json(\%args);
	#warn $data;
	#warn Dumper $ua->default_headers;

	my $req = HTTP::Request->new( 'POST', $url );
	$req->content( $data );
	my $res = $ua->request( $req );
	#my $res = $ua->post($url, Content => $data);

	die $res->status_line if not $res->is_success;
	return from_json $res->decoded_content;
}

=head2 add_column

   $w->add_column($sheet_id, { title => 'Delivered', type => 'DATE', index => 5})

=cut

sub add_column {
	my ($self, $sheet_id, $column) = @_;

	my $url = "$API_URL/sheet/$sheet_id/columns";
}

=head2 insert_rows

 =  json.dumps({"toTop":True, "rows":[ {"cells": [ 
												    {"columnId":column_info[0]['id'], "value":"Brownies"},
                                                    {"columnId":column_info[1]['id'], "value":"julieanne@smartsheet.com","strict": False},
                                                    {"columnId":column_info[2]['id'], "value":"$1", "strict":False},
                                                    {"columnId":column_info[3]['id'], "value":True},
                                                    {"columnId":column_info[4]['id'], "value":"Finished"},
                                                    {"columnId":column_info[5]['id'], "value": "None", "strict":False}]
                                                   },
	insert_Rows = Call._raw_request('/sheet/{}/rows'.format(sheet_id), header, row_Insert1)
=cut

sub insert_rows {
	my ($self) = @_;
	#insert_Rows = Call._raw_request('/sheet/{}/rows'.format(sheet_id), header, row_Insert1)
}


1;

