# upload files to trainingstagebuch.org

package VeloHero;
use strict;
use warnings;
use Carp;
#use LWP::Debug qw/ + +conns/;
use LWP::ConnCache;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

our $velohero_url = 'http://app.velohero.com';

sub new {
	my( $proto, $arg ) = @_;

	bless {
		debug	=> 0,
		debug_data => 0,
		$arg ? %$arg : (),
		ua	=> LWP::UserAgent->new(
			conn_cache	=> LWP::ConnCache->new,
			agent	=> 'VeloHero.pm/0.1',
		),
		session	=> undef,
	}, ref $proto || $proto;
}

sub debug {
	my $self = shift;
	return unless $self->{debug};
	print STDERR "@_\n";
}

sub request {
	my( $self, $path, $query, $body ) = @_;

	my $uri = URI->new( $velohero_url . $path );
	$uri->query_form(
		@$query,
		view	=> 'xml'
	);

	$self->debug( "request uri: ". $uri );

	my $res = $self->{ua}->post( $uri, ( $body
		? ( $body, Content_Type => 'form-data' )
		: () ),
		'Accept'		=> 'application/xml',
		'Accept-Charset'	=> 'utf-8',
	);

	$res->is_success
		or croak "request failed: ". $res->status_line;

	$self->debug( "response status: ", $res->status_line );
	$self->{debug_data} && $self->debug( "response content: ", $res->content );

	my $data = XMLin( $res->content );
	$self->{debug_data} && $self->debug( "response data: ", Dumper( $data ) );

	$data
		or croak "got invalid XML response";

	$data->{error}
		&& croak "request failed: $data->{error}";

	$data;
}

sub srequest {
	my( $self, $path, $query, $body ) = @_;

	# TODO: allow %$param, too
	$self->request( $path, [
		sso	=> $self->session,
		$query ? @$query : (),
	], $body );
}

sub new_session {
	my( $self ) = @_;

	$self->debug( "requesting new SSO session..." );
	my $res = $self->request( '/sso', [
		user	=> $self->{user},
		pass	=> $self->{pass},
	]);

	$res->{session}
		or croak "SSO failed, got no session-ID";

	$self->debug( "got new SSO session ". $res->{session} );

	$res->{session};
}

sub session {
	my( $self ) = @_;

	$self->{session} ||= $self->new_session;
}

############################################################

#sub sport_list {
#	my( $self, $page, $rows ) = @_;
#
#	$self->srequest( '/sports/list', [
#		page	=> $page || 1,
#		rows	=> $rows || 20,
#	]);
#}

############################################################

#sub material_list {
#	my( $self, $page, $rows ) = @_;
#
#	$self->srequest( '/material/list', [
#		page	=> $page || 1,
#		rows	=> $rows || 20,
#	]);
#}

############################################################

#sub zone_list {
#	my( $self, $page, $rows ) = @_;
#
#	$self->srequest( '/zones/list', [
#		page	=> $page || 1,
#		rows	=> $rows || 20,
#	]);
#}

############################################################

#sub workout_list {
#	my( $self, $page, $rows ) = @_;
#
#	$self->srequest( '/workouts/list', [
#		page	=> $page || 1,
#		rows	=> $rows || 20,
#	]);
#}

#sub workout_get {
#	my( $self, $id ) = @_;
#
#	$self->srequest( '/workouts/show/'. $id );
#}

#sub workout_set {
#	my( $self, $id, $param ) = @_;
#
#	$self->srequest( '/workouts/edit/'. $id, $param );
#}

sub file_upload {
	my( $self, $file ) = @_;

	$self->session;

	my $limit =  16 * 1024 * 1024;

	my $size = (stat($file))[7]
		or croak "no/empty file: $file";

	$self->debug( "file size: $size, limit: $limit" );
	$size < $limit
		or croak "file too large, $size > $limit: $file";

	my $res = $self->srequest( '/upload/file', [], [
		upload_submit	=> 'hrm',
		file		=> [$file],
	] );

	$self->debug( "saved as workout ". ($res->{id}||'-') );
	$res->{id};
}

1;
