#!/usr/bin/perl
#------------------------------------------------------------------------------------------
#
#    Lecture et manipulation des fichiers d'albédos de surface calculs par Maélie
#
#------------------------------------------------------------------------------------------
# D. Cordier, 4-29 octobre 2019.
#
# 2019/10/29 : - passage au ratio (pas d'écart à la moyenne) et ajout du calcul de l'albédo moyen 
#                dans la fenêtre à 5 microns.
#
# 2019/11/04 - v1.9 : ajout du calcul de l'incertitude relative sur l'albédo, pour chaque pixel.
# 2021/06/16 : test de publication sur Zenodo.
#
use Term::ANSIColor; # Sortie standard avec des couleurs.

#------------------------------------------------------------------------------------------
#
print "\n";
print color('bold red');   
print " ----------------------------------------------------------------------------\n";
print " ---                                                                       --\n";
print " ---             Lecture et traitement des albédos de surface              --\n";
print " ---                                                                       --\n";
print " ----------------------------------------------------------------------------\n";
print color('reset');
print "\n";
#
#------------------------------------------------------------------------------------------
my $now_string = localtime;  # On récupère la date et l'heure d'exécution afin de la reporter dans les fichiers de sortie.

#------------------------------------------------------------------------------------------
# Nom de fichier de sortie passé en argument du script :
#$CUBE_ID          = $ARGV[0]; 
#$file_out_27_28   = $ARGV[1]; $file_out_20_108  = $ARGV[2]; $file_out_20_128 = $ARGV[3]; 
#$file_out_159_128 = $ARGV[4]; $file_out_128_108 = $ARGV[5]; $file_out_moy5   = $ARGV[6];
#
#if ( $CUBE_ID eq "" || $file_out_27_28 eq "" || $file_out_20_108 eq "" || $file_out_20_128 eq "" || $file_out_159_128 eq "" || $file_out_128_108 eq "" || $file_out_moy5 eq "" ){
#    print color('yellow'); 
#    print "Usage: $0 CUBE_ID (e.g. C1809727868_1)file_out_2p7_2p8 file_out_2p0_1p08 file_out_20_128 file_out_159_128 file_out_128_108 file_out_moy5\n";
#    print "\n";
#    print "        0- CUBE_ID           : l'identifiant du cube\n";
#    print "        1- file_out_2p7_2p8  : fichier d'output contenant le rapport 2.7/2.8\n";
#    print "        2- file_out_2p0_1p08 : fichier d'output contenant le rapport 2.0/1.08\n";
#    print "        3- file_out_20_128   : fichier d'output contenant le rapport 2.0_1.28\n";
#    print "        4- file_out_159_128  : fichier d'output contenant le rapport 1.59/1.28\n";
#    print "        5- file_out_128_108  : fichier d'output contenant le rapport 1.28/1.08\n";
#    print "        6- file_out_moy5     : fichier d'output contenant la moyenne de l'albédo sur la fenêtre à 5 microns\n";
#    print color('reset');
#    print "\n";
#    exit(0);
#}

# Exemple de nom de fichier : "C1590648776_1_3-1_test_SHDOMPP_SFCPARMS.dat"

#  C1590648776_1_3-14_test_SHDOMPP_SFCPARMS.dat 
#
# Pour extraire les valeurs de "sample" et "line" des noms de fichiers on a besoin de deux clefs :
$CUBE_ID          = "C1590648776_1"; # clef pour enlever le début du nom de fichier.
#$CUBE_ID          = "C1809727868_1"; # clef pour enlever le début du nom de fichier.
#$FILE_TAIL        = "_test_legendp2.3_SFCPARMS.dat"; # clef pour extraire la fin du nom de fichier.
$FILE_TAIL        = "_test_SHDOMPP_SFCPARMS.dat"; # clef pour extraire la fin du nom de fichier.

$LABEL = "C15_STD"; # Identifiant du calcul/traitement de données.

$file_out_27_28   = $LABEL."_2p7_2p8.gltin"; 
$file_out_20_108  = $LABEL."_2p0_1p08.gltin"; 
$file_out_20_128  = $LABEL."_20_128.gltin"; 
$file_out_159_128 = $LABEL."_159_128.gltin"; 
$file_out_128_108 = $LABEL."_128_108.gltin"; 
$file_out_moy5    = $LABEL."_moy5.gltin"; 

#------------------------------------------------------------------------------------------
# On liste tous les fichiers d'albdos prsents dans le rpertoire de travail :
@list_file_albedo= `ls -1 *_SFCPARMS.dat`;

# On compte le nombre total de fichiers d'albdo :
$nbr_files_albe = @list_file_albedo;

print color('bold red');
print " > Nombre total de fichiers d'albédo dans ce répertoire : ";
print color('bold blue');
print "$nbr_files_albe\n";
print color('reset');

#------------------------------------------------------------------------------------------
# Indice des canaux VIMS qu'on utilise pour faire des rapports :
$i_IsF_2p7= 112;
$i_IsF_2p8= 116;

$i_IsF_2p00= 69;
$i_IsF_1p08= 13;

$i_IsF_1p28= 25;

$i_IsF_1p57= 43;
$i_IsF_1p59= 44;

# Limites de la fenêtre à 5 microns :
$i_min_5microns_window= 241;
$i_MAX_5microns_window= 256;

#------------------------------------------------------------------------------------------
# Message d'information :
$file_list= "liste_des_fichiers_albedos_utilises.list";
print color('bold red');
print " > La liste exhaustive des fichiers d'albedo utilises par ce script va etre ecrite dans le fichier : ";
print color('bold blue');
print "$file_list\n";
print color('reset');

#------------------------------------------------------------------------------------------
# Extraction des coordonnes des pixels :

$first= 1;
$moy_ratio_2p7_2p8  = 0.;
$moy_ratio_2p00_1p08= 0.;
$moy_ratio_2p00_1p28= 0.;
$moy_ratio_1p59_1p28= 0.;
$moy_ratio_1p28_1p08= 0.;

# Les incertitudes relatives MOYENNES (sur le cube, ou les pixels sélectionnés) des ratios d'albédos ou albédos :
$AVERAGE_Uncert_ratio_2p7_2p8   = 0.;
$AVERAGE_Uncert_ratio_2p00_1p08 = 0.;
$AVERAGE_Uncert_ratio_2p00_1p28 = 0.;
$AVERAGE_Uncert_ratio_1p59_1p28 = 0.;
$AVERAGE_Uncert_ratio_1p28_1p08 = 0.;
$AVERAGE_Uncert_moy_albe_5micron= 0.;

open(FILE_LIST, "> $file_list"); # Fichier dans lequel on enregistre la liste des fichiers traités par ce script.

