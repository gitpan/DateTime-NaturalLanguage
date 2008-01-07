## Luke Hutscal
## Started November 12 2007

## Finished November 13 or so.

## Added display order setting on the 14th. 

package DateTime::NaturalLanguage;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.04';


# Preloaded methods go here.

## These are my local subs
## users should not be able to get at them. 
my $processInterval = sub {
	my $self = shift;
	my($var,$plural,$singular) = @$_;
	if($var > 0) {
		my %entry;
		$entry{value} = $var;
		$entry{word} = $var > 1 ? $self->{$plural} : $self->{$singular};
		return \%entry;
	}
	return undef;
};


sub new {
	my $self = shift;
	my $defaults = {};
	## here we set the default values for our module.
	%$defaults = (
		second 		=> 'second',
		seconds 	=> 'seconds',
		minute 		=> 'minute',
		minutes		=> 'minutes',
		hour 		=> 'hour',
		hours 		=> 'hours',
		day			=> 'day',
		days		=> 'days',
		week 		=> 'week',
		weeks 		=> 'weeks',
		month 		=> 'month',
		months 		=> 'months',
		year 		=> 'year',
		years 		=> 'years',
		display		=> 2,		# This is how many are displayed by default
		order		=> 'desc',	# this is the order things are displayed in
		@_						# load in all the options passed to us
	);
	bless $defaults, $self;
}

sub parse_seconds {
	my $self = shift;
	my $seconds = shift;
	my $display = shift;
	my $parsed;
	my($minutes,$hours,$days,$weeks,$years);
	## We don't have any months because it's harder - 12 months, but 52 weeks makes for 13. See?

	# minutes
	$minutes = int($seconds/60);
	$seconds-=$minutes*60;
	# hours
	$hours = int($minutes/60);
	$minutes-=$hours*60;
	# days
	$days = int($hours/24);
	$hours-=$days*24;
	# weeks
	$weeks = int($days/7);
	$days-=$weeks*7;
	# years
	$years = int($weeks/52);
	$weeks-=$years*52;
	
	my @output;
	
	
	## We add our intervals in this order, so that we can have output show up from largest to smallest.
	my @intervals = (
		[$years,'years','year'],
		[$weeks,'weeks','week'],
		[$days,'days','day'],
		[$hours,'hours','hour'],
		[$minutes,'minutes','minute'],
		[$seconds,'seconds','second'],
	);
	# By default, we're displaying in descending order. However, if the user has specified
	# ascending order, we reverse the order we'll be handling our array in.	
	
	## This is done with a regex so that users can supply "asc", "ascend", "ascending", and still have
	## everything work properly.	
	if ($self->{order} =~ /^asc/) {
		@intervals = reverse @intervals;
	}
	
	# thanks Andrew!
	@output = grep {defined} map { $processInterval->($self,$_) } @intervals;
	
	for(my $i = 0; $i < ($display ? $display : $self->{display}) && $i < @output; $i++) {
		## padding our output
		my $padding = $i > 0 ? ' ' : '';		
		my $ending = ($i < ($display ? ($display-1) : ($self->{display}-1))) && ($i < (@output-1)) ? ',' : '';
		$parsed .= $padding . $output[$i]->{'value'} . ' ' .  $output[$i]->{'word'} . $ending;
	}
	return $parsed;
}



1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DateTime::NaturalLanguage - Perl extension for converting seconds to "natural" time values.

=head1 SYNOPSIS

  use DateTime::NaturalLanguage;
  
  my $foo = DateTime::NaturalLanguage->new();
  print $foo->parse_seconds(60);		# prints "1 minute"
  
  my $bar = DateTime::NaturalLanguage->new(day => 'sleep',days => 'sleeps');
  print $bar->parse_seconds(86400);		# prints "1 sleep"
  print $bar->parse_seconds(86400*2);	# prints "2 sleeps"
  
  my $foobar = DateTime::NaturalLanguage->new(display => 3);
  print $foobar->parse_seconds(3661);	# prints "1 hour, 1 minute, 1 second"
  print $foobar->parse_seconds(3661,2);	# prints "1 hour, 1 minute"

=head1 DESCRIPTION

This module is for converting raw second values(like those returned by localtime()) into fuzzier, more "natural" values - like minutes, hours, and days. It allows you to convert a given number of seconds into a natural value - 3661, for example, becomes something like "1 hour, 1 minute" (or "1 hour, 1 minute, 1 second" if you send a different display value).

This module is licensed under the GPL. See the LICENSE section below for more details.

=head1 METHODS

=head2 new()
	
Call new() to create a new DateTime::NaturalLanguage object:

	my $t = DateTime::NaturalLanguage->new();
	
You can pass values into new() to specify how many items to display after converting a second-value(from largest to smallest), along with substitutions for the words it uses by default. See DEFAULTS for more information on what the default words are.

=head2 parse_seconds()

parse_seconds() takes a seconds value, along with an (optional) display value - which defines how many converted elements to display. It is called on already created DateTime::NaturalLanguage objects.

	my $converted_time = $t->parse_seconds(3661,2);
	
=head1 CONFIGURATION

There are a number of default values that get set when DateTime::NaturalLanguage objects are created - most of them are words. 

=head2 words

The default words that DateTime::NaturalLanguage uses are all english - they are "second,seconds,minute,minutes,hour,hours,day,days,week,weeks,year,years". To change any of them, simply change them in your call to new():

	my $t = DateTime::NaturalLanguage->new(second => "foo", seconds => "bar");
	print $t->parse_seconds(1);		# prints "1 foo"
	print $t->parse_seconds(2);		# prints "2 bar"

=head2 display

The 'display' attribute determines how many elements 'wide' the string returned from parse_seconds() is. Its default is 2, and it can be set either at initialization, or in the call to parse_seconds:

	my $t = DateTime::NaturalLanguage->new(display => 1);
	print $t->parse_seconds(3661);		# prints "1 hour"
	print $t->parse_seconds(3661,2);	# prints "1 hour, 1 minute"
	print $t->parse_seconds(3661,3);	# prints "1 hour, 1 minute, 1 second"

=head2 order

The order attribute defines the order results are displayed in. The default is descending order(largest natural value(years) to smallest(seconds)). However, it can be set to ascending or descending, respectively.It is set at initialization:

	my $t = DateTime::NaturalLanguage->new(order="asc");
	print $t->parse_seconds(3661);		# prints "1 second, 1 hour"
	
	my $t = DateTime::NaturalLanguage->new(order="desc");	# this is default behavior
	print $t->parse_seconds(3661);		# prints "1 hour, 2 minute"

=head1 AUTHOR

Luke Hutscal E<lt>hybrid.basis@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Luke Hutscal E<lt>hybrid.basis@gmail.com<gt>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut