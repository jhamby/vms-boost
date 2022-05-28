#!/usr/bin/perl -w
#
# handlertree.pl
# ~~~~~~~~~~~~~~
# A tool for post-processing the debug output generated by Asio-based programs
# to print the tree of handlers that resulted in some specified handler ids.
# Programs write this output to the standard error stream when compiled with
# the define `BOOST_ASIO_ENABLE_HANDLER_TRACKING'.
#
# Copyright (c) 2003-2020 Christopher M. Kohlhoff (chris at kohlhoff dot com)
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#

use strict;

my %target_handlers = ();
my @cached_output = ();
my %outstanding_handlers = ();
my %running_handlers = ();

#-------------------------------------------------------------------------------
# Build the initial list of target handlers from the command line arguments.

sub build_initial_target_handlers()
{
  for my $handler (@ARGV)
  {
    $target_handlers{$handler} = 1;
  }
}

#-------------------------------------------------------------------------------
# Parse the debugging output and cache the handler tracking lines.

sub parse_debug_output()
{
  while (my $line = <STDIN>)
  {
    chomp($line);

    if ($line =~ /\@asio\|([^|]*)\|([^|]*)\|(.*)$/)
    {
      push(@cached_output, $line);
    }
  }
}

#-------------------------------------------------------------------------------
# Iterate over the cached output in revese and build a hash of all target
# handlers' ancestors.

sub build_target_handler_tree()
{
  my $i = scalar(@cached_output) - 1;
  while ($i >= 0)
  {
    my $line = $cached_output[$i];

    if ($line =~ /\@asio\|([^|]*)\|([^|]*)\|(.*)$/)
    {
      my $action = $2;

      # Handler creation.
      if ($action =~ /^([0-9]+)\*([0-9]+)$/)
      {
        if ($1 ne "0" and exists($target_handlers{$2}))
        {
          $target_handlers{$1} = 1;
        }
      }
    }

    --$i;
  }
}

#-------------------------------------------------------------------------------
# Print out all handler tracking records associated with the target handlers.

sub print_target_handler_records()
{
  for my $line (@cached_output)
  {
    if ($line =~ /\@asio\|([^|]*)\|([^|]*)\|(.*)$/)
    {
      my $action = $2;

      # Handler location.
      if ($action =~ /^([0-9]+)\^([0-9]+)$/)
      {
        print("$line\n") if ($1 eq "0" or exists($target_handlers{$1})) and exists($target_handlers{$2});
      }

      # Handler creation.
      if ($action =~ /^([0-9]+)\*([0-9]+)$/)
      {
        print("$1, $2, $line\n") if ($1 eq "0" or exists($target_handlers{$1})) and exists($target_handlers{$2});
      }

      # Begin handler invocation. 
      elsif ($action =~ /^>([0-9]+)$/)
      {
        print("$line\n") if (exists($target_handlers{$1}));
      }

      # End handler invocation.
      elsif ($action =~ /^<([0-9]+)$/)
      {
        print("$line\n") if (exists($target_handlers{$1}));
      }

      # Handler threw exception.
      elsif ($action =~ /^!([0-9]+)$/)
      {
        print("$line\n") if (exists($target_handlers{$1}));
      }

      # Handler was destroyed without being invoked.
      elsif ($action =~ /^~([0-9]+)$/)
      {
        print("$line\n") if (exists($target_handlers{$1}));
      }

      # Operation associated with a handler.
      elsif ($action =~ /^\.([0-9]+)$/)
      {
        print("$line\n") if (exists($target_handlers{$1}));
      }
    }
  }
}

#-------------------------------------------------------------------------------

build_initial_target_handlers();
parse_debug_output();
build_target_handler_tree();
print_target_handler_records();