for (my $i = 0; $i < $nbr_files_albe; $i++) {
    $file= $list_file_albedo[$i];
    $file=~ s/\n//;
    $pixel_coord= $file;
    
    $motifdebut= $CUBE_ID."_";
    $pixel_coord=~ s/$motifdebut//;
    $pixel_coord=~ s/$FILE_TAIL//;
    
    @coord= split(/-/, $pixel_coord);
    
    $sample= $coord[0];
    $line  = $coord[1];
    
    if ($first == 1) { # On initialise les valeurs des bornes de 'sample' et 'line' :
       $sample_min= $sample;
       $sample_max= $sample;
       $line_min  = $line;
       $line_max  = $line;
       $first= 0;
    }
    
    if ($sample < $sample_min) {
       $sample_min= $sample;
    }
    if ($sample > $sample_max) {
       $sample_max= $sample;
    }
    if ($line < $line_min) {
       $line_min= $line;
    }
    if ($line > $line_max) {
       $line_max= $line;
    }
    
    #$rank= $i+1;
    #print " -- $rank $file :: $pixel_coord == $sample[$i] $line[$i]\n";
    
    # -----------------------------------------------------------
    # Lecture du fichier ----------------------------------------
    $file_in = $file;
    $moy_albe_5micron= 0.; # Albédo moyen dans la fenêtre à 5 microns.
    $moy_albe_5micron_err_min= 0.; # Pour estimer l'erreur sur l'albédo moyen à 5 microns.
    $moy_albe_5micron_err_max= 0.; # Pour estimer l'erreur sur l'albédo moyen à 5 microns.
    
    $n_data_5mic= 0;       # Nbr de valeurs dans la fenêtre à 5 microns.
    open(FILE_IN, "< $file_in") 
    or die " *** le fichier : $file_in n'est pas lisible : $!";
    # Oprations sur les fichiers :
    #print "    - lecture de $file_in\n";
    $ifile= $i+1;
    printf FILE_LIST ("$ifile : $file_in\n");
    
    $ligne=<FILE_IN>; # On saute la première ligne.
    $il= 0;
    while ( defined($ligne=<FILE_IN>)) { # Procéder avec "defined( ..." sinon on
          @champ = split(/\s+/, $ligne); # permet de ventiler les donnes sépares
                                   # par un nombre quelconque de blancs sur
                                   # une ligne données.
          $il=$il+1;
          # Ratio 2.7/2.8 -----------------------------
          $lambda= $champ[1]/1.E-6;
          if ($il == $i_IsF_2p7) {
             $IsF_2p7= $champ[2];
             $IsF_2p7_err_min= $champ[6];
             $IsF_2p7_err_max= $champ[7];
          }
          if ($il == $i_IsF_2p8) {
             $IsF_2p8= $champ[2];
             $IsF_2p8_err_min= $champ[6];
             $IsF_2p8_err_max= $champ[7];
          }
          
          # Ratio 2.0/1.08 -----------------------------
          if ($il == $i_IsF_2p00) {
             $IsF_2p00= $champ[2];
             $IsF_2p00_err_min= $champ[6];
             $IsF_2p00_err_max= $champ[7];
          }
          if ($il == $i_IsF_1p08) {
             $IsF_1p08= $champ[2];
             $IsF_1p08_err_min= $champ[6];
             $IsF_1p08_err_max= $champ[7];
          }
          
          # Ratio 2.0/1.28 -----------------------------
          if ($il == $i_IsF_1p28) {
             $IsF_1p28= $champ[2];
             $IsF_1p28_err_min= $champ[6];
             $IsF_1p28_err_max= $champ[7];
          }

          # Ratio 1.59/1.28 -----------------------------
          if ($il == $i_IsF_1p59) {
             $IsF_1p59= $champ[2];
             $IsF_1p59_err_min= $champ[6];
             $IsF_1p59_err_max= $champ[7];
          }
          
          # --------------------------------------------
          # Calcul de l'albédo moyen sur la fenêtre à 5 microns :
          if ( ($i_min_5microns_window <= $il) && ($il <= $i_MAX_5microns_window) ) {
             $n_data_5mic= $n_data_5mic + 1;
             $moy_albe_5micron= $moy_albe_5micron + $champ[2];
             $moy_albe_5micron_err_min= $moy_albe_5micron_err_min + $champ[6];
             $moy_albe_5micron_err_max= $moy_albe_5micron_err_max + $champ[7];
          }
    }
    close(FILE_IN);
    
    # Ratio 2.7/2.8 : ------------------------------------------------------------
    $ratio_2p7_2p8[$sample][$line]= $IsF_2p7 / $IsF_2p8;
    $moy_ratio_2p7_2p8= $moy_ratio_2p7_2p8 + $ratio_2p7_2p8[$sample][$line]; # Pour calculer la moyenne du ratio 2.7/2.8.
    
    $Delta_2p7= ($IsF_2p7_err_max - $IsF_2p7_err_min) / 2.;
    $Delta_2p8= ($IsF_2p8_err_max - $IsF_2p8_err_min) / 2.;
    
    #print "  $IsF_2p7 $IsF_2p8\n";
    
    if ( ($IsF_2p7 == 0.) && ($IsF_2p8 == 0.)  ) {
        $Delta_ratio_2p7_2p8[$sample][$line]= 0.;
    } else {
      if (($IsF_2p7 != 0.) && ($IsF_2p8 != 0.)) {
	  $Delta_ratio_2p7_2p8[$sample][$line]= $Delta_2p7 / $IsF_2p7 + $Delta_2p8 / $IsF_2p8;
      } else {
        if ( $IsF_2p7 == 0.) {
           $Delta_ratio_2p7_2p8[$sample][$line]= $Delta_2p8 / $IsF_2p8;
        }
        if ( $IsF_2p8 == 0.) {
           $Delta_ratio_2p7_2p8[$sample][$line]= $Delta_2p7 / $IsF_2p7;
        }
      }
    }

    #print "$Delta_ratio_2p7_2p8[$sample][$line]\n";       
    
    $AVERAGE_Uncert_ratio_2p7_2p8  = $AVERAGE_Uncert_ratio_2p7_2p8 + $Delta_ratio_2p7_2p8[$sample][$line];

    # Ratio 2.0/1.08 : ------------------------------------------------------------
    #if (!($IsF_1p08 < 0.005)) {
    if (!($IsF_1p08 == 0.)) {
        $ratio_2p00_1p08[$sample][$line]= $IsF_2p00 / $IsF_1p08;
    } else {
	$ratio_2p00_1p08[$sample][$line]= 0.;
    }
    $moy_ratio_2p00_1p08= $moy_ratio_2p00_1p08 + $ratio_2p00_1p08[$sample][$line]; # Pour calculer la moyenne du ratio 2.00/1.08.
    
    $Delta_2p00= ($IsF_2p00_err_max - $IsF_2p00_err_min) / 2.;
    $Delta_1p08= ($IsF_1p08_err_max - $IsF_1p08_err_min) / 2.;
    
    if ( ($IsF_2p00 == 0.) && ($IsF_1p08 == 0.) ) {
	$Delta_ratio_2p00_1p08[$sample][$line]= 0.;
    } else {
	if ( ($IsF_2p00 != 0.) && ($IsF_1p08 != 0.) ) {
	   $Delta_ratio_2p00_1p08[$sample][$line]= $Delta_2p00 / $IsF_2p00 + $Delta_1p08 / $IsF_1p08;
	} else {
	   if ( $IsF_2p00 == 0. ) {
	      $Delta_ratio_2p00_1p08[$sample][$line]= $Delta_2p00 / $IsF_2p00;
	   }
	   if ( $IsF_1p08 == 0. ) {
	      $Delta_ratio_2p00_1p08[$sample][$line]= $Delta_2p00 / $IsF_2p00;
	   }
	}
    }
    
    #print " $IsF_2p00 $IsF_1p08 \n";
    #print "$Delta_2p00 -- $Delta_1p08 -- $Delta_ratio_2p00_1p08[$sample][$line]\n";
    $AVERAGE_Uncert_ratio_2p00_1p08= $AVERAGE_Uncert_ratio_2p00_1p08 + $Delta_ratio_2p00_1p08[$sample][$line];

    # Ratio 2.0/1.28 : ------------------------------------------------------------
    $ratio_2p00_1p28[$sample][$line]= $IsF_2p00 / $IsF_1p28;
    $moy_ratio_2p00_1p28= $moy_ratio_2p00_1p28 + $ratio_2p00_1p28[$sample][$line];
    
    $Delta_2p00= ($IsF_2p00_err_max - $IsF_2p00_err_min) / 2.;
    $Delta_1p28= ($IsF_1p28_err_max - $IsF_1p28_err_min) / 2.;
    
    $Delta_ratio_2p00_1p28[$sample][$line]= $Delta_2p00 / $IsF_2p00 + $Delta_1p28 / $IsF_1p28;   
    #print "$Delta_ratio_2p00_1p28[$sample][$line]\n"; 
    $AVERAGE_Uncert_ratio_2p00_1p28= $AVERAGE_Uncert_ratio_2p00_1p28 + $Delta_ratio_2p00_1p28[$sample][$line];

    # Ratio 1.59/1.28 : ------------------------------------------------------------
    #$IsF_1p5759= $IsF_1p57 + $IsF_1p59; 
    
    $ratio_1p59_1p28[$sample][$line]= $IsF_1p59 / $IsF_1p28;
    $moy_ratio_1p59_1p28= $moy_ratio_1p59_1p28 + $ratio_1p59_1p28[$sample][$line];
    
    $Delta_1p59= ($IsF_1p59_err_max - $IsF_1p59_err_min) / 2.;
    $Delta_1p28= ($IsF_1p28_err_max - $IsF_1p28_err_min) / 2.;
    
    $Delta_ratio_1p59_1p28[$sample][$line]= $Delta_1p59 / $IsF_1p59 + $Delta_1p28 / $IsF_1p28;
    #print " $Delta_ratio_1p59_1p28[$sample][$line]\n";
    $AVERAGE_Uncert_ratio_1p59_1p28= $AVERAGE_Uncert_ratio_1p59_1p28 + $Delta_ratio_1p59_1p28[$sample][$line];

    # Ratio 1.28/1.08 : ------------------------------------------------------------
    #    if (!($IsF_1p08 < 0.005)) {
    if (!($IsF_1p08 == 0.)) {
	$ratio_1p28_1p08[$sample][$line]= $IsF_1p28 / $IsF_1p08;
	
	$Delta_1p28= ($IsF_1p28_err_max - $IsF_1p28_err_min) / 2.;
	$Delta_1p08= ($IsF_1p08_err_max - $IsF_1p08_err_min) / 2.;
	
	$Delta_ratio_1p28_1p08[$sample][$line]= $Delta_1p28 / $IsF_1p28 + $Delta_1p08 / $IsF_1p08;
	
    } else {
	$ratio_1p28_1p08[$sample][$line]= 0.;
	$Delta_ratio_1p28_1p08[$sample][$line]= 0.;
    }
    $moy_ratio_1p28_1p08= $moy_ratio_1p28_1p08 + $ratio_1p28_1p08[$sample][$line]; # Pour calculer la moyenne du ratio 1.28/1.08.
    #print "$Delta_ratio_1p28_1p08[$sample][$line]\n";
    $AVERAGE_Uncert_ratio_1p28_1p08= $AVERAGE_Uncert_ratio_1p28_1p08 + $Delta_ratio_1p28_1p08[$sample][$line];
    
    # Moyenne de l'albédo dans la fenêtre à 5 microns : ----------------------------
    $moy_albe5m[$sample][$line]= $moy_albe_5micron / $n_data_5mic;
    
    $moy_albe_5micron_err_min= $moy_albe_5micron_err_min / $n_data_5mic;
    $moy_albe_5micron_err_max= $moy_albe_5micron_err_max / $n_data_5mic;
    
    $Delta_moy_albe_5micron[$sample][$line]= ($moy_albe_5micron_err_max - $moy_albe_5micron_err_min) / 2./ $moy_albe5m[$sample][$line];
    
    #print "> $sample $line $moy_albe5m[$sample][$line] -->> $Delta_moy_albe_5micron[$sample][$line]\n";
    #print "$Delta_moy_albe_5micron[$sample][$line]\n";
    $AVERAGE_Uncert_moy_albe_5micron= $AVERAGE_Uncert_moy_albe_5micron + $Delta_moy_albe_5micron[$sample][$line];
}
close(FILE_LIST);

