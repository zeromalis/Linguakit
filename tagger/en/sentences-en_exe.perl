#!/usr/bin/env perl

# Separador de frases
# autor: Pablo Gamallo e Marcos Garcia
# Grupo ProlNat@GE, CiTIUS
# Universidade de Santiago de Compostela

# Inglês com base no Português

# SEPARA FRASES IDENTIFICANDO O PONTO FINAL

use strict; 
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
use utf8;

# Absolute path 
use Cwd 'abs_path';
use File::Basename;
my $abs_path = dirname(abs_path($0));

##ficheiros de recursos
open (ABR, $abs_path."/lexicon/abreviaturas-en.txt") or die "Faltam as abreviaturas: $!\n";
binmode ABR,  ':utf8';
my @abr = <ABR>;

##variaveis globais
my $UpperCase = "[A-ZÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÑÇÜ]" ;
my $LowerCase = "[a-záéíóúàèìòùâêîôûñçü]" ;

my $Abr;
foreach my $line (@abr) { ##lendo as abreviaturas...
	chomp $line;
	my ($abr, $trad) = split (" ", $line) if ($line =~ /\./);
        $abr =~ s/\./\\./g;
	#$abr = lc $abr; ## Marcos: comento isto para dar cobertura a abreviaturas em maiúscula (Prof. X). Dupliquei as abreviaturas na lista
        $Abr .= "|" . "$abr" ;
	
}
$Abr =~ s/\|[\|]+/\|/g;
$Abr =~ s/^\|//g;
#print STDERR "#$Abr#\n";
#my $separador = "\.\n" ;
#$/ = $separador;

#sub sentences {
my $CountLines=0;
while (my $texto = <STDIN>) { 
  if ( ($CountLines % 100) == 0) {;
       printf  STDERR "- - - number of lines :(%6d) - - -\r",$CountLines;
  }
  $CountLines++;
  
   # my @saida;
    
    my $mark_abr = "<ABR-TMP>";
    my $mark_sigla= "<SIGLA-TMP>"; 
    
    ##identificando abreviaturas no texto e substitui-las por um marcador temporal
    $texto =~ s/ ($Abr) / $1$mark_abr /ig;
#    print STDERR "--#$texto#\n";
    
    $texto =~ s/\.($mark_abr)/$1/g;
    
    ##identificar pontos dentro de urls, emails..
    $texto =~ s/($LowerCase)\.($LowerCase)/$1$mark_sigla$2/g;
    
    ##identificar tres pontos
    $texto =~ s/\.\.\./$mark_sigla$mark_sigla$mark_sigla/g;
    
    ##identificar pontos entre quantidades:
    $texto =~  s/([0-9]+)\.([0-9]+)/$1$mark_sigla$2/g;
    
    #Identificar siglas com ponto intermedio
    #print STDERR "1#$texto#";
    $texto =~ s/($UpperCase)\.($UpperCase)/$1$mark_sigla$2/g;
    $texto =~ s/($mark_sigla$UpperCase)\.($UpperCase)/$1$mark_sigla$2/g;
    
    $texto =~ s/($mark_sigla$UpperCase)\.([\s]+)($LowerCase)/$1$mark_sigla$2$3/g; ##o P.P. está ....
    
    #print STDERR "2#$texto#";
    
    #$texto =~ s/\./\.\n/g; ##resto de pontos: final de frase 
    $texto =~ s/\.([^\"'])/\.\n$1/g;
    $texto =~ s/$/\n/ ; ##final de texto: final de frase
    
    ##limpar espaços principio de linha
    $texto =~ s/(\n)[\s]+/$1/g;
    
    ##restaurar pontos que não marcam final de frase
    $texto =~ s/$mark_abr/\./g;
    $texto =~ s/$mark_sigla/\./g;
 
    print "$texto";
#    push (@saida, $texto);
#return @saida;    
}
