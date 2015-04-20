#!/usr/bin/env perl
#
# cjk-gs-integrate - setup ghostscript for CID/TTF CJK fonts
#
# Copyright 2015 by Norbert Preining
#
# Based on research and work by Yusuke Kuroki, Bruno Voisin, Munehiro Yamamoto
# and the TeX Q&A wiki page
#
# This file is licensed under GPL version 3 or any later version.
# For copyright statements see end of file.
#
# For development see
#  https://github.com/norbusan/cjk-gs-support
#
# TODO
# - Morisawa fonts don't work, as he PS name is differernt then the filename
#   needs fixing/script
#

$^W = 1;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use File::Basename;
use strict;

(my $prg = basename($0)) =~ s/\.pl$//;
my $version = '$VER$';

my %encode_list = (
  Japan => [ qw/
    78-EUC-H
    78-EUC-V
    78-H
    78-RKSJ-H
    78-RKSJ-V
    78-V
    78ms-RKSJ-H
    78ms-RKSJ-V
    83pv-RKSJ-H
    90ms-RKSJ-H
    90ms-RKSJ-V
    90msp-RKSJ-H
    90msp-RKSJ-V
    90pv-RKSJ-H
    90pv-RKSJ-V
    Add-H
    Add-RKSJ-H
    Add-RKSJ-V
    Add-V
    Adobe-Japan1-0
    Adobe-Japan1-1
    Adobe-Japan1-2
    Adobe-Japan1-3
    Adobe-Japan1-4
    Adobe-Japan1-5
    Adobe-Japan1-6
    EUC-H
    EUC-V
    Ext-H
    Ext-RKSJ-H
    Ext-RKSJ-V
    Ext-V
    H
    Hankaku
    Hiragana
    Identity-H
    Identity-V
    Katakana
    NWP-H
    NWP-V
    RKSJ-H
    RKSJ-V
    Roman
    UniJIS-UCS2-H
    UniJIS-UCS2-HW-H
    UniJIS-UCS2-HW-V
    UniJIS-UCS2-V
    UniJIS-UTF16-H
    UniJIS-UTF16-V
    UniJIS-UTF32-H
    UniJIS-UTF32-V
    UniJIS-UTF8-H
    UniJIS-UTF8-V
    UniJIS2004-UTF16-H
    UniJIS2004-UTF16-V
    UniJIS2004-UTF32-H
    UniJIS2004-UTF32-V
    UniJIS2004-UTF8-H
    UniJIS2004-UTF8-V
    UniJISPro-UCS2-HW-V
    UniJISPro-UCS2-V
    UniJISPro-UTF8-V
    UniJISX0213-UTF32-H
    UniJISX0213-UTF32-V
    UniJISX02132004-UTF32-H
    UniJISX02132004-UTF32-V
    V
    WP-Symbol/ ],
  GB => [ qw/
    Adobe-GB1-0
    Adobe-GB1-1
    Adobe-GB1-2
    Adobe-GB1-3
    Adobe-GB1-4
    Adobe-GB1-5
    GB-EUC-H
    GB-EUC-V
    GB-H
    GB-RKSJ-H
    GB-V
    GBK-EUC-H
    GBK-EUC-V
    GBK2K-H
    GBK2K-V
    GBKp-EUC-H
    GBKp-EUC-V
    GBT-EUC-H
    GBT-EUC-V
    GBT-H
    GBT-RKSJ-H
    GBT-V
    GBTpc-EUC-H
    GBTpc-EUC-V
    GBpc-EUC-H
    GBpc-EUC-V
    Identity-H
    Identity-V
    UniGB-UCS2-H
    UniGB-UCS2-V
    UniGB-UTF16-H
    UniGB-UTF16-V
    UniGB-UTF32-H
    UniGB-UTF32-V
    UniGB-UTF8-H
    UniGB-UTF8-V/ ],
  CNS => [ qw/
    Adobe-CNS1-0
    Adobe-CNS1-1
    Adobe-CNS1-2
    Adobe-CNS1-3
    Adobe-CNS1-4
    Adobe-CNS1-5
    Adobe-CNS1-6
    B5-H
    B5-V
    B5pc-H
    B5pc-V
    CNS-EUC-H
    CNS-EUC-V
    CNS1-H
    CNS1-V
    CNS2-H
    CNS2-V
    ETHK-B5-H
    ETHK-B5-V
    ETen-B5-H
    ETen-B5-V
    ETenms-B5-H
    ETenms-B5-V
    HKdla-B5-H
    HKdla-B5-V
    HKdlb-B5-H
    HKdlb-B5-V
    HKgccs-B5-H
    HKgccs-B5-V
    HKm314-B5-H
    HKm314-B5-V
    HKm471-B5-H
    HKm471-B5-V
    HKscs-B5-H
    HKscs-B5-V
    Identity-H
    Identity-V
    UniCNS-UCS2-H
    UniCNS-UCS2-V
    UniCNS-UTF16-H
    UniCNS-UTF16-V
    UniCNS-UTF32-H
    UniCNS-UTF32-V
    UniCNS-UTF8-H
    UniCNS-UTF8-V/ ],
  Korea => [ qw/
    Adobe-Korea1-0
    Adobe-Korea1-1
    Adobe-Korea1-2
    Identity-H
    Identity-V
    KSC-EUC-H
    KSC-EUC-V
    KSC-H
    KSC-Johab-H
    KSC-Johab-V
    KSC-RKSJ-H
    KSC-V
    KSCms-UHC-H
    KSCms-UHC-HW-H
    KSCms-UHC-HW-V
    KSCms-UHC-V
    KSCpc-EUC-H
    KSCpc-EUC-V
    UniKS-UCS2-H
    UniKS-UCS2-V
    UniKS-UTF16-H
    UniKS-UTF16-V
    UniKS-UTF32-H
    UniKS-UTF32-V
    UniKS-UTF8-H
    UniKS-UTF8-V/ ] );

my $dry_run = 0;
my $opt_help = 0;
my $opt_quiet = 0;
my $opt_debug = 0;
my $opt_listaliases = 0;
my $opt_listfonts = 0;
my $opt_info = 0;
my $opt_fontdef;
my $opt_output;
my @opt_aliases;

if (! GetOptions(
        "n|dry-run"   => \$dry_run,
        "info"        => \$opt_info,
        "list-aliases" => \$opt_listaliases,
        "list-fonts"  => \$opt_listfonts,
        "o|output=s"  => \$opt_output,
	      "h|help"      => \$opt_help,
        "q|quiet"     => \$opt_quiet,
        "d|debug+"    => \$opt_debug,
        "f|fontdef=s" => \$opt_fontdef,
        "a|alias=s"   => \@opt_aliases,
        "v|version"   => sub { print &version(); exit(0); }, ) ) {
  die "Try \"$0 --help\" for more information.\n";
}

sub win32 { return ($^O=~/^MSWin(32|64)$/i); }
my $nul = (win32() ? 'nul' : '/dev/null') ;
my $sep = (win32() ? ';' : ':');
my %fontdb;
my %aliases;
my %user_aliases;

if ($opt_help) {
  Usage();
  exit 0;
}

if ($opt_debug) {
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
}

main(@ARGV);

#
# only sub definitions from here on
#
sub main {
  print_info("reading font database ...\n");
  read_font_database();
  print_info("checking for files ...\n");
  check_for_files();
  if ($opt_info) {
    $opt_listfonts = 1;
    $opt_listaliases = 1;
  }
  if ($opt_listfonts) {
    info_found_fonts();
  }
  if ($opt_listaliases) {
    print "List of aliases and their options (in decreasing priority):\n";
    my (@jal, @kal, @tal, @sal);
    for my $al (sort keys %aliases) {
      my $cl;
      my @ks = sort { $a <=> $b} keys(%{$aliases{$al}});
      my $foo = "$al:\n";
      for my $p (@ks) {
        my $t = $aliases{$al}{$p};
        my $fn = $fontdb{$t}{'target'};
        # should always be the same ;-)
        $cl = $fontdb{$t}{'class'};
        if ($fontdb{$t}{'type'} eq 'TTF' && $fontdb{$t}{'subfont'} > 0) {
          $fn .= "($fontdb{$t}{'subfont'})";
        }
        $foo .= "\t($p) $aliases{$al}{$p} ($fn)\n";
      }
      if ($cl eq 'Japan') {
        push @jal, $foo;
      } elsif ($cl eq 'Korea') {
        push @kal, $foo;
      } elsif ($cl eq 'GB') {
        push @sal, $foo;
      } elsif ($cl eq 'CNS') {
        push @tal, $foo;
      } else {
        print STDERR "unknown class $cl for $al\n";
      }
    }
    print "Aliases for Japanese fonts:\n", @jal, "\n" if @jal;
    print "Aliases for Korean fonts:\n", @kal, "\n" if @kal;
    print "Aliases for Traditional Chinese fonts:\n", @tal, "\n" if @tal;
    print "Aliases for Simplified Chinese fonts:\n", @sal, "\n" if @sal;
  }
  exit(0) if ($opt_listfonts || $opt_listaliases);

  if (! $opt_output) {
    print_info("searching for GhostScript resource\n");
    my $gsres = find_gs_resource();
    if (!$gsres) {
      print_error("Cannot find GhostScript, terminating!\n");
      exit(1);
    } else {
      $opt_output = $gsres;
    }
  }
  if (! -d $opt_output) {
    $dry_run || mkdir($opt_output) || 
      die ("Cannot create directory $opt_output: $!");
  }
  print_info("output is going to $opt_output\n");
  print_info("generating font snippets and link CID fonts ...\n");
  do_otf_fonts();
  print_info("generating font snippets, links, and cidfmap.local for TTF fonts ...\n");
  do_ttf_fonts();
  print_info("finished\n");
}

sub update_master_cidfmap {
  my $cidfmap_master = "$opt_output/Init/cidfmap";
  my $cidfmap_local = "$opt_output/Init/cidfmap.local";
  if (-r $cidfmap_master) {
    open(FOO, "<", $cidfmap_master) ||
      die ("Cannot open $cidfmap_master for reading: $!");
    my $found = 0;
    while(<FOO>) {
      $found = 1 if
        m/^\s*\(cidfmap\.local\)\s\s*\.runlibfile\s*$/;
    }
    if ($found) {
      print_info("cidfmap.local already loaded in $cidfmap_master, no changes\n");
    } else {
      return if $dry_run;
      open(FOO, ">>", $cidfmap_master) ||
        die ("Cannot open $cidfmap_master for appending: $!");
      print FOO "(cidfmap.local) .runlibfile\n";
      close(FOO);
    }
  } else {
    return if $dry_run;
    open(FOO, ">", $cidfmap_master) ||
      die ("Cannot open $cidfmap_master for writing: $!");
    print FOO "(cidfmap.local) .runlibfile\n";
    close(FOO);
  }
}


sub do_otf_fonts {
  my $fontdest = "$opt_output/Font";
  my $ciddest  = "$opt_output/CIDFont";
  if (-r $fontdest) {
    if (! -d $fontdest) {
      print_error("$fontdest is not a directory, cannot create CID snippets there!\n");
      exit 1;
    }
  } else {
    $dry_run || mkdir($fontdest);
  }
  if (-r $ciddest) {
    if (! -d $ciddest) {
      print_error("$ciddest is not a directory, cannot link CID fonts there!\n");
      exit 1;
    }
  } else {
    $dry_run || mkdir($ciddest);
  }
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'} && $fontdb{$k}{'type'} eq 'CID') {
      generate_font_snippet($fontdest,
        $k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'});
      link_font($fontdb{$k}{'target'}, $ciddest, $k);
    }
  }
}

sub generate_font_snippet {
  my ($fd, $n, $c, $f) = @_;
  return if $dry_run;
  for my $enc (@{$encode_list{$c}}) {
    open(FOO, ">$fd/$n-$enc") || 
      die("cannot open $fd/$n-$enc for writing: $!");
    print FOO "%%!PS-Adobe-3.0 Resource-Font
%%%%DocumentNeededResources: $enc (CMap)
%%%%IncludeResource: $enc (CMap)
%%%%BeginResource: Font ($n-$enc)
($n-$enc)
($enc) /CMap findresource
[($n) /CIDFont findresource]
composefont
pop
%%%%EndResource
%%%%EOF
";
    close(FOO);
  }
}

sub link_font {
  my ($f, $cd, $n) = @_;
  return if $dry_run;
  if (!$n) {
    $n = basename($f);
  }
  my $target = "$cd/$n";
  if (-r $target) {
    if (-l $target) {
      if (readlink($target) eq $f) {
        # do nothing, it is the same link
      } else {
        print_error("link $target already existing, but different target then $target, exiting!\n");
        exit(1);
      }
    } else {
      print_error("$target already existing, but not a link, exiting!\n");
      exit(1);
    }
  } else {
    symlink($f, $target) || die("Cannot link font $f to $target: $!");
  }
}