print " \n";
print " > sample_min= $sample_min\n";
print " > sample_max= $sample_max\n";
print " > line_min  = $line_min\n";
print " > line_max  = $line_max\n";
print " \n";
$nbr_px = $sample_max * $line_max;
print " > sample_max * line_max  = ";
print color('blue');
print"$nbr_px\n";
print color('reset');
print " \n";

$moy_ratio_2p7_2p8= $moy_ratio_2p7_2p8 / $nbr_files_albe;
print " > Valeur moyenne (sur l'ensemble du cube) du ratio 2p7/2p8   = $moy_ratio_2p7_2p8\n";

$moy_ratio_2p00_1p08= $moy_ratio_2p00_1p08 / $nbr_files_albe;
print " > Valeur moyenne (sur l'ensemble du cube) du ratio 2p00/1p08 = $moy_ratio_2p00_1p08\n";

$moy_ratio_2p00_1p28= $moy_ratio_2p00_1p28 / $nbr_files_albe;
print " > Valeur moyenne (sur l'ensemble du cube) du ratio 2p00/1p28 = $moy_ratio_2p00_1p28\n";

$moy_ratio_1p59_1p28= $moy_ratio_1p59_1p28 / $nbr_files_albe;
print " > Valeur moyenne (sur l'ensemble du cube) du ratio 1p59/1p28 = $moy_ratio_1p59_1p28\n";

