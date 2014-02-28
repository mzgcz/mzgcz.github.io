#!/usr/bin/env perl

# @todo
# article, title, sections, heading, caption, paragraphs, list

use strict;
use warnings;
use Template;
use Pod::Parser;

package PPE;
our @ISA = qw(Pod::Parser);

my %article;

sub article_grow {
  my ($type, $content) = @_;

  chomp $content;
  chomp $content;

  if ($type eq "title") {
    $article{"title"} = $content;
  } elsif ($type eq "heading") {
    my $sections = $article{"sections"};
    my $new_no = 0;
    if (defined $sections) {
      $new_no = @$sections;
    }
    $article{"sections"}->[$new_no]->{"heading"} = $content;
    if ($content =~ /">(.*?)<\/a>/) {
      $article{"sections"}->[$new_no]->{"caption"} = $1;
    } else {
      $article{"sections"}->[$new_no]->{"caption"} = $content;
    }
  } elsif ($type eq "paragraph") {
    my $sections = $article{"sections"};
    my $last_no = @$sections-1;
    my $paragraphs = $sections->[$last_no]->{"paragraphs"};
    if (defined $paragraphs) {
      push @$paragraphs, $content;
    } else {
      $article{"sections"}->[$last_no]->{"paragraphs"}->[0] = $content;
    }
  } elsif ($type eq "entry") {
    my $sections = $article{"sections"};
    my $last_no = @$sections-1;
    my $list = $sections->[$last_no]->{"entrys"};
    if (defined $list) {
      push @$list, $content;
    } else {
      $article{"sections"}->[$last_no]->{"entrys"}->[0] = $content;
    }
  }
}

sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;
    # print $paragraph."--".$command."--> 1\n";
    my $expansion = $parser->interpolate($paragraph, $line_num);

    ## Interpret the command and its text; sample actions might be:
    if ($command eq 'head1') {
      article_grow("title", $expansion);
    } elsif ($command eq 'head2') {
      article_grow("heading", $expansion);
    } elsif ($command eq 'item') {
      article_grow("entry", $expansion);
    }
    ## ... other commands and their actions
}

sub verbatim {
    my ($parser, $paragraph, $line_num) = @_;
    # print $paragraph."--> 2\n";
    ## Format verbatim paragraph; sample actions might be:
    my $out_fh = $parser->output_handle();
    # print $out_fh $paragraph;
}

sub textblock {
    my ($parser, $paragraph, $line_num) = @_;
    # print $paragraph."--> 3\n";
    ## Translate/Format this block of text; sample actions might be:

    my $expansion = $parser->interpolate($paragraph, $line_num);

    article_grow("paragraph", $expansion);
}

sub interior_sequence {
    my ($parser, $seq_command, $seq_argument) = @_;
    ## Expand an interior sequence; sample actions might be:
    return "*$seq_argument*"     if ($seq_command eq 'B');
    return "`$seq_argument'"     if ($seq_command eq 'C');
    return "_${seq_argument}_'"  if ($seq_command eq 'I');
    if ($seq_command eq 'L') {
      if ($seq_argument =~ /(.+?)\|(.+)/) {
        return qq(<a href="$2">$1</a>);
      }
    }
    ## ... other sequence commands and their resulting text
}

package main;

my ($pod_file, $tt_file, $html_file) = @ARGV;

my $parser = new PPE();
$parser->parse_from_file($pod_file);

# 生成目标网页
my $tt = Template->new({
                        INCLUDE_PATH => "/home/mzgcz/game_room/mzgcz.github.io/template/",
                        INTERPOLATE  => 1,
                       }) || die "$Template::ERROR\n";

$tt->process($tt_file, \%article, $html_file) || die $tt->error();