sub do_ttf_fonts {
  my $fontdest = "$opt_output/Font";
  my $cidfsubst = "$opt_output/CIDFSubst";
  my $outp = '';
  if (-r $fontdest) {
    if (! -d $fontdest) {
      print_error("$fontdest is not a directory, cannot create CID snippets there!\n");
      exit 1;
    }
  } else {
    $dry_run || mkdir($fontdest);
  }
  if (-r $cidfsubst) {
    if (! -d $cidfsubst) {
      print_error("$cidfsubst is not a directory, cannot link CID fonts there!\n");
      exit 1;
    }
  } else {
    $dry_run || mkdir($cidfsubst);
  }
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'} && $fontdb{$k}{'type'} eq 'TTF') {
      generate_font_snippet($fontdest,
        $k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'});
      $outp .= generate_cidfmap_entry($k, $fontdb{$k}{'class'}, $fontdb{$k}{'target'}, $fontdb{$k}{'subfont'});
      link_font($fontdb{$k}{'target'}, $cidfsubst);
    }
  }
  #
  # alias handling
  # we use two levels of aliases, one is for the default names that
  # are not actual fonts:
  # Ryumin-Light, GothicBBB-Medium, FutoMinA101-Bold, FutoGoB101-Bold, 
  # Jun101-Light which are the original Morisawa names.
  #
  # the second level of aliases is for Morisawa OTF font names:
  # A-OTF-RyuminPro-Light, A-OTF-GothicBBBPro-Medium,
  # A-OTF-FutoMinA101Pro-Bold, A-OTF-FutoGoB101Pro-Bold
  # A-OTF-Jun101Pro-Light
  #
  # the order of fonts selected is
  # Morisawa Pr6, Morisawa, Hiragino ProN, Hiragino, 
  # Yu OSX, Yu Win, Kozuka ProN, Kozuka, IPAex, IPA
  # but is defined in the Provides(Priority): Name in the font definiton
  #
  $outp .= "\n\n% Aliases\n\n";
  #
  for my $al (keys %aliases) {
    my $target;
    my $class;
    if ($user_aliases{$al}) {
      $target = $user_aliases{$al};
      # determine class
      if ($fontdb{$target}{'available'}) {
        $class = $fontdb{$target}{'class'};
      } else {
        # must be an aliases, we checked this when initializing %user_aliases
        # reset the $al value
        # and since $class is still undefined we will use the next code below
        $al = $target;
      }
    }
    if (!$class) {
      # search lowest number
      my @ks = keys(%{$aliases{$al}});
      my $first = (sort { $a <=> $b} @ks)[0];
      $target = $aliases{$al}{$first};
      $class  = $fontdb{$target}{'class'};
    }
    # we also need to create font snippets in Font for the aliases!
    generate_font_snippet($fontdest, $al, $class, $target);
    $outp .= "/$al /$target ;\n";
  }
  #
  return if $dry_run;
  if ($outp) {
    if (! -d "$opt_output/Init") {
      mkdir("$opt_output/Init") ||
        die("Cannot create directory $opt_output/Init: $!");
    }
    open(FOO, ">$opt_output/Init/cidfmap.local") || 
      die "Cannot open $opt_output/cidfmap.local: $!";
    print FOO $outp;
    close(FOO);
  }
  print_info("adding cidfmap.local to cidfmap file ...\n");
  update_master_cidfmap();
}

sub generate_cidfmap_entry {
  my ($n, $c, $f, $sf) = @_;
  # we link the ttf fonts, so we use only the base name
  # otherwise the ps2pdf breaks due to -dSAFER
  my $bn = basename($f);
  # extract subfont
  my $s = "/$n << /FileType /TrueType 
  /Path pssystemparams /GenericResourceDir get 
  (CIDFSubst/$bn) concatstrings
  /SubfontID $sf
  /CSI [($c";
  if ($c eq "Japan") {
    $s .= "1) 6]";
  } elsif ($c eq "GB") {
    $s .= "1) 5]";
  } elsif ($c eq "CNS") {
    $s .= "1) 5]";
  } elsif ($c eq "Korea") {
    $s .= "1) 2]";
  } else {
    print_warning("unknown class $c for $n, skipping.\n");
    return '';
  }
  $s .= " >> ;\n";
  return $s;
}

#
# dump found files
sub info_found_fonts {
  print "List of found fonts:\n\n";
  for my $k (keys %fontdb) {
    my @foundfiles;
    if ($fontdb{$k}{'available'}) {
      print "Font:  $k\n";
      print "Type:  $fontdb{$k}{'type'}\n";
      print "Class: $fontdb{$k}{'class'}\n";
      my $fn = $fontdb{$k}{'target'};
      if ($fontdb{$k}{'type'} eq 'TTF' && $fontdb{$k}{'subfont'} > 0) {
        $fn .= "($fontdb{$k}{'subfont'})";
      }
      print "File:  $fn\n";
      print "\n";
    }
  }
}

#
# checks all file names listed in %fontdb
# and sets
sub check_for_files {
  # first collect all files:
  my @fn;
  for my $k (keys %fontdb) {
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      # check for subfont extension 
      if ($f =~ m/^(.*)\(\d*\)$/) {
        push @fn, $1;
      } else {
        push @fn, $f;
      }
    }
  }
  #
  # collect extra directories for search
  my @extradirs;
  if (win32()) {
    push @extradirs, "c:/windows/fonts//";
  } else {
    # other dirs to check, for normal unix?
    for my $d (qw!/Library/Fonts /System/Library/Fonts /Network/Library/Fonts!) {
      push @extradirs, $d if (-d $d);
    }
    my $home = $ENV{'HOME'};
    push @extradirs, "$home/Library/Fonts" if (-d "$home/Library/Fonts");
  }
  #
  if (@extradirs) {
    # final dummy directory
    push @extradirs, "/this/does/not/really/exists/unless/you/are/stupid";
    # push current value of OSFONTDIR
    push @extradirs, $ENV{'OSFONTDIR'} if $ENV{'OSFONTDIR'};
    # compose OSFONTDIR
    my $osfontdir = join ':', @extradirs;
    $ENV{'OSFONTDIR'} = $osfontdir;
  }
  if ($ENV{'OSFONTDIR'}) {
    print_debug("final setting of OSFONTDIR: $ENV{'OSFONTDIR'}\n");
  }
  # prepare for kpsewhich call, we need to do quoting
  my $cmdl = 'kpsewhich ';
  for my $f (@fn) {
    $cmdl .= " \"$f\" ";
  }
  # shoot up kpsewhich
  print_ddebug("checking for $cmdl\n");
  chomp( my @foundfiles = `$cmdl`);
  print_ddebug("Found files @foundfiles\n");
  # map basenames to filenames
  my %bntofn;
  for my $f (@foundfiles) {
    my $bn = basename($f);
    $bntofn{$bn} = $f;
  }
  if ($opt_debug > 1) {
    print_ddebug("dumping basename to filename list:\n");
    print_ddebug(Data::Dumper::Dumper(\%bntofn));
  }

  # update the %fontdb with the found files
  for my $k (keys %fontdb) {
    $fontdb{$k}{'available'} = 0;
    for my $f (keys %{$fontdb{$k}{'files'}}) {
      # check for subfont extension 
      my $realfile = $f;
      $realfile =~ s/^(.*)\(\d*\)$/$1/;
      if ($bntofn{$realfile}) {
        # we found a representative, make it available
        $fontdb{$k}{'files'}{$f}{'target'} = $bntofn{$realfile};
        $fontdb{$k}{'available'} = 1;
      } else {
        # delete the entry for convenience
        delete $fontdb{$k}{'files'}{$f};
      }
    }
  }
  # second round to determine the winner in case of more targets
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'}) {
      my $mp = 1000000; my $mf;
      for my $f (keys %{$fontdb{$k}{'files'}}) {
        if ($fontdb{$k}{'files'}{$f}{'priority'} < $mp) {
          $mp = $fontdb{$k}{'files'}{$f}{'priority'};
          $mf = $f;
        }
      }
      # extract subfont if necessary
      my $sf = 0;
      if ($mf =~ m/^(.*)\((\d*)\)$/) { $sf = $2; }
      $fontdb{$k}{'target'} = $fontdb{$k}{'files'}{$mf}{'target'};
      $fontdb{$k}{'subfont'} = $sf if ($fontdb{$k}{'type'} eq 'TTF');
    }
    # not needed anymore
    delete $fontdb{$k}{'files'};
  }
  # third round through the fontdb to check for provides
  # accumulate all provided fonts in @provides
  for my $k (keys %fontdb) {
    if ($fontdb{$k}{'available'}) {
      for my $p (keys %{$fontdb{$k}{'provides'}}) {
        # do not check alias if the real font is available
        next if $fontdb{$p}{'available'};
        # use the priority as key
        # if priorities are double, this will pick one at chance
        $aliases{$p}{$fontdb{$k}{'provides'}{$p}} = $k;
      }
    }
  }
  # check for user supplied aliases
  for my $a (@opt_aliases) {
    if ($a =~ m/^(.*)=(.*)$/) {
      my $ll = $1;
      my $rr = $2;
      # check for consistency of user provided aliases:
      # - ll must not be available
      # - rr needs to be available as font or alias
      # check whether $rr is available, either as real font or as alias
      if ($fontdb{$ll}{'available'}) {
        print_error("left side of alias spec is provided by a real font: $a\n");
        print_error("stopping here\n");
        exit(1);
      }
      if (!($fontdb{$rr}{'available'} || $aliases{$rr})) {
        print_error("right side of alias spec is not available as real font or alias: $a\n");
        print_error("stopping here\n");
        exit(1);
      }
      $user_aliases{$ll} = $rr;
    }
  }
  if ($opt_debug > 0) {
    print_debug("dumping font database:\n");
    print_debug(Data::Dumper::Dumper(\%fontdb));
    print_debug("dumping aliases:\n");
    print_debug(Data::Dumper::Dumper(\%aliases));
  }
}