$moy_ratio_1p28_1p08= $moy_ratio_1p28_1p08 / $nbr_files_albe;
print " > Valeur moyenne (sur l'ensemble du cube) du ratio 1p28/1p08 = $moy_ratio_1p28_1p08\n";

print " \n";

# Calcul des incertitudes moyennes :
$AVERAGE_Uncert_ratio_2p7_2p8   = $AVERAGE_Uncert_ratio_2p7_2p8    / $nbr_files_albe;
$AVERAGE_Uncert_ratio_2p00_1p08 = $AVERAGE_Uncert_ratio_2p00_1p08  / $nbr_files_albe;
$AVERAGE_Uncert_ratio_2p00_1p28 = $AVERAGE_Uncert_ratio_2p00_1p28  / $nbr_files_albe;
$AVERAGE_Uncert_ratio_1p59_1p28 = $AVERAGE_Uncert_ratio_1p59_1p28  / $nbr_files_albe;
$AVERAGE_Uncert_ratio_1p28_1p08 = $AVERAGE_Uncert_ratio_1p28_1p08  / $nbr_files_albe;
$AVERAGE_Uncert_moy_albe_5micron= $AVERAGE_Uncert_moy_albe_5micron / $nbr_files_albe;

print " > Incertitudes relatives moyennes sur l'ensemble des pixels sélectionnés :\n";
print color('blue');
print "   - ratio 2.70/2.80 : $AVERAGE_Uncert_ratio_2p7_2p8\n";
print "   - ratio 2.00/1.08 : $AVERAGE_Uncert_ratio_2p00_1p08\n";
print "   - ratio 2.00/1.28 : $AVERAGE_Uncert_ratio_2p00_1p28\n";
print "   - ratio 1.59/1.28 : $AVERAGE_Uncert_ratio_1p59_1p28\n";
print "   - ratio 1.28/1.08 : $AVERAGE_Uncert_ratio_1p28_1p08\n";
print "   - alb. moy. 5 mic : $AVERAGE_Uncert_moy_albe_5micron\n";
print color('reset');
print " \n";

# ===============================================================================================================================
# ===============================================================================================================================
# ===============================================================================================================================
# Ecriture des fichiers de sorties :

