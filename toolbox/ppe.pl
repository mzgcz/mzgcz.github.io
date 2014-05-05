#!/usr/bin/env perl

# 文档（数据）结构模型
# +---------+
# | article |
# +---------+
#      |
#      v
#  +-------+    +---------+    +---------+
#  | title |--->| section |--->| section |--->...
#  +-------+    +---------+    +---------+
#                    |
#                    v
#          +---------+---------+    +-----------+    +------+
#          | heading | caption |--->| paragraph |--->| list |--->...
#          +---------+---------+    +-----------+    +------+
#                                                        |
#                                                        v
#                                                     +------+    +------+
#                                                     | item |--->| item |--->...
#                                                     +------+    +------+
#                                                        |
#                                                        v
#                                                     +-------+    +------+    +-----------+
#                                                     | entry |--->| list |--->| paragraph |--->...
#                                                     +-------+    +------+    +-----------+

use strict;
use warnings;
use Template;
use Pod::Parser;

# 解析POD文档，生成相应的html格式
package PPE;
our @ISA = qw(Pod::Parser);

my %article;
my @article;
my @list_stack;

# 将command分为两类：1. 独立的， 2. 成对的
sub article_grow {
  my ($type, $content) = @_;
  chomp $content;
  chomp $content;

  if ($type eq 'head1') {
    $article[0] = {title => $content};
  } elsif ($type eq 'head2') {
    my $no = @article;
    my @section;
    if ($content =~ /">(.*?)<\/a>/) {
      $section[0] = {heading => $content,
                     caption => $1};
    } else {
      $section[0] = {heading => $content,
                     caption => $content};
    }
    $article[$no] = {section => \@section};
  } elsif ($type eq 'paragraph') {
    my $item;
    if (@list_stack <= 0) {            # 处于非列表环境
      $item = $article[-1]->{section}; # 最后的section
    } else {                           # 处于列表环境
      $item = $list_stack[-1]->[-1]->{item}; # 最后的item
    }
    my $no = @$item;
    $item->[$no] = {paragraph => $content};
  } elsif ($type eq 'over') {
    my $item;
    if (@list_stack <= 0) {            # 处于非列表环境
      $item = $article[-1]->{section}; # 最后的section
    } else {                           # 处于列表环境
      $item = $list_stack[-1]->[-1]->{item}; # 最后的item
    }
    my @list;
    my $no = @$item;
    $item->[$no] = {list => \@list};
    push @list_stack, \@list;
  } elsif ($type eq 'back') {
    pop @list_stack;
  } elsif ($type eq 'item') {
    my @item;
    my $list = $list_stack[-1]; # push, pop操作的是列表最后一个元素
    my $no = @$list;
    $item[0] = {entry => $content};
    $list->[$no] = {item => \@item};
  } else {
    print "unknown type: $type => $content!\n";
  }
}

sub command {
  my ($parser, $command, $paragraph, $line_num) = @_;

  my $expansion = $parser->interpolate($paragraph, $line_num);
  article_grow($command, $expansion);
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
  article_grow('paragraph', $expansion);
}

package main;

sub get_html_name {
    my $pod_file = shift;

    if ($pod_file =~ /(.*)\.pod/) {
        $1.".html";
    } else {
        die "Not A Pod File Error!\n";
    }
}

my $pod_file = $ARGV[0] || die "No Pod File Error!\n";
my $tt_file = $ARGV[1] || "common.tt";
my $html_file = $ARGV[2] || get_html_name($pod_file);

my $parser = new PPE();
$parser->parse_from_file($pod_file);

# 生成网页
my $home_dir = "/home/mzgcz/game_room/mzgcz.github.io/";
my $tt_path = $home_dir."template/";
my $tt = Template->new({
                        INCLUDE_PATH => $tt_path,
                        INTERPOLATE  => 1,
                       }) || die "$Template::ERROR\n";

$article{article} = \@article;
$tt->process($tt_file, \%article, $html_file) || die $tt->error();


# 数据结构测试
# use Data::Dumper;
# print Dumper \@article;
