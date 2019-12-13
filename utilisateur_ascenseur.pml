/*----------------------------------------------------------------------------------------
PROGRAMME PROMELA : SYSTEME DE CONTROLE D UN ASCENSUR
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les constantes
----------------------------------------------------------------------------------------*/
#define MAX 1000 //
#define timerTpsAttenteMax 20
#define appelAscMax  18 //Le nombre maximal d'appels simultanes a l'ascenseur 2*nbEtages - 2
#define persMax 5 //nombre maximal de personnes dans l'ascenseur




/*----------------------------------------------------------------------------------------
Les declarations
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les varialbes
----------------------------------------------------------------------------------------*/


mtype:sensDepl = { monter, descendre }; //sens de deplacement de l'ascenseur
mtype:etatPorte = { ouverte, fermee }//etats possibles des portes de l'ascenseur

typedef commandeAsc {
	int etage;
	mtype:sensDepl sens;
};


int etageCourantAsc = 0;
mtype:etatPorte etatPorteAsc = fermee;

/*----------------------------------------------------------------------------------------
Les canaux
----------------------------------------------------------------------------------------*/

chan chAppelAscenseur = [appelAscMax] of { commandeAsc, bool } ;
chan chCommandeAsc = [1] of { commandeAsc } ;


/*----------------------------------------------------------------------------------------
Les processus
----------------------------------------------------------------------------------------*/
/* ----------------------------
  Controleur
---------------------------- */

active proctype Controleur() {
    
	commandeAsc cmdAsc;
	
	 //copier le message a partir du canal chAppelAscenseur
	 //envoyer l'ordre a l'ascenseur
	 //recevoir la confirmation d'arrivee de l'ascenseur
	 //effacer le message traite correspondant du canal

	do	//traitement des appels a l'ascenseur (de l'exterieur)

		:: empty(chCommandeAsc) -> chAppelAscenseur?cmdAsc, true; 
									chCommandeAsc!cmdAsc

		:: nempty(chCommandeAsc) -> //attendre la confirmation que l'ascenseur a fini	 
									do
										:: (cmdAsc.etage == etageCourantAsc) && (etatPorteAsc == ouverte) -> break
									od
	od
}


/* ----------------------------
  AppuisMultiples
---------------------------- */
proctype AppuisMultiples() priority 100{

	commandeAsc cmdNonVerif, cmdTemp;
	bool verifie = false;
	int _tmp_;

debut: 	
	//verification des commandes multiples	chAppelAscenseur
	do
		::chAppelAscenseur??cmdNonVerif, false -> //extraction du 1er message non verifie

		//parcourrir le canal pour comparer
		_tmp_ = 0;
		do
		:: _tmp_ < len(chAppelAscenseur) ->
			chAppelAscenseur?cmdTemp, verifie; /* rotate in place */
			chAppelAscenseur!cmdTemp, verifie;	

			verifie && (cmdTemp.etage ==  cmdNonVerif.etage) && (cmdTemp.sens ==  cmdNonVerif.sens) -> goto debut
			/* from the user code in the for body */
	
			/* from the user code in the for body */
			_tmp_++

		::_tmp_ == len(chAppelAscenseur) -> chAppelAscenseur!cmdNonVerif, true;

		:: else ->  goto debut
		od
		

	od
};


/* ----------------------------
  Ascenseur 
---------------------------- */

active proctype Ascenseur() {

	commandeAsc cmd;

	do
		::chCommandeAsc?cmd ->
			printf("Ascenseur arrive a Etage %d \n", cmd.etage);
		 	etageCourantAsc = cmd.etage ; etatPorteAsc = ouverte;
		 
	od

};

/* ----------------------------
  Utilisateur
---------------------------- */

proctype Utilisateur(int etageUtilisateur; mtype:sensDepl sens) {
	
	commandeAsc cmdAsc;
	cmdAsc.etage = etageUtilisateur;
	cmdAsc.sens = sens;
	
	//l'utilisateur appelle l'ascenseur
	chAppelAscenseur!cmdAsc, false ; printf("utilisateur %d appelle asc: (Etage %d, %e)\n", _pid,cmdAsc.etage,sens);
														
	do //attente de l'ascenseur
		::(etageUtilisateur == etageCourantAsc) && (etatPorteAsc == ouverte) -> 
			atomic { 
				//printf("Ascenseur arrive a Etage %d \n", etageUtilisateur);
				printf("utilisateur %d entre asc: (Etage %d, %e)\n", _pid,cmdAsc.etage,sens)  ; break //entrer dans l'ascenseur
			}
	od

		//entrerDansAsc: //chDetectionEntree!SIGNAL_UTIL_DANS_ASC;
						
};


/*----------------------------------------------------------------------------------------
Initialisations
----------------------------------------------------------------------------------------*/

init{
	atomic{
	run Utilisateur(0, monter);
	run Utilisateur(0, monter);
	run Utilisateur(0, monter);
	run Utilisateur(0, monter);
	run AppuisMultiples()
	}
}
