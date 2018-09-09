=pod
CgiDecode.pm

Copyright (c) [2018] [code-notes.com]

This software is released under the MIT License.
http://opensource.org/licenses/mit-license.php
=cut

our(%_GET,%_POST,%_COOKIE,@_FILES);

package CgiDecode;

use strict;
use warnings;

use File::Temp qw/ tempfile /;

sub new {

	my $class = shift;

	if ($ENV{'REQUEST_METHOD'} eq 'POST') {

		if ($ENV{'CONTENT_TYPE'} =~ m/multipart\/form-data; boundary=(.+)/) {

			my $b = $1;
			%_POST = _multipart(\$b);

		} else {

			my $buf = <STDIN>;
			%_POST = _decode(\$buf);
		}
	}

	%_GET = _decode(\$ENV{'QUERY_STRING'});
	%_COOKIE = _decode(\$ENV{'HTTP_COOKIE'},'; ');

	return bless {}, $class;
}

sub _decode {

	my $buf = shift;
	my $de = shift;
	my %h = ();

	return %h unless defined $$buf;
	$de = '&' unless defined $de;

	my $r = qr/%([a-fA-F0-9][a-fA-F0-9])/;

	foreach (split(/$de/, $$buf)) {

		my($key, $val) = split /=/;

		$val = '' unless defined $val;

		$key =~ tr/+/ /;
		$key =~ s/$r/pack('H2',$1)/eg;

		$val =~ tr/+/ /;
		$val =~ s/$r/pack('H2',$1)/eg;

		_setHash(\$key,\$val,\%h);
	}

	return %h;
}

sub _setHash {

	my($key,$val,$h) = @_;


	if (exists $h->{$$key}) {

		if (ref $h->{$$key} eq 'ARRAY') {

			push @{$h->{$$key}}, $$val;

		} else {

			my @a = ($h->{$$key}, $$val);
			$h->{$$key} = \@a;
		}
 
	} else {

		$h->{$$key} = $$val;
	}
}

sub _multipart {

	my $bound = shift;

	my($key,$val,$file,$type) = ('','','','');
	my %h = ();
	my @f = ();
	my $rec = 0;

	my $r1 = qr/$$bound/;
	my $r2 = qr/\r\n$/;
	my $r3 = qr/Content-Disposition: form-data; name="([^"]+)"; filename="([^"]+)"/;
	my $r4 = qr/Content-Disposition: form-data; name="([^"]+)"/;
	my $r5 = qr/Content-Type: (.+)/;
	my $r6 = qr/^\r\n$/;

	while (<STDIN>) {

		if (m/$r1/) {

			if ($key ne '') {

				$val =~ s/$r2//;

				if ($file ne '') {

					my($fp, $fname) = tempfile( UNLINK => 0 );
					print $fp $val;

					my %f = ('name'=>$key,'up_name'=>$file,'type'=>$type,'tmp_name'=>$fname);
					push @f, \%f;

					$file = '';
					$type = '';

				} else {

					_setHash(\$key,\$val,\%h);
				}
				$key = '';
				$val = '';
			}
			$rec = 0;

		} elsif($rec==1) {

			$val .= $_;

		} elsif(m/$r3/) {

			$key = $1;
			$file = $2;

		} elsif(m/$r4/) {

			$key = $1;

		} elsif(m/$r5/) {

			$type = $1;

		} elsif($rec==0 && m/$r6/) {

			$rec = 1;
		}
	}
	@_FILES = @f;

	return %h;
}

sub move {

	my $self = shift;
	my $f = shift;
	my $name = shift;

	if (!exists $f->{'tmp_name'} || $name eq '') {

		return 0;
	}

	if (open TMP, '<'.$f->{'tmp_name'}) {

		if (open DAT, '>'.$name) {

			print DAT do { local $/;<TMP> };
			close DAT;

			close TMP;
			unlink $f->{'tmp_name'};

			return $name;
		}
	}

	return 0;
}

sub clear {

	my $self = shift;

	foreach(@_FILES){

		unlink $_->{'tmp_name'} if -f $_->{'tmp_name'};
	}
}

sub DESTROY {

	my $self = shift;

	$self->clear();
}

1;
