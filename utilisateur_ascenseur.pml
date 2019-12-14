/*----------------------------------------------------------------------------------------
PROGRAMME PROMELA : SYSTEME DE CONTROLE D UN ASCENSUR
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les constantes
----------------------------------------------------------------------------------------*/
#define MAX 1000 //
#define NB_ETAGES  10 //Le nombre d'etages
#define NB_APPELS_MAX (NB_ETAGES - 1) //nombre max d'appels dans un sens de deplacement




/*----------------------------------------------------------------------------------------
Les declarations
----------------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------------
Les varialbes
----------------------------------------------------------------------------------------*/


mtype:sensDepl = { monter, descendre }; //sens de deplacement de l'ascenseur
mtype:etatPorte = { ouverte, fermee }//etats possibles des portes de l'ascenseur


int etageCourantAsc = 0;
mtype:etatPorte etatPorteAsc = fermee;

/*----------------------------------------------------------------------------------------
Les canaux
----------------------------------------------------------------------------------------*/

chan chMonter = [NB_APPELS_MAX] of { byte };
chan chCommandeAsc = [1] of { byte };


inline enleverMonteeMultiples(etage) {
	byte etageAvant;
	debut:
	chMonter?<etageAvant>;
	do
		::(etage == etageAvant) -> chMonter?_; atomic {printf("chMonter multiple [%d] efface\n",etage);printCh(chMonter);}; goto debut
		::else -> break 								
	od
}

inline printCh(channel){
	int tmp = 0;
	byte msg;
	do
		:: tmp < len(channel) ->
			channel?msg; channel!msg;		/* rotate in place */
			printf("[%d]\n", msg);
			tmp++
		:: else -> break
	od			
}
/*----------------------------------------------------------------------------------------
Les processus
----------------------------------------------------------------------------------------*/
/* ----------------------------
  Controleur
---------------------------- */

active proctype Controleur() {
    
	byte cmdAsc;
	
	do	
		:: chMonter?cmdAsc -> atomic {enleverMonteeMultiples(cmdAsc); chCommandeAsc!cmdAsc}

		//:: (cmdAsc.etage == etageCourantAsc) && (etatPorteAsc == ouverte) -> goto envoyerCmdAsc
	od
}


/* ----------------------------
  AppuisMultiples
---------------------------- */


/* ----------------------------
  Ascenseur 
---------------------------- */

active proctype Ascenseur() {

	byte cmd;

	do
		::chCommandeAsc?cmd -> 
			atomic {/*enleverMonteeMultiples(cmd);*/printf("Ascenseur arrive a Etage %d \n", cmd);printCh(chMonter);
		 	etageCourantAsc = cmd ; etatPorteAsc = ouverte;	} 
	od

};

/* ----------------------------
  Utilisateur
---------------------------- */

proctype Utilisateur(byte etage; mtype:sensDepl sens) {

	if//appel de l'ascenseur
		::(sens == monter) -> atomic {chMonter!!etage; 
									 printf("utilisateur %d appelle asc: (Etage %d, %e)\n", _pid,etage,sens)}
		::else //(sens == descendre) -> chDescendre!etageUtilisateur
	fi
													
	do //attente de l'ascenseur
		::(etage == etageCourantAsc) && (etatPorteAsc == ouverte) -> 
			printf("utilisateur %d entre asc: (Etage %d, %e)\n", _pid,etage,sens)  ; break //entrer dans l'ascenseur
	od					
};


/*----------------------------------------------------------------------------------------
Initialisations
----------------------------------------------------------------------------------------*/

init{
	run Utilisateur(3, monter);
	run Utilisateur(10, monter);
	run Utilisateur(3, monter);
	run Utilisateur(0, monter);
	run Utilisateur(3, monter);
	run Utilisateur(0, monter);
	run Utilisateur(18, monter);
	run Utilisateur(0, monter);
	run Utilisateur(3, monter);
}