sub read_font_database {
  my @dbl;
  if ($opt_fontdef) {
    open (FDB, "<$opt_fontdef") ||
      die "Cannot find $opt_fontdef: $!";
    @dbl = <FDB>;
    close(FDB);
  } else {
    @dbl = <DATA>;
  }
  chomp(@dbl);
  # add a "final empty line" to easy parsing
  push @dbl, "";
  my $fontname = "";
  my $fonttype = "";
  my $fontclass = "";
  my %fontprovides = ();
  my %fontfiles;
  my $psname = "";
  my $lineno = 0;
  for my $l (@dbl) {
    $lineno++;

    next if ($l =~ m/^\s*#/);
    if ($l =~ m/^\s*$/) {
      if ($fontname || $fonttype || $fontclass || keys(%fontfiles)) {
        if ($fontname && $fonttype && $fontclass && keys(%fontfiles)) {
          $fontdb{$fontname}{'type'} = $fonttype;
          $fontdb{$fontname}{'class'} = $fontclass;
          $fontdb{$fontname}{'files'} = { %fontfiles };
          $fontdb{$fontname}{'provides'} = { %fontprovides };
          # reset to start
          $fontname = $fonttype = $fontclass = $psname = "";
          %fontfiles = ();
          %fontprovides = ();
        } else {
          print_warning("incomplete entry above line $lineno for $fontname/$fonttype/$fontclass, skipping!\n");
          # reset to start
          $fontname = $fonttype = $fontclass = $psname = "";
          %fontfiles = ();
          %fontprovides = ();
        }
      } else {
        # no term is set, so nothing to warn about
      }
      next;
    }
    if ($l =~ m/^Name:\s*(.*)$/) { $fontname = $1; next; }
    if ($l =~ m/^PSName:\s*(.*)$/) { $psname = $1; next; }
    if ($l =~ m/^Type:\s*(.*)$/) { $fonttype = $1 ; next ; }
    if ($l =~ m/^Class:\s*(.*)$/) { $fontclass = $1 ; next ; }
    if ($l =~ m/^Filename(\((\d+)\))?:\s*(.*)$/) { 
      $fontfiles{$3}{'priority'} = ($2 ? $2 : 10);
      next;
    }
    if ($l =~ m/^Provides\((\d+)\):\s*(.*)$/) { $fontprovides{$2} = $1; next; }
    # we are still here??
    print_error("Cannot parse this file at line $lineno, exiting. Strange line: >>>$l<<<\n");
    exit (1);
  }
}

sub find_gs_resource {
  # we assume that gs is in the path
  # on Windows we probably have to try something else
  my @ret = `gs --help 2>$nul`;
  my $foundres = '';
  if ($?) {
    print_error("Cannot find gs ...\n");
  } else {
    # try to find resource line
    for (@ret) {
      if (m!Resource/Font!) {
        $foundres = $_;
        $foundres =~ s/^\s*//;
        $foundres =~ s/\s*:\s*$//;
        $foundres =~ s!/Font!!;
        last;
      }
    }
    if (!$foundres) {
      print_error("Found gs but no resource???\n");
    }
  }
  return $foundres;
}

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub Usage {
  my $usage = <<"EOF";

Usage: $prg [OPTION] ...

Configuring GhostScript for CJK CID/TTF fonts.

Options:
  -n, --dry-run         do not actually output anything
  -f, --fontdef FILE    specify alternate set of font definitions, if not
                        given, the built-in set is used
  -o, --output DIR      specifies the base output dir, if not provided,
                        the Resource directory of an install GhostScript
                        is searched and used.
  -a, --alias LL=RR     defines an alias, or overrides a given alias
                        illegal if LL is provided by a real font, or
                        RR is neither available as real font or alias
                        can be given multiple times
  -q, --quiet           be less verbose
  -d, --debug           output debug information, can be given multiple times
  -v, --version         outputs only the version information
  -h, --help            this help

Command like options:
  --list-aliases        lists the aliases and their options, with the selected
                        option on top
  --list-fonts          lists the fonts found on the system
  --info                combines the above two information

Operation:

  This script searches a list of directories (see below) for CJK fonts,
  and makes them available to an installed GhostScript. In the simplest
  case with sufficient privileges, a run without arguments should effect
  in a complete setup of GhostScript.

  For each found TrueType (TTF) font it creates a cidfmap entry in
    <Resource>/Init/cidfmap.local
  For each CID font it creates a snippet in
    <Resource>/Font/
  and links the font to 
    <Resource>/CIDFont
  The <Resource> dir is either given by -o/--output, or otherwise searched
  from an installed GhostScript (binary name is assumed to be 'gs').

  Finally, it tries to add runlib call to
    <Resource>/Init/cidfmap
  to load the cidfmap.local.

How and which directories are searched:

  Search is done using the kpathsea library, in particular using kpsewhich
  program. By default the following directories are searched:
  - all TEXMF trees
  - /Library/Fonts and /System/Library/Fonts (if available)
  - c:/windows/fonts (on Windows)
  - the directories in OSFONTDIR environment variable

  In case you want to add some directories to the search path, adapt the
  OSFONTDIR environment variable accordingly: Example:
    OSFONTDIR="/usr/local/share/fonts/truetype//:/usr/local/share/fonts/opentype//" $prg
  will result in fonts found in the above two given directories to be
  searched in addition.

Output files:

  If no output option is given, the program searches for a GhostScript
  interpreter 'gs' and determines its Resource directory. This might
  fail, in which case one need to pass the output directory manually.

  Since the program adds files and link to this directory, sufficient
  permissions are necessary.

Aliases:

  Aliases are managed via the Provides values in the font database.
  At the moment entries for the basic font names for CJK fonts
  are added:

  Japanese:
    Ryumin-Light GothicBBB-Medium FutoMinA101-Bold FutoGoB101-Bold Jun101-Light

  Korean:
    HYGoThic-Medium HYSMyeongJo-Medium

  Simplified Chinese:
    STSong-Light STHeiti-Regular STHeiti-Light STKaiti-Regular

  Traditional Chinese:
    MSung-Light MHei-Medium MKai-Medium

  In addition, we also includes provide entries for the OTF Morisawa names:
    A-OTF-RyuminPro-Light A-OTF-GothicBBBPro-Medium A-OTF-FutoMinA101Pro-Bold
    A-OTF-FutoGoB101Pro-Bold A-OTF-Jun101Pro-Light

  The order is determined by the Provides setting in the font database,
  and for the Japanese fonts it is currently:
    Morisawa Pr6, Morisawa, Hiragino ProN, Hiragino, 
    Yu OSX, Yu Win, Kozuka ProN, Kozuka, IPAex, IPA

  That is, the first font found in this order will be used to provide the
  alias if necessary.

Overriding aliases

  Using the command line option `--alias LL=RR` one can add arbitrary aliases,
  or override ones selected by the program. For this to work the following
  requirements of `LL` and `RR` must be fulfilled:
  * `LL` is not provided by a real font
  * `RR` is available either as real font, or as alias (indirect alias)

Authors, Contributors, and Copyright:

  The script and its documentation was written by Norbert Preining, based
  on research and work by Yusuke Kuroki, Bruno Voisin, Munehiro Yamamoto
  and the TeX Q&A wiki page.

  The script is licensed under GNU General Public License Version 3 or later.
  The contained font data is not copyrightable.

EOF
;
  print $usage;
  exit 0;
}

# info/warning can be suppressed
# verbose/error cannot be suppressed
sub print_info {
  print STDOUT "$prg: ", @_ if (!$opt_quiet);
}
sub print_verbose {
  print STDOUT "$prg: ", @_;
}
sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opt_quiet) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}
sub print_debug {
  print STDERR "$prg [DEBUG]: ", @_ if ($opt_debug >= 1);
}
sub print_ddebug {
  print STDERR "$prg [DEBUG]: ", @_ if ($opt_debug >= 2);
}


