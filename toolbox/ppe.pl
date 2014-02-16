#! /usr/bin/perl -w

# use strict;
use Pod::Parser;

package PPE;
@ISA = qw(Pod::Parser);

my %article;
my $title;
my %section;
my $head;
my $content;

sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;

    my $expansion = $parser->interpolate($paragraph, $line_num);

    ## Interpret the command and its text; sample actions might be:
    if ($command eq 'head1') {
      $title = $expansion;
      $article{'title'} = $expansion;
    } elsif ($command eq 'head2') {
      $head = $expansion;
      chomp $head;
    }
    ## ... other commands and their actions
}

sub verbatim {
    my ($parser, $paragraph, $line_num) = @_;
    ## Format verbatim paragraph; sample actions might be:
    my $out_fh = $parser->output_handle();
    print $out_fh $paragraph;
}

sub textblock {
    my ($parser, $paragraph, $line_num) = @_;
    ## Translate/Format this block of text; sample actions might be:

    my $expansion = $parser->interpolate($paragraph, $line_num);

    $content = $paragraph;

    chomp $content;

    print $head." => ".$content."\n";
}

sub interior_sequence {
    my ($parser, $seq_command, $seq_argument) = @_;
    ## Expand an interior sequence; sample actions might be:
    return "*$seq_argument*"     if ($seq_command eq 'B');
    return "`$seq_argument'"     if ($seq_command eq 'C');
    return "_${seq_argument}_'"  if ($seq_command eq 'I');
    ## ... other sequence commands and their resulting text
}

package main;

$parser = new PPE();
for (@ARGV) {
  $parser->parse_from_file($_);
}
