#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use WWW::SmartSheet;
use IO::Prompt qw(prompt);
use List::Util qw(min);

my $token   = prompt "Enter Smartsheet API access token: ";
my $w = WWW::SmartSheet->new(token => $token);

my $sheet_name = 'test_' . time;
$w->create_sheet(
    name    => $sheet_name,
	columns =>  [
        { title => "First Col",  type => 'TEXT_NUMBER', primary => JSON::true },
	],
);

#    	{ title => "Second Col", type => 'CONTACT_LIST' },
#        { title => 'Third Col',  type => 'TEXT_NUMBER' },
#        { title => "Fourth Col", type => 'CHECKBOX', symbol => 'FLAG' },
#        { title => 'Status',     type => 'PICKLIST', options => ['Started', 'Finished' , 'Delivered'] }
#   ]);