__DATA__
#
# CJK FONT DEFINITIONS
#

# JAPAN

# Morisawa

Name: A-OTF-FutoGoB101Pr6N-Bold
PSName: FutoGoB101Pr6N-Bold
Type: CID
Class: Japan
Provides(10): FutoGoB101-Bold
Provides(10): A-OTF-FutoGoB101Pro-Bold
Filename: A-OTF-FutoGoB101Pr6N-Bold.otf

Name: A-OTF-FutoGoB101Pro-Bold
PSName: FutoGoB101Pro-Bold
Type: CID
Class: Japan
Provides(20): FutoGoB101-Bold
Filename: A-OTF-FutoGoB101Pro-Bold.otf

Name: A-OTF-FutoMinA101Pr6N-Bold
PSName: FutoMinA101Pr6N-Bold
Type: CID
Class: Japan
Provides(10): FutoMinA101-Bold
Provides(10): A-OTF-FutoMinA101Pro-Bold
Filename: A-OTF-FutoMinA101Pr6N-Bold.otf

Name: A-OTF-FutoMinA101Pro-Bold
PSName: FutoMinA101Pro-Bold
Type: CID
Class: Japan
Provides(20): FutoMinA101-Bold
Filename: A-OTF-FutoMinA101Pro-Bold.otf

Name: A-OTF-GothicBBBPr6N-Medium
PSName: GothicBBBPr6N-Medium
Type: CID
Class: Japan
Provides(10): GothicBBB-Medium
Provides(10): A-OTF-GothicBBBPro-Medium
Filename: A-OTF-GothicBBBPr6N-Medium.otf

Name: A-OTF-GothicBBBPro-Medium
PSName: GothicBBBPro-Medium
Type: CID
Class: Japan
Provides(20): GothicBBB-Medium
Filename: A-OTF-GothicBBBPro-Medium.otf

Name: A-OTF-Jun101Pro-Light
PSName: Jun101Pro-Light
Type: CID
Class: Japan
Provides(20): Jun101-Light
Filename: A-OTF-Jun101Pro-Light.otf

Name: A-OTF-MidashiGoPr6N-MB31
PSName: MidashiGoPr6N-MB31
Type: CID
Class: Japan
Filename: A-OTF-MidashiGoPr6N-MB31.otf

Name: A-OTF-MidashiGoPro-MB31
PSName: MidashiGoPro-MB31
Type: CID
Class: Japan
Filename: A-OTF-MidashiGoPro-MB31.otf

Name: A-OTF-RyuminPr6N-Light
PSName: RyuminPr6N-Light
Type: CID
Class: Japan
Provides(10): Ryumin-Light
Provides(10): A-OTF-RyuminPro-Light
Filename: A-OTF-RyuminPr6N-Light.otf

Name: A-OTF-RyuminPro-Light
PSName: RyuminPro-Light
Type: CID
Class: Japan
Provides(20): Ryumin-Light
Filename: A-OTF-RyuminPro-Light.otf

Name: A-OTF-ShinMGoPr6N-Light
PSName: ShinMGoPr6N-Light
Type: CID
Class: Japan
Provides(10): Jun101-Light
Provides(10): A-OTF-Jun101Pro-Light
Filename: A-OTF-ShinMGoPr6N-Light.otf


# Hiragino

Name: HiraKakuPro-W3
Type: CID
Class: Japan
Provides(40): GothicBBB-Medium
Provides(40): A-OTF-GothicBBBPro-Medium
Filename(20): ヒラギノ角ゴ Pro W3.otf
Filename(10): HiraKakuPro-W3.otf

Name: HiraKakuPro-W6
Type: CID
Class: Japan
Provides(40): FutoGoB101-Bold
Provides(40): A-OTF-FutoGoB101Pro-Bold
Filename(20): ヒラギノ角ゴ Pro W6.otf
Filename(10): HiraKakuPro-W6.otf

