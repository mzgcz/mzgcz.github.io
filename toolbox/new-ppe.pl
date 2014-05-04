#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Parser;

# 解析POD文档，生成相应的html格式
package PPE;
our @ISA = qw(Pod::Parser);

my %article;
my @array;

# 将command分为两类：1. 独立的， 2. 成对的
# 独立的：直接将类型入栈
# 成对的：将类型和开闭标签入栈

# head1为标题，head2为子标题，item为列表

# 支持head1，head2，item
sub command {
  my ($parser, $command, $paragraph, $line_num) = @_;

  my $expansion = $parser->interpolate($paragraph, $line_num);
  if ($command eq 'head1') {
    push @array, 'title';
  } elsif ($command eq 'head2') {
    push @array, 'heading';
  } elsif ($command eq 'item') {
    push @array, 'item';
  } elsif ($command eq 'over') {
    push @array, 'over';
  } elsif ($command eq 'back') {
    push @array, 'back';
  } else {
    print "command -->".$command."-->".$expansion."\n";
  }
}

# 支持 L<A|B>表示A为链接名，B为链接地址
sub interior_sequence {
  my ($parser, $seq_command, $seq_argument) = @_;
  if ($seq_command eq 'L') {
    if ($seq_argument =~ /(.+?)\|(.+)/) {
      return qq(<a href="$2">$1</a>);
    }
  }
}

# 支持多段普通文本和html文本
sub textblock {
  my ($parser, $paragraph, $line_num) = @_;

  my $expansion = $parser->interpolate($paragraph, $line_num);
  push @array, "paragraph";
}

# 

package main;

my ($pod_file) = @ARGV;

my $parser = new PPE();
$parser->parse_from_file($pod_file);

foreach my $item (@array) {
  print $item."\n";
}
