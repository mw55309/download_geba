#!/usr/bin/perl

# open table.txt and skip headers
open(IN, "table.txt");
while(<IN>) {
	last;
}

# go through table
while(<IN>) {
	chomp();
	my @d = split(/\t/);

	# make species / directory names safe
	my $name = $d[2];
	$name =~ s/\s+/_/g;
	$name =~ s/,/_/g;
	$name =~ s/:/_/g;
	$name =~ s/\//_/g;
	$name =~ s/-/_/g;
	my $outdir = $d[0] . "." . $name;

	# skip if we already have this one
	next if (-d $outdir);

	# there are four forms of accessions
	# and some are provides as lists
	#
	# CP002452 - straightforward accession for FASTA download
	# GCA_900176005 - genome project accession (?)
	# JNKA00000000 - WGS sequence set accession
	# SRX1760621 - ENA SRA accession
	if ($d[24] =~ m/^C/) {
		print "Got $d[24] - downloading into $outdir\n";
		download_accession($outdir, $d[24]);
	} elsif ($d[24] =~ m/^GCA/) {
		print "Got $d[24] - downloading into $outdir\n";
		download_gca($outdir, $d[24]);
	} elsif ($d[24] =~ m/^S/) {
		download_srx($outdir, $d[24]);
	} else {
		print "Got $d[24] - downloading into $outdir\n";
		download($outdir, $d[24]);
	}

}
close IN;


sub download_accession {

	my $dir = shift;
	my $acc = shift;

	# split if a list
	my @accns = split(/,/, $acc);

	# make and change dir
	# SHOULD DO MORE CHECKING BUT CBA
	mkdir $dir;
	chdir $dir;

	foreach $a (@accns) {
		# remove whitespace and do
		# simple FASTA download
		$a =~ s/\s+//g;
		
		print "Trying http://www.ebi.ac.uk/ena/data/view/$a&display=fasta\n";
		system("curl \"http://www.ebi.ac.uk/ena/data/view/$a&display=fasta\" 2>/dev/null 1>>$dir.fasta");
	}

	chdir ".."; 	
}

sub download_srx {
	
	my $dir = shift;
        my $acc = shift;

	# split if a list
        my @accns = split(/,/, $acc);

	# see above
	mkdir $dir;
	chdir $dir;

	foreach $a (@accns) {
                $a =~ s/\s+//g;

		# download XML for the SRX and find the ENA run number
		# begins SRR
		open(SRX, "curl \"http://www.ebi.ac.uk/ena/data/view/$a&display=xml&download=xml&filename=$a.xml\" 2>/dev/null |");
		while(<SRX>) {
			if (m/<ID>(SRR.+)<\/ID>/) {
				my $run = $1;
				my $stub = substr($run, 0, 6);
				
				# try the different fastq volumes at EBI for this run's FASTQ
				foreach $try (("000","001","002","003","004","005","006","007","008","009")) {
					my $url = "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/$stub/$try/$run/*.fastq.gz";
					print "Trying $url\n";
					system("wget -q $url");
				}
			}
		}
		close SRX;	
        }

        chdir "..";

	

}


sub download_gca {

	my $dir = shift;
        my $acc = shift;

	# download XML and find sequence set info
	open(GCA, "curl \"http://www.ebi.ac.uk/ena/data/view/$acc&display=xml&download=xml&filename=$acc.xml\" 2>/dev/null |");
	my $pfx;
        my $vsn;
	while(<GCA>) {	

		if (m/<PREFIX>(.+)<\/PREFIX>/) {
			$pfx = $1;
		}

		if (m/<VERSION>(.+)<\/VERSION>/) {
			$vsn = $1;
		}

	}
	close GCA;

	# built sequence set accession
	my $newacc = $pfx . "0" . $vsn . "000000";

	# if it looks good, download it
	unless ($newacc eq "0000000") {
        	&download($dir, $newacc);
	}

}


sub download {

	my $dir = shift;
        my $acc = shift;

	# download XML and find ENA-WGS accessions
	open(DL, "curl \"http://www.ebi.ac.uk/ena/data/view/$acc&display=xml&download=xml&filename=$acc.xml\" 2>/dev/null |");
	while(<DL>) {
        	if (m/<xref db=\"ENA-WGS\" id=\"(.+)\"\/>/) {
                	my $get = $1;
                	mkdir $dir;
                	chdir $dir;
			print "Trying http://www.ebi.ac.uk/ena/data/view/$get&display=fasta\n";
                	system("curl \"http://www.ebi.ac.uk/ena/data/view/$get&display=fasta\" 2>/dev/null 1>$dir.fasta");
			chdir "..";
        	}
        }
        close DL;

}