Name: HiraKakuProN-W3
Type: CID
Class: Japan
Provides(30): GothicBBB-Medium
Provides(30): A-OTF-GothicBBBPro-Medium
Filename(20): ヒラギノ角ゴ ProN W3.otf
Filename(10): HiraKakuProN-W3.otf

Name: HiraKakuProN-W6
Type: CID
Class: Japan
Provides(30): FutoGoB101-Bold
Provides(30): A-OTF-FutoGoB101Pro-Bold
Filename(20): ヒラギノ角ゴ ProN W6.otf
Filename(10): HiraKakuProN-W6.otf

Name: HiraKakuStd-W8
Type: CID
Class: Japan
Filename(20): ヒラギノ角ゴ Std W8.otf
Filename(10): HiraKakuStd-W8.otf

Name: HiraKakuStdN-W8
Type: CID
Class: Japan
Filename(20): ヒラギノ角ゴ StdN W8.otf
Filename(10): HiraKakuStdN-W8.otf

Name: HiraMaruPro-W4
Type: CID
Class: Japan
Provides(40): Jun101-Light
Provides(40): A-OTF-Jun101Pro-Light
Filename(20): ヒラギノ丸ゴ Pro W4.otf
Filename(10): HiraMaruPro-W4.otf

Name: HiraMaruProN-W4
Type: CID
Class: Japan
Provides(30): Jun101-Light
Provides(30): A-OTF-Jun101Pro-Light
Filename(20): ヒラギノ丸ゴ ProN W4.otf
Filename(10): HiraMaruProN-W4.otf

Name: HiraMinPro-W3
Type: CID
Class: Japan
Provides(40): Ryumin-Light
Provides(40): A-OTF-RyuminPro-Light
Filename(20): ヒラギノ明朝 Pro W3.otf
Filename(10): HiraMinPro-W3.otf

Name: HiraMinPro-W6
Type: CID
Class: Japan
Provides(40): FutoMinA101-Bold
Provides(40): A-OTF-FutoMinA101Pro-Bold
Filename(20): ヒラギノ明朝 Pro W6.otf
Filename(10): HiraMinPro-W6.otf

Name: HiraMinProN-W3
Type: CID
Class: Japan
Provides(30): Ryumin-Light
Provides(30): A-OTF-RyuminPro-Light
Filename(20): ヒラギノ明朝 ProN W3.otf
Filename(10): HiraMinProN-W3.otf

Name: HiraMinProN-W6
Type: CID
Class: Japan
Provides(30): FutoMinA101-Bold
Provides(30): A-OTF-FutoMinA101Pro-Bold
Filename(20): ヒラギノ明朝 ProN W6.otf
Filename(10): HiraMinProN-W6.otf


Name: HiraginoSansGB-W3
Type: CID
Class: GB
Filename(20): Hiragino Sans GB W3.otf
Filename(10): HiraginoSansGB-W3.otf

Name: HiraginoSansGB-W6
Type: CID
Class: GB
Filename(20): Hiragino Sans GB W6.otf
Filename(10): HiraginoSansGB-W6.otf


# Yu-fonts MacOS version

Name: YuGo-Medium
Type: CID
Class: Japan
Provides(50): GothicBBB-Medium
Provides(50): A-OTF-GothicBBBPro-Medium
Filename(20): Yu Gothic Medium.otf
Filename(10): YuGo-Medium.otf

Name: YuGo-Bold
Type: CID
Class: Japan
Provides(50): FutoGoB101-Bold
Provides(50): A-OTF-FutoGoB101Pro-Bold
Provides(50): Jun101-Light
Provides(50): A-OTF-Jun101Pro-Light
Filename(20): Yu Gothic Bold.otf
Filename(10): YuGo-Bold.otf

Name: YuMin-Medium
Type: CID
Class: Japan
Provides(50): Ryumin-Light
Provides(50): A-OTF-RyuminPro-Light
Filename(20): Yu Mincho Medium.otf
Filename(10): YuMin-Medium.otf

Name: YuMin-Demibold
Type: CID
Class: Japan
Provides(50): FutoMinA101-Bold
Provides(50): A-OTF-FutoMinA101Pro-Bold
Filename(20): Yu Mincho Demibold.otf
Filename(10): YuMin-Demibold.otf

# Yu-fonts Windows version
Name: YuMincho-Regular
Type: TTF
Class: Japan
Provides(60): Ryumin-Light
Provides(60): A-OTF-RyuminPro-Light
Filename(20): yumin.ttf
Filename(10): YuMincho-Regular.ttf

Name: YuMincho-Light
Type: TTF
Class: Japan
Filename(20): yuminl.ttf
Filename(10): YuMincho-Light.ttf

Name: YuMincho-DemiBold
Type: TTF
Class: Japan
Provides(60): FutoMinA101-Bold
Provides(60): A-OTF-FutoMinA101Pro-Bold
Filename(20): yumindb.ttf
Filename(10): YuMincho-DemiBold.ttf

Name: YuGothic-Regular
Type: TTF
Class: Japan
Provides(60): GothicBBB-Medium
Provides(60): A-OTF-GothicBBBPro-Medium
Filename(20): yugothic.ttf
Filename(10): YuGothic-Regular.ttf

Name: YuGothic-Light
Type: TTF
Class: Japan
Filename(20): yugothil.ttf
Filename(10): YuGothic-Light.ttf

Name: YuGothic-Bold
Type: TTF
Class: Japan
Provides(60): FutoGoB101-Bold
Provides(60): A-OTF-FutoGoB101Pro-Bold
Provides(60): Jun101-Light
Provides(60): A-OTF-Jun101Pro-Light
Filename(20): yugothib.ttf
Filename(10): YuGothic-Bold.ttf

# IPA fonts

Name: IPAMincho
Type: TTF
Class: Japan
Provides(110): Ryumin-Light
Provides(110): A-OTF-RyuminPro-Light
Filename(20): ipam.ttf
Filename(10): IPAMincho.ttf

Name: IPAGothic
Type: TTF
Class: Japan
Provides(110): GothicBBB-Medium
Provides(110): A-OTF-GothicBBBPro-Medium
Provides(110): FutoMinA101-Bold
Provides(110): A-OTF-FutoMinA101Pro-Bold
Provides(110): FutoGoB101-Bold
Provides(110): A-OTF-FutoGoB101Pro-Bold
Provides(110): Jun101-Light
Provides(110): A-OTF-Jun101Pro-Light
Filename(20): ipag.ttf
Filename(10): IPAGothic.ttf

Name: IPAexMincho
Type: TTF
Class: Japan
Provides(100): Ryumin-Light
Provides(100): A-OTF-RyuminPro-Light
Filename(20): ipaexm.ttf
Filename(10): IPAexMincho.ttf

Name: IPAexGothic
Type: TTF
Class: Japan
Provides(100): GothicBBB-Medium
Provides(100): A-OTF-GothicBBBPro-Medium
Provides(100): FutoMinA101-Bold
Provides(100): A-OTF-FutoMinA101Pro-Bold
Provides(100): FutoGoB101-Bold
Provides(100): A-OTF-FutoGoB101Pro-Bold
Provides(100): Jun101-Light
Provides(100): A-OTF-Jun101Pro-Light
Filename(20): ipaexg.ttf
Filename(10): IPAexGothic.ttf

