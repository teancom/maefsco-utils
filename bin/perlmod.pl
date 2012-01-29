#!/usr/bin/env perl

use strict;
use warnings;
use CPAN;
use LWP::Simple qw(!get);
use File::Path 'make_path';
use File::Path::Expand;

my $num_args = $#ARGV + 1;
if ($num_args != 1) {
  print "\nUsage: perlmod.pl <modulename>\n";
  exit;
}

my $module = $ARGV[0];
if ( $module =~ m/-/ ) warn "WARNING: you need to pass in module names using Foo::Bar, not Foo-Bar. Continuing anyway.\n";
my $mod = CPAN::Shell->expand( 'Module', $module);
my $ver = $mod->cpan_version();
my $desc = $mod->description() . "... is what CPAN says, anyways.";
my $id = "http://search.cpan.org/CPAN/authors/id/" . $mod->cpan_file();
my $dslip = CPAN::Shell->expand("Module", "CPAN")->dslip_status();
my $arch = $dslip->{L};
my @temp = split('/', $id);
my $srcfile = $temp[-1];

# Must be done after CPAN::Shell->expand and before any file operations
$module =~ s/::/-/g;

my $srcdir = expand_filename("~/rpm/SOURCES/perl-${module}");
unless (-d $srcdir) {
    make_path($srcdir) or die "Couldn't make directory: $!";
}

getstore($id, "$srcdir/$srcfile");

my $forig;
if ($arch eq "p") {
    $forig = expand_filename("~/rpm/SPECS/perl-template-noarch.spec");
} else {
    $forig = expand_filename("~/rpm/SPECS/perl-template-arch.spec");
}
my $copy = expand_filename("~/rpm/SPECS/perl-$module.spec");
my $orig;
{
    local $/ = undef;
    open TEMPLATE, "<", "$forig" or die $!;
    $orig = <TEMPLATE>;
    close TEMPLATE;
}

my $date = `date '+%a %b %d %Y'`;
chomp($date);
$orig =~ s/!!NAME!!/$module/g;
$orig =~ s/!!VER!!/$ver/g;
$orig =~ s/!!SUMMARY!!/$desc/g;
$orig =~ s/!!DATE!!/$date/g;

open SPEC, ">", "$copy" or die $!;

print SPEC $orig;
close SPEC;
