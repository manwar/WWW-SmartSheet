package WWW::SmartSheet;
use Moo;
use MooX::late;

our $VERSION = '0.01';

# Example error message, (status_line and content):
# 400 Bad Request{"errorCode":5026,"message":"Your account has reached the maximum number of sheets allowed for your trial. To save additional sheets, you must upgrade to a paid plan."}

use Carp ();
use Data::Dumper qw(Dumper);
use LWP::UserAgent;
use JSON qw(from_json to_json);

has token => (is => 'ro', required => 1);

has sheets => (is => 'rw', isa => 'ArrayRef');

my $API_URL = "https://api.smartsheet.com/2.0";
my @ACCESS_LEVELS = qw(VIEWER EDITOR EDITOR_SHARE ADMIN);

sub ua {
	my ($self) = @_;

	my $ua = LWP::UserAgent->new( agent => "WWW::SmartSheet v$VERSION https://github.com/szabgab/WWW-SmartSheet" );
	$ua->timeout(10);
	$ua->default_header("Authorization" => "Bearer " . $self->token);
	$ua->default_header("Content-Type" => "application/json");
	return $ua;
}

=head2 get_current_user

   returns a hash of info on the current user

=cut

sub get_current_user {

  my ($self) = @_;

  my $current_user = $self->_get('users/me');
  return $current_user;

}

=head2 get_sheets($pagesize, $page)

optional parameters default to $pagesize=100 and $page=1

sample returned info:
  {
      "pageNumber": 1,
      "pageSize": 100,
      "totalPages": 1,
      "totalCount": 2,
      "data": [
          {
              "accessLevel": "OWNER",
              "id": 4583173393803140,
              "name": "sheet 1",
              "permalink": "https://app.smartsheet.com/b/home?lx=xUefSOIYmn07iJJesvSHCQ",
              "createdAt": "2015-06-05T20:05:29Z",
              "modifiedAt": "2015-06-05T20:05:43Z"
          },
          {
              "accessLevel": "OWNER",
              "id": 2331373580117892,
              "name": "sheet 2",
              "permalink": "https://app.smartsheet.com/b/home?lx=xUefSOIYmn07iJJrthEFTG",
              "createdAt": "2015-06-05T20:05:29Z",
              "modifiedAt": "2015-06-05T20:05:43Z"
          }
      ]
  }

=cut

sub get_sheets {
	my ($self, $pagesize, $page) = @_;

	my $all_sheets = $self->_get("sheets", $pagesize, $page);
	return $all_sheets;
}


=head2 get_columns

http://smartsheet-platform.github.io/api-docs/#get-all-columns
Takes a sheetid and returns "IndexResult Object containing an array of Column Objects"



    Example Response:

{
    "pageNumber": 1,
    "pageSize": 100,
    "totalPages": 1,
    "totalCount": 3,
    "data": [
        {
            "id": 7960873114331012,
            "index": 0,
            "symbol": "STAR",
            "title": "Favorite",
            "type": "CHECKBOX",
            "validation": false
        },
        {
            "id": 642523719853956,
            "index": 1,
            "primary": true,
            "title": "Primary Column",
            "type": "TEXT_NUMBER",
            "validation": false
        },
        {
            "id": 5146123347224452,
            "index": 2,
            "title": "Status",
            "type": "PICKLIST",
            "validation": false
        }
    ]
}

=cut

sub get_columns {
	my ($self, $sheetid, $pagesize, $page) = @_;
	my $cols = $self->_get("sheets/$sheetid/columns", $pagesize, $page);
	return $cols;
}

=head2 share_sheet

  sheet_id
  email => 'foo@examples.com',
  access_level => one of the following strings: VIEWER EDITOR EDITOR_SHARE ADMIN

=cut

sub share_sheet {
	my ($self, $sheet_id, $email, $access_level) = @_;

	$self->_post("sheet/$sheet_id/shares?sendEmail=true", {email => $email, accessLevel => $access_level});
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

	return $self->_post('sheets', \%args);
}

sub delete_sheet {
	my ($self, $id) = @_;
	$self->_delete("sheet/$id");
}

=head2 add_column

   $w->add_column($sheet_id, { title => 'Delivered', type => 'DATE', index => 5})

=cut

sub add_column {
	my ($self, $sheet_id, $column) = @_;

	return $self->_post("sheet/$sheet_id/columns", $column );
}

=head2 insert_rows

    $w->insert_rows($sheet_id,
        {
            toTop => JSON::true,
            rows => [ {
                cells => [
                    {"columnId":column_info[0]['id'], "value":"Brownies"},
                    {"columnId":column_info[1]['id'], "value":"julieanne@smartsheet.com","strict": False},
                    {"columnId":column_info[2]['id'], "value":"$1", "strict":False},
                    {"columnId":column_info[3]['id'], "value":True},
                    {"columnId":column_info[4]['id'], "value":"Finished"},
                    {"columnId":column_info[5]['id'], "value": "None", "strict":False}]
                                                   },
                    ],
        }
      )

=cut

sub insert_rows {
	my ($self, $sheet_id, $rows, %args) = @_;

	my $res = $self->ua->get("$API_URL/sheet/$sheet_id/columns");

	#_post("sheet/$sheet_id/rows", $rows)
}

sub get_sheet_by_id {
	my ($self, $id) = @_;
	my $data = $self->_get("sheet/$id");
	require WWW::SmartSheet::Sheet;
	WWW::SmartSheet::Sheet->new($data);
}

sub _post {
	my ($self, $path, $data) = @_;

	my $url = "$API_URL/$path";
	my $ua = $self->ua;
	my $json = to_json($data);
	#warn $json;
	#warn Dumper $ua->default_headers;

	my $req = HTTP::Request->new( 'POST', $url );
	$req->content( $json );
	my $res = $ua->request( $req );
	#my $res = $ua->post($url, Content => $json);

	Carp::croak $res->status_line . $res->content if not $res->is_success;
	return from_json $res->decoded_content;
}

sub _get {
	my ($self, $path, $pagesize, $page) = @_;

	#use the defaults if no pagesize or page set http://smartsheet-platform.github.io/api-docs/#paging
	if (!$pagesize) { $pagesize = 100;}
	if (!$page) {$page = 1;}

	my $paramstr = "?pageSize=$pagesize&page=$page";
	my $url = "$API_URL/$path$paramstr";

	my $res = $self->ua->get($url);
	Carp::croak $res->status_line . $res->content if not $res->is_success;
	return from_json $res->decoded_content;
}

sub _delete {
	my ($self, $path) = @_;

	my $url = "$API_URL/$path";
	my $res = $self->ua->delete($url);
	Carp::croak $res->status_line . $res->content if not $res->is_success;
	return from_json $res->decoded_content;
}


=head1 OTHER

The code of this client is free software.
Access to the services of L<Smartsheet|http://www.smartsheet.com/> requires registration and payment.

L<API Documentation|http://smartsheet-platform.github.io/api-docs/>

=cut



1;