# Kozuka fonts

Name: KozGoPr6N-Bold
Type: CID
Class: Japan
Provides(70): FutoGoB101-Bold
Provides(70): A-OTF-FutoGoB101Pro-Bold
Filename: KozGoPr6N-Bold.otf

Name: KozGoPr6N-Heavy
Type: CID
Class: Japan
Provides(70): Jun101-Light
Provides(70): A-OTF-Jun101Pro-Light
Filename: KozGoPr6N-Heavy.otf

Name: KozGoPr6N-Medium
Type: CID
Class: Japan
Provides(70): GothicBBB-Medium
Provides(70): A-OTF-GothicBBBPro-Medium
Filename: KozGoPr6N-Medium.otf

Name: KozGoPr6N-Regular
Type: CID
Class: Japan
Filename: KozGoPr6N-Regular.otf

Name: KozGoPro-Bold
Type: CID
Class: Japan
Provides(90): FutoGoB101-Bold
Provides(90): A-OTF-FutoGoB101Pro-Bold
Filename: KozGoPro-Bold.otf

Name: KozGoPro-Heavy
Type: CID
Class: Japan
Provides(90): Jun101-Light
Provides(90): A-OTF-Jun101Pro-Light
Filename: KozGoPro-Heavy.otf

Name: KozGoPro-Medium
Type: CID
Class: Japan
Provides(90): GothicBBB-Medium
Provides(90): A-OTF-GothicBBBPro-Medium
Filename: KozGoPro-Medium.otf

Name: KozGoPro-Regular
Type: CID
Class: Japan
Filename: KozGoPro-Regular.otf

Name: KozGoProVI-Bold
Type: CID
Class: Japan
Provides(80): FutoGoB101-Bold
Provides(80): A-OTF-FutoGoB101Pro-Bold
Filename: KozGoProVI-Bold.otf

Name: KozGoProVI-Heavy
Type: CID
Class: Japan
Provides(80): Jun101-Light
Provides(80): A-OTF-Jun101Pro-Light
Filename: KozGoProVI-Heavy.otf

Name: KozGoProVI-Medium
Type: CID
Class: Japan
Provides(80): GothicBBB-Medium
Provides(80): A-OTF-GothicBBBPro-Medium
Filename: KozGoProVI-Medium.otf

Name: KozGoProVI-Regular
Type: CID
Class: Japan
Filename: KozGoProVI-Regular.otf

Name: KozMinPr6N-Bold
Type: CID
Class: Japan
Provides(70): FutoMinA101-Bold
Provides(70): A-OTF-FutoMinA101Pro-Bold
Filename: KozMinPr6N-Bold.otf

Name: KozMinPr6N-Light
Type: CID
Class: Japan
Filename: KozMinPr6N-Light.otf

Name: KozMinPr6N-Regular
Type: CID
Class: Japan
Provides(70): Ryumin-Light
Provides(70): A-OTF-RyuminPro-Light
Filename: KozMinPr6N-Regular.otf

Name: KozMinPro-Bold
Type: CID
Class: Japan
Provides(90): FutoMinA101-Bold
Provides(90): A-OTF-FutoMinA101Pro-Bold
Filename: KozMinPro-Bold.otf

Name: KozMinPro-Light
Type: CID
Class: Japan
Filename: KozMinPro-Light.otf

Name: KozMinPro-Regular
Type: CID
Class: Japan
Provides(90): Ryumin-Light
Provides(90): A-OTF-RyuminPro-Light
Filename: KozMinPro-Regular.otf

Name: KozMinProVI-Bold
Type: CID
Class: Japan
Provides(80): FutoMinA101-Bold
Provides(80): A-OTF-FutoMinA101Pro-Bold
Filename: KozMinProVI-Bold.otf

Name: KozMinProVI-Light
Type: CID
Class: Japan
Filename: KozMinProVI-Light.otf

Name: KozMinProVI-Regular
Type: CID
Class: Japan
Provides(80): Ryumin-Light
Provides(80): A-OTF-RyuminPro-Light
Filename: KozMinProVI-Regular.otf

#
# CHINESE FONTS
#

Name: LiHeiPro
Type: TTF
Class: CNS
Provides(50): MHei-Medium
Provides(50): MHei-Medium-
Filename(20): 儷黑 Pro.ttf
Filename(10): LiHeiPro.ttf

Name: LiSongPro
Type: TTF
Class: CNS
Provides(50): MSung-Medium
Provides(50): MSung-Light
Provides(50): MSung-Light-
Filename(20): 儷宋 Pro.ttf
Filename(10): LiSongPro.ttf

Name: STXihei
Type: TTF
Class: GB
Provides(20): STHeiti-Light
Filename(20): 华文细黑.ttf
Filename(10): STXihei.ttf

Name: STHeiti
Type: TTF
Class: GB
Provides(50): STHeiti-Regular
Provides(50): STHeiti-Regular-
Filename(20): 华文黑体.ttf
Filename(10): STHeiti.ttf

Name: STHeitiSC-Light
Type: TTF
Class: GB
Provides(10): STHeiti-Light
Filename(10): STHeiti Light.ttc(1)
Filename(20): STHeitiSC-Light.ttf

Name: STHeitiSC-Medium
Type: TTF
Class: GB
Provides(40): STHeiti-Regular
Provides(40): STHeiti-Regular-
Filename(10): STHeiti Medium.ttc(1)
Filename(20): STHeitiSC-Medium.ttf

Name: STHeitiTC-Light
Type: TTF
Class: CNS
Filename(10): STHeiti Light.ttc(0)
Filename(20): STHeitiTC-Light.ttf

Name: STHeitiTC-Medium
Type: TTF
Class: CNS
Provides(40): MHei-Medium
Provides(40): MHei-Medium-
Filename(10): STHeiti Medium.ttc(0)
Filename(20): STHeitiTC-Medium.ttf

Name: STFangsong
Type: TTF
Class: GB
Provides(40): STFangsong-Light
Provides(40): STFangsong-Light-
Provides(40): STFangsong-Regular
Filename(20): 华文仿宋.ttf
Filename(10): STFangsong.ttf

Name: STSong
Type: TTF
Class: GB
Provides(50): STSong-Light
Provides(50): STSong-Light-
Filename(10): Songti.ttc(4)
Filename(20): 宋体.ttc(3)
Filename(30): 华文宋体.ttf
Filename(40): STSong.ttf

Name: STSongti-SC-Light
Type: TTF
Class: GB
Provides(40): STSong-Light
Provides(40): STSong-Light-
Filename(10): Songti.ttc(3)
Filename(20): 宋体.ttc(2)
Filename(30): STSongti-SC-Light.ttf

Name: STSongti-SC-Regular
Type: TTF
Class: GB
Filename(10): Songti.ttc(6)
Filename(20): 宋体.ttc(4)
Filename(30): STSongti-SC-Regular.ttf