# -----------------------------------------------------------
# Ecriture du fichier de sortie pour le ratio 2.7/2.8 :
open(FILE_OUT, "> $file_out_27_28");
$file_out_27_28_mat= $file_out_27_28.".matrix"; # Fichier "matrix" pour GNUplot
$file_out_27_28_err= $file_out_27_28.".err";    # Fichier "erreur" pour GNUplot
open(FILE_OUT_MAT, "> $file_out_27_28_mat");
open(FILE_OUT_ERR, "> $file_out_27_28_err");

print color('bold red');
print " > Ecriture des fichiers de sortie :";
print color('bold blue');
print " - $file_out_27_28\n";
print "                                     - $file_out_27_28_mat\n";
print "                                     - $file_out_27_28_err\n";
print color('reset');

printf FILE_OUT ("\# Maélie & Daniel -- Exploitation des données d'albédo.\n");
printf FILE_OUT ("\# Date : $now_string\n");
printf FILE_OUT ("\# \n");
printf FILE_OUT ("\# sample\n");
printf FILE_OUT ("\# |  line\n");
printf FILE_OUT ("\# |  |  Data\n");
printf FILE_OUT ("\# |  |  |\n");

for (my $i = $sample_min; $i <= $sample_max; $i++) {
    $myline= "";
    for (my $j = $line_min; $j <= $line_max; $j++) {
        # Construction de la ligne du fichier "matrix" pour GNUplot :
        #$my_ratio= $ratio_2p7_2p8[$i][$j];
        #$myline= $myline." $my_ratio";
        # Ecriture dans le fichier de sortie où les indices 'sample' et 'line' apparaissent :
        #printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $ratio_2p7_2p8[$i][$j]);
        

        $my_ratio= $ratio_2p7_2p8[$i][$j];
        $my_err  = $Delta_ratio_2p7_2p8[$i][$j];
        
        $myline= $myline." $my_ratio";
	printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $my_ratio); # 
	printf FILE_OUT_ERR ("%3d%3d %10.7f\n", $i, $j, $my_err); # 
    }
    printf FILE_OUT_MAT ("$myline"."\n");
    printf FILE_OUT ("\#\n");
    printf FILE_OUT_ERR ("\#\n");
}
close(FILE_OUT);
close(FILE_OUT_MAT);
close(FILE_OUT_ERR);

# -----------------------------------------------------------
# Ecriture du fichier de sortie pour le ratio 2.00/1.08 :
open(FILE_OUT, "> $file_out_20_108 ");
$file_out_20_108_mat= $file_out_20_108.".matrix"; # Fichier "matrix" pour GNUplot
$file_out_20_108_err= $file_out_20_108.".err";    # Fichier "erreur" pour GNUplot
open(FILE_OUT_MAT, "> $file_out_20_108_mat");
open(FILE_OUT_ERR, "> $file_out_20_108_err");

print "\n";
print color('bold red');
print " > Ecriture des fichiers de sortie :";
print color('bold blue');
print " - $file_out_20_108\n";
print "                                     - $file_out_20_108_mat\n";
print "                                     - $file_out_20_108_err\n";
print color('reset');

printf FILE_OUT ("\# Maélie & Daniel -- Exploitation des données d'albédo.\n");
printf FILE_OUT ("\# Date : $now_string\n");
printf FILE_OUT ("\# \n");
printf FILE_OUT ("\# sample\n");
printf FILE_OUT ("\# |  line\n");
printf FILE_OUT ("\# |  |  Data\n");
printf FILE_OUT ("\# |  |  |\n");

for (my $i = $sample_min; $i <= $sample_max; $i++) {
    $myline= "";
    for (my $j = $line_min; $j <= $line_max; $j++) {
        # Construction de la ligne du fichier "matrix" pour GNUplot :
        #$my_ratio= $ratio_2p00_1p08[$i][$j];
        #$myline= $myline." $my_ratio";
        # Ecriture dans le fichier de sortie où les indices 'sample' et 'line' apparaissent :
        #printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $ratio_2p00_1p08[$i][$j]);

        $my_ratio= $ratio_2p00_1p08[$i][$j];
        $my_err  = $Delta_ratio_2p00_1p08[$i][$j];
        
        $myline= $myline." $my_ratio";
        printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $my_ratio); # 
        printf FILE_OUT_ERR ("%3d%3d %10.7f\n", $i, $j, $my_err); # 
    }
    printf FILE_OUT_MAT ("$myline"."\n");
    printf FILE_OUT ("\#\n");
    printf FILE_OUT_ERR ("\#\n");
}
close(FILE_OUT);
close(FILE_OUT_MAT);
close(FILE_OUT_ERR);

# -----------------------------------------------------------
# Ecriture du fichier de sortie pour le ratio 2.00/1.28 :
open(FILE_OUT, "> $file_out_20_128 ");
$file_out_20_128_mat= $file_out_20_128.".matrix"; # Fichier "matrix" pour GNUplot
$file_out_20_128_err= $file_out_20_128.".err";    # Fichier "erreur" pour GNUplot
open(FILE_OUT_MAT, "> $file_out_20_128_mat");
open(FILE_OUT_ERR, "> $file_out_20_128_err");

print "\n";
print color('bold red');
print " > Ecriture des fichiers de sortie :";
print color('bold blue');
print " - $file_out_20_128\n";
print "                                     - $file_out_20_128_mat\n";
print "                                     - $file_out_20_128_err\n";
print color('reset');

printf FILE_OUT ("\# Maélie & Daniel -- Exploitation des données d'albédo.\n");
printf FILE_OUT ("\# Date : $now_string\n");
printf FILE_OUT ("\# \n");
printf FILE_OUT ("\# sample\n");
printf FILE_OUT ("\# |  line\n");
printf FILE_OUT ("\# |  |  Data\n");
printf FILE_OUT ("\# |  |  |\n");

for (my $i = $sample_min; $i <= $sample_max; $i++) {
    $myline= "";
    for (my $j = $line_min; $j <= $line_max; $j++) {
        # Construction de la ligne du fichier "matrix" pour GNUplot :
        #$my_ratio= $ratio_2p00_1p28[$i][$j];
        #$myline= $myline." $my_ratio";
        # Ecriture dans le fichier de sortie où les indices 'sample' et 'line' apparaissent :
        #printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $ratio_2p00_1p28[$i][$j]);

        $my_ratio= $ratio_2p00_1p28[$i][$j];
        $my_err  = $Delta_ratio_2p00_1p28[$i][$j];
        
        $myline= $myline." $my_ratio";
        printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $my_ratio); # 
        printf FILE_OUT_ERR ("%3d%3d %10.7f\n", $i, $j, $my_err); # 
    }
    printf FILE_OUT_MAT ("$myline"."\n");
    printf FILE_OUT ("\#\n");
    printf FILE_OUT_ERR ("\#\n");
}
close(FILE_OUT);
close(FILE_OUT_MAT);
close(FILE_OUT_ERR);

# -----------------------------------------------------------
# Ecriture du fichier de sortie pour le ratio 1.59/1.28 :
open(FILE_OUT, "> $file_out_159_128 ");
$file_out_159_128_mat= $file_out_159_128.".matrix"; # Fichier "matrix" pour GNUplot
$file_out_159_128_err= $file_out_159_128.".err";    # Fichier "erreur" pour GNUplot
open(FILE_OUT_MAT, "> $file_out_159_128_mat");
open(FILE_OUT_ERR, "> $file_out_159_128_err");

print "\n";
print color('bold red');
print " > Ecriture des fichiers de sortie :";
print color('bold blue');
print " - $file_out_159_128\n";
print "                                     - $file_out_159_128_mat\n";
print "                                     - $file_out_159_128_err\n";
print color('reset');

printf FILE_OUT ("\# Maélie & Daniel -- Exploitation des données d'albédo.\n");
printf FILE_OUT ("\# Date : $now_string\n");
printf FILE_OUT ("\# \n");
printf FILE_OUT ("\# sample\n");
printf FILE_OUT ("\# |  line\n");
printf FILE_OUT ("\# |  |  Data\n");
printf FILE_OUT ("\# |  |  |\n");

for (my $i = $sample_min; $i <= $sample_max; $i++) {
    $myline= "";
    for (my $j = $line_min; $j <= $line_max; $j++) {
        # Construction de la ligne du fichier "matrix" pour GNUplot :
        #$my_ratio= $ratio_1p59_1p28[$i][$j];
        #$myline= $myline." $my_ratio";
        # Ecriture dans le fichier de sortie où les indices 'sample' et 'line' apparaissent :
        #printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $ratio_1p59_1p28[$i][$j]);

 	$my_ratio= $ratio_1p59_1p28[$i][$j];
 	$my_err  = $Delta_ratio_1p59_1p28[$i][$j];
 	
        $myline= $myline." $my_ratio";
        printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $my_ratio); # 
        printf FILE_OUT_ERR ("%3d%3d %10.7f\n", $i, $j, $my_err); #
    }
    printf FILE_OUT_MAT ("$myline"."\n");
    printf FILE_OUT ("\#\n");
    printf FILE_OUT_ERR ("\#\n");
}
close(FILE_OUT);
close(FILE_OUT_MAT);
close(FILE_OUT_ERR);

# -----------------------------------------------------------
# Ecriture du fichier de sortie pour le ratio 1.28/1.08 :
open(FILE_OUT, "> $file_out_128_108 ");
$file_out_128_108_mat= $file_out_128_108.".matrix"; # Fichier "matrix" pour GNUplot
$file_out_128_108_err= $file_out_128_108.".err";    # Fichier "erreur" pour GNUplot
open(FILE_OUT_MAT, "> $file_out_128_108_mat");
open(FILE_OUT_ERR, "> $file_out_128_108_err");

print "\n";
print color('bold red');
print " > Ecriture des fichiers de sortie :";
print color('bold blue');
print " - $file_out_128_108\n";
print "                                     - $file_out_128_108_mat\n";
print "                                     - $file_out_128_108_err\n";
print color('reset');

printf FILE_OUT ("\# Maélie & Daniel -- Exploitation des données d'albédo.\n");
printf FILE_OUT ("\# Date : $now_string\n");
printf FILE_OUT ("\# \n");
printf FILE_OUT ("\# sample\n");
printf FILE_OUT ("\# |  line\n");
printf FILE_OUT ("\# |  |  Data\n");
printf FILE_OUT ("\# |  |  |\n");

for (my $i = $sample_min; $i <= $sample_max; $i++) {
    $myline= "";
    for (my $j = $line_min; $j <= $line_max; $j++) {
        # Construction de la ligne du fichier "matrix" pour GNUplot :
        #$my_ratio= $ratio_1p28_1p08[$i][$j];
        #$myline= $myline." $my_ratio";
        # Ecriture dans le fichier de sortie où les indices 'sample' et 'line' apparaissent :
        #printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $ratio_1p28_1p08[$i][$j]);

	$my_ratio= $ratio_1p28_1p08[$i][$j];
	$my_err  = $Delta_ratio_1p28_1p08[$i][$j];
	
        $myline= $myline." $my_ratio";
        printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $my_ratio); # 
        printf FILE_OUT_ERR ("%3d%3d %10.7f\n", $i, $j, $my_err); # 
    }
    printf FILE_OUT_MAT ("$myline"."\n");
    printf FILE_OUT ("\#\n");
    printf FILE_OUT_ERR ("\#\n");
}
close(FILE_OUT);
close(FILE_OUT_MAT);
close(FILE_OUT_ERR);

# -----------------------------------------------------------
# Ecriture du fichier de sortie pour la moyenne de l'albédo dans la fenêtre à 5 microns


open(FILE_OUT, "> $file_out_moy5 ");
$file_out_moy5_mat= $file_out_moy5.".matrix"; # Fichier "matrix" pour GNUplot
$file_out_moy5_err= $file_out_moy5.".err";    # Fichier "erreur" pour GNUplot
open(FILE_OUT_MAT, "> $file_out_moy5_mat");
open(FILE_OUT_ERR, "> $file_out_moy5_err");

print "\n";
print color('bold red');
print " > Ecriture des fichiers de sortie :";
print color('bold blue');
print " - $file_out_moy5\n";
print "                                     - $file_out_moy5_mat\n";
print "                                     - $file_out_moy5_err\n";
print color('reset');

printf FILE_OUT ("\# Maélie & Daniel -- Exploitation des données d'albédo.\n");
printf FILE_OUT ("\# Date : $now_string\n");
printf FILE_OUT ("\# \n");
printf FILE_OUT ("\# sample\n");
printf FILE_OUT ("\# |  line\n");
printf FILE_OUT ("\# |  |  Data\n");
printf FILE_OUT ("\# |  |  |\n");

for (my $i = $sample_min; $i <= $sample_max; $i++) {
    $myline= "";
    for (my $j = $line_min; $j <= $line_max; $j++) {

	$my_moy5= $moy_albe5m[$i][$j];
	$my_err = $Delta_moy_albe_5micron[$i][$j];
	
        $myline= $myline." $my_moy5";
        printf FILE_OUT ("%3d%3d %10.7f\n", $i, $j, $my_moy5); # 
        printf FILE_OUT_ERR ("%3d%3d %10.7f\n", $i, $j, $my_err); # 
    }
    printf FILE_OUT_MAT ("$myline"."\n");
    printf FILE_OUT ("\#\n");
    printf FILE_OUT_ERR ("\#\n");
}
close(FILE_OUT);
close(FILE_OUT_MAT);
close(FILE_OUT_ERR);

# -----------------------------------------------------------

print color('bold red');   
print " > Done!\n";
print "\n";

exit(0);

































