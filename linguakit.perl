#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use utf8;

push @ARGV, "-h" if $#ARGV < 0;

#Linguakit dependencies
my $deps = 1;
if (!eval{require Getopt::ArgParse;}){
	warn "Please install Getopt::ArgParse module: cpan Getopt::ArgParse\n";
	$deps = 0;
}
if (!eval{require Storable;}){
	warn "Please install Storable module: cpan Storable\n";
	$deps = 0;
}
if (!eval{require PerlIO::gzip}){
	warn "WARNING PerlIO::gzip module not installed, use 'cpan PerlIO::gzip' to solve\n";
}
if (!eval{require LWP::UserAgent;}){
	warn "WARNING LWP::UserAgent module not installed, use 'cpan LWP::UserAgent' to solve\n";
}
if (!eval{require HTTP::Request::Common;}){
	warn "WARNING HTTP::Request::Common module not installed, use 'cpan HTTP::Request::Common' to solve\n";
}
exit 1 if !$deps;


#Custom text
my $name = "linguakit";
my $shortDescription = "";
my $longDescription = "";
my $foot = "";
my $errorPrint = "$name: ";


my $parser = Getopt::ArgParse -> new_parser( prog => $name, help => $shortDescription, description => $longDescription, epilog => $foot, error_prefix  => $errorPrint);

my @common_args = (
	['lang', type => 'Scalar', dest => 'lang', required => 1, metavar => "<lang>", help => "Choose the language", choices_i => ["en", "es", "gl", "pt"], default => "en"],
	['input', type => 'Scalar',  dest => 'input', metavar => "<input>", help => "Path of the input(a plain text file or gz/zip) by default STDIN"],
	['-s', type => 'Bool',  dest => 'string', help => "Changes input from a file path to a text string"]
);


#Modulos
$parser->add_subparsers(title => 'Modules', description => '');

my $dep= $parser->add_parser('dep', help => "Dependency syntactic analysis");
$dep->add_args(@common_args);
$dep->add_argument('-a', type => 'Bool', dest => 'a', help => "Simple dependency analysis (by default syntactic output");
$dep->add_argument('-fa', type => 'Bool', dest => 'fa', help => "Full dependency analysis");
$dep->add_argument('-c', type => 'Bool', dest => 'c', help => "Tagged text with syntactic information (for correction rules)");
$dep->add_argument('-conll', type => 'Bool', dest => 'conll', help => "CoNLL output style");

my $tagger= $parser->add_parser('tagger', help => "Part-of-speech tagging");
$tagger->add_args(@common_args);
$tagger->add_argument('-noner', type => 'Bool', dest => 'noner', help => "No NER or NEC is processed (by default PoS tagger output)");
$tagger->add_argument('-ner', type => 'Bool', dest => 'ner', help => "PoS tagger with Named Entity Recognition - NER (only with 'tagger' module)");
$tagger->add_argument('-nec', type => 'Bool', dest => 'nec', help => "PoS tagger with Named Entity Classification - NEC (only with 'tagger' module)");

my $mwe= $parser->add_parser('mwe', help => "Multiword extraction");
$mwe->add_args(@common_args);
$mwe->add_argument('-chi', type => 'Bool', dest => 'chi', help => "Chi-square co-occurrence measure (by default)");
$mwe->add_argument('-log', type => 'Bool', dest => 'log', help => "Loglikelihood ");
$mwe->add_argument('-scp', type => 'Bool', dest => 'scp', help => "Symmetrical conditional probability");
$mwe->add_argument('-mi', type => 'Bool', dest => 'mi', help => "Mutual information ");
$mwe->add_argument('-cooc', type => 'Bool', dest => 'cooc', help => "Co-occurrence counting");

my $key= $parser->add_parser('key', help => "Keyword extraction");
$key->add_args(@common_args);

my $recog= $parser->add_parser('recog', help => "Language recognition");
$recog->add_args(@common_args[1..2]);

my $sent= $parser->add_parser('sent', help => "Sentiment analysis");
$sent->add_args(@common_args);

my $rel= $parser->add_parser('rel', help => "Relation extraction");
$rel->add_args(@common_args);

my $tok= $parser->add_parser('tok', help => "Tokenizer");
$tok->add_args(@common_args);
$tok->add_argument('-split', type => 'Bool', dest => 'split', help => "Tokenization with splitting");
$tok->add_argument('-sort', type => 'Bool', dest => 'sort', help => "Tokenization with tokens sorted by frequency");

my $seg= $parser->add_parser('seg', help => "Sentence segmentation");
$seg->add_args(@common_args);

my $lem= $parser->add_parser('lem', help => "Lemmatization");
$lem->add_args(@common_args);

my $kwic= $parser->add_parser('kwic', help => "Keyword in context (concordances)");
$kwic->add_args(@common_args);
$kwic->add_argument('-tokens', type => 'Scalar', dest => 'tokens', required => 1 ,help => "the keyword to be searched");

my $link= $parser->add_parser('link', help => "Entity linking and semantic annotation");
$link->add_args(@common_args);
$link->add_argument('-json', type => 'Bool', dest => 'json', help => "Json output format of entity linking (by default)");
$link->add_argument('-xml', type => 'Bool', dest => 'xml', help => "Xml output format of entity linking");

my $sum= $parser->add_parser('sum', help => "Text summarizer");
$sum->add_args(@common_args);
$sum->add_argument('-p', type => 'Scalar', dest => 'percentage', help => "Percentage of the input text that will be summarized (by default 10%)");

my $conj= $parser->add_parser('conj', help => "Verb conjugator");
$conj->add_args(@common_args);
$conj->add_argument('-pe', type => 'Bool', dest => 'pe', help => "The verb conjugator uses European Portuguese (by default)");
$conj->add_argument('-pb', type => 'Bool', dest => 'pb', help => "The verb conjugator uses Brasilian Portuguese");
$conj->add_argument('-pen', type => 'Bool', dest => 'pen', help => "The verb conjugator uses European Portuguese before the spell agreement");
$conj->add_argument('-pbn', type => 'Bool', dest => 'pbn', help => "The verb conjugator uses Brasilian Portuguese before the spell agreement");

my $coref= $parser->add_parser('coref', help => "Named entity coreference solver");
$coref->add_args(@common_args);
$coref->add_argument('-crnec', type => 'Bool', dest => 'crnec', help => "NEC correction with NE Coreference Resolution");

my $args = $parser->parse_args();

my $LING = $args->get_attr("lang")?$args->lang:"en";
my $MOD = $args->current_command();
my $FILE = $args->get_attr("input");
my $STRING = $args->get_attr("string");

###################################################################
# Script to use different linguistic tools, for instance:
#   - - dependency parser (DepPattern)
#   - - PoS tagger + NER + NEC
#   - - Sentiment Analysis 
#   - - Multiword Extractor (GaleXtra)
#
# Pablo Gamallo
# ProLNat@GE Group, CiTIUS
# University of Santiago de Compostela
###################################################################

############################
# Config
############################
my $MAIN_DIR = dirname(__FILE__);
unshift(@INC, $MAIN_DIR);

my $PROGS = "$MAIN_DIR/scripts";
my $DIRPARSER = "$MAIN_DIR/parsers";

my $NAMEPARSER ="$DIRPARSER/parserDefault-$LING.perl";
my $FILTER ="$PROGS/AdapterFreeling-${LING}.perl";
my $CONLL ="$PROGS/saidaCoNLL-fa.perl";

my $SENT = "$MAIN_DIR/tagger/$LING/sentences-${LING}_exe.perl";
my $TOK = "$MAIN_DIR/tagger/$LING/tokens-${LING}_exe.perl";
my $SPLIT = "$MAIN_DIR/tagger/$LING/splitter-${LING}_exe.perl";
my $LEMMA = "$MAIN_DIR/tagger/$LING/lemma-${LING}_exe.perl";
my $NER = "$MAIN_DIR/tagger/$LING/ner-${LING}_exe.perl";
my $TAGGER = "$MAIN_DIR/tagger/$LING/tagger-${LING}_exe.perl" ;
my $NEC = "$MAIN_DIR/tagger/$LING/nec-${LING}_exe.perl";

my $COREF = "$MAIN_DIR/tagger/coref/coref_exe.perl";

my $SENTIMENT = "$MAIN_DIR/sentiment/nbayes.perl";

my $MWE = "$MAIN_DIR/mwe/mwe.perl";
my $MWE_FILT = "$MAIN_DIR/mwe/filtro_galextra.perl";
my $MWE_SIX = "$MAIN_DIR/mwe/six_tokens.perl";

my $KEYWORD = "$MAIN_DIR/keywords/keywords_exe.perl";
my $REL = "$MAIN_DIR/triples/triples_exe.perl";
my $LINK = "$MAIN_DIR/linking/linking_exe.perl";
my $SUM = "$MAIN_DIR/summarizer/summarizer_exe.perl";
my $CONJ = "$MAIN_DIR/conjugator/conjugator_exe.perl";