Name: STSongti-SC-Bold
Type: TTF
Class: GB
Filename(10): Songti.ttc(1)
Filename(20): 宋体.ttc(1)
Filename(30): STSongti-SC-Bold.ttf

Name: STSongti-SC-Black
Type: TTF
Class: GB
Filename(10): Songti.ttc(0)
Filename(20): 宋体.ttc(0)
Filename(30): STSongti-SC-Black.ttf

Name: STSongti-TC-Light
Type: TTF
Class: CNS
Provides(40): MSung-Light
Provides(40): MSung-Light-
Filename(10): Songti.ttc(5)
Filename(20): STSongti-TC-Light.ttf

Name: STSongti-TC-Regular
Type: TTF
Class: CNS
Provides(40): MSung-Medium
Filename(10): Songti.ttc(7)
Filename(20): STSongti-TC-Regular.ttf

Name: STSongti-TC-Bold
Type: TTF
Class: CNS
Filename(10): Songti.ttc(2)
Filename(20): STSongti-TC-Bold.ttf

Name: STKaiti
Type: TTF
Class: GB
Provides(50): STKaiti-Regular
Provides(50): STKaiti-Regular-
Filename(10): Kaiti.ttc(4)
Filename(20): 楷体.ttc(3)
Filename(30): 华文楷体.ttf
Filename(40): STKaiti.ttf

Name: STKaiti-SC-Regular
Type: TTF
Class: GB
Provides(40): STKaiti-Regular
Provides(40): STKaiti-Regular-
Filename(10): Kaiti.ttc(3)
Filename(20): 楷体.ttc(2)
Filename(30): STKaiti-SC-Regular.ttf

Name: STKaiti-SC-Bold
Type: TTF
Class: GB
Filename(10): Kaiti.ttc(1)
Filename(20): 楷体.ttc(1)
Filename(30): STKaiti-SC-Bold.ttf

Name: STKaiti-SC-Black
Type: TTF
Class: GB
Filename(10): Kaiti.ttc(0)
Filename(20): 楷体.ttc(0)
Filename(30): STKaiti-SC-Black.ttf

Name: STKaiTi-TC-Regular
Type: TTF
Class: CNS
Provides(40): MKai-Medium
Provides(40): MKai-Medium-
Filename(10): Kaiti.ttc(5)
Filename(20): STKaiTi-TC-Regular.ttf

Name: STKaiTi-TC-Bold
Type: TTF
Class: CNS
Filename(10): Kaiti.ttc(2)
Filename(20): STKaiTi-TC-Bold.ttf

Name: STKaiti-Adobe-CNS1
Type: TTF
Class: CNS
Provides(50): MKai-Medium
Provides(50): MKai-Medium-
Filename: STKaiti.ttf

# Adobe fonts

# simplified chinese

Name: AdobeSongStd-Light
Type: CID
Class: GB
Provides(30): STSong-Light
Provides(30): STSong-Light-
Filename(10): AdobeSongStd-Light.otf

Name: AdobeHeitiStd-Regular
Type: CID
Class: GB
Provides(30): STHeiti-Regular
Provides(30): STHeiti-Regular-
Filename(20): AdobeHeitiStd-Regular.otf

Name: AdobeKaitiStd-Regular
Type: CID
Class: GB
Provides(30): STKaiti-Regular
Provides(30): STKaiti-Regular-
Filename(20): AdobeKaitiStd-Regular.otf

Name: AdobeFangsongStd-Regular
Type: CID
Class: GB
Provides(30): STFangsong-Light
Provides(30): STFangsong-Light-
Provides(30): STFangsong-Regular
Filename(20): AdobeFangsongStd-Regular.otf

# traditional chinese

Name: AdobeMingStd-Light
Type: CID
Class: CNS
Provides(30): MSung-Light
Provides(30): MSung-Light-
Filename(20): AdobeMingStd-Light.otf

Name: AdobeFanHeitiStd-Bold
Type: CID
Class: CNS
Provides(30): MHei-Medium
Provides(30): MHei-Medium-
Filename(20): AdobeFanHeitiStd-Bold.otf

# korean

Name: AdobeMyungjoStd-Medium
Type: CID
Class: Korea
Provides(20): HYSMyeongJo-Medium
Provides(20): HYSMyeongJo-Medium-
Filename: AdobeMyungjoStd-Medium.otf

Name: AdobeGothicStd-Bold
Type: CID
Class: Korea
Provides(20): HYGoThic-Medium
Provides(20): HYGoThic-Medium-
Provides(50): HYRGoThic-Medium
Filename: AdobeGothicStd-Bold.otf

#
# KOREAN FONTS
#
Name: AppleMyungjo
Type: TTF
Class: Korea
Provides(50): HYSMyeongJo-Medium
Provides(50): HYSMyeongJo-Medium-
Filename: AppleMyungjo.ttf

Name: AppleGothic
Type: TTF
Class: Korea
Provides(50): HYGoThic-Medium
Provides(50): HYGoThic-Medium-
Provides(80): HYRGoThic-Medium
Filename: AppleGothic.ttf

Name: NanumMyeongjo
Type: TTF
Class: Korea
Provides(30): HYSMyeongJo-Medium
Provides(30): HYSMyeongJo-Medium-
Filename: NanumMyeongjo.ttc(0)

Name: NanumMyeongjoBold
Type: TTF
Class: Korea
Filename: NanumMyeongjo.ttc(1)

Name: NanumMyeongjoExtraBold
Type: TTF
Class: Korea
Filename: NanumMyeongjo.ttc(2)

Name: NanumGothic
Type: TTF
Class: Korea
Provides(30): HYGoThic-Medium
Provides(30): HYGoThic-Medium-
Provides(60): HYRGoThic-Medium
Filename: NanumGothic.ttc(0)

Name: NanumGothicBold
Type: TTF
Class: Korea
Filename: NanumGothic.ttc(1)

Name: NanumGothicExtraBold
Type: TTF
Class: Korea
Filename: NanumGothic.ttc(2)

Name: NanumBrush
Type: TTF
Class: Korea
Filename: NanumScript.ttc(0)

Name: NanumPen
Type: TTF
Class: Korea
Filename: NanumScript.ttc(1)

Name: AppleSDGothicNeo-Thin
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-Thin.otf

Name: AppleSDGothicNeo-UltraLight
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-UltraLight.otf

Name: AppleSDGothicNeo-Light
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-Light.otf

Name: AppleSDGothicNeo-Regular
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-Regular.otf

Name: AppleSDGothicNeo-Medium
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-Medium.otf

Name: AppleSDGothicNeo-SemiBold
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-SemiBold.otf

Name: AppleSDGothicNeo-Bold
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-Bold.otf

Name: AppleSDGothicNeo-ExtraBold
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-ExtraBold.otf

Name: AppleSDGothicNeo-Heavy
Type: OTF
Class: Korea
Filename: AppleSDGothicNeo-Heavy.otf


### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim: set tabstop=2 expandtab autoindent:
