clearinfo

################################################
# Ouverture des fichiers utiles
#################################################
son = Read from file: "sonlist.wav"
# Après qu'on a le son, on doit remiser la fréquence d'échantillonnage : nombre d'échantillons par seconde. 
freq_echant = Get sampling frequency
dico = Read Table from tab-separated file: "dico.txt"
select 'son'
intersection = To PointProcess (zeroes): 1, "no", "yes"
grille = Read from file: "sonlist.Textgrid"
nb_intervalles = Get number of intervals: 1
#il faut qu'on savoir il y acombien de interval au total
# la fréquence d'échantillon qu'on crée doit être conhérebte avec notre file de son original, donc ici on a mit 48000Hz
fichier_vide = Create Sound from formula: "sineWithNoise", 1, 0, 0.01, 48000, "0"


#################################################
#             DÉBUT DU PROGRAMME                #
#################################################
# boite de dialogue#
# ----------------------------------------------#

form TTS
 	comment Quelle phrase voulez-vous synthétiser ?

	optionmenu Choisir_la_phrase: 1
		
		option 1. la fille aime la musique		
		option 2. la fille aime manger de la pizza dans la forêt	
		option 3. la fille aime manger de la pizza avec le garçon
		option 4. la fille aime le chien		
		option 5. la fille aime le garçon
		option 6. le garçon aime la fille dans le forêt
		option 7. le garçon va dans la forêt avec la fille et le chien
		option 8. le garçon aime la musique et le chien
		option 9. le chien mange de la pizza dans le forêt
		option 10. le chien aime manger de la pizza avec le garçon
		

	comment Ou saisir un mot / une phrase à concaténer:
	text mot_ortho

	comment _________________________________________________________________________________
	
	comment Voulez-vous une modification prosodique ?
		boolean F0
    	boolean Duree

		
	comment _________________________________________________________________________________
	comment Voulez-vous enregistrer le fichier .wav à la fin ?
		boolean Enregistrement 1
	comment Voulez-vous supprimer les objets PRAAT à la fin du traitement  ?
		boolean Supprimer 1
endform


phrase$ [1] = "la fille aime la musique"
phrase$ [2] = "la fille aime manger de la pizza dans la forêt"
phrase$ [3] = "la fille aime manger de la pizza avec le garçon"
phrase$ [4] = "la fille aime le chien"
phrase$ [5] = "la fille aime le garçon"
phrase$ [6] = "le garçon aime la fille dans le forêt"
phrase$ [7] = "le garçon va dans la forêt avec la fille et le chien"
phrase$ [8] = "le garçon aime la musique et le chien"
phrase$ [9] = "le chien mange de la pizza dans la forêt"
phrase$ [10] = "le chien aime manger de la pizza avec le garçon"


# On a choisit une phrase dans la liste déroulante
if ( mot_ortho$ = "" )
	mot_ortho$ = phrase$[choisir_la_phrase]
	phrase_saisie = 0
else
	phrase_saisie = 1
endif

# ----------------------------------------------#
# vérification de chaque mot dans la phrase
# ----------------------------------------------#
espace = index(mot_ortho$, " ")

while espace > 0
	premier_mot$ = mid$(mot_ortho$,1,espace-1)
	mot_ortho$ = mid$(mot_ortho$,espace+1,length(mot_ortho$))

	@Synthese: premier_mot$
	espace = index(mot_ortho$, " ")
endwhile

if length(mot_ortho$) > 0
	premier_mot$ = mot_ortho$
	@Synthese: premier_mot$
endif

# ----------------------------------------------#
# Modification f0 et la durée 
# ----------------------------------------------#
if ( f0 )
	@manF
endif

if ( duree )
	@manD
endif
# ----------------------------------------------#
# Lecture du fichier son obtenu
# ----------------------------------------------#
select 'fichier_vide'
Play

# ----------------------------------------------#
# Enregistrement du fichier son obtenu
# ----------------------------------------------#
if ( enregistrement )
	Save as WAV file: "monson.wav"

endif

# Fin du programme et nettoyage
if ( supprimer )
	select all
	Remove
endif


##########################################
# 01 Procédure de synthèse d'un mot      #
##########################################
procedure Synthese: mot_synthetise$

	selectObject: 'dico'
	extract_dico = Extract rows where column (text): "orthographe", "is equal to", mot_synthetise$
	
	mot_phonetique$ = Get value: 1, "phonetique"
	mot_phonetique$ = mot_phonetique$ 

	appendInfoLine("Text to speech: " + mot_synthetise$ + " -> En phonétique: " + mot_phonetique$)
		
	nb_caracteres = length(mot_phonetique$)


	for y from 1 to nb_caracteres-1
		diphone$ = mid$(mot_phonetique$,y,2)
		phoneme1$ = left$(diphone$,1)
		phoneme2$ = right$(diphone$,1)
		
		diphoneget = 0
		for x from 1 to nb_intervalles-1
		
			select 'grille'
			st_intervalles = Get start time of interval: 1, x
			et_intervalles = Get end time of interval: 1, x
			label_intervalle$ = Get label of interval: 1, x
			label_intervalle_suivant$ = Get label of interval: 1, x+1
			et_interval_suivant = Get end time of interval: 1, x+1
							


			if (label_intervalle$ = phoneme1$ and label_intervalle_suivant$ = phoneme2$)
				diphoneget = diphoneget + 1
				# temps au centre de phonème
				m1 = st_intervalles+(et_intervalles - st_intervalles)/2
				m2 = et_intervalles + (et_interval_suivant - et_intervalles)/2
				
				# Recherche du temps correspondand à l'intersection avec 0 la plus proche
				select 'intersection'
				index1 = Get nearest index: m1
				m1 = Get time from index: index1

				index2 = Get nearest index: m2
				m2 = Get time from index: index2

				# Extraction du son du diphone
				select 'son'
				extrait_son = Extract part: m1, m2, "rectangular", 1, "no"

				# Concaténation du diphone
				select 'fichier_vide'
				plus 'extrait_son'
				fichier_vide = Concatenate

				removeObject: extrait_son ;
			endif
		endfor

	endfor

endproc

#####################################################
# 02modification prosodique de f0
#####################################################

procedure manF

selectObject: 'fichier_vide'
endTime=Get end time
manipulationProso = To Manipulation: 0.01, 75, 600
extractPitch = Extract pitch tier
Remove points between: 0, 0.85
Add point: 0.001,220
Add point: 0.45,220
Add point: 0.85,280
select 'manipulationProso' 
plus 'extractPitch' 
Replace pitch tier
select 'manipulationProso' 
fichier_mot = Get resynthesis (overlap-add)


endproc
##########################################
# 03modification de durée  
##########################################

procedure manD

selectObject: 'fichier_vide'
endTime=Get end time
manipulationProso = To Manipulation: 0.01, 75, 600
modificationDuree = Extract duration tier
Remove points between: 0, endTime

Add point: 0.01,1
Add point: 0.45,1.1
Add point: 0.451,1.5
Add point: 0.85,1.5
select 'manipulationProso' 
plus 'modificationDuree' 
Replace duration tier
select 'manipulationProso' 
fichier_vide= Get resynthesis (overlap-add)

endproc