my $QUELINGUA = "$MAIN_DIR/lanrecog/lanrecog.perl";
my $QUELINGUA_LEX = "$MAIN_DIR/lanrecog/build_lex.perl";

my $KWIC = "$MAIN_DIR/kwic/kwic.perl";


#######################
#      EXECUTION      #
#######################
my $input;
if($FILE){
	if ($STRING){
		open($input,"<",\$FILE);
	}elsif ($FILE =~ m/\.zip$/){
		open ($input, '<:gzip', $FILE) or die("'$FILE' not found.");
	}else{
		open ($input, '<', $FILE) or die("'$FILE' not found.");
	}
	binmode $input, ':utf8';
}else{
	$input = \*STDIN;
}


if($MOD eq "dep"){
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $NER;
	do $TAGGER;
	do $FILTER;
	do $NAMEPARSER;

	if($args->conll){  ##Conll dependency output
		do $CONLL;
		while(my $line = <$input>){
			my $list = CONLL::conll(Parser::parse(AdapterFreeling::adapter(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), '-fa'));
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}elsif($args->fa){
		while(my $line = <$input>){
			my $list = Parser::parse(AdapterFreeling::adapter(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))),  '-fa');
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}elsif($args->c){
		while(my $line = <$input>){
			my $list = Parser::parse(AdapterFreeling::adapter(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), '-c');
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}else{##by default dependency output
		while(my $line = <$input>){
			my $list = Parser::parse(AdapterFreeling::adapter(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), '-a');
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}

}elsif($MOD eq "rel"){  ##Triples extration (Open Information Extraction)
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $NER;
	do $TAGGER;
	do $FILTER;
	do $NAMEPARSER;
	do $CONLL;
	do $REL;

	while(my $line = <$input>){
		my $list = Triples::triples(CONLL::conll(Parser::parse(AdapterFreeling::adapter(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), '-fa')));
		for my $result (@{$list}){
			print "$result\n";
		}
	}
	
#	while(my $line = <$input>){
#		my $list = Triples::triples(CONLL::conll(Parser::parse(AdapterFreeling::adapter(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), '-fa')));
#		for my $result (@{$list}){
#			print "$result\n";
#		}
#	}

}elsif($MOD eq "tagger"){
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $TAGGER;

	if ($args->ner){  ##PoS tagging with ner
		do $NER;
		while(my $line = <$input>){
			my $list = Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))));
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}elsif($args->nec){  ##PoS tagging with nec
		do $NER;
		do $NEC;
		while(my $line = <$input>){
			my $list = Nec::nec(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))));
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}else{  ##by default PoS tagging
		do $LEMMA;
		while(my $line = <$input>){
			my $list = Tagger::tagger(Lemma::lemma(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))));
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}

}elsif($MOD eq "coref"){
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $NER;
	do $TAGGER;
	do $NEC;
	do $COREF;
	my $Mentions_id = {};#<ref><hash><integer>

	if($args->crnec){  ##PoS tagging with Coreference Resolution and NEC correction
		while(my $line = <$input>){
			my $list = Coref::coref(0, 1, Nec::nec(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), 500, $Mentions_id);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}else{  ##PoS tagging with Coreference Resolution
		while(my $line = <$input>){
			my $list = Coref::coref(1, 0, Nec::nec(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])))))), 500, $Mentions_id);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}

}elsif($MOD eq "mwe"){  ##multiword extraction
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $NER;
	do $TAGGER;
	do $MWE_FILT;
	do $MWE_SIX;
	do $MWE;

	if($args->log){
		while(my $line = <$input>){
			my $list = Mwe::mwe(SixTokens::sixTokens(FiltroGalExtra::filtro(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))))),"-log",1);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}elsif($args->scp){
		while(my $line = <$input>){
			my $list = Mwe::mwe(SixTokens::sixTokens(FiltroGalExtra::filtro(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))))),"-scp",1);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}elsif($args->mi){
		while(my $line = <$input>){
			my $list = Mwe::mwe(SixTokens::sixTokens(FiltroGalExtra::filtro(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))))),"-mi",1);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}elsif($args->cooc){
		while(my $line = <$input>){
			my $list = Mwe::mwe(SixTokens::sixTokens(FiltroGalExtra::filtro(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))))),"-cooc",1);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}else{
		while(my $line = <$input>){
			my $list = Mwe::mwe(SixTokens::sixTokens(FiltroGalExtra::filtro(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))))),"-chi",1);
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}

}elsif($MOD eq "key"){
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $NER;
	do $TAGGER;
	do $KEYWORD;
	Keywords::load($LING);

	while(my $line = <$input>){
		my $list = Keywords::keywords(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))));
		for my $result (@{$list}){
			print "$result\n";
		}
	}

}elsif($MOD eq "sent"){  ##sentiment analysis
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $NER;
	do $TAGGER;
	do $SENTIMENT;
	Nbayes::load($LING);

	while(my $line = <$input>){
		my $result = Nbayes::nbayes(Tagger::tagger(Ner::ner(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))))));
		print "$result\n";
	}


}elsif($MOD eq "recog"){  ##language recognition
	do $SENT;
	do $TOK;
	do $QUELINGUA_LEX;
	do $QUELINGUA;
	my %Peso = ();#Line acumulator
	
	while(my $line = <$input>){
		my $ling = LanRecog::langrecog(Tokens::tokens(Sentences::sentences([$line])));
		$Peso{$ling}++;
	}
	
	foreach my $ling (sort {$Peso{$b} <=> $Peso{$a}} keys %Peso ) {
		print "$ling\n";
		last;
	}

}elsif($MOD eq "tok"){  ##tokenizer
	do $SENT;
	do $TOK;
	if($args->sort){  ##tokenizer with sorting by frequency
		do $SPLIT;
		my %count = ();
		while(my $line = <$input>){
			my $list = Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])));
			for my $token (@{$list}){
				$count{$token} = $count{$token} ? $count{$token} + 1 : 1;
			}
		}
		for my $result (sort {$count{$b} <=> $count{$a}} keys %count){
			print "$count{$result}\t$result\n";
		}
	}elsif($args->split){
		do $SPLIT;
		while(my $line = <$input>){
			my $list = Splitter::splitter(Tokens::tokens(Sentences::sentences([$line])));
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}else{
		while(my $line = <$input>){
			my $list = Tokens::tokens(Sentences::sentences([$line]));
			for my $result (@{$list}){
				print "$result\n";
			}
		}
	}

}elsif($MOD eq "seg"){  ##segmentation
	do $SENT;
	while(my $line = <$input>){
		my $list = Sentences::sentences([$line]);
		for my $result (@{$list}){
			print "$result\n";
		}
	}

}elsif($MOD eq "lem"){  ##lemmatizer and PoS tagging
	do $SENT;
	do $TOK;
	do $SPLIT;
	do $LEMMA;
	while(my $line = <$input>){
		my $list = Lemma::lemma(Splitter::splitter(Tokens::tokens(Sentences::sentences([$line]))));
		for my $result (@{$list}){
			print "$result\n";
		}
	}

}elsif($MOD eq "kwic"){  ##key word in context (kwic) or concordances with just tokens as context
	do $SENT;
	do $KWIC;
	while(my $line = <$input>){
		my $list = Kwic::kwic(Sentences::sentences([$line]),$args->tokens);
		for my $result (@{$list}){
			print "$result\n";
		}
	}

}elsif($MOD eq "link"){  ##entity linking
	do $LINK;
	if($args->xml){
		while(my $line = <$input>){
			my $result = Linking::linking($line,$LING,"xml");
			print "$result\n"
		}
	}else{
		while(my $line = <$input>){
			my $result = Linking::linking($line,$LING,"json");
			print "$result\n"
		}
	}

}elsif($MOD eq "sum"){  ##summarizer
	do $SUM;
	if($args->percentage){
		my @lines = <$input>;
		my $result = Summarizer::summarizer(join("\n" ,@lines),$LING,$args->percentage);
		print "$result\n"
		
	}else{
		my @lines = <$input>;
		my $result = Summarizer::summarizer(join("\n" ,@lines),$LING,10);
		print "$result\n"
	}
}elsif($MOD eq "conj"){  ##conjugator
	do $CONJ;
	if($args->pe){
		while(my $line = <$input>){
			my $result = Conjugator::conjugator($line,$LING,'-pe');
			print "$result\n"
		}
	}elsif($args->pb && $LING eq "pt"){
		while(my $line = <$input>){
			my $result = Conjugator::conjugator($line,$LING,'-pb');
			print "$result\n"
		}
	}elsif($args->pen && $LING eq "pt"){
		while(my $line = <$input>){
			my $result = Conjugator::conjugator($line,$LING,'-pen');
			print "$result\n"
		}
	}elsif($args->pbn && $LING eq "pt"){
		while(my $line = <$input>){
			my $result = Conjugator::conjugator($line,$LING,'-pbn');
			print "$result\n"
		}
	}else{
		while(my $line = <$input>){
			my $result = Conjugator::conjugator($line,$LING);
			print "$result\n"
		}
	}
}
close($input);