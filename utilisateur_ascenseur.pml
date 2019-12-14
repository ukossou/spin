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
mtype:etatPorte etatPorteAsc = ouverte;

/*----------------------------------------------------------------------------------------
Les canaux
----------------------------------------------------------------------------------------*/

chan chMonter = [NB_APPELS_MAX] of { byte };
chan chCommandeAsc = [1] of { byte };


inline enleverMonteeMultiples(etage) {
	byte etageAvant;
	debut:
	
	do
		::chMonter?<etageAvant>;
		::(etage == etageAvant) -> chMonter?etageAvant//atomic {chMonter?etageAvant;printf("chMonter multiple [%d] efface\n",etage);printCh(chMonter)}
		::(etage != etageAvant) || empty(chMonter)	-> break							
	od
};

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

active proctype Controleur() priority 5 {
    
	byte cmdAsc;
	
	do	
		::chMonter?cmdAsc -> atomic {enleverMonteeMultiples(cmdAsc); chCommandeAsc!cmdAsc}									
	od
};

/* ----------------------------
  Ascenseur 
---------------------------- */

active proctype Ascenseur() {

	byte cmd;

	do
		::chCommandeAsc?cmd 
			
		::(cmd >= etageCourantAsc) -> atomic {
			etageCourantAsc = cmd ; etatPorteAsc = ouverte; 
			printf("Ascenseur arrive a Etage %d \n", cmd);printCh(chMonter); chCommandeAsc?cmd} 	
	od

};

/* ----------------------------
  Utilisateur
---------------------------- */

proctype Utilisateur(byte etage; mtype:sensDepl sens) {

	if//appel de l'ascenseur
		::(sens == monter) -> atomic { printf("utilisateur %d appelle asc: (Etage %d, %e)\n", _pid,etage,sens); chMonter!!etage;}
									 
		//::else //(sens == descendre) -> chDescendre!etageUtilisateur
	fi
													
	do //attente de l'ascenseur
		::(etage == etageCourantAsc) && (etatPorteAsc == ouverte) -> 
			atomic {printf("utilisateur %d entre asc: (Etage %d, %e)\n", _pid,etage,sens)  ; break} //entrer dans l'ascenseur
	od					
};

proctype runUtilisateurs(){

	run Utilisateur(10, monter);
	run Utilisateur(1, monter);

	run Utilisateur(2, monter);
	
	run Utilisateur(10, monter);
	run Utilisateur(4, monter);
	
	run Utilisateur(10, monter);
	run Utilisateur(16, monter);

	run Utilisateur(7, monter);
	run Utilisateur(10, monter);
};


/*----------------------------------------------------------------------------------------
Initialisations
----------------------------------------------------------------------------------------*/

init{

	run runUtilisateurs();
};